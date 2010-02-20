package Media::Handler::TV;

use Modern::Perl;
use MooseX::FollowPBP;
use Moose;
use MooseX::Method::Signatures;

extends 'Media::Handler';



method is_type ( Str $name ) {
    # it is of TV type if:
    # we have the hinted type at the start of the string
    my ( $hint, undef ) = $self->parse_type_for_hint( $name );
    if ( defined $hint ) {
        return $hint;
    }
    
    # or the string can be parsed into metadata
    if ( defined $self->parse_type_string( $name ) ) {
        return 'TV';
    }
    
    return;
}

method install_file ( Str $directory, Str $file ) {
    my %details   = $self->parse_type_string( $directory );
    my $extension = $self->get_file_extension( $file );
    
    my( $destination_directory, $destination_filename ) 
        = $self->get_episode_location( \%details, $extension );
    my $target      = "${directory}/${file}";
    
    $self->tag_file( $target, \%details );
    my $moved_to 
        = $self->safely_move_file( 
                $target,
                $destination_directory, 
                $destination_filename 
            );
        
    $self->add_to_itunes( $moved_to );
}
method tag_file ( Str $file, HashRef $details ) {
    my $extension = $self->get_file_extension( $file );
    return unless '.m4v' eq $extension;
    
    my $episode = qq($details->{'season'}x$details->{'episode'});
    my @arguments;
    
    push @arguments, q(--TVShowName),   $details->{'series'};
    push @arguments, q(--TVSeasonNum),  $details->{'season'};
    push @arguments, q(--TVEpisodeNum), $details->{'episode'};
    push @arguments, q(--TVEpisode),    $episode;
    push @arguments, q(--title),        $details->{'title'};
    push @arguments, q(--stik),         q(TV Show);
    
    my $media = $self->get_media();
    $media->tag_file( $file, \@arguments );
}

