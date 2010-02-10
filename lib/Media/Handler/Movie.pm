package Media::Handler::Movie;

use Modern::Perl;
use MooseX::FollowPBP;
use Moose;
use MooseX::Method::Signatures;

extends 'Media::Handler';

use File::Path;
use File::Temp;
use IO::All;
use IMDB::Film;
use LWP::UserAgent;


method is_type ( Str $name ) {
    # it is of Movie type if:
    # we have the hinted type at the start of the string
    my ( $hint, undef ) = $self->parse_type_for_hint( $name );
    if ( defined $hint ) {
        return $hint;
    }
    
    # or the string can be parsed into metadata
    if ( defined $self->parse_type_string( $name ) ) {
        return 'Movie';
    }
    
    return;
}

method install_file ( Str $directory, Str $file ) {
    my %details   = $self->parse_type_string( $directory );
    my $extension = $self->get_file_extension( $file );
    
    my( $destination_directory, $destination_filename ) 
        = $self->get_movie_location( \%details, $extension );
    my $target = "${directory}/${file}";
    
    $self->tag_file( $target, \%details );
    my $moved_to 
        = $self->safely_move_file( 
                $target,
                $destination_directory, 
                $destination_filename 
            );
    
    # only the main feature is linked to multiple locations
    # and added to itunes, extras are not cluttering things up
    if ( !defined $details{'extra'} ) {
        $self->create_movie_links( $moved_to, \%details, $extension );
        $self->add_to_itunes( $moved_to );
    }
}

method create_movie_links ( Str $origin, HashRef $details, Str $extension ) {
    my $year = $details->{'year'} // '1900';
    $self->link_movie( $origin, "Year/${year}", $filename );
    
    foreach my $genre ( @{ $details->{'genre'} } ) {
        $self->link_movie( $origin, "Genre/${genre}", $filename );
    }
    foreach my $actor ( @{ $details->{'actor'} } ) {
        $self->link_movie( $origin, "Actor/${actor}", $filename );
    }
    foreach my $director ( @{ $details->{'director'} } ) {
        $self->link_movie( $origin, "Director/${director}", $filename );
    }
    foreach my $writer ( @{ $details->{'writer'} } ) {
        $self->link_movie( $origin, "Writer/${writer}", $filename );
    }
}
method link_movie ( Str $origin, Str $directory, Str $filename ) {
    my $base        = $self->get_movie_directory();
    my $destination = "${base}/${directory}";
    my $target      = "${destination}/${filename}";
    
    mkpath( $destination );
    symlink( $origin, $target );
}
method tag_file ( Str $file, HashRef $details ) {
    my( $directory, undef, $extension ) = $self->get_path_segments( $file );
    return unless '.m4v' eq $extension;
    
    my $genre     = join( ', ', @{ $details->{'genre'} } );
    my $director  = join( ', ', @{ $details->{'director'} } );
    my $movi_data = $self->get_movi_data( $details );
    
    my @arguments;
    if ( -f "$directory/poster.jpg" ) {
        push @arguments, 
            q(--artwork),   "$directory/poster.jpg";
    }
    
    push @arguments, 
        q(--description),   $details->{'plot'},
        q(--title),         $details->{'title'},
        q(--year),          $details->{'year'},
        q(--artist),        $director,
        q(--genre),         $genre,
        q(--rDNSatom),      $movi_data, 
                            q(name=iTunMOVI), 
                            q(domain=com.apple.iTunes),
        q(--contentRating), $details->{'rating'},
        q(--stik),          q(Movie);
    
    my $media = $self->get_media();
    $media->tag_file( $file, \@arguments );
}

