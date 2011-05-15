use Modern::Perl;
use MooseX::Declare;

role Media::Encoder::HandBrake {
    use Capture::Tiny   qw( capture_merged tee_merged );
    use File::Basename;
    use File::Copy;
    use File::Path      qw( mkpath );
    use IO::All         -utf8;
    use List::Util      qw( first );
    # use Net::Discident;
    use POSIX;
    
    use constant SILENT                => 1;
    use constant NOISY                 => 2;
    use constant CONVERSION_FILE       => 'Z-conversion.m4v';
    use constant CONVERTED_FILE        => 'Z-converted.m4v';
    use constant MATCH_HANDBRAKE       => qr{^HandBrake ([\d\.]+) };
    use constant MATCH_INPUT_TYPE      => qr{^Input #0, (\w+),};
    use constant MATCH_VOB_FILE        => qr{ is MPEG DVD Program Stream};
    use constant MATCH_M2TS_FILE       => qr{ is MPEG Transport Stream};
    use constant MATCH_DVD             => qr{DVD has (\d+) title};
    use constant MATCH_NEW_TITLE       => qr{^\+ title (\d+):};
    use constant MATCH_COMBING         => qr{^\s+\+ combing detected};
    use constant MATCH_INTERLACING     => qr{^\s+\+ likely interlaced};
    use constant MATCH_DURATION        => qr{^\s+\+ duration: ([\d:]+)};
    use constant MATCH_CROP            => qr{^\s+\+ autocrop: ([\d\/]+)};
    use constant MATCH_ANGLES          => qr{^\s+\+ angle\(s\) ([\d\/]+)};
    use constant MATCH_SIZE            => qr{^\s+\+ size: (.*)};
    use constant MATCH_CHAPTER         => qr{^\s+\+ (\d+)\: cells};
    use constant MATCH_FEATURE_TITLE   => qr{^\s+\+ Main Feature};
    use constant MATCH_IGNORED         => qr{
        ^ (?: \s+ \+ \s (?: 
            audio\strack | stream | subtitle\strack | vts
          ) ) | \S
    }x;
    use constant MATCH_SUBTITLES       => qr{
        ^
            \s+ \+ \s
            (?<track> \d+ ) \, \s+
            (?<language> \w+ ) \s+
            (?: \( (?<name> .*? ) \) \s+ )?
            \( iso639-2: \s (?<code> [^\)]+ ) \) \s+
            \( (?<type> \w+ ) \)
    }x;
    use constant MATCH_AUDIO           => qr{
        ^ 
            \s+ \+ \s 
            (?<track> \d+) \, \s+
            (?<language> \w+ ) \s+
            \( (?<format> \w+ ) \) \s+
            (?: \( (?<name> .*? ) \) \s+ )?
            \( (?<channels> .*? ) \) \s+
            \( iso639-2: \s (?<code> .*? ) \) 
            (?:
                \, \s+
                \d+Hz \, \s+
                \d+bps
            )?
        $
    }x;
    use constant NOT_VIDEO_ARGS        => qw(
        title series season episode 
        year rating feature director genre actor writer studio plot company
        artist album poster extra
        audio subtitles track duration size angles chapter_count
    );
    use constant STANDARD_CONFIG_INTRO => q(
        # fill out one or the other of:
        type   = TV
        series = NAME_OF_SHOW
        season = SEASON_OF_SHOW
        
        type   = Movie
        title  = NAME_OF_MOVIE
        year   = YEAR_OF_MOVIE
        poster = URL_OF_POSTER_IMAGE
        rating = RATING_OF_MOVIE
        
        # other options you can use globally, or per-video include:
        # denoise  = ( 1 | weak | medium | strong | <SL:SC:TL:TC> )
        # start-at = <seconds>
        # stop-at  = <seconds>
        # quality  = ( 0-51 )   # 0 highest, 51 lowest, in 0.25 increments
        # size     = <MB>       # target size for output video
        # vb       = <kb/s>     # fixed bitrate for output video
        # two-pass = 1
        # turbo    = 1
        # width    = <pixels>
        # height   = <pixels>
        # ... see `HandBrakeCLI -h` for more
    );
    use constant STANDARD_CONFIG_TITLE => q(
        # for a TV show:
        episode  = NUMBER_OF_EPISODE
        title    = TITLE_OF_EPISODE
        
        # for a movie, one or the other of:
        feature  = 1
        extra    = NAME_OF_DVD_EXTRA
        
    );
    use constant COMBING_OPTIONS       => q(
        # combing detected; ways of fixing this are:
        # decomb   = ( 1 | <MO:ME:MT:ST:BT:BX:BY:MG:VA:LA:DI:ER:NO:MD:PP:FD> )
        # deinterlace = ( 1 | fast | slow | slower | <YM:FD:MM:QP> )
        # detelecine  = ( 1 | <L:R:T:B:SB:MP:FD> )
    );
    
    my $numerically = sub {
        my $a_num = $a;
        my $b_num = $b;
        $a_num = -1 if !isdigit $a;
        $b_num = -1 if !isdigit $b;
        return $a_num <=> $b_num;
    };
    
    
    method encode_content {
        my $input  = $self->input_file;
        my $dir    = $self->get_conversion_directory();
        my $output = "${dir}/Z-conversion.m4v";
        mkpath $dir;
        
        my $in_progress = sprintf "%s/%s",
                                $dir,
                                CONVERSION_FILE;
        my $completed   = sprintf "%s/%s",
                                $dir,
                                CONVERTED_FILE;
        
        my %audio_args    = $self->get_audio_args( $self->details->{'audio'} );
        my %video_args    = $self->get_video_args( $self->details );
        my %subtitle_args = $self->get_subtitle_args( $self->details );
        my %args          = (
                %audio_args,
                %video_args,
                %subtitle_args,
            );
        
        my @arguments = $self->get_handbrake_args( %args );
        
        my $start = time();
        $self->run_handbrake(
                NOISY,
                @arguments,
                '-t', $self->input->{'title'},
                '-i', $input,
                '-o', $output,
            );
        
        move( $in_progress, $completed );
    }
    method clean_up_conversion {
        rmdir $self->get_conversion_directory();
        $self->clean_up_input();
    }
    
    method conversion_file {
        my $dir = $self->get_conversion_directory();
        return sprintf "%s/%s", $dir, CONVERSION_FILE;
    }
    method conversion_filename {
        return CONVERSION_FILE;
    }
    method converted_file {
        my $dir = $self->get_conversion_directory();
        return sprintf "%s/%s", $dir, CONVERTED_FILE;
    }
    
    method scan_input ( $input_title=1, $input_file? ) {
        $input_file = $self->input_file
            if !defined $input_file;
        
        return $self->run_handbrake(
                SILENT,
                '-i', $input_file,
                '-t', $input_title,
                '--scan',
            );
    }
    method analyse_input ( $input ) {
        my $input_type;
        my $handbrake_version;
        my $title;
        my %titles;
        
        LINE:
        foreach my $line ( split( m/\n/, $input ) ) {
            given ( $line ) {
                when ( m{^\s*$} ) {}
                when ( MATCH_HANDBRAKE ) {
                    $titles{'handbrake_version'} = $1;
                }
                when ( MATCH_INPUT_TYPE ) {
                    $titles{'input_type'} = $1;
                }
                when ( MATCH_VOB_FILE ) {
                    $titles{'input_type'} = 'vob';
                }
                when ( MATCH_M2TS_FILE ) {
                    $titles{'input_type'} = 'm2ts';
                }
                when ( MATCH_DVD ) {
                    $titles{'input_type'} = 'dvd';
                }
                when ( MATCH_NEW_TITLE ) {
                    $title = $1;
                    $titles{ $title } = {};
                    $titles{ $title }{'chapter_count'} = 0;
                    $titles{ $title }{'subtitles'}     = [];
                }
                when ( MATCH_SIZE ) {
                    $titles{ $title }{'size'} = $1;
                }
                when ( MATCH_COMBING ) {
                    $titles{ $title }{'combing'} = 'true';
                }
                when ( MATCH_INTERLACING ) {
                    $titles{ $title }{'interlacing'} = 'true';
                }
                when ( MATCH_CHAPTER ) {
                    $titles{ $title }{'chapter_count'}++;
                }
                when ( MATCH_FEATURE_TITLE ) {
                    $titles{ $title }{'feature'} = 1;
                }
                when ( MATCH_DURATION ) {
                    $titles{ $title }{'duration'} = $1;
                }
                when ( MATCH_CROP ) {
                    $titles{ $title }{'crop'} = $1;
                }
                when ( MATCH_ANGLES ) {
                    $titles{ $title }{'angles'} = $1;
                }
                when ( MATCH_AUDIO ) {
                    my %track = %+;
                    push @{ $titles{ $title }{'audio'} }, \%track;
                }
                when ( MATCH_SUBTITLES ) {
                    my %subtitle = %+;
                    push @{ $titles{ $title }{'subtitles'} }, \%subtitle;
                }
                when ( MATCH_IGNORED ) {}
                default {
                    die "Unknown line:\n$line\n";
                }
            }
        }
        
        # HB 0.9.5 always detects one chapter in a video file with no chapters
        foreach my $title ( keys %titles ) {
            next if $title eq 'handbrake_version';
            next if $title eq 'input_type';
            
            delete $titles{$title}{'chapter_count'}
                if 1 == $titles{$title}{'chapter_count'};
        }
        
        return %titles;
    }
    method get_handbrake_args ( %args ) {
        # turn arguments like "quality" into "--quality" (this 
        # makes the configuration file more readable), also notes
        # "no-loose-anamorphic" style arguments and then removes them
        my %encoding_arguments;
        my @remove_arguments;
        foreach my $key ( keys %args ) {
            my $value = $args{ $key };
            
            if ( $key =~ m{^no-(.*)} ) {
                push @remove_arguments, $1;
            }
            else {
                $key = "--$key" unless '-' eq substr( $key, 0, 1 );
                $encoding_arguments{ $key } = $value;
            }
        }
        foreach my $key ( @remove_arguments ) {
            delete $encoding_arguments{"--$key"};
        }
        
        return %encoding_arguments;
    }
    method get_audio_args ( $profiles ) {
        my %audio_args = (
                ab       => [], aencoder => [], aname    => [],
                arate    => [], audio    => [], mixdown  => [],
            );
        
        # can be an array or a single item - FIXME should always be an array
        my @profiles;
        push @profiles, $profiles
            if '' eq ref $profiles;
        push @profiles, @$profiles
            if 'ARRAY' eq ref $profiles;
        
        foreach my $profile ( @profiles ) {
            my( $track, $audio_type, $name ) = split m{:}, $profile;
            
            push @{ $audio_args{'audio'} }, $track;
            push @{ $audio_args{'aname'} }, $name;
            
            my $lookup = "audio_${audio_type}";
            foreach my $key ( keys %{ $self->config->{$lookup} } ) {
                push @{ $audio_args{$key} },
                     $self->config->{$lookup}{$key};
            }
        }
        
        my %args;
        foreach my $arg ( keys %audio_args ) {
            $args{ $arg } = join( ',', @{ $audio_args{ $arg } } );
        }
        
        return %args;
    }
    method get_video_args ( $title ) {
        my %args = %{ $self->config->{'handbrake'} };
        my @not_video_args = NOT_VIDEO_ARGS;
        
        KEY:
        foreach my $key ( keys %$title ) {
            next KEY if first { $key eq $_ } @not_video_args;
            
            given ( $key ) {
                when ( m{ (?: start | stop ) -at }x ) {
                    $args{$key} = 'duration:' . $title->{$key};
                }
                default {
                    $args{$key} = $title->{$key};
                }
            }
        }
        
        return %args;
    }
    method get_subtitle_args ( $details ) {
        my %srt_files = (
            'srt-file'    => [],
            'srt-codeset' => [],
            'srt-lang'    => [],
        );
        my %args;
        
        # can be an array or a single item - FIXME should always be an array
        my @streams;
        my $subtitle = $details->{'subtitle'};
        push @streams, $subtitle
            if '' eq ref $subtitle;
        push @streams, @$subtitle
            if 'ARRAY' eq ref $subtitle;
        
        my $base_dir = $self->input_file;
        $base_dir = dirname $base_dir
            if -f $base_dir;
        
        foreach my $stream ( @streams ) {
            next unless defined $stream;
            
            my( $lang, $source ) = split m{:}, $stream;
            
            if ( $lang eq 'burn' ) {
                $args{'subtitle'}      = $source;
                $args{'subtitle-burn'} = 1;
            }
            else {
                $source = "${base_dir}/${source}"
                    if $source !~ m{^/};
                
                push @{ $srt_files{'srt-file'}    }, $source;
                push @{ $srt_files{'srt-codeset'} }, 'UTF-8';
                push @{ $srt_files{'srt-lang'}    }, $lang;
            }
            
            foreach my $arg ( keys %srt_files ) {
                $args{ $arg } = join ',', @{ $srt_files{$arg} };
            }
        }
        
        return %args;
    }
    
    method get_audio_profiles_for_title ( $title ) {
        my $lang = $self->get_config( 'language_code' );
        my @profiles;
        
        foreach my $stream ( @{ $title->{'audio'} } ) {
            my $code = $stream->{'code'};
            
            if ( $lang eq $code || 'und' eq $code ) {
                my $track     = $stream->{'track'};
                my $lang      = $stream->{'language'};
                
                my $sprofiles = $self->get_audio_profiles(
                        $stream->{'format'},
                        $stream->{'channels'},
                    );
                
                foreach my $profile ( @$sprofiles ) {
                    my $name = $self->get_name_for_audio_profile(
                                            $stream, $profile );
                    push @profiles, "$track:$profile:$name";
                }
            }
        }
        
        return @profiles;
    }
    method get_audio_profiles ( $format, $channels ) {
        given ( $channels ) {
            when ( '5.1 ch' ) {
                given ( $format ) {
                    when ( 'AC3' ) { return [ 'ac3pass', 'dpl2' ]; }
                    when ( 'DTS' ) { return [ 'ac3',     'dpl2' ]; }
                }
            }
            when ( 'Dolby Surround' ) {
                given ( $format ) {
                    when ( 'AC3' ) { return [ 'ac3pass', 'dpl2' ]; }
                    when ( 'DTS' ) { return [ 'ac3',     'dpl2' ]; }
                }
            }
            when ( '2.0 ch' ) {
                return [ 'stereo' ];
            }
            when ( '1.0 ch' ) {
                return [ 'mono' ];
            }
        }
        return [ 'stereo' ];
    }
    method get_name_for_audio_profile ( $stream, $profile ) {
        my $lang     = $stream->{'language'};
        my $channels = $stream->{'channels'};
        my $format   = $stream->{'format'};
        my $name     = $stream->{'name'};
        
        if ( !defined $name ) {
            $name  = "${lang} ";
            $name .= $channels eq '2.0 ch' ? 'Stereo' :
                     $channels eq '1.0 ch' ? 'Mono' :
                                             $channels;
        }
        
        $name .= " AC3"
            if $profile =~ m{^ac3};
        
        return $name;
    }
    
    method run_handbrake ( $silent, @args ) {
        unshift @args, 'HandBrakeCLI';
        # use Data::Dumper::Concise;
        # print Dumper \@args;
        
        my $output;
        my $return;
        if ( SILENT == $silent ) {
            $output = capture_merged { 
                system @args;
                $return = $? >> 8;
            };
        }
        else {
            $output = tee_merged { 
                say join ' ', @args;
                system @args;
                $return = $? >> 8;
            };
        }
        
        die "HandBrake exited with $return.\nOutput: $output" if $return;
        
        return $output;
    }
    method get_input_track_details {
        my $content  = $self->scan_input( 1, $self->input->{'file'} );
        my %titles   = $self->analyse_input( $content );
        my @profiles = $self->get_audio_profiles_for_title( $titles{1} );
        my %details  = (
                audio => \@profiles,
                %{ $self->details },
            );
        
        return \%details;
    }
    method create_config_file ( $input ) {
        my $handbrake = $self->scan_input( 0, $input );
        my %titles    = $self->analyse_input( $handbrake );
        
        # FIXME - fetch details from the mediaconfig service
        # my $ndi = Net::Discident->new( $dvd );
        # my $ident = $ndi->ident();
        # 
        # my $http = Net::HTTP->new();
        # my $uri  = sprintf "%s/%s", MEDIACONFIG_BASE, $ident;
        # 
        # say "$ident";
        # say "$uri";
        
        my $config = STANDARD_CONFIG_INTRO;
        my $lang   = $self->get_config( 'language_code' );
        
        foreach my $index ( sort $numerically keys %titles ) {
            next if $index eq 'handbrake_version';
            next if $index eq 'input_type';
            my $title = $titles{$index};
            
            $config .= sprintf "\n\n[%d]\n### duration %s\n### size %s\n",
                            $index,
                            $title->{'duration'},
                            $title->{'size'};
            $config .= STANDARD_CONFIG_TITLE;
            
            $config .= sprintf "crop     = %s\n",
                            $title->{'crop'};
            
            $config .= sprintf(
                    "markers  = 1\n# chapters = 1-%s\n",
                        $title->{'chapter_count'}
                ) if defined $title->{'chapter_count'};
            
            $config .= COMBING_OPTIONS
                if defined $title->{'combing'};

            foreach my $stream ( @{ $title->{'audio'} } ) {
                $config .= sprintf "### audio track %d: %s (%s) %s %s\n",
                                $stream->{'track'},
                                $stream->{'language'},
                                $stream->{'code'},
                                $stream->{'format'},
                                $stream->{'channels'};
                
                my $code = $stream->{'code'};
                if ( $lang eq $code || 'und' eq $code ) {
                    my $profiles = $self->get_audio_profiles(
                            $stream->{'format'},
                            $stream->{'channels'},
                        );
                    foreach my $profile ( @$profiles ) {
                        $config .= sprintf "audio    = %d:%s:%s\n",
                                        $stream->{'track'},
                                        $profile,
                                        $stream->{'language'};
                    }
                }
            }
            
            foreach my $subtitle ( @{ $title->{'subtitles'} } ) {
                my $name = '';
                $name = sprintf ' "%s"', $subtitle->{'name'}
                    if defined $subtitle->{'name'};
                
                $config .= sprintf "### subtitle track %d: %s%s (%s) %s\n",
                                $subtitle->{'track'},
                                $subtitle->{'language'},
                                $name,
                                $subtitle->{'code'},
                                $subtitle->{'type'};
                
                $config .= sprintf(
                        "subtitle = burn:%s\n",
                        $subtitle->{'track'}
                    ) if $name =~ m{Forced};
            }
        }
        
        # neaten the file a little
        $config =~ s{^\s*}{}s;
        $config =~ s{^ +}{}gm;
        $config > io "$input/media.conf";
    }
}
