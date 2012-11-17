package Media::Config;

use Modern::Perl;
use Config::Std;
use Exporter;

our @ISA    = qw( Exporter );
our @EXPORT = qw( get_configuration );

sub get_configuration {
    my $config_file = shift;
    
    my %default = ( 
        # DEFAULT SECTION
        # options for the whole "media" handling thingy
        '' => {
            add_to_itunes    => 1,
            cache_directory  => "$ENV{'HOME'}/Downloads/queue/cache",
            encoder_log_file => "$ENV{'HOME'}/Downloads/queue/encoder.log",
            encoder_pid_file => "$ENV{'HOME'}/Downloads/queue/encoder.pid",
            encode_directory => "$ENV{'HOME'}/Downloads",
            language_code    => 'eng',
            low_disk_space   => '5G',
            movies_directory => "/files/movies",
            music_directory  => "/files/music",
            queue_directory  => "$ENV{'HOME'}/Downloads/queue",
            trash_directory  => "$ENV{'HOME'}/.Trash",
            trash_files      => 0,
            tv_directory     => "/files/tv",
        },

        # NAMED SECTIONS - HandBrake
        # Different flags for HandBrake depending upon the source type
        # (can be file extension, source type...). Section must exist
        # if that type is valid in the system (leave section empty to just 
        # accept the code defaults).
        handbrake => {
            encoder   => 'x264',
            encopts   => 'b-adapt=2',
            format    => 'mp4',
            
            quality   => '22',
            
            maxWidth  => '1280',
            maxHeight => '720',
            
            'loose-anamorphic' => '',
        },
        
        # NAMED SECTIONS - audio profiles
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
    
    if ( -f $config_file ) {
        read_config $config_file => my %file_config;
        
        # override the defaults with anything in the config file
        foreach my $section ( keys %file_config ) {
            foreach my $key ( keys %{ $file_config{$section} } ) {
                $default{$section}{$key} = $file_config{$section}{$key};
            }
        }
    }
    else {
        say STDERR "** $config_file does not exist, using defaults.";
    }
    
    return %default;
}

1;

__END__

=head1 NAME

Media::Config -- configuration for the Media project

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

    [audio_stereo]
    -B = 320
    
    [series_priority]
    House = 10

Any line starting with a hash (#) character are ignored.

=head1 SETTINGS

=head2 Global section

The first part of the file are the global settings.

=over

=item B<tv_directory>

The base directory where episodes of television shows are stored. Default is
F</files/tv/>.

=item B<movies_directory>

The base directory where movies and their extras are stored. Default is
F</files/movies/>.

=item B<music_directory>

The base directory where music videos are stored. Default is F</files/music/>.

=item B<single_directory>

Setting this overrides the settings C<tv_directory>, C<movies_directory> and
C<music_directory>, and any encoded video will be stored as a file in the
directory specified. Useful for pointing to "Automatically Add to iTunes"
if you let iTunes organise your video content. Default is empty.

=item B<queue_directory>

The directory used to store the data for the encoder queue. Default is
C<~/Downloads/queue>.

=item B<encoder_log_file>

The C<encoder> script keeps a log of its actions. It is stored in this file.
An empty value turns off logging. Default is C<~/Downloads/queue/encoder.log>.

=item B<encoder_pid_file>

The file that the C<encoder> script writes its process ID to (later used when
the encoder should be paused or killed). Default is
C<~/Downloads/queue/encoder.log>.

=item B<encode_directory>

When C<encoder> converts media, the temporary conversion files are stored
within this directory. Default is C<~/Downloads>.

=item B<cache_directory>

The C<encoder> and C<queue> scripts sometimes use external web services to
look up details. These details are cached into this directory. Default is
C<~/Downloads/queue/cache>.

=item B<trash_files>

After encoding a source video file (note: but not a DVD image), encoder can
remove it, which it does by moving it into the "Trash". Set this to any value
other than 0 to trash the source files. Default is C<0>.

=item B<trash_directory>

The directory that "trashed" files are moved to. Default is C<~/.Trash>.

=item B<use_imdb>

After looking up a movie in the Internet Movie Database, C<Media> can use 
the found values to set the year and rating/certificate of the movie, even
if they were provided in the source. Set this to any value other othan 0
to use IMDb values in preference. Default is C<0>.

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

=item B<language_code>

Set the default ISO 639-2 language code for the audio and subtitle streams to
use in your source, if it contains multiple languages. Default is C<eng>.

=back

=head2 HandBrake settings

The F<handbrake> section defines arguments passed to HandBrakeCLI for
any video encode (they are then further overriden depending upon the
source type). An example:

    # lowest quality, used during debugging
    [handbrake]
    quality             = 50
    maxWidth            = 240
    maxHeight           = 120
    no-loose-anamorphic = 1

Any command line options that HandBrake accepts can be set in this section.
Some common settings are:

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

=item encoder

The video library to use to encode the video (ffmpeg, x264, theora). Default
is C<x264>.

=item format

The file output format to use (mp4, mkv). Default is C<mp4>.

=item encopts

The advanced settings passed to the x264 encoder. Default is:

    b-adapt=2

which is suitable for Apple TV 3 and modern iPads. For older hardware, use:

    cabac=0:ref=2:me=umh:b-adapt=2:weightb=0
    :trellis=0:weightp=0:b-pyramid=none
    :vbv-maxrate=9500:vbv-bufsize=9500

which is tuned to produce content that will work on the early iPhones, iPads
and the first Apple TV.

=item two-pass

Whether HandBrake should use two passes over the source.

=back

=head2 Audio profiles

Audio profiles are explained in greater detail in L<Media::Tutorial>.

Individual arguments for any audio profile can be changed in a section
called C<audio_<profile>> (eg. C<audio_stereo> for the stereo profile).
The options available are:

=over

=item aencoder

the encoder to use

=item ab

the bitrate to use

=item mixdown

the mixdown setting

=item arate

the audio samplerate

=back

Any profile with the exception of C<ac3> can have their default settings
altered.

=head2 Series priorities

The default queue priority for a TV series can be set in the section 
C<series_priority>. The option is the name of the show, and the value is
the priority to use.

=head2 Rationalise

B<NOTE: this section describes functionality not implemented in this
version of L<Media>>.

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
