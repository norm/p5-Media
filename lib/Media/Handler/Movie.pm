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
    # is of type Movie if the string can be parsed into metadata
    my ( $confidence, %details ) = $self->parse_type_string( $name );
    if ( %details ) {
        return ( 'Movie', $confidence );
    }
    
    return;
}

method install_file ( Str $directory, Str $file ) {
    my( undef, %details ) = $self->parse_type_string( $directory );
    my $extension         = $self->get_file_extension( $file );
    
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
    my( undef, $filename ) 
        = $self->get_movie_location( $details, $extension );
    
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
    my $rating    = $self->get_rating_string( $details->{'rating'} );
    my $movi_data = $self->get_movie_data( $details );
    
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
        q(--contentRating), "$rating",
        q(--stik),          q(Movie);
    
    my $media = $self->get_media();
    $media->tag_file( $file, \@arguments );
}

method parse_type_string ( $title_string ) {
    my %details = $self->details_from_location( $title_string );
    return %details if %details;
    
    my $type = $self->strip_leading_directories( $title_string );
       $type = $self->strip_type_hint( $type );
    
    my $confidence;
    ( $confidence, %details ) = $self->parse_title_string( $type );
    return ( $confidence, %details ) 
        if %details;
    
    return $self->parse_title_string( $title_string );
}
method parse_title_string ( $title ) {
    my $confidence = 0;
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
                    (?<rating> \w+ )
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
        
        # 'feature' is a required attribute
        $details{'feature'} = 1
            unless defined $details{'extra'};
        
        # traits that identify this as a legitimate movie
        $confidence = 1
            if defined $details{'rating'} and defined $details{'year'};

        # look up extra information in the IMDB
        my $found_movie = 1;
        my $imdb        = IMDB::Film->new(
                crit  => $details{'title'},
                year  => $details{'year'},
                cache => 1,
            );
        
        $found_movie = 0
            unless $imdb->title();
        $found_movie = 0
            if $imdb->kind() eq 'tv series';
        $found_movie = 0
            if $imdb->kind() eq 'tv mini series';
        $found_movie = 0
            if $imdb->kind() eq 'episode';
        
        if ( $found_movie ) {
            $confidence++;
            
            my $looked_up_same_film = 0;
            my $imdb_title          = $imdb->title();
            
            if ( $details{'title'} eq $imdb_title ) {
                $looked_up_same_film = 1;
            }
            elsif ( $imdb_title =~ $details{'title'} ) {
                $looked_up_same_film = 1;
            }
            
            $confidence += 2
                if $looked_up_same_film;
            
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
            
            if ( !defined $details{'rating'} ) {
                my $certs = $imdb->certifications();
                $details{'rating'} = $certs->{'UK'} 
                                  // $certs->{'USA'} 
                                  // 'Unrated';
            }
            
            $details{'company'} = $imdb->company();
            $details{'plot'}    = $imdb->full_plot();
        }
        
        return( $confidence, %details );
    }
    
    # no match
    return;
}
method get_rating_string ( Str $rating ) {
    return 'PG' eq $rating ? 'PG (UK)'
         : '12' eq $rating ? '12 (UK)'
         : '15' eq $rating ? '15 (UK)'
         : '18' eq $rating ? '18 (UK)'
         : $rating;
}
method get_movie_data ( HashRef $details ) {
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
            
            title  => $config->{''}{'title'},
            year   => $config->{''}{'year'},
            rating => $config->{''}{'rating'},
            poster => $config->{''}{'poster'},
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
        my $full_details = qr{
                    /
                    (?<title> [^/]+ )
                    \s+ - \s+
                    (?<rating> \w+ )
                    \s+
                    \(
                    (?<year> \d+ )
                    \)
                    \. [^\.]+
                $
            }x;
        
        if ( $pathname =~ $full_details ) {
            my %details = %+;
            $details{'feature'} = 1;
            return %details;
        }
        
        # All/Serenity - 15 (2005)/Deleted Scenes.avi
        my $extra_content = qr{
                    (?<title> [^/]+ )
                    \s+ - \s+
                    (?<rating> \w+ )
                    \s+
                    \(
                    (?<year> \d+ )
                    \)
                    /
                    (?<extra> [^/]+ )
                    \. [^\.]+
                $
            }x;
        
        if ( $pathname =~ $extra_content ) {
            my %details = %+;
            $details{'feature'} = 1
                unless defined $details{'extra'};
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
    my $title  = $details->{'title'} 
                 // 'No Title';
    my $year   = $details->{'year'} 
                 // '1900';
    my $rating = $details->{'rating'}
                 // 'NR';
    
    return "${title} - ${rating} (${year})";
}
method get_processing_directory ( HashRef $details ) {
    my $path  = $self->get_movie_filename( $details );
    my $extra = $details->{'extra'};
    
    if ( !defined $details->{'feature'} && !defined $extra ) {
        $extra = "Title $details->{'key'}";
    }
    
    if ( defined $extra ) {
        $path .= " - ${extra}";
    }
    
    return $path;
}
method get_movie_directory {
    my $media = $self->get_media();
    
    return $media->get_config( 'movie_directory' );
}

1;
