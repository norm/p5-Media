use Modern::Perl;
use MooseX::Declare;

role Media::Type::TV {
    use IMDB::Film;
    
    has type => (
        isa     => 'Str',
        is      => 'ro',
        default => 'TV',
    );
    has details => (
        isa      => 'HashRef',
        is       => 'ro',
        required => 1,
    );
    
    
    method get_tag_elements {
        my $episode_number = $self->details->{'episode'}
                             // $self->details->{'first_episode'};
        
        my @elements = (
                '--TVShowName',     $self->details->{'series'},
                '--TVSeasonNum',    $self->details->{'season'},
                '--TVEpisodeNum',   $episode_number,
                '--TVEpisode',      $self->get_episode_id(),
                '--title',          $self->details->{'title'},
                '--stik',           'TV Show',
            );
        
        return @elements;
    }
    method post_install {}
    
    method get_default_priority {
        my $priority = $self->get_config(
                $self->details->{'series'},
                'series_priority',
            );
        
        return defined $priority ? $priority : 50;
    }
    method get_processing_directory {
        return $self->get_full_episode_directory();
    }
    method get_destination_directory {
        my $single = $self->get_config( 'single_directory' );
        return $single if defined $single;
        
        my $dir    = $self->get_config( 'tv_directory' );
        my $subdir = $self->get_episode_location();
        return "${dir}/${subdir}";
    }
    method get_destination_filename {
        my $single = $self->get_config( 'single_directory' );
        return $self->get_full_episode_filename()
            if defined $single;
        
        return $self->get_short_episode_filename();
    }
    method get_job_name {
        return $self->get_full_episode_directory();
    }
    method get_priority_name {
        return $self->details->{'series'};
    }
    
    method get_episode_location {
        my $series  = '';
        my $season  = '';
        my $episode = '';
        my $title   = '';

        # fix anything without a valid series or season
        # (one-off TV shows, for example)
        if ( !defined $self->details->{'series'} ) {
            $series = 'Miscellaneous';
            $season = '';
        }
        else {
            $series = $self->details->{'series'};
            $season = ( defined $self->details->{'season'} )
                    ? sprintf( '/Season %s', $self->details->{'season'} )
                    : '';
        }

        if ( defined $self->details->{'first_episode'} ) {
            # concatenate multiple episodes to a range
            $episode = sprintf '%s-%s - ',
                           $self->details->{'first_episode'},
                           $self->details->{'last_episode'};
        }
        else {
            $episode = ( defined $self->details->{'episode'} ) 
                     ? sprintf( '%s - ', $self->details->{'episode'} )
                     : '';
        }

        if ( !defined $self->details->{'title'} ) {
            if ( defined $self->details->{'first_episode'} ) {
                $title = sprintf( 
                        'Episodes %s-%s',
                            $self->details->{'first_episode'}, 
                            $self->details->{'last_episode'}
                    );
            }
            elsif ( defined $self->details->{'episode'} ) {
                $title = sprintf( 'Episode %s', $self->details->{'episode'} );
            }
        }
        else {
            $title = $self->details->{'title'} // '';
        }

        if ( defined $self->details->{'special'} ) {
            if ( !defined $self->details->{'season'} ) {
                $season = '/Specials';
            }
            else {
                $episode = '';
            }
        }
        
        return "${series}${season}";
    }
    method get_full_episode_filename {
        return $self->get_full_episode_directory() . ".m4v";
    }
    method get_full_episode_directory {
        my $title      = $self->get_safe_title() // '';
        my $episode    = $self->details->{'episode'} // '';
        my $episode_id = $self->get_episode_id();
        my $season     = $self->details->{'season'};
        
        $episode_id = '' if $episode_id eq $title;
        $title      = " - $title"   if length $title;
        $episode_id = " - $episode_id"
            if length $episode_id && $episode_id ne $episode;
        $episode_id = " $episode_id"
            if length $episode_id && $episode_id eq $episode;
        
        return sprintf "%s%s%s",
                $self->details->{'series'},
                $episode_id,
                $title;
    }
    method get_short_episode_filename {
        my $episode = $self->get_episode_number() // '';
        my $title   = $self->get_safe_title();
        
        if ( !defined $title ) {
            if ( $self->details->{'first_episode'} ) {
                $title = sprintf "Episodes %s to %s",
                            $self->details->{'first_episode'},
                            $self->details->{'last_episode'};
            }
            else {
                $title = sprintf "Episode %s", $self->get_episode_number();
            }
        }
        
        $episode = "$episode - " if length $episode;
        
        return sprintf "%s%s.m4v",
                $episode,
                $title;
    }
    method get_safe_title {
        my $title = $self->details->{'title'};
        return unless defined $title;
        
        $title =~ s{[:/]+}{}g;
        return $title;
    }
    method get_episode_id {
        my $season  = $self->details->{'season'};
        my $episode = $self->get_episode_number();
        my $special = $self->details->{'special'};
        my $title   = $self->details->{'title'};
        
        my $separator = $self->details->{'dated'}
                            ? '.'
                            : 'x';
        
        return "$season - Round $episode"
            if defined $self->details->{'rounds'}
                && length $episode
                && length $season;
        
        $season = 'S'
            if !defined $season && defined $special;
        
        return sprintf(
                "%s%s%s", $season, $separator, $episode
            ) if defined $season && defined $episode;
        
        return $season  if defined $season && $season ne 'S';
        return $episode if defined $episode;
        return $title   if defined $title;
    }
    method get_episode_number {
        return sprintf( '%02d-%02d',
                    $self->details->{'first_episode'},
                    $self->details->{'last_episode'}
                ) if defined $self->details->{'first_episode'};
        
        my $format = defined $self->details->{'dated'}
                        ? '%s'
                        : '%02d';
        
        return sprintf( $format, $self->details->{'episode'} )
            if defined $self->details->{'episode'};
        
        return;
    }
    
    
    method parse_title_string ( $title, $hints? ) {
        my $type = $hints->{'type'};
        return if defined $type && $type ne 'TV';
        
        # strip a potential pathname into the last element
        $title =~ s{ (?: .*? / )? ([^/]+) (?: / )? $}{$1}x;
        
        if ( defined $hints and defined $hints->{'strip_extension'} ) {
            $title =~ s{ \. [^\.]+ $}{}x;
            delete $hints->{'strip_extension'};
        }
        
        my %details    = $self->get_title_string_elements( $title, $hints );
        my $confidence = 0;
        
        # hints affect confidence
        $confidence += 3 if defined $hints->{'series'};
        $confidence += 1 if defined $hints->{'season'};
        $confidence += 1 if defined $hints->{'episode'};
        
        if ( %details or defined $hints->{'series'} ) {
            if ( defined $hints ) {
                %details = (
                        %details,
                        %$hints,
                    );
            }
            
            return unless defined $details{'series'};
            
            my $data_dir    = $self->config->{''}{'cache_directory'};
            my $imdb        = IMDB::Film->new(
                    crit       => $details{'series'},
                    cache      => 1,
                    cache_root => "${data_dir}/imdb",
                );
            
            if ( defined $imdb->title() || scalar @{$imdb->matched} > 1 ) {
                # try for the 2nd match if 1st is movie, as IMDB prefers them
                if ( $imdb->kind() eq 'movie' ) {
                    my $second = $imdb->matched->[1];
                    
                    $imdb = IMDB::Film->new(
                            crit       => $second->{'id'},
                            cache      => 1,
                            cache_root => "${data_dir}/imdb",
                        ) if defined $second;
                }
                
                if ( $imdb->kind() =~ m{^tv} ) {
                    my $similarity
                        = $self->compare_titles( $details{'series'}, $imdb );
                    $confidence += (1 - $similarity) * 3;

                    $confidence++
                        if $imdb->kind() eq 'tv series';
                    $confidence++
                        if $imdb->kind() eq 'tv mini series';
                }
            }
            
            $confidence++
                if defined $details{'season'};
            $confidence++
                if defined $details{'disk'};
            $confidence++
                if defined $details{'episode'};
            $confidence++
                if defined $details{'first_episode'};
            $confidence++
                if defined $details{'special'};
        }

        return( $confidence, %details );
    }
    method get_title_string_elements ( $title, $hints? ) {
        my %words = ( 
                'one'  => 1, 'two' => 2, 'three' => 3, 'four'  => 4, 
                'five' => 5, 'six' => 6, 'seven' => 7, 'eight' => 8,
                'nine' => 9, 'ten' => 10
            );
        my %details;
        $hints = {}
            unless defined $hints;

        # standard episode title looks like:
        # House - 2x23 - Who's Your Daddy
        # The Kevin Bishop Show - 1x04
        # Grey's Anatomy - 5x03 - Here Comes the Flood    
        #
        # also covers specials outside of all seasons:
        # Time Team - Sx18 - Londinium, Greater London - Edge of Empire
        my $simple_episode_title = qr{
                ^
                    (?:
                        (?<series> .*? )
                        \s+ - \s+
                    )?
                    (?:
                        (?<season> [S\d]+ )
                        x
                    )?
                    (?<episode> \d+ )
                    (?:
                        \s+ - \s+
                        (?<title> .*? )
                    )?
                $
            }x;
        
        if ( $title =~ $simple_episode_title ) {
            %details = (
                    %+,
                    %$hints,
                );
            
            if ( defined $details{'season'} ) {
                if ( 'S' eq $details{'season'} ) {
                    $details{'special'} = 1;
                    delete $details{'season'};
                }
            }
            
            return %details;
        }
        
        # dated (not season-based) shows
        # The Daily Show - 2009-08-13 - Rachel McAdams
        # Vil Du Bli Millionr Hot Seat - 2010.01.04
        my $dated_episode_title = qr{
                ^
                    (?<series> .*? )
                    \s+ - \s+
                    (?<season> \d+ )
                    [\.-]
                    (?<episode> \d+ [\.-] \d+ )
                    (?:
                        \s+ - \s+
                        (?<title> .*? )
                    )?
                $
            }x;
        
        if ( $title =~ $dated_episode_title ) {
            %details = %+;
            $details{'episode'} =~ s{-}{.};
            $details{'dated'} = 1;
            return %details;
        }
        
        # sports events
        # NASCAR Nationwide Series 2009 - Round 01 - Daytona (Race)
        my $sports_event_title = qr{
                ^
                    (?<series> .*? )
                    \s+
                    (?<season> \d{4} )
                    \s+ - \s+ Round \s+
                    (?<episode> \d+ )
                    \s+ - \s+ 
                    (?<title> .*? )
                $
            }x;
        
        if ( $title =~ $sports_event_title ) {
            %details = %+;
            $details{'rounds'} = 1;
            return %details;
        }
        
        # sports events, specials
        # Bundesliga 2010 - Week 20: Highlights
        my $sports_event_special_title = qr{
                ^
                    (?<series> .*? )
                    \s+
                    (?<season> \d{4} )
                    \s+ - \s+ 
                    (?<title> .*? )
                $
            }x;
            
        if ( $title =~ $sports_event_special_title ) {
            %details = %+;
            
            $details{'special'} = 1;
            return %details;
        }
        
        # Shows in a series, not in a season
        # UFC 52 - Couture vs. Liddell 2
        # UFC 109: Relentless
        my $no_season_title = qr{
                ^
                    (?<series> .*? )
                    \s+
                    (?<episode> \d+ )
                    (?: \: \s+ | \s+ \- \s+ )
                    (?<title> .*? )
                $
            }x;
        
        if ( $title =~ $no_season_title ) {
            %details = %+;
            return %details;
        }
        
        # multiple episodes:
        # Bones - 4x01-02 - Yanks in the U.K.
        # Stargate Universe - 1x01-1x02 - Air
        # Tyler Perry's Meet the Browns - 1x10-01x20
        # (nb. this ignores the season-crossing format such as
        #  'Series - 1x01-2x06 - Blah' deliberately)
        my $multiple_episode_title = qr{
                ^
                    (?:
                        (?<series> .*? )
                        \s+ - \s+
                    )?
                    (?:
                        (?<season> \d+ )
                        x
                    )?
                    (?<first_episode> \d+ )
                    -
                    (?: \d+x )?
                    (?<last_episode> \d+ )
                    (?:
                        \s+ - \s+
                        (?<title> .*? )
                    )?
                $
            }x;
        
        if ( $title =~ $multiple_episode_title ) {
            %details = %+;
            
            foreach my $episode ( $+{'first_episode'}..$+{'last_episode'} ) {
                push @{ $details{'episodes'} }, $episode;
            }
            
            return %details;
        }
        
        # sports events, alternate
        # 2010 AMA Supercross Series - Supercross Class Round 5
        my $sports_event_title_alt = qr{
                ^
                    (?<season> \d+ )
                    \s+
                    (?<series> .*? )
                    \s+ - \s+ 
                    (?<title> .*? )
                $
            }x;
        
        if ( $title =~ $sports_event_title_alt ) {
            %details = %+;
            return %details;
        }
        
        # named special episodes
        # Top Gear - The Great Adventures Vietnam Special
        my $named_special_title = qr{
                ^
                    (?<series> .*? )
                    \s+ - \s+
                    (?<title> .*? Special )
                $
            }x;
        
        if ( $title =~ $named_special_title ) {
            %details = %+;
            $details{'special'} = 1;
            
            return %details;
        }
        
        # Shows in a series, not in a season alternate
        # Howard Stern On Demand (Heidi Baron)
        # Crop To Shop - Jimmy's Supermarket Secrets
        my $no_season_title_alt = qr{
                ^
                    (?<series> .*? ) 
                    \s+ (?: \( | - \s+ )
                    (?<title> .*? ) 
                    \)?
                $
            }x;
        
        if ( $title =~ $no_season_title_alt ) {
            %details = %+;
            
            # don't accept just numbers (that makes it a movie's year)
            if ( $details{'title'} !~ m{^\d+$} ) {
                return %details;
            }
        }
        
        # no other match, assume that it is just the episode title
        %details = (
                title => $title,
            );
        return %details;
    }
}
