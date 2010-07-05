package Media::Handler::DVD;

use Modern::Perl;
use MooseX::FollowPBP;
use Moose;
use MooseX::Method::Signatures;

extends 'Media::Handler';

use Config::Std;
use File::Path;
use FileHandle;
use IO::CaptureOutput   qw( capture_exec );



method is_type ( Str $name ) {
    # is DVD if the directory contains another directory 'VIDEO_TS'
    if ( -d $name ) {
        if ( -d "${name}/VIDEO_TS" ) {
            return( 'DVD', $self->high_confidence );
        }
    }
    
    return;
}

method install_from ( Str $directory, Int $priority ) {
    my $config = "$directory/dvd.conf";
    
    if ( -f $config ) {
        $self->process_dvd( $directory, $priority );
    }
    else {
        $self->scan_dvd( $directory );
    }
}
method process_dvd ( Str $directory, Int $priority ) {
    my $config_file = "$directory/dvd.conf";
    read_config $config_file, my $config;
    my %config = %{ $config };
    
    my $type = $config{''}{'type'};
    if ( !defined $type ) {
        say "-> $directory has no known type";
        $self->edit_dvd_config( $directory );
        return;
    }
    
    my $media   = $self->get_media();
    my $handler = $media->get_handler_type( $type );
    mkpath( $directory );
    
    foreach my $key ( sort keys %config ) {
        next if $key eq '';
        next if $config{ $key }{'ignore'};
        
        my %details = $handler->get_dvd_details( \%config, $key );
        $details{'key'} = $key;
        
        my $process = $handler->get_processing_directory( \%details );
        
        $self->write_log( "queue conversion: ${directory} title ${key}" );
        my %conversion = (
                'input'   => $directory,
                'output'  => $process,
                'options' => {
                    '-t'       => $key,
                    'audio'    => $details{'audio'},
                    'subtitle' => $details{'subtitle'},
                    'crop'     => $details{'crop'},
                    'poster'   => $details{'poster'},
                },
            );
        
        my $set_option_with_default = sub {
                my $option = shift;
                my $key    = shift // $option;
                
                my $value = $details{ $option };
                return unless defined $value;
                
                # '1' just means turn on the option; anything else means
                # to use that value as the argument to the option
                $conversion{'options'}{ $key } = '';
                $conversion{'options'}{ $key } = $value
                    if '1' ne $value;
            };
        
        # copy chapter markers, with optional description file
        &$set_option_with_default( 'chapters', 'markers' );
        
        # only convert some chapters in the source title
        &$set_option_with_default( 'range', 'chapters' );
        
        # visual effects
        &$set_option_with_default( 'decomb'     );
        &$set_option_with_default( 'detelecine' );
        &$set_option_with_default( 'denoise'    );
        
        $media->queue_conversion( \%conversion, $priority );
    }
}
method scan_dvd ( Str $directory ) {
    my( $out, $err ) = capture_exec( 
            'HandBrakeCLI',
            '-i',
            $directory,
            '-t',
            '0',
        );
    
    my $dvd_config  = $self->determine_title_config( $err );
    my $config_file = "$directory/dvd.conf";
    my $handle      = FileHandle->new( $config_file, 'w' )
        or die "write ${config_file}: $!";
    
    print {$handle} $dvd_config;
    undef $handle;
    
    $self->edit_dvd_config( $directory );
}
method determine_title_config ( Str $handbrake_output ) {
    my $new_title = qr{^ \+ \s title \s (\d+): }x;
    my $duration  = qr{^ \s+ \+ \s duration: \s ( [\d:]+ ) }x;
    my $crop      = qr{^ \s+ \+ \s autocrop: \s ( [\d\/]+ ) }x;
    my $size      = qr{^ \s+ \+ \s size: \s ( .* ) }x;
    my $chapter   = qr{^ \s+ \+ \s ( \d+ ) \: \s cells }x;
    my $vts       = qr{^ \s+ \+ \s vts }x;
    my $angles    = qr{^ \s+ \+ \s angle }x;
    my $subtitles = qr{^ \s+ \+ \s (\d+) \, ( .* ) }x;
    my $subtypes  = qr{^ \s+ \+ \s 
                         (chapters|audio\stracks|subtitle\stracks): }x;
    my $audio_track = qr{^ 
            \s+ \+ \s 
            (?<track> \d+) \, \s+
            (?<language> \w+ ) \s+
            \( (?<format> \w+ ) \) \s+
            (?: \( (?<description> .*? ) \) \s+ )?
            \( (?<channels> .*? ) \) \s+
            \( (?<langcode> .*? ) \) \, \s+
            \d+Hz \, \s+
            \d+bps
        }x;
    my( $title, $config, $title_comments, $title_options, %titles );
    
    foreach my $line ( split( m/\n/, $handbrake_output ) ) {
        next unless $line =~ m{^ \s* \+ }x;     # skip the debugging lines
        next if     $line =~ $subtypes;         # don't care
        next if     $line =~ $vts;              # don't care
        next if     $line =~ $angles;           # don't care
        
        given ( $line ) {
            when ( $new_title ) {
                $title = $1;
                $titles{ $title }{'title_comments'} = '';
                $titles{ $title }{'title_options'}  = "ignore   = 0\n";
            }
            when ( $size ) {
                $titles{ $title }{'title_comments'} .= "# size $1\n";
            }
            when ( $chapter ) {
                $titles{ $title }{'chapters'} = "chapters = 1\n"
                    if 1 != $1;
            }
            when ( $duration ) {
                $titles{ $title }{'title_comments'} .= "# duration $1\n";
            }
            when ( $crop ) {
                $titles{ $title }{'title_options'} .= "crop     = $1\n";
            }
            when ( $audio_track ) {
                my %track  = %+;
                my $name   = $track{'description'} // 'Sound';
                my $stream = $+{'track'};
                
                my $in_stereo = (
                        $track{'channels'} =~ m{2\.0}
                        or
                        $name =~ m{commentary}i
                    );
                
                if ( $in_stereo ) {
                    $titles{ $title }{'title_options'}
                        .= "audio    = ${stream}:stereo:${name}\n";
                }
                else {
                    $titles{ $title }{'title_options'}
                        .= "audio    = ${stream}:aac:${name}\n"
                         . "audio    = ${stream}:ac3:${name}\n";
                }
                $titles{ $title }{'title_comments'} 
                    .= "# audio: $stream $line\n";
            }
            when ( $subtitles ) {
                $titles{ $title }{'title_comments'} .= "# subtitle: $1 $2\n";
                $titles{ $title }{'title_options'}  
                    .= "subtitle = file.srt\n";
                
            }
            default {
                $line =~ s{^ \s+ \+ \s+ }{}x;
                $titles{ $title }{'title_comments'} .= "# $line\n";
            }
        }
    }
    
    # add options for the different types
    $titles{''}{'title_options'} .= "# type   = TV\n"
                                  . "# series = ???\n"
                                  . "# season = 0\n\n"
                                  . "# type   = Movie\n"
                                  . "# title  = ???\n"
                                  . "# year   = 1900\n"
                                  . "# poster = http://blah\n"
                                  . "# rating = NR\n";
    
    foreach my $title ( keys %titles ) {
        next if $title eq '';
        
        delete $titles{ $title }{'duration'};
        $titles{ $title }{'title_options'} .= "# decomb   = 1\n\n"
                                            . "### for TV:\n"
                                            . "# title    = ???\n"
                                            . "# episode  = 0\n"
                                            . "### for Movies:\n"
                                            . "# feature  = 1\n"
                                            . "# extra    = ???\n";
    }
    
    # assemble the string returned
    $config = join( q(), values %{ $titles{''} } );
    delete $titles{''};
    
    foreach my $title ( sort { $a <=> $b } keys %titles ) {
        $config .= "\n[$title]\n"
                 . join( q(), sort values %{ $titles{ $title } } );
    }
    
    return $config;
}

