#!/usr/bin/env perl

use Modern::Perl;
use Capture::Tiny   qw( capture );
use Cwd;
use File::Copy;
use File::Path;
use IO::All;
use Media;
use Test::More;


my $input_file = "$ENV{'MEDIA_TESTING'}/mp3.avi";
my $cwd        = getcwd();

if ( !-f $input_file ) {
    plan skip_all => "${input_file} file is missing";
    exit;
}

plan tests => 9;

# ensure a clean directory structure
my $result = system 'rm -rf xt/encode xt/source xt/tv xt/queue xt/trash';
die "'rm -rf xt/encode xt/source xt/tv xt/queue xt/trash': $!"
    if $result >> 8;


my $media  = Media->new( 't/conf/trash.conf' );
my $source = 'xt/source/1x03 - Bastille Day.avi';
mkpath 'xt/source';
copy( $input_file, $source )
    or die;

$media->queue_media(
        $source,
        undef,
        {
            strip_extension => 1,
            series          => 'Battlestar Galactica (2003)',
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
                audio   => [
                    '1:stereo:Unknown Stereo',
                ],
                episode => '03',
                season  => '1',
                series  => 'Battlestar Galactica (2003)',
                title   => 'Bastille Day',
            },
            input   => {
                media_conf => "$cwd/t/conf/trash.conf",
                file       => $source,
                title      => '1',
            },
            medium  => 'VideoFile',
            name    => 'Battlestar Galactica (2003) - 1x03 - Bastille Day',
            type    => 'TV',
        }
    );

$media->encode_media( $payload );


# check the output
my $target_file = 'xt/tv/Battlestar Galactica (2003)/Season 1/'
                . '03 - Bastille Day.m4v';
ok( -f $target_file, 'file installed' );
exit unless -f $target_file;

ok( ! -d 'xt/encode/Battlestar Galactica (2003) - 1x03 - Bastille Day',
    'encoder clears up after itself' );
ok( ! -f $source,
    'encoder trashes source files' );

my $handler  = $media->get_empty_handler( 'TV', 'VideoFile' );
my %metadata = $handler->extract_metadata( $target_file );
is_deeply(
        \%metadata,
        {
            kind       => 'TV Show',
            series     => 'Battlestar Galactica (2003)',
            season     => '1',
            episode    => '3',
            episode_id => '1x03',
            title      => 'Bastille Day',
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
                duration  => '00:03:00',
                size      => '688x384, pixel aspect: 1/1, display '
                           . 'aspect: 1.79, 25.018 fps',
                subtitles => []
            },
        },
        'music video appears to have been encoded correctly',
    );
