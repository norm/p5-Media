#!/usr/bin/env perl

use Modern::Perl;
use Capture::Tiny   qw( capture );
use Cwd;
use File::Copy;
use File::Path;
use IO::All;
use Media;
use Test::More;


my $input_file = "$ENV{'MEDIA_TESTING'}/hooker.avi";
my $cwd        = getcwd();
my $priority   = 10;

if ( !-f $input_file ) {
    plan skip_all => "${input_file} file is missing";
    exit;
}

plan tests => 11;

# ensure a clean directory structure
my $result = system 'rm -rf xt/source xt/encode xt/tv xt/queue xt/trash';
die "'rm -rf xt/source xt/encode xt/tv xt/queue xt/trash': $!"
    if $result >> 8;


my $media       = Media->new( 't/conf/trash.conf' );
my $source      = 'xt/source/T.J. Hooker - 3x01 - The Return';
my $config_file = "$source/media.conf";
mkpath $source;
copy( $input_file, $source )
    or die;

$media->queue_media(
        $source,
        $priority,
        {},
        {
            decomb     => 1,
            'start-at' => 0,
            'stop-at'  => '97',
        }
    );
ok( $media->queue_count() == 1, 'queue created' );

# infinite wait without the queue job
die unless $media->queue_count() == 1;

my( $job, $payload ) = $media->next_queue_job();
isa_ok( $job, 'IPC::DirQueue::Job' );
is_deeply(
        $payload,
        {
            details => {
                'start-at' => 0,
                'stop-at'  => '97',
                audio      => [
                    '1:stereo:Unknown Stereo',
                ],
                decomb     => 1,
                episode    => '01',
                season     => '3',
                series     => 'T.J. Hooker',
                title      => 'The Return',
            },
            input   => {
                file       => "$source/hooker.avi",
                media_conf => "$cwd/t/conf/trash.conf",
                title      => '1',
            },
            medium  => 'VideoFile',
            name    => 'T.J. Hooker - 3x01 - The Return',
            type    => 'TV',
        },
        'payload is correct',
    );

# confirm HandBrake will be called correctly
my $handler = $media->get_handler(
        $payload->{'type'},
        $payload->{'medium'},
        $payload->{'details'},
        $payload->{'input'},
    );

my %audio_args = $handler->get_audio_args( $payload->{'details'}{'audio'} );
my %video_args = $handler->get_video_args( $payload->{'details'} );
my %args       = (
        %audio_args,
        %video_args,
    );

is_deeply(
        \%args,
        {
            'loose-anamorphic' => '',
            ab                 => '160',
            aencoder           => 'ca_aac',
            aname              => 'Unknown Stereo',
            arate              => '48',
            audio              => '1',
            decomb             => '1',
            encoder            => 'x264',
            format             => 'mp4',
            maxHeight          => '720',
            maxWidth           => '1280',
            mixdown            => 'stereo',
            quality            => '22',
            'start-at'         => 'duration:0',
            'stop-at'          => 'duration:97',
            x264opts           => 'cabac=0:ref=2:me=umh:b-adapt=2:'
                                . 'weightb=0:trellis=0:weightp=0:'
                                . 'b-pyramid=none:vbv-maxrate=9500:'
                                . 'vbv-bufsize=9500'
        },
        'handbrake arguments are correct'
    );


$media->encode_media( $payload );


# check the output
my $target_file = 'xt/tv/T.J. Hooker/Season 3/'
                . '01 - The Return.m4v';
ok( -f $target_file, 'file installed' );
exit unless -f $target_file;

ok( ! -d 'xt/encode/T.J. Hooker - 3x01 - The Return',
    'encoder clears up after itself' );
ok( -f 'xt/trash/hooker.avi',
    'encoder trashes source files' );
ok( ! -d $source, 
    'encoder clears up source directories' );

$handler = $media->get_empty_handler( 'TV', 'VideoFile' );
my %metadata = $handler->extract_metadata( $target_file );
is_deeply(
        \%metadata,
        {
            kind       => 'TV Show',
            series     => 'T.J. Hooker',
            season     => '3',
            episode    => '1',
            episode_id => '3x01',
            title      => 'The Return',
        },
        'metadata'
    );

my @tracks = $handler->extract_tracks( $target_file );
is_deeply(
        \@tracks,
        [
            {
                kind => "avc1",
                type => "vide",
            },
            {
                kind => "mp4a",
                type => "soun",
            }
        ],
        'tracks'
    );


my $handbrake_output = $handler->scan_input( 0, $target_file );
my %titles           = $handler->analyse_input( $handbrake_output );
is_deeply(
        \%titles,
        {
            handbrake_version => "0.9.5",
            input_type        => "mov",
            1                 => {
                audio     => [
                    {
                        channels => '2.0 ch',
                        code     => 'und',
                        format   => 'AAC',
                        language => 'Unknown',
                        track    => '1',
                    },
                ],
                crop      => '0/0/0/0',
                duration  => '00:01:37',
                size      => '704x480, pixel aspect: 89/88, display '
                           . 'aspect: 1.48, 29.929 fps',
                subtitles => [],
            },
        },
        'tv episode appears to have been encoded correctly',
    );
