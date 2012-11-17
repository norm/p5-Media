use Modern::Perl;
use IO::All;
use Media;
use Test::More      tests => 26;



# check the parsing of HandBrakeCLI output
my $media   = Media->new( 't/conf/media.conf' );
my $handler = $media->get_empty_handler( 'TV', 'VideoFile' );

{
    my $content    < io 't/handbrake/mp3_avi.txt';
    my %titles     = $handler->analyse_input( $content );
    my @profiles   = $handler->get_audio_profiles_for_title( $titles{1} );
    my %audio_args = $handler->get_audio_args( \@profiles );
    my %video_args = $handler->get_video_args( $titles{1} );
    
    is_deeply(
            \%titles,
            {
                handbrake_version => '0.9.5',
                input_type        => 'avi',
                1                 => {
                    audio     => [
                        {
                            channels => '2.0 ch',
                            code     => 'und',
                            format   => 'MP3',
                            language => 'Unknown',
                            track    => 1,
                        },
                    ],
                    crop      => '0/0/0/0',
                    duration  => '00:03:01',
                    size      => '688x384, pixel aspect: 1/1, display '
                                 . 'aspect: 1.79, 25.000 fps',
                    subtitles => [],
                },
            }
        );
    is_deeply(
            \@profiles,
            [
                '1:stereo:Unknown Stereo',
            ]
        );
    is_deeply(
            \%audio_args,
            {
                mixdown => 'stereo',
                aname => 'Unknown Stereo',
                ab => '160',
                aencoder => 'ca_aac',
                arate => '48',
                audio => '1'
            }
        );
    is_deeply(
            \%video_args,
            {
                crop               => '0/0/0/0',
                encoder            => 'x264',
                encopts            => 'b-adapt=2',
                format             => 'mp4',
                'loose-anamorphic' => "",
                maxHeight          => '720',
                maxWidth           => '1280',
                quality            => '22',
            }
        );
}
{
    my $content    < io 't/handbrake/mkv_dts.txt';
    my %titles     = $handler->analyse_input( $content );
    my @profiles   = $handler->get_audio_profiles_for_title( $titles{1} );
    my %audio_args = $handler->get_audio_args( \@profiles );
    my %video_args = $handler->get_video_args( $titles{1} );
    
    is_deeply(
            \%titles,
            {
                handbrake_version => '0.9.5',
                input_type        => 'matroska',
                1                 => {
                    audio     => [
                        {
                            channels => '5.1 ch',
                            code     => 'eng',
                            format   => 'DTS',
                            language => 'English',
                            track    => 1,
                        },
                    ],
                    crop      => '0/0/0/0',
                    duration  => '00:00:43',
                    size      => '1920x800, pixel aspect: 1/1, display '
                                 . 'aspect: 2.40, 23.976 fps',
                    subtitles => [
                        {
                            code     => 'eng',
                            language => 'English',
                            track    => 1,
                            type     => 'Text',
                        },
                        {
                            code     => 'eng',
                            language => 'English',
                            track    => 2,
                            type     => 'Text',
                        },
                    ],
                },
            }
        );
    is_deeply(
            \@profiles,
            [
                '1:dpl2:English 5.1 ch',
                '1:ac3:English 5.1 ch AC3',
            ]
        );
    is_deeply(
            \%audio_args,
            {
                mixdown => 'dpl2,6ch',
                aname => 'English 5.1 ch,English 5.1 ch AC3',
                ab => '160,640',
                aencoder => 'ca_aac,ffac3',
                arate => '48,Auto',
                audio => '1,1'
            }
        );
    is_deeply(
            \%video_args,
            {
                crop               => '0/0/0/0',
                encoder            => 'x264',
                encopts            => 'b-adapt=2',
                format             => 'mp4',
                'loose-anamorphic' => "",
                maxHeight          => '720',
                maxWidth           => '1280',
                quality            => '22',
            }
        );
}
{
    my $content    < io 't/handbrake/ac3_vob.txt';
    my %titles     = $handler->analyse_input( $content );
    my @profiles   = $handler->get_audio_profiles_for_title( $titles{1} );
    my %audio_args = $handler->get_audio_args( \@profiles );
    my %video_args = $handler->get_video_args( $titles{1} );
    
    is_deeply(
            \%titles,
            {
                handbrake_version => '0.9.5',
                input_type        => 'vob',
                1                 => {
                    audio     => [
                        {
                            channels => '5.1 ch',
                            code     => 'und',
                            format   => 'AC3',
                            language => 'Unknown',
                            track    => 1,
                        },
                    ],
                    crop      => '2/0/0/0',
                    duration  => '00:01:08',
                    size      => '720x576, pixel aspect: 64/45, display '
                                 . 'aspect: 1.78, 25.000 fps',
                    subtitles => [],
                },
            }
        );
    is_deeply(
            \@profiles,
            [
                '1:dpl2:Unknown 5.1 ch',
                '1:ac3pass:Unknown 5.1 ch AC3',
            ]
        );
    is_deeply(
            \%audio_args,
            {
                mixdown => 'dpl2,6ch',
                aname => 'Unknown 5.1 ch,Unknown 5.1 ch AC3',
                ab => '160,640',
                aencoder => 'ca_aac,copy:ac3',
                arate => '48,Auto',
                audio => '1,1'
            }
        );
    is_deeply(
            \%video_args,
            {
                crop               => '2/0/0/0',
                encoder            => 'x264',
                encopts            => 'b-adapt=2',
                format             => 'mp4',
                'loose-anamorphic' => "",
                maxHeight          => '720',
                maxWidth           => '1280',
                quality            => '22',
            }
        );
}
{
    my $content < io 't/handbrake/ds9_s7d7.txt';
    my %titles = $handler->analyse_input( $content );
    
    my @common_subtitles = (
        {
            code     => 'eng',
            language => 'English',
            track    => '1',
            type     => 'Bitmap',
        },
        {
            code     => 'fra',
            language => 'Francais',
            track    => '2',
            type     => 'Bitmap',
        },
        {
            code     => 'deu',
            language => 'Deutsch',
            track    => '3',
            type     => 'Bitmap',
        },
        {
            code     => 'swe',
            language => 'Svenska',
            track    => '4',
            type     => 'Bitmap',
        },
        {
            code     => 'dan',
            language => 'Dansk',
            track    => '5',
            type     => 'Bitmap',
        },
        {
            code     => 'nor',
            language => 'Norsk',
            track    => '6',
            type     => 'Bitmap',
        },
        {
            code     => 'nld',
            language => 'Nederlands',
            track    => '7',
            type     => 'Bitmap',
        },
        {
            code     => 'ita',
            language => 'Italiano',
            track    => '8',
            type     => 'Bitmap',
        },
        {
            code     => 'spa',
            language => 'Espanol',
            track    => '9',
            type     => 'Bitmap',
        },
    );
    my @common_audio = (
        {
            channels => 'Dolby Surround',
            code     => 'eng',
            format   => 'AC3',
            language => 'English',
            track    => 1,
        },
    );
    
    is_deeply(
            \%titles,
            {
                handbrake_version => '0.9.5',
                input_type        => 'dvd',
                1                 => {
                    audio     => \@common_audio,
                    crop      => '0/2/10/10',
                    duration  => '00:12:52',
                    size      => '720x576, pixel aspect: 16/15, display '
                                 . 'aspect: 1.33, 25.000 fps',
                    subtitles => \@common_subtitles,
                },
                2                 => {
                    audio     => \@common_audio,
                    crop      => '0/2/8/10',
                    duration  => '00:09:58',
                    size      => '720x576, pixel aspect: 16/15, display '
                                 . 'aspect: 1.33, 25.000 fps',
                    subtitles => \@common_subtitles,
                },  
                3                 => {
                    audio     => \@common_audio,
                    crop      => '10/2/6/6',
                    duration  => '00:15:11',
                    size      => '720x576, pixel aspect: 16/15, display '
                                 . 'aspect: 1.33, 25.000 fps',
                    subtitles => \@common_subtitles,
                },  
                4                 => {
                    audio     => \@common_audio,
                    crop      => '2/0/8/8',
                    duration  => '00:14:02',
                    size      => '720x576, pixel aspect: 16/15, display '
                                 . 'aspect: 1.33, 25.000 fps',
                    subtitles => \@common_subtitles,
                },  
                5                 => {
                    audio     => \@common_audio,
                    crop      => '14/2/10/10',
                    duration  => '00:09:36',
                    size      => '720x576, pixel aspect: 16/15, display '
                                 . 'aspect: 1.33, 25.000 fps',
                    subtitles => \@common_subtitles,
                },  
                6                 => {
                    audio     => \@common_audio,
                    crop      => '0/2/8/10',
                    duration  => '00:07:24',
                    size      => '720x576, pixel aspect: 16/15, display '
                                 . 'aspect: 1.33, 25.000 fps',
                    subtitles => \@common_subtitles,
                },  
                7                 => {
                    audio     => \@common_audio,
                    crop      => '0/2/8/10',
                    duration  => '00:02:25',
                    size      => '720x576, pixel aspect: 16/15, display '
                                 . 'aspect: 1.33, 25.000 fps',
                    subtitles => \@common_subtitles,
                },  
                8                 => {
                    audio     => \@common_audio,
                    crop      => '74/72/6/10',
                    duration  => '00:04:15',
                    size      => '720x576, pixel aspect: 16/15, display '
                                 . 'aspect: 1.33, 25.000 fps',
                    subtitles => \@common_subtitles,
                },  
                9                 => {
                    audio     => \@common_audio,
                    crop      => '80/74/8/20',
                    duration  => '00:02:41',
                    size      => '720x576, pixel aspect: 16/15, display '
                                 . 'aspect: 1.33, 25.000 fps',
                    subtitles => \@common_subtitles,
                },  
                10                => {
                    audio     => \@common_audio,
                    crop      => '0/2/8/10',
                    duration  => '00:02:52',
                    size      => '720x576, pixel aspect: 16/15, display '
                                 . 'aspect: 1.33, 25.000 fps',
                    subtitles => \@common_subtitles,
                },  
                11                => {
                    audio     => \@common_audio,
                    crop      => '0/2/6/10',
                    duration  => '00:04:03',
                    size      => '720x576, pixel aspect: 16/15, display '
                                 . 'aspect: 1.33, 25.000 fps',
                    subtitles => \@common_subtitles,
                },  
                12                => {
                    audio     => \@common_audio,
                    crop      => '72/74/6/6',
                    duration  => '00:02:54',
                    size      => '720x576, pixel aspect: 16/15, display '
                                 . 'aspect: 1.33, 25.000 fps',
                    subtitles => \@common_subtitles,
                },  
                13                => {
                    audio     => \@common_audio,
                    crop      => '0/6/8/8',
                    duration  => '00:03:17',
                    size      => '720x576, pixel aspect: 16/15, display '
                                 . 'aspect: 1.33, 25.000 fps',
                    subtitles => \@common_subtitles,
                },  
                14                => {
                    audio     => \@common_audio,
                    crop      => '0/2/8/16',
                    duration  => '00:02:24',
                    size      => '720x576, pixel aspect: 16/15, display '
                                 . 'aspect: 1.33, 25.000 fps',
                    subtitles => \@common_subtitles,
                },  
                15                => {
                    audio     => \@common_audio,
                    crop      => '0/0/6/10',
                    duration  => '00:04:08',
                    size      => '720x576, pixel aspect: 16/15, display '
                                 . 'aspect: 1.33, 25.000 fps',
                    subtitles => \@common_subtitles,
                },  
                16                => {
                    audio     => \@common_audio,
                    combing   => 'true',
                    crop      => '0/0/8/8',
                    duration  => '00:06:35',
                    size      => '720x576, pixel aspect: 16/15, display '
                                 . 'aspect: 1.33, 25.000 fps',
                    subtitles => \@common_subtitles,
                },  
                18                => {
                    audio         => [
                        {
                            channels => '5.1 ch',
                            code     => 'eng',
                            format   => 'AC3',
                            language => 'English',
                            track    => 1,
                        },
                        {
                            channels => '5.1 ch',
                            code     => 'deu',
                            format   => 'AC3',
                            language => 'Deutsch',
                            track    => 2,
                        },
                        {
                            channels => 'Dolby Surround',
                            code     => 'fra',
                            format   => 'AC3',
                            language => 'Francais',
                            track    => 3,
                        },
                        {
                            channels => 'Dolby Surround',
                            code     => 'ita',
                            format   => 'AC3',
                            language => 'Italiano',
                            track    => 4,
                        },
                        {
                            channels => 'Dolby Surround',
                            code     => 'spa',
                            format   => 'AC3',
                            language => 'Espanol',
                            track    => 5,
                        },
                    ],
                    chapter_count => 16,
                    crop          => '0/0/0/0',
                    duration      => '01:28:10',
                    feature       => 1,
                    size          => '720x576, pixel aspect: 16/15, display '
                                 . 'aspect: 1.33, 25.000 fps',
                    subtitles     => [
                        {
                            code     => 'eng',
                            language => 'English',
                            track    => '1',
                            type     => 'Bitmap',
                        },
                        {
                            code     => 'eng',
                            language => 'English',
                            track    => '2',
                            type     => 'Bitmap',
                        },
                        {
                            code     => 'fra',
                            language => 'Francais',
                            track    => '3',
                            type     => 'Bitmap',
                        },
                        {
                            code     => 'deu',
                            language => 'Deutsch',
                            track    => '4',
                            type     => 'Bitmap',
                        },
                        {
                            code     => 'swe',
                            language => 'Svenska',
                            track    => '5',
                            type     => 'Bitmap',
                        },
                        {
                            code     => 'dan',
                            language => 'Dansk',
                            track    => '6',
                            type     => 'Bitmap',
                        },
                        {
                            code     => 'nor',
                            language => 'Norsk',
                            track    => '7',
                            type     => 'Bitmap',
                        },
                        {
                            code     => 'nld',
                            language => 'Nederlands',
                            track    => '8',
                            type     => 'Bitmap',
                        },
                        {
                            code     => 'ita',
                            language => 'Italiano',
                            track    => '9',
                            type     => 'Bitmap',
                        },
                        {
                            code     => 'spa',
                            language => 'Espanol',
                            track    => '10',
                            type     => 'Bitmap',
                        },
                    ],
                },  
            }
        );
    
    my @profiles   = $handler->get_audio_profiles_for_title( $titles{1} );
    my %audio_args = $handler->get_audio_args( \@profiles );
    my %video_args = $handler->get_video_args( $titles{1} );
    
    is_deeply(
            \@profiles,
            [
                '1:dpl2:English Dolby Surround',
                '1:ac3pass:English Dolby Surround AC3',
            ]
        );
    is_deeply(
            \%audio_args,
            {
                mixdown => 'dpl2,6ch',
                aname => 'English Dolby Surround,English Dolby Surround AC3',
                ab => '160,640',
                aencoder => 'ca_aac,copy:ac3',
                arate => '48,Auto',
                audio => '1,1'
            }
        );
    is_deeply(
            \%video_args,
            {
                crop               => '0/2/10/10',
                encoder            => 'x264',
                encopts            => 'b-adapt=2',
                format             => 'mp4',
                'loose-anamorphic' => "",
                maxHeight          => '720',
                maxWidth           => '1280',
                quality            => '22',
            }
        );
}
{
    my $content    < io 't/handbrake/m2ts.txt';
    my %titles     = $handler->analyse_input( $content );
    my @profiles   = $handler->get_audio_profiles_for_title( $titles{1} );
    my %audio_args = $handler->get_audio_args( \@profiles );
    my %video_args = $handler->get_video_args( $titles{1} );
    
    is_deeply(
            \%titles,
            {
                handbrake_version => '0.9.5',
                input_type        => 'm2ts',
                1                 => {
                    audio     => [
                        {
                            channels => '5.1 ch',
                            code     => 'eng',
                            format   => 'AC3',
                            language => 'English',
                            track    => 1,
                        },
                    ],
                    crop      => '142/144/0/0',
                    duration  => '01:52:56',
                    size      => '1920x1080, pixel aspect: 1/1, display '
                                 . 'aspect: 1.78, 23.976 fps',
                    subtitles => [],
                },
            }
        );
    is_deeply(
            \@profiles,
            [
                '1:dpl2:English 5.1 ch',
                '1:ac3pass:English 5.1 ch AC3',
            ]
        );
    is_deeply(
            \%audio_args,
            {
                mixdown => 'dpl2,6ch',
                aname => 'English 5.1 ch,English 5.1 ch AC3',
                ab => '160,640',
                aencoder => 'ca_aac,copy:ac3',
                arate => '48,Auto',
                audio => '1,1'
            }
        );
    is_deeply(
            \%video_args,
            {
                crop               => '142/144/0/0',
                encoder            => 'x264',
                encopts            => 'b-adapt=2',
                format             => 'mp4',
                'loose-anamorphic' => "",
                maxHeight          => '720',
                maxWidth           => '1280',
                quality            => '22',
            }
        );
}
{
    my $content    < io 't/handbrake/a_new_hope.txt';
    my %titles     = $handler->analyse_input( $content );
    my @profiles   = $handler->get_audio_profiles_for_title( $titles{1} );
    my %audio_args = $handler->get_audio_args( \@profiles );
    my %video_args = $handler->get_video_args( $titles{1} );
    
    is_deeply(
            \%titles,
            {
                handbrake_version => '0.9.5',
                input_type        => 'dvd',
                1                 => {
                    angles        => '5',
                    audio         => [
                        {
                            channels => '5.1 ch',
                            code     => 'eng',
                            format   => 'AC3',
                            language => 'English',
                            track    => '1',
                        },
                        {
                            channels => 'Dolby Surround',
                            code     => 'eng',
                            format   => 'AC3',
                            language => 'English',
                            track    => '2',
                        },
                        {
                            channels => 'Dolby Surround',
                            code     => 'eng',
                            format   => 'AC3',
                            name     => "Director's Commentary 1",
                            language => 'English',
                            track    => '3',
                        },
                    ],
                    chapter_count => '51',
                    crop          => '72/72/0/0',
                    duration      => '01:59:37',
                    feature       => '1',
                    size          => '720x576, pixel aspect: 64/45, display '
                               . 'aspect: 1.78, 25.000 fps',
                    subtitles     => [
                        {
                            code     => 'eng',
                            language => 'English',
                            name     => 'Closed Caption',
                            track    => '1',
                            type     => 'Bitmap',
                        },
                        {
                            code     => 'dan',
                            language => 'Dansk',
                            track    => '2',
                            type     => 'Bitmap',
                        },
                        {
                            code     => 'fin',
                            language => 'Suomi',
                            track    => '3',
                            type     => 'Bitmap',
                        },
                        {
                            code     => 'nor',
                            language => 'Norsk',
                            track    => '4',
                            type     => 'Bitmap',
                        },
                        {
                            code     => 'swe',
                            language => 'Svenska',
                            track    => '5',
                            type     => 'Bitmap',
                        },
                        {
                            code     => 'eng',
                            language => 'English',
                            name     => "Director's Commentary",
                            track    => '6',
                            type     => 'Bitmap',
                        },
                        {
                            code     => 'eng',
                            language => 'English',
                            name     => "Director's Commentary",
                            track    => '7',
                            type     => 'Bitmap',
                        },
                        {
                            code     => 'eng',
                            language => 'English',
                            name     => "Forced Caption",
                            track    => '8',
                            type     => 'Bitmap',
                        },
                    ],
                },
                3                 => {
                    audio         => [
                        {
                            channels => '5.1 ch',
                            code     => 'eng',
                            format   => 'AC3',
                            language => 'English',
                            track    => '1',
                        },
                    ],
                    chapter_count => '2',
                    crop          => '0/0/10/8',
                    duration      => '00:00:27',
                    size          => '720x576, pixel aspect: 64/45, display '
                               . 'aspect: 1.78, 25.000 fps',
                    subtitles     => [],
                },
                10                => {
                    audio         => [
                        {
                            channels => '5.1 ch',
                            code     => 'eng',
                            format   => 'AC3',
                            language => 'English',
                            track    => '1',
                        },
                    ],
                    chapter_count => '2',
                    crop          => '70/70/2/0',
                    duration      => '00:00:26',
                    size          => '720x576, pixel aspect: 64/45, display '
                               . 'aspect: 1.78, 25.000 fps',
                    subtitles     => [],
                },
                12                => {
                    chapter_count => '14',
                    combing       => 'true',
                    crop          => '0/0/0/0',
                    duration      => '00:00:25',
                    size          => '720x576, pixel aspect: 16/15, display '
                               . 'aspect: 1.33, 25.000 fps',
                    subtitles     => [
                        {
                            code     => 'und',
                            language => 'Unknown',
                            track    => '1',
                            type     => 'Bitmap',
                        },
                    ],
                },
            }
        );
    is_deeply(
            \@profiles,
            [
                '1:dpl2:English 5.1 ch',
                '1:ac3pass:English 5.1 ch AC3',
                '2:dpl2:English Dolby Surround',
                '2:ac3pass:English Dolby Surround AC3',
                "3:dpl2:Director's Commentary 1",
                "3:ac3pass:Director's Commentary 1 AC3",
            ]
        );
    is_deeply(
            \%audio_args,
            {
                mixdown => 'dpl2,6ch,dpl2,6ch,dpl2,6ch',
                aname => "English 5.1 ch,English 5.1 ch AC3,English Dolby Surround,English Dolby Surround AC3,Director's Commentary 1,Director's Commentary 1 AC3",
                ab => '160,640,160,640,160,640',
                aencoder => 'ca_aac,copy:ac3,ca_aac,copy:ac3,ca_aac,copy:ac3',
                arate => '48,Auto,48,Auto,48,Auto',
                audio => '1,1,2,2,3,3'
            }
        );
    is_deeply(
            \%video_args,
            {
                crop               => '72/72/0/0',
                encoder            => 'x264',
                encopts            => 'b-adapt=2',
                format             => 'mp4',
                'loose-anamorphic' => "",
                maxHeight          => '720',
                maxWidth           => '1280',
                quality            => '22',
            }
        );
}
{
    my %details = (
            subtitle => [
                'burn:1',
                'eng:/files/subs/movie.srt',
                'eng:commentary.srt',
            ],
        );
    my $subhandler = $media->get_handler(
            'Movie',
            'DVD',
            \%details,
            {
                image  => '/files/source/movie',
                poster => 'xt/poster.png',
                title  => '1',
            },
        );
    my %subtitle_args = $subhandler->get_subtitle_args( \%details );
    
    is_deeply(
            \%subtitle_args,
            {
                'srt-codeset'   => 'UTF-8,UTF-8',
                'srt-file'      => '/files/subs/movie.srt,'
                                 . '/files/source/movie/commentary.srt',
                'srt-lang'      => 'eng,eng',
                subtitle        => '1',
                'subtitle-burn' => '1',
            }
        );
}
{
    my %details    = (
            markers => 'chapters.csv',
        );
    my $subhandler = $media->get_handler(
            'Movie',
            'DVD',
            \%details,
            {
                image  => '/files/source/movie',
                title  => '1',
            },
        );
    my %video_args = $subhandler->get_video_args( \%details );
    
    is_deeply(
            \%video_args,
            {
                encoder            => 'x264',
                encopts            => 'b-adapt=2',
                format             => 'mp4',
                "loose-anamorphic" => '',
                
                # HandBrake is screwed in the brain to require this
                'markers=/files/source/movie/chapters.csv' => '',
                
                maxHeight          => '720',
                maxWidth           => '1280',
                quality            => '22',
            }
        );
}
