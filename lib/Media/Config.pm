package Media::Config;

use Modern::Perl;
use Moose::Role;



sub get_default_config {
    my %config = ( 
        '' => {
            'tv_directory'    => '/files/tv',
            'movie_directory' => '/files/movies',
            'log_directory'   => "$ENV{'HOME'}/Downloads/queue",
            'data_directory'  => "$ENV{'HOME'}/Downloads/queue",
            'base_directory'  => "$ENV{'HOME'}/Downloads",
            'trash_directory' => "$ENV{'HOME'}/.Trash",
            'trash_files'     => 1,
            'add_to_itunes'   => 1,
            'install_encodes' => 1,
        },
        # blank to just use code defaults
        'audio_aac' => {},
        'audio_stereo' => {
            'downmix' => 'stereo',
        },
        'common' => {
            'encoder'   => 'x264',
            'format'    => 'mp4',
            
            'quality'   => '22',
            
            'maxWidth'  => '1280',
            'maxHeight' => '720',
            
            'loose-anamorphic' => '',
            'x264opts'
                => 'cabac=0:ref=2:me=umh:b-adapt=2:'
                 . 'weightb=0:trellis=0:weightp=0',
        },
        '.mkv' => {
            'audio' => [ '1:aac', '1:ac3' ],
        },
        '.avi' => {
            'audio' => [ '1:stereo' ],
        },
        'DVD' => {
            'audio'   => [ '1:aac', '1:ac3' ],
        },
    );
    
    return %config;
}

1;
