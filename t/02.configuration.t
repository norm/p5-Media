use Modern::Perl;
use Media;
use Test::More      tests => 6;



# check that the config files are read correctly and override the 
# built-in defaults when applied
my $default_config     = {
    add_to_itunes    => 1,
    cache_directory  => "$ENV{'HOME'}/Downloads/queue/cache",
    encoder_log_file => "$ENV{'HOME'}/Downloads/queue/encoder.log",
    encoder_pid_file => "$ENV{'HOME'}/Downloads/queue/encoder.pid",
    encode_directory => "$ENV{'HOME'}/Downloads",
    language_code    => 'eng',
    low_disk_space   => '5G',
    movies_directory => '/files/movies',
    music_directory  => '/files/music',
    queue_directory  => "$ENV{'HOME'}/Downloads/queue",
    trash_directory  => "$ENV{'HOME'}/.Trash",
    trash_files      => 0,
    tv_directory     => '/files/tv',
};
my %audio_profiles     = (
    audio_ac3pass => {
        ab       => '640',
        aencoder => 'copy:ac3',
        arate    => 'Auto',
        mixdown  => '6ch',
    },
    audio_ac3 => {
        ab       => '640',
        aencoder => 'ffac3',
        arate    => 'Auto',
        mixdown  => '6ch',
    },
    audio_dpl2 => {
        ab       => '160',
        aencoder => 'ca_aac',
        arate    => '48',
        mixdown  => 'dpl2',
    },
    audio_stereo => {
        ab       => '160',
        aencoder => 'ca_aac',
        arate    => '48',
        mixdown  => 'stereo',
    },
    audio_mono => {
        ab       => '80',
        aencoder => 'ca_aac',
        arate    => '48',
        mixdown  => 'mono',
    },
);
my $default_handbrake  = {
    encoder            => "x264",
    encopts            => 'b-adapt=2',
    format             => "mp4",
    "loose-anamorphic" => "",
    maxHeight          => 720,
    maxWidth           => 1280,
    quality            => 22,
};
my $test_config        = {
    add_to_itunes    => '0',
    cache_directory  => 'xt/encode/cache',
    encoder_log_file => 'xt/queue/encoder.log',
    encoder_pid_file => 'xt/queue/encoder.pid',
    encode_directory => 'xt/encode',
    language_code    => 'eng',
    log_directory    => 'xt/log',
    low_disk_space   => '5G',
    movies_directory => 'xt/movies',
    music_directory  => 'xt/music',
    queue_directory  => 'xt/queue',
    trash_directory  => 'xt/trash',
    trash_files      => '0',
    tv_directory     => 'xt/tv',
    use_imdb         => 'true',
};

# default config
{
    my $media = Media->new( '/dev/null' );
    is_deeply(
            $media->full_configuration,
            {
                ''        => $default_config,
                handbrake => $default_handbrake,
                %audio_profiles,
            },
        );
}

# configuration has overwritten the defaults
{
    my $media = Media->new( 't/conf/media.conf' );
    is_deeply(
            $media->full_configuration,
            {
                '' => {
                    %$test_config,
                },
                handbrake => $default_handbrake,
                series_priority => { House => 10 },
                %audio_profiles,
            },
        );
}

# configuration has overwritten the defaults for handbrake
{
    my $media = Media->new( 't/conf/1080p.conf' );
    is_deeply(
            $media->full_configuration,
            {
                ''        => $default_config,
                handbrake => {
                    encoder            => "x264",
                    encopts            => '',
                    format             => "mp4",
                    "loose-anamorphic" => "",
                    maxHeight          => 1080,
                    maxWidth           => 1920,
                    quality            => 15,
                },
                %audio_profiles,
            },
        );
}

# single output directory
{
    my $media = Media->new( 't/conf/single_dir.conf' );
    is_deeply(
            $media->full_configuration,
            {
                '' => {
                    %$test_config,
                    single_directory => 'xt/add',
                    trash_files      => '0',
                },
                handbrake => $default_handbrake,
                %audio_profiles,
            },
        );
}

# configuration has overwritten the defaults for handbrake
{
    my $media = Media->new( 't/conf/movie_extras_as_tv.conf' );
    is_deeply(
            $media->full_configuration,
            {
                '' => {
                    %$test_config,
                    movie_extras_as_tv => 'true',
                },
                handbrake => $default_handbrake,
                %audio_profiles,
            },
        );
}

# trash input files
{
    my $media = Media->new( 't/conf/trash.conf' );
    is_deeply(
            $media->full_configuration,
            {
                '' => {
                    %$test_config,
                    low_disk_space  => '200M',
                    trash_files     => 'true',
                    video_directory => 'xt/video',
                },
                handbrake => $default_handbrake,
                %audio_profiles,
            },
        );
}