method parse_type_string ( $title_string ) {
    my %details = $self->details_from_location( $title_string );
    return %details if %details;
    
    my $type = $self->strip_leading_directories( $title_string );
       $type = $self->strip_type_hint( $type );
    
    %details = $self->parse_title_string( $type );
    return %details if %details;
    
    return $self->parse_title_string( $title_string );
}
method parse_title_string ( $title ) {
    my %details;
    
    # movie title looks like:
    # Ghostbusters (1984)
    # Who Do I Gotta Kill? - 15 (1994)
    #
    # movie extras (found on many DVDs) look like:
    # Bill & Ted's Excellent Adventure (1989) - Outtakes
    my $movie_title = qr{
            ^
                (?<title> .*? )
                (?:
                    \s+ - \s+
                    (?<certificate> \w+ )
                )?
                \s+
                \(
                (?<year> \d+ )
                \)
                (?:
                    \s+ - \s+
                    (?<extra> .* )
                )?
            $
        }x;
    
    if ( $title =~ $movie_title ) {
        %details = %+;
        
        # look up extra information in the IMDB
        my $imdb = IMDB::Film->new( 
                crit  => $details{'title'}, 
                year  => $details{'year'},
                cache => 1,
            );
        
        # make sure we've found the same thing
        if ( $details{'title'} eq $imdb->title() ) {
            foreach my $director ( @{ $imdb->directors() } ) {
                my $name = $director->{'name'};
                push @{ $details{'director'} }, $name;
            }
            
            foreach my $genre ( @{ $imdb->genres() } ) {
                push @{ $details{'genre'} }, $genre;
            }
            
            my $count = 0;
            foreach my $actor ( @{ $imdb->cast() } ) {
                my $name = $actor->{'name'};
                push @{ $details{'actor'} }, $name;
                last if ++$count == 10;
            }
            
            foreach my $writer ( @{ $imdb->writers() } ) {
                my $name = $writer->{'name'};
                push @{ $details{'writer'} }, $name;
            }
            
            if ( !defined $details{'certificate'} ) {
                my %certs = $imdb->certifications();
                $details{'rating'} = $certs{'UK'} 
                                  // $certs{'USA'} 
                                  // 'Unrated';
            }
            
            $details{'company'} = $imdb->company();
            $details{'plot'}    = $imdb->full_plot();
        }
        
        return %details;
    }
    
    # no match
    return;
}
method get_movi_data ( HashRef $details ) {
    my $studio    = $details->{'company'};
    my $cast      = '';
    my $directors = '';
    my $writers   = '';
    
    my $array_key = <<XML;
    <dict>
        <key>name</key>
        <string>%s</string>
    </dict>
XML

    foreach my $actor ( @{ $details->{'actor'} } ) {
        $cast .= sprintf $array_key, $actor;
    }
    foreach my $director ( @{ $details->{'director'} } ) {
        $directors .= sprintf $array_key, $director;
    }
    foreach my $writer ( @{ $details->{'writer'} } ) {
        $writers .= sprintf $array_key, $writer;
    }
    
    return <<XML;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>studio</key>
    <key>${studio}</key>
    <key>cast</key>
    <array>
${cast}
    </array>
    <key>directors</key>
    <array>
${directors}
    </array>
    <key>screenwriters</key>
    <array>
${writers}
    </array>
</dict>
</plist>
XML
}
method get_dvd_details ( HashRef $config, Str $key ) {
    my %details = (
            %{ $config->{ $key } },
            
            title       => $config->{''}{'title'},
            year        => $config->{''}{'year'},
            certificate => $config->{''}{'certificate'},
            poster      => $config->{''}{'poster'},
        );
    
    if ( defined $config->{ $key }{'title'} ) {
        $details{'extra'} = $config->{ $key }{'title'};
    }
    
    return %details;
}
method details_from_location ( Str $pathname ) {
    my $base = $self->get_config( 'movie_directory' );
    
    if ( $pathname =~ s{^$base/?}{}s ) {
        # All/Batman Begins - 12A (2005)/Batman Begins - 12A (2005).m4v
        # Genre/Science Fiction/Dark Star - PG (1974).avi
        
        # the leading directory is irrelevant
        $pathname =~ s{^ .*? ( [^/]+ ) $}{$1}sx;
        
        my $full_details = qr{
                ^
                    (?<title> .*? )
                    \s+ - \s+
                    (?<certificate> \w+ )
                    \s+
                    \(
                    (?<year> \d+ )
                    \)
                    \. [^\.]+
                $
            }x;
        
        if ( $pathname =~ $full_details ) {
            my %details = %+;
            return %details;
        }
    }
    return;
}
method get_movie_location ( HashRef $details, Str $extension ) {
    my $base       = $self->get_movie_directory();
    my $movie_path = $self->get_movie_filename( $details );
    
    my $directory  = "${base}/All/${movie_path}";
    my $filename   = "${movie_path}${extension}";
    my $extra      = $details->{'extra'};
    
    if ( defined $extra ) {
        $filename = "${extra}${extension}";
    }
    
    return( $directory, $filename );
}
method get_movie_filename ( HashRef $details ) {
    my $title       = $details->{'title'} 
                   // 'No Title';
    my $year        = $details->{'year'} 
                   // '1900';
    my $certificate = $details->{'certificate'}
                   // 'NR';
    
    return "${title} - ${certificate} (${year})";
}
method get_processing_directory ( HashRef $details ) {
    my $path  = $self->get_movie_filename( $details );
    my $base  = $self->get_config( 'base_directory' );
    my $extra = $details->{'extra'};
    
    if ( !defined $details->{'feature'} && !defined $extra ) {
        $extra = "Title $details->{'key'}";
    }
    
    if ( defined $extra ) {
        $path .= " - ${extra}";
    }
    
    return "${base}/${path}";
}
method get_movie_directory {
    my $media = $self->get_media();
    
    return $media->get_config( 'movie_directory' );
}

1;
