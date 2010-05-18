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

__END__

=head1 NAME

B<Media::Config> -- configuration for the Media project

=head1 CONFIGURATION FILE

The Media project has a lot of sensible defaults, but they can be overriden
by declaring them in a configuration file.

By default, this file is F<~/etc/media.conf>, but you can alter that by
setting the environment variable C<MEDIA_CONFIG> to the location of your
configuration file.

=head1 CONFIGURATION FORMAT

The configuration file is in the standard "INI" format, which looks like this:

    # don't delete files once encoded
    trash_files = 0
    
    [rationalise]
    Human Target (2010) = Human Target
    
    [audio_six]
    bitrate = 320

Any line starting with a hash (#) character are ignored.

=head1 SETTINGS

=head2 Global section

The first part of the file are the global settings.

=over

=item B<tv_directory>

This sets the base directory where episodes of television shows are stored.
The default is F</files/tv/>.

=item B<movie_directory>

This sets the base directory where movies are stored. The default is
F</files/movies>.

=item B<log_directory>

The C<encoder> and C<media> scripts keep logs of their actions. These are
placed in this directory. Default is C<~/Downloads/queue>.

=item B<data_directory>

The Media project keeps various state objects (such as the processing
queue) in files, which are placed within this directory.
Default is C<~/Downloads/queue>.

=item B<base_directory>

When C<encoder> converts media, the temporary conversion files are stored
within this directory. Default is C<~/Downloads>.

=item B<trash_files>

After encoding a source video file (note: but not a DVD image), encoder can
remove it, which it does by moving it into the "Trash". Setting this to C<0>
means the files will not be deleted. Default is C<1> (files are trashed).

=item B<trash_directory>

The directory that "trashed" files are moved to. Default is C<~/.Trash>.

=item B<install_encodes>

After converting video content, C<encoder> can install the output into the
right location (see L<Locations> in L<Media> for more information)
automatically. Setting this to C<0> means the files will not be installed
so they can be further post-processed (eg. adding subtitles, chapters...).
Default is C<1> (files are installed).

=item B<add_to_itunes>

After installing a video file, it can be added to the iTunes library. Setting
this to C<0> stops the file installation from doing this. Default is C<1>
(files are added).

B<Note>: Added files are directly linked into the iTunes library, which
ignores the iTunes C<Copy files to iTunes media folder when adding to library>
setting.

=item B<sync_to>

After adding a file to the library, iTunes can be instructed to synchronise
with attached devices (iPod, iPhone, iPad, Apple TV). Set this to a string
that matches the device you wish to automatically sync to. Defaults to
nothing, so no synching will occur.

=back

=head2 Common encoding settings

The F<common> section defines arguments passed to HandBrakeCLI for
any video encode (they are then further overriden depending upon the
source type). An example:

    # lowest quality, used during debugging
    [common]
    quality = 50
    maxWidth = 240
    maxHeight = 120
    no-loose-anamorphic = 1

Any command line options that HandBrake accepts can be set in this section.

=over

=item quality

Defines the "constant quality" setting, which ranges from 51 (0% quality) up
to 0 (100% quality) in increments of 0.25. Default is C<22>.

=item maxWidth

The maximum width of the output, in pixels. Default is C<1280> (width of 720p
video).

=item maxHeight

The maximum height of the output, in pixels. Default is C<720> (height of
720p video).

=item audio

The audio profile to use. See L<Audio Profiles> below for more information.
Default is C<1:stereo:Stereo>.

=item encoder

The video library to use to encode the video (ffmpeg, x264, theora). Default
is C<x264>.

=item format

The file output format to use (mp4, mkv). Default is C<mp4>.

=item x264opts

The advanced settings passed to the x264 encoder. Default is
C<cabac=0:ref=2:me=umh:b-adapt=2:weightb=0:trellis=0:weightp=0>, which is
mostly suitable for Apple TVs.

=back

=head2 Source encoding settings

Different sources of video can have different encoding settings.

    [VHS]
    maxWidth = 480
    maxHeight = 320
    quality = 30,
    crop = 4:10:0:8

Again, these are all options as accepted by HandBrakeCLI. The source is either
the filename extension (including the dot, eg. '.mkv', '.avi') when processing
an individual video file, or the original source type (either 'DVD' or 'VHS'
currently).

Settings from the filename take precedence and will override those from the
original source type and common settings; source will in turn override those
from the common settings.

=head3 Defaults

The defaults for DVD sources and .mkv source files are to use both C<ac3>
and C<aac> audio profiles for the first audio stream.

The defaults for VHS sources are C<quality = 24>, C<denoise = weak> and
C<crop = 4:10:0:8>.

=head2 Audio profiles

To simplify the settings in the video source sections, audio tracks are
defined using profiles, which in turn contain the complex options for audio.
This allows for easier adding of multiple audio streams.

An audio setting is a string which is a triple value, separated by colons,
that look like:

    # pass through the main sound
    audio = 1:ac3:Sound
    # mono for the commentary
    audio = 2:mono:Director's Commentary

The first value is the source audio channel, the second is the profile to use,
the third is the name of the audio stream.

The profiles are:

=over

=item B<ac3>

pass through the original audio stream unchanged.

=item B<aac>

convert the original audio into an AAC stream, containing
Dolby Pro-Logic II audio.

=item B<six>

convert the original audio into a six channel AAC stream.

=item B<stereo>

convert the original audio into a stereo AAC stream.

=item B<mono>

convert the original audio into a mono AAC stream.

=back

Any of these profiles, with the exception of C<ac3> can have their default
settings altered, or you can create a new one by putting the audio arguments
into a section of the configuration file named F<audio_C<profile>>. For example:

    # create a low profile for reduced filesize
    [audio_low]
    bitrate = 32
    sample = 22.05
    
    # increase bitrate on six-channel audio
    [audio_six]
    bitrate = 320

The settings accepted are:

=over

=item encoder

The audio encoder to use (faac, lame, vorbis, ac3, dts, and ca_aac on OS X
only). Default is C<ca_aac>.

=item bitrate

The bitrate of the converted audio stream. Default is C<160> for all profiles
except C<six>, where it is C<256>.

=item downmix

Original complex audio (5.1 digital AC3 surround sound, for example) can be
"downmixed" to other formats that are supported on more devices, such as the
iPod/iPhone/iPad. The available settings are:

=over

=item mono

a single audio channel

=item stereo

two audio channels, left and right

=item dpl1

Dolby Pro Logic, which encodes surround sound within stereo audio.

=item dpl1

Dolby Pro Logic II

=item 6ch

six-channel AAC

=back

=item sample

The audio sample rate in kHz (22.05, 24, 32, 44.1, 48). Default is C<48>.

=item range

Apply dynamic range compression (making quiet sound louder)
to the source. Values range between 0.0 (no compression) to
4.0 (very loud). Default is <0.0>.

=back

=head2 Rationalise

This section allows TV show names to be "rationalised" -- altering the
(probably definitive) source to a preferred value before installation.

For example:

    [rationalise]
    American Dad_ = American Dad!
    American Dad  = American Dad!

The source video for the TV show "American Dad!" may be named without the
exclamation mark or with an underscore (iTunes will escape some characters
that are shell metacharacters when creating filenames automatically). This
ensures that once processed by C<Media>, it will have an exclamation mark.

    Castle (2009) = Castle

Some source video for the 2009 TV show "Castle" will come with the year, to
differentiate it from the 2003 Mini-Series of the same name. This ensures
that once processed, it will just be called "Castle" as the year is unwanted.

    Star Wars[C] The Clone Wars (2008) = Star Wars - The Clone Wars

The definitive name for the CGI 2008 Star Wars TV show is I<S<Star Wars:
The Clone Wars>>. Many sources will add the year to differentiate it from the
animated 2003 TV series with a similar name. This line ensures that after
processing, the name will be "Star Wars - The Clone Wars", as hyphens are
preferred to colons in filenames and the year is unwanted.

This also illustrates that it is impossible to use literal colons or equals
signs in the TV show names, as they would be interpreted as the delimiter
of the configuration line, not as part of the show name. The placeholders
C<[E]> and C<[C]> can be used instead.