method edit_dvd_config ( Str $directory ) {
    my $config_file = "$directory/dvd.conf";
    my $editor      = $ENV{'EDITOR'} 
                   // $ENV{'VISUAL'}
                   // 'vi';
    
    system( $editor, $config_file );
}

1;

__END__

=head1 NAME

B<Media::Handler::DVD> - DVD specific handling code

=head1 DVD DESCRIPTION FILE

When first processing a DVD, the C<media> script will examine the DVD and
write out a F<dvd.conf> file, which is a skeleton description of the contents
of the DVD.

Like the L<Media::Config> configuration, lines beginning with a hash (#)
character are comments, which are ignored. The skeleton file will contain
various comments informing you of what the scan of the DVD found.

=head2 Introduction section

The first part of the file tells C<Media> what type of content is on the DVD,
television episodes or a movie; what the title is and anything else that is
disc-wide information.

=head3 Television show example

    type   = TV
    series = Firefly
    season = 1

=head3 Movie example

    type   = Movie
    title  = Serenity
    year   = 2005
    poster = http://...
    rating = 15

=head2 Title sections

An individual video file (an episode of a television series, a movie, extra
content such as out-takes) on a DVD is called a title.

Each title on the DVD has a section in the description file, which contains
details about that specific title.

=head3 Television show example

    [5]
    audio      = 1:ac3:Sound
    audio      = 1:aac:Sound
    title      = Our Mrs Reynolds
    episode    = 5

=head3 Movie feature example

    [5]
    audio      = 1:ac3:Surround Sound
    audio      = 1:aac:Surround Sound
    audio      = 2:aac:Director's Commentary
    subtitle   = english.srt
    subtitle   = commentary.srt
    feature    = 1

=head3 Movie extra content example

    [5]
    audio      = 1:aac:Sound
    extra      = Out-takes

=head2 Available options

More options are available in the per-title sections than
are shown in the example.

=over

=item B<ignore>

Set this to C<1> to tell C<Media> not to bother with this title. Useful for
titles such as adverts, FBI warnings, animated menus and more.

=item B<crop>

Pass a specific crop value to HandBrake when processing the video.
This is inserted into the file when created for each title, using
automatic detection. Almost always this value is correct.

=item B<audio>

An audio profile. See L<Audio profiles> in L<Media::Tutorial> for more
information.

The actual audio found when scanning the DVD is listed in the comments for
that title. The default is to have two profiles on the first channel, one the
original AC3 audio, the other a reprocessed version of this which is suitable
for devices that cannot play AC3.

=item B<subtitle>

A subtitle file, in the SRT format. Currently, the language value of this
subtitle in the output file will be taken from a hard-coded list. This will
change soon.

=item B<range>

Set this to a range value (eg. C<1-3>) to only convert some of
the chapters of the title.

=item B<chapters>

Set this to C<1> to copy the chapter markers from the title to the converted
video. Set this to the filename of a chapter description file if you wish to
have named chapters.

=item B<decomb>

Set this to C<1> to turn on HandBrake's default decombing, or set it to
a value to control the decombing further.

=item B<detelecine>

Set this to C<1> to turn on HandBrake's default detelecine processing, or
set it to a value to control this behaviour further.

=item B<denoise>

Set this to C<weak>, C<medium>, C<strong> or a more detailed control string
to turn on HandBrake's denoise filtering.
