package Media::Config;

use Modern::Perl;
use Moose::Role;



sub get_default_config {
    my %config = ( 
        # DEFAULT SECTION
        # options for the whole "media" handling thingy
        '' => {
            tv_directory    => '/files/tv',
            movie_directory => '/files/movies',
            log_directory   => "$ENV{'HOME'}/Downloads/queue",
            data_directory  => "$ENV{'HOME'}/Downloads/queue",
            base_directory  => "$ENV{'HOME'}/Downloads",
            trash_directory => "$ENV{'HOME'}/.Trash",
            trash_files     => 1,
            add_to_itunes   => 1,
            install_encodes => 1,
        },
        
        # NAMED SECTION
        # Different flags for HandBrake depending upon the source type
        # (can be file extension, source type...). Section must exist
        # if that type is valid in the system (leave section empty to just 
        # accept the code defaults).
        
        # flags used in every encode (is over-ridden by other sections)
        common => {
            encoder   => 'x264',
            format    => 'mp4',
            
            quality   => '22',
            
            maxWidth  => '1280',
            maxHeight => '720',
            
            audio     => [ '1:stereo:Stereo' ],
            
            x264opts  => 'cabac=0:ref=2:me=umh:b-adapt=2:'
                       . 'weightb=0:trellis=0:weightp=0',
            
            'loose-anamorphic' => '',
        },
        
        # audio flags
        audio_aac => {
            downmix => 'dpl2',
        },
        audio_six => {
            downmix => '6ch',
            bitrate => '256',
        },
        audio_stereo => {
            downmix => 'stereo',
        },
        audio_mono => {
            downmix => 'mono',
        },
        
        # file extension based flags
        '.mkv' => {
            audio => [ 
                '1:aac:Dolby Surround', 
                '1:ac3:Dolby Surround' 
            ],
        },
        '.avi' => {},
        '.mp4' => {},
        
        # original source based flags
        default_source => {},
        VHS => {
            crop    => '4:10:0:8',  # cut out folded-back and fuzzy bits
            denoise => 'weak',      # smooth out tape noise
            quality => '24',        # no need for higher quality
        },
        DVD => {
            audio => [ 
                '1:aac:Dolby Surround', 
                '1:ac3:Dolby Surround' 
            ],
        },
    );
    
    return %config;
}

1;