method parse_type_string ( $title_string ) {
    my %details = $self->details_from_location( $title_string );
    return %details if %details;
    
    my $type = $self->strip_leading_directories( $title_string );
       $type = $self->strip_type_hint( $type );
    
    %details = $self->parse_title_string( $type );
    if ( ! %details ) {
        %details = $self->parse_title_string( $title_string );
    }
    
    if ( defined $details{'series'} ) {
        my $rational = $self->rationalise_series( $details{'series'} );
        
        if ( defined $rational ) {
            $details{'original_series'} = $details{'series'};
            $details{'series'}          = $rational;
        }
    }
    return %details 
        if %details;
    
    return;
}
method rationalise_series ( Str $series ) {
    my $media    = $self->get_media();
    my $rational = $self->get_config( $series, 'rationalise' );
    
    if ( defined $rational ) {
        # = and : cannot be used in keys, but are needed, so
        # use a [C] and [E] notation to represent them
        $rational =~ s{ \[ C \] }{:}gx;
        $rational =~ s{ \[ E \] }{=}gx;
    }
    
    return $rational // $series;
}
method parse_title_string ( $title ) {
    my %details;
    my %words = ( 
            'one'  => 1, 'two' => 2, 'three' => 3, 'four'  => 4, 
            'five' => 5, 'six' => 6, 'seven' => 7, 'eight' => 8,
            'nine' => 9, 'ten' => 10
        );
    
    # standard episode title looks like:
    # House - 2x23 - Who's Your Daddy
    # The Kevin Bishop Show - 1x04
    # Grey's Anatomy - 5x03 - Here Comes the Flood    
    #
    # also covers specials outside of all seasons:
    # Time Team - Sx18 - Londinium, Greater London - Edge of Empire
    my $simple_episode_title = qr{
            ^
                (?<series> .*? )
                \s+ - \s+
                (?<season> [S\d]+ )
                x
                (?<episode> \d+ )
                (?:
                    \s+ - \s+
                    (?<title> .*? )
                )?
            $
        }x;
    
    if ( $title =~ $simple_episode_title ) {
        %details = %+;
        
        if ( 'S' eq $details{'season'} ) {
            $details{'special'} = 1;
            delete $details{'season'};
        }
        
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
        return %details;
    }
    
    # sports events
    # NASCAR Nationwide Series 2009 - Round 01 - Daytona (Race)
    my $sports_event_title = qr{
            ^
                (?<series> .*? )
                \s+
                (?<season> \d+ )
                \s+ - \s+ Round \s+
                (?<episode> \d+ )
                \s+ - \s+ 
                (?<title> .*? )
            $
        }x;
    
    if ( $title =~ $sports_event_title ) {
        %details = %+;
        return %details;
    }
    
    # sports events, specials
    # Bundesliga 2010 - Week 20: Highlights
    my $sports_event_special_title = qr{
            ^
                (?<series> .*? )
                \s+
                (?<season> \d+ )
                \s+ - \s+ 
                (?<title> .*? )
            $
        }x;
    
    if ( $title =~ $sports_event_special_title ) {
        %details = %+;
        
        $details{'special'} = 1;
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
                (?<series> .*? )
                \s+ - \s+
                (?<season> \d+ )
                x
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
        
        foreach my $episode ( $+{'first_episode'} .. $+{'last_episode'} ) {
            push @{ $details{'episodes'} }, $episode;
        }
        
        return %details;
    }
    
    # seasons:
    # John Doe - Season 1
    # Are You Afraid Of The Dark? - Season Two
    my $season_title = qr{
            ^
                (?<series> .*? )
                \s+ - \s+ 
                (?:
                    Season \s+ (?<season> \d+ )
                    |
                    Season \s+ (?<seasonwords> \w+ )
                )
            $
        }x;
    
    if ( $title =~ $season_title ) {
        %details = %+;
        
        if ( defined $details{'seasonwords'} ) {
            my $word = lc $details{'seasonwords'};
            if ( defined $words{ $word } ) {
                $details{'season'} = $words{ $word } // 0;
                delete $details{'seasonwords'};
            }
        }
        
        return %details;
    }
    
    # series:
    # The Adventures of Pete and Pete - Complete Series
    my $series_title = qr{
            ^
                (?<series> .*? )
                \s+ - \s+ Complete \s+ Series
            $
        }x;
    
    if ( $title =~ $series_title ) {
        %details = %+;
        $details{'season'} = 1;
        
        return %details;
    }
    
    # DVD/BluRay collections
    # Futurama Season 1 (DVD 1)
    # You're Hired [DVD 6]
    # Battlestar Galactica (2004) - Season 4 [BD 4]
    # Invader Zim Vol. 1 [DVD 1]
    # Generation Kill (Mini-Series) [DVD 2/3]
    # You're Hired - 19-22 [DVD 5/5]
    # Looney Tunes Golden Collection (Vol. 2) [DVD 3]
    # Sherlock Holmes (1984) - Season 1 (DVD 4)
    # 30 Rock - Season 3 [DVD 2A]
    my $dvd_title = qr{
            ^
                # show name
                (?<series> .*? )
                
                # optional Season 1 / Vol. 1 / (Mini-Series)
                (?:
                    \s+
                    (?: [-] \s+ )?
                    (?:
                        Season \s+ (?<season> \d+ )
                        |
                        \(? Vol\. \s+ (?<volume> \d+ ) \)?
                        |
                        (?<mini> \( Mini-Series \) )
                    )
                )?
                
                # optional episodes 5-10
                (?:
                    \s+
                    (?: \- \s+ )?
                    (?: 
                        (?<season_eps> \d+ ) x
                    )?
                    (?<first_episode> \d+ )
                    -
                    (?: \d+ x )?
                    (?<last_episode> \d+ )
                )?
                
                \s+
                
                # [DVD 2/3], [BD 4], (DVD 4)
                [ \( \[ ] 
                (?: DVD | BD ) \s+
                (?<disk> \d[\d\w]* )
                # (?<overflow> [/] \d+ )?
                (?: [/] \d+ )?
                [ \) \] ]
            $
        }x;
    
    if ( $title =~ $dvd_title ) {
        %details = %+;
        
        if ( defined $+{'first_episode'} ) {
            foreach my $ep ( $+{'first_episode'} .. $+{'last_episode'} ) {
                push @{ $details{'episodes'} }, $ep;
            
                if ( defined $+{'season_eps'} ) {
                    $details{'season'} = $+{'season_eps'};
                }
            }
        }
        
        if ( !defined $details{'season'} ) {
            $details{'season'} = 1;
        }
        
        if ( defined $details{'mini'} ) {
            delete $details{'mini'};
            delete $details{'season'};
        }
        
        if ( defined $details{'volume'} ) {
            $details{'season'} = $details{'volume'};
            delete $details{'volume'};
        }
        
        return %details;
    }
    
    # Shows in a series, not in a season
    # UFC 109: Relentless
    my $no_season_title = qr{
            ^
                (?<series> .*? )
                \s+
                (?<episode> \d+ )
                \: \s+
                (?<title> .*? )
            $
        }x;
    
    if ( $title =~ $no_season_title ) {
        %details = %+;
        return %details;
    }
    
    # Numbered episodes in a series, not in a season
    # The Eloquent Ji Xiaolan IV - 18
    my $no_season_no_title = qr{
            ^
                (?<series> .*? ) 
                \s+ - \s+
                (?<episode> \d+ )
            $
        }x;
    
    if ( $title =~ $no_season_no_title ) {
        %details = %+;
        return %details;
    }
    
    # Extras
    # The Big Bang Theory - Season 2 (Subpack)
    # Star Trek: Deep Space Nine - Season 2 (DVD Extras)
    my $extras_title = qr{
            ^
                # show name
                (?<series> .*? )
                \s+ - \s+ 
                (?:
                    Season \s+ (?<season> \d+ )
                    |
                    Season \s+ (?<seasonwords> \w+ )
                )
                \s+ \( (?<extra> .*? ) \)
            $
        }x;
    
    if ( $title =~ $extras_title ) {
        %details = %+;
        
        if ( defined $details{'seasonwords'} ) {
            my $word = lc $details{'seasonwords'};
            if ( defined $words{ $word } ) {
                $details{'season'} = $words{ $word } // 0;
                delete $details{'seasonwords'};
            }
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
    
    # no match
    return;
}
method get_dvd_details ( HashRef $config, Str $key ) {
    my %details = (
            %{ $config->{ $key } },
            
            series => $config->{''}{'series'},
            season => $config->{''}{'season'},
        );
    
    if ( defined $config->{ $key }{'title'} ) {
        $details{'episode'}  = sprintf '%02d', $config->{ $key }{'episode'};
        $details{'title'}    = $config->{ $key }{'title'};
    }
    
    return %details;
}
method details_from_location ( Str $pathname ) {
    my $base = $self->get_config( 'tv_directory' );
    
    if ( $pathname =~ s{^$base/?}{}s ) {
        # Top Gear/Specials/The Great Adventures Vietnam Special.avi
        my $special_episode = qr{
                ^
                    (?<series> .*? )
                    / Specials /
                    # optional number
                    (?:
                        (?<episode> [\d]+ )
                        \s+ - \s+
                    )?
                    (?<title> .*? )
                    \. [^\.]+
                $
            }x;
        
        if ( $pathname =~ $special_episode ) {
            my %details = %+;
            $details{'special'} = 1;
            return %details;
        }
        
        # John Doe/Season 1
        my $season = qr{
                ^
                    (?<series> .*? )
                    / Season \s+ 
                    (?<season> \d+ )
                    /?
                $
            }x;
        
        if ( $pathname =~ $season ) {
            my %details = %+;
            return %details;
        }
        
        # Bones/Season 4/01-02 - Yanks in the U.K..avi
        my $multiple_episodes = qr{
                ^
                    (?<series> .*? )
                    / Season \s+ 
                    (?<season> \d+ )
                    / (?: \d x )?
                    (?<first_episode> \d+ ) 
                    - (?: \d x )?
                    (?<last_episode> \d+ )
                    \s+ - \s+
                    (?<title> .*? )
                    \. [^\.]+
                $
            }x;
        
        if ( $pathname =~ $multiple_episodes ) {
            my %details = %+;
            my @episodes 
                    = $details{'first_episode'} .. $details{'last_episode'};
            
            foreach my $episode ( @episodes ) {
                push @{ $details{'episodes'} }, $episode;
            }
            
            return %details;
        }
        
        # The Daily Show/Season 2009/08.13 - Rachel McAdams
        my $dated_episode = qr{
                ^
                    (?<series> .*? )
                    / Season \s+ 
                    (?<season> \d+ )
                    / 
                    (?<episode> [\d\.]+ )?
                    \s+ - \s+
                    (?<title> .*? )
                    \. [^\.]+
                $
            }x;
        
        if ( $pathname =~ $dated_episode ) {
            my %details = %+;
            return %details;
        }
        
        # Bundesliga/Season 2010/Week 20: Highlights.avi
        my $special_episode_in_season = qr{
                ^
                    (?<series> .*? )
                    / Season \s+ (?<season> \d+ )
                    / (?<title> .*? )
                    \. [^\.]+
                $
            }x;
        
        if ( $pathname =~ $special_episode_in_season ) {
            my %details = %+;
            $details{'special'} = 1;
            
            return %details;
        }
        
        # Angel/Season 1/1x01 - Pilot.avi
        # UFC/109 - Relentless.avi
        my $episode = qr{
                ^
                    (?<series> .*? )
                    # optional season
                    (?:
                        / Season \s+ 
                        (?<season> \d+ )
                    )?
                    / (?: \d x )?
                    # optional number
                    (?:
                        (?<episode> [\d]+ )
                        \s+ - \s+
                    )?
                    (?<title> .*? )
                    \. [^\.]+
                $
            }x;
        
        if ( $pathname =~ $episode ) {
            my %details = %+;
            return %details;
        }
        
        # Invader Zim
        # John Doe/Season 1
        # Angel/Season 1/1x01 - Pilot.avi
        my $show_title = qr{
                ^
                    (?<series> [^/]+ )
                    /?
                $
            }x;
        
        if ( $pathname =~ $show_title ) {
            my %details = %+;
            return %details;
        }
        
    }
    return;
}
method have_series ( Str $series ) {
    my( $directory, undef ) 
        = $self->get_episode_location( { series => $series } );
    
    return 1 
        if -d $directory;
    
    return 0;
}
method have_episode ( HashRef $details ) {
    my( $directory, $filename ) = $self->get_episode_location( $details );
    
    opendir( my $handle, $directory )
        or return 0;
    
    while ( my $test = readdir $handle ) {
        next unless $test =~ m{^$filename};
        return 1;
    }
    
    return 0;
}
method get_episode_location ( HashRef $details, Str $extension = '' ) {
    my $series  = '';
    my $season  = '';
    my $episode = '';
    my $title   = '';

    # fix anything without a valid series or season
    # (one-off TV shows, for example)
    if ( !defined $details->{'series'} ) {
        $series = 'Miscellaneous';
        $season = '';
    }
    else {
        $series = $details->{'series'};
        $season = ( defined $details->{'season'} )
                ? sprintf( '/Season %s', $details->{'season'} )
                : '';
    }
    
    if ( defined $details->{'first_episode'} ) {
        # concatenate multiple episodes to a range
        $episode = sprintf '%s-%s - ',
                       $details->{'first_episode'},
                       $details->{'last_episode'};
    }
    else {
        $episode = ( defined $details->{'episode'} ) 
                 ? sprintf( '%s - ', $details->{'episode'} )
                 : '';
    }
    
    if ( !defined $details->{'title'} ) {
        if ( defined $details->{'first_episode'} ) {
            $title = sprintf( 
                    'Episodes %s-%s',
                        $details->{'first_episode'}, 
                        $details->{'last_episode'}
                );
        }
        elsif ( defined $details->{'episode'} ) {
            $title = sprintf( 'Episode %s', $details->{'episode'} );
        }
        else {
            # no episode at all, so no file, so no extension needed
            $extension = '';
        }
    }
    else {
        $title = $details->{'title'} // '';
    }
    
    if ( defined $details->{'special'} ) {
        if ( !defined $details->{'season'} ) {
            $season = '/Specials';
        }
        else {
            $episode = '';
        }
    }
    
    my $base      = $self->get_tv_directory();
    my $directory = "${base}/${series}${season}";
    my $filename  = "${episode}${title}${extension}";
    
    return( $directory, $filename );
}
method get_processing_directory ( HashRef $details ) {
    my $short_name = $self->get_short_filename( $details );
    my $base       = $self->get_config( 'base_directory' );
    
    return "${base}/${short_name}";
}
method get_short_filename ( HashRef $details ) {
    my( $series, $season, $episode, $title );

    # fix anything without a valid series or season
    # (one-off TV shows, for example)
    if ( !defined $details->{'series'} ) {
        $series = 'Miscellaneous';
        $season = '';
    }
    else {
        $series = $details->{'series'};
        $season = $details->{'season'} // 0;
    }

    if ( defined $details->{'first_episode'} ) {
        # concatenate multiple episodes to a range
        $episode = sprintf '%s-%s',
                       $details->{'first_episode'},
                       $details->{'last_episode'};
    }
    else {
        $episode = $details->{'episode'} // '0';
    }

    if ( !defined $details->{'title'} ) {
        my( $season_title, $episode_title );

        if ( defined $details->{'season'} ) {
            $season_title .= sprintf( 'Season %s', $details->{'season'} );
        }
        
        if ( defined $details->{'episode'} ) {
            $episode_title .= sprintf( 'Episode ', $details->{'episode'} );
        }
        elsif ( defined $details->{'first_episode'} ) {
            $episode_title .= sprintf( 
                    'Episodes %s-%s',  
                        $details->{'first_episode'},
                        $details->{'last_episode'}
                );
        }

        $title = join q(,), $season_title, $episode_title; 
    }
    else {
        $title = $details->{'title'};
    }
    
    return "${series} - ${season}x${episode} - ${title}";
}
method get_tv_directory {
    my $media = $self->get_media();
    
    return $media->get_config( 'tv_directory' );
}

method is_ignoring ( Str $title ) {
    my $media = $self->get_media();
    
    return $media->is_ignoring( "TV: $title" );
}
method start_ignoring ( Str $title ) {
    my $media = $self->get_media();
    
    $media->start_ignoring( "TV: $title" );
}

1;
