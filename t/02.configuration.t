use Modern::Perl;
use Media;
use Test::More      tests => 6;



# check that the config files are read correctly and override the 
# built-in defaults when applied
my $default_config     = {
    queue_directory  => "$ENV{'HOME'}/Downloads/queue",
    cache_directory  => "$ENV{'HOME'}/Downloads/queue/cache",
    encoder_pid_file => "$ENV{'HOME'}/Downloads/queue/encoder.pid",
    encoder_log_file => "$ENV{'HOME'}/Downloads/queue/encoder.log",
    encode_directory => "$ENV{'HOME'}/Downloads",
    trash_directory  => "$ENV{'HOME'}/.Trash",
    tv_directory     => '/files/tv',
    movies_directory => '/files/movies',
    music_directory  => '/files/music',
    language_code    => 'eng',
    add_to_itunes    => 1,
};
my %audio_profiles     = (
    audio_ac3pass => {
        '-E' => 'copy',
        '-B' => '640',
        '-6' => '6ch',
        '-R' => 'Auto',
    },
    audio_ac3 => {
        '-E' => 'ac3',
        '-B' => '640',
        '-6' => '6ch',
        '-R' => 'Auto',
    },
    audio_dpl2 => {
        '-E' => 'ca_aac',
        '-B' => '160',
        '-6' => 'dpl2',
        '-R' => '48',
    },
    audio_stereo => {
        '-E' => 'ca_aac',
        '-B' => '160',
        '-6' => 'stereo',
        '-R' => '48',
    },
    audio_mono => {
        '-E' => 'ca_aac',
        '-B' => '80',
        '-6' => 'mono',
        '-R' => '48',
    },
);
my $default_handbrake  = {
    encoder            => "x264",
    format             => "mp4",
    "loose-anamorphic" => "",
    maxHeight          => 720,
    maxWidth           => 1280,
    quality            => 22,
    x264opts           => 'cabac=0:ref=2:me=umh:b-adapt=2:'
                        . 'weightb=0:trellis=0:weightp=0:'
                        . 'b-pyramid=none:vbv-maxrate=9500:'
                        . 'vbv-bufsize=9500',
};
my $test_config        = {
    encode_directory => 'xt/encode',
    cache_directory  => 'xt/encode/cache',
    encoder_pid_file => 'xt/queue/encoder.pid',
    encoder_log_file => 'xt/queue/encoder.log',
    log_directory    => 'xt/log',
    queue_directory  => 'xt/queue',
    tv_directory     => 'xt/tv',
    movies_directory => 'xt/movies',
    music_directory  => 'xt/music',
    use_imdb         => 'true',
    trash_directory  => 'xt/trash',
    language_code    => 'eng',
    add_to_itunes    => '0',
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
                    format             => "mp4",
                    "loose-anamorphic" => "",
                    maxHeight          => 1080,
                    maxWidth           => 1920,
                    quality            => 15,
                    x264opts           => '',
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
                    trash_files => 'true',
                },
                handbrake => $default_handbrake,
                %audio_profiles,
            },
        );
}
