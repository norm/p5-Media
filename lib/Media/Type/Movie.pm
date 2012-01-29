use utf8;
use Modern::Perl;
use MooseX::Declare;

role Media::Type::Movie {
    use File::Path      qw( mkpath );
    use IMDB::Film;
    use Try::Tiny;
    
    has type => (
        isa     => 'Str',
        is      => 'ro',
        default => 'Movie',
    );
    has details => (
        isa      => 'HashRef',
        is       => 'ro',
        required => 1,
    );
    
    method get_tag_elements {
        my $extras_as_tv     = $self->get_config( 'movie_extras_as_tv' )
                               && defined $self->details->{'extra'};
        
        my @elements;
        if ( $extras_as_tv ) {
            my $title = sprintf '%s - %s',
                $self->get_movie_filename(),
                $self->details->{'extra'};
            
            @elements = (
                    '--TVShowName',     'DVD Extras',
                    '--title',          $title,
                    '--stik',           'TV Show',
                    '--genre',          'Documentary',
                );
        }
        else {
            my $title = $self->details->{'extra'}
                        // $self->details->{'title'};
            @elements = (
                    '--stik',           'Movie',
                    '--year',           $self->details->{'year'},
                    '--title',          $title,
                    '--rDNSatom',       $self->get_uk_rating_string(),
                                        'name=iTunEXTC',
                                        'domain=com.apple.iTunes',
                    '--rDNSatom',       $self->get_movie_data(),
                                        'name=iTunMOVI',
                                        'domain=com.apple.iTunes',
                );
            
            my $plot = $self->details->{'plot'};
            if ( defined $plot ) {
                push @elements, '--longdesc', $plot;
                substr $plot, 252, length($plot), ' …'
                    if length $plot > 254;
                push @elements, '--description', $plot;
            }
            
            push( @elements, '--artist', $self->details->{'director'}[0] )
                if defined $self->details->{'director'}
                   && scalar @{ $self->details->{'director'} } >= 1;
            
            push( @elements, '--genre', $self->details->{'genre'}[0] )
                if defined $self->details->{'genre'}
                   && scalar @{ $self->details->{'genre'} } >= 1;
        }
        
        return @elements;
    }
    method post_install {
        $self->create_symlinks()
            unless defined $self->get_config( 'single_directory' )
                or defined $self->details->{'extra'};
    }
    
    method get_default_priority {
        return 50;
    }
    # FIXME - refactor to common code between TV and Movie
    method get_processing_directory {
        my $path  = $self->get_movie_filename();
        my $extra = $self->details->{'extra'};
        
        $extra = "Title " . $self->details->{'key'}
            if !defined $self->details->{'feature'} && !defined $extra;
        
        $path .= " - ${extra}"
            if defined $extra;

        return $path;
    }
    method get_destination_directory {
        my $single = $self->get_config( 'single_directory' );
        return $single if defined $single;
        
        return $self->get_extra_as_tv_directory()
            if ( $self->get_config( 'movie_extras_as_tv')
                 && $self->details->{'extra'} );
        
        my $dir    = $self->get_config( 'movies_directory' );
        my $subdir = $self->get_movie_directory();
        return "${dir}/${subdir}";
    }
    method get_destination_filename {
        return $self->get_extra_filename()
            if $self->details->{'extra'};
        return $self->get_full_movie_filename();
    }
    method get_job_name {
        return $self->get_full_movie_name();
    }
    
    method create_symlinks {
        my $movie_dir   = $self->get_movie_directory();
        my $filename    = $self->get_destination_filename();
        my $target      = "../../$movie_dir/$filename";
        my $movies_base = $self->get_config( 'movies_directory' );
        
        foreach my $genre ( @{ $self->details->{'genre'} } ) {
            my $directory = "$movies_base/Genre/$genre";
            $self->link_movie( $target, $directory, $filename );
        }
        foreach my $actor ( @{ $self->details->{'actor'} } ) {
            my $directory = "$movies_base/Actor/$actor";
            $self->link_movie( $target, $directory, $filename );
        }
        foreach my $director ( @{ $self->details->{'director'} } ) {
            my $directory = "$movies_base/Director/$director";
            $self->link_movie( $target, $directory, $filename );
        }
        foreach my $writer ( @{ $self->details->{'writer'} } ) {
            my $directory = "$movies_base/Writer/$writer";
            $self->link_movie( $target, $directory, $filename );
        }
        
        my $year = $self->details->{'year'};
        $self->link_movie( $target, "$movies_base/Year/$year", $filename )
            if defined $year;
    }
    method link_movie ( $original, $dir, $filename ) {
        my $target = "$dir/$filename";
        
        mkpath $dir;
        symlink $original, $target;
    }
    
    method get_movie_directory {
        my $subdir = $self->get_config( 'movie_extras_as_tv' )
                        ? ''
                        : '/' . $self->get_full_movie_directory();
        
        return "All${subdir}";
    }
    method get_full_movie_filename {
        my $path  = $self->get_movie_filename();
        my $extra = $self->details->{'extra'};
        
        $extra = "Title " . $self->details->{'key'}
            if !defined $self->details->{'feature'} && !defined $extra;
        
        $path .= " - ${extra}"
            if defined $extra;
        
        return "$path.m4v";
    }
    method get_movie_filename {
        my $title  = $self->details->{'title'}  // 'No Title';
        my $year   = $self->details->{'year'}   // '';
        my $rating = $self->details->{'rating'} // '';
        
        $year   = " ($year)"    if length $year;
        $rating = " - $rating"  if length $rating;
        
        return "${title}${rating}${year}";
    }
    method get_extra_filename {
        return $self->details->{'extra'} . '.m4v';
    }
    method get_full_movie_name {
        my $path  = $self->get_movie_filename();
        my $extra = $self->details->{'extra'};
        
        $extra = "Title " . $self->details->{'key'}
            if !defined $self->details->{'feature'} && !defined $extra;
        
        $path .= " - ${extra}"
            if defined $extra;
        
        return $path;
    }
    method get_full_movie_directory {
        return $self->get_movie_filename();
    }
    method get_extra_as_tv_directory {
        my $dir   = $self->get_config( 'tv_directory' );
        my $movie = $self->get_movie_filename();
        
        return "$dir/DVD Extras/$movie";
    }

    method get_uk_rating_string {
        my $rating = $self->details->{'rating'};
        
        return 'PG'  eq $rating ? 'uk-movie|PG|200|'
             : '12'  eq $rating ? 'uk-movie|12|300|'
             : '12A' eq $rating ? 'uk-movie|12A|325|'
             : '15'  eq $rating ? 'uk-movie|15|350|'
             : '18'  eq $rating ? 'uk-movie|18|400|'
             : $rating;
    }
    method get_movie_data {
        my $studio    = $self->details->{'company'} // '';
        my $cast      = '';
        my $directors = '';
        my $writers   = '';

        my $array_key = <<XML;
    <dict>
        <key>name</key>
        <string>%s</string>
    </dict>
XML

        foreach my $actor ( @{ $self->details->{'actor'} } ) {
            $cast .= sprintf $array_key, $actor;
        }
        foreach my $director ( @{ $self->details->{'director'} } ) {
            $directors .= sprintf $array_key, $director;
        }
        foreach my $writer ( @{ $self->details->{'writer'} } ) {
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
    
    
    method parse_title_string ( $title, $hints? ) {
        my $type = $hints->{'type'};
        return if defined $type && $type ne 'Movie';
        
        # strip a potential pathname into the last element
        $title =~ s{ (?: .*? / )? ([^/]+) (?: / )? $}{$1}x;
        
        if ( defined $hints and defined $hints->{'strip_extension'} ) {
            $title =~ s{ \. [^\.]+ $}{}x;
            delete $hints->{'strip_extension'};
        }
        
        my $confidence = 0;
        my %details;
        
        # hints affect confidence
        $confidence += 2 if defined $hints->{'year'};
        $confidence += 2 if defined $hints->{'rating'};
        $confidence += 2 if defined $hints->{'extra'};
        
        # movie title looks like:
        # Gone With the Wind
        # Ghostbusters (1984)
        # Who Do I Gotta Kill? - 15 (1994)
        #
        # movie extras (found on many DVDs) look like:
        # Bill & Ted's Excellent Adventure (1989) - Outtakes
        my $movie_title = qr{
                ^
                    (?:
                        (?<title> .*? )
                        (?:
                            \s+ - \s+
                            (?<rating> \w+ )?
                        )
                        (?:
                            \s+
                            \(
                            (?<year> \d+ )
                            \)
                        )
                        (?:
                            \s+ - \s+
                            (?<extra> .* )
                        )?
                    |
                        (?<title> .*? )
                        (?:
                            \s+ - \s+
                            (?<rating> \w+ )
                        )?
                        (?:
                            \s+
                            \(
                            (?<year> \d+ )
                            \)
                        )?
                        (?:
                            \s+ - \s+
                            (?<extra> .* )
                        )?
                    )
                $
            }x;

        if ( $title =~ $movie_title ) {
            %details = %+;
            
            if ( %$hints ) {
                %details = (
                        %details,
                        %$hints,
                    );
            }
            
            return unless $details{'title'};
            
            # traits that identify this as a legitimate movie
            $confidence++ if defined $details{'rating'};
            $confidence++ if defined $details{'year'};
            
            # 'feature' is a required attribute for the actual movie
            $details{'feature'} = 1
                unless defined $details{'extra'};
            
            # look up extra information in the IMDB
            my $found_movie = 1;
            my $data_dir    = $self->config->{''}{'cache_directory'};
            my $imdb;
            
            foreach my $attempt ( 1..3 ) {
                try {
                    $imdb = IMDB::Film->new(
                            crit       => $details{'title'},
                            year       => $details{'year'},
                            cache      => 1,
                            cache_root => "${data_dir}/imdb",
                        );
                }
                catch {
                    # from IMDB::Film "in some case it can be returned 
                    # critical error", so try again in a moment
                    say STDERR 'IMDB 500 error on ' . $details{'title'};
                    sleep 5;
                };
                last if defined $imdb;
            }
            
            return unless defined $imdb;
            
            if ( !defined $imdb->title() && defined $imdb->error ) {
                $found_movie = 0;
            }
            else {
                $found_movie = 0
                    if $imdb->kind() eq 'tv series';
                $found_movie = 0
                    if $imdb->kind() eq 'tv mini series';
                $found_movie = 0
                    if $imdb->kind() eq 'episode';
            }
            
            if ( $found_movie ) {
                my $use_imdb = $self->config->{''}{'use_imdb'};
                
                my $similarity 
                    = $self->compare_titles( $details{'title'}, $imdb );
                $confidence += (1 - $similarity) * 3;
                
                $details{'year'} = $imdb->year()
                    if !defined $details{'year'} || $use_imdb;
                $details{'title'} = $self->repair_title( $imdb->title() )
                    if $use_imdb;
                
                if ( !defined $details{'rating'} || $use_imdb ) {
                    my $certs = $imdb->certifications();
                    $details{'rating'} = $self->get_normalised_rating(
                        $certs->{'UK'} // $certs->{'USA'}
                    );
                }
                
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
                
                $details{'company'} = $imdb->company();
                $details{'plot'}    = $imdb->full_plot();
            }
            
            return( $confidence, %details );
        }
        
        # no match
        return;
    }
    method repair_title ( $title ) {
        $title =~ s{\s*:\s*}{ - }g;
        
        return $title;
    }
    method get_normalised_rating ( $rating ) {
        return '12' if $rating eq '12A';
        return 'PG' if $rating eq 'A';
        return '15' if $rating eq 'X';
        return $rating;
    }
}
