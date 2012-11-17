#!/usr/bin/env perl

use Modern::Perl;
use Capture::Tiny   qw( capture );
use Cwd;
use File::Copy;
use File::Path;
use IO::All;
use Media;
use Test::More;


my $input_file = "$ENV{'MEDIA_TESTING'}/ac3.vob";
my $cwd        = getcwd();

if ( !-f $input_file ) {
    plan skip_all => "${input_file} file is missing";
    exit;
}

plan tests => 17;

# ensure a clean directory structure
my $result = system 'rm -rf xt/encode xt/source xt/video xt/queue xt/trash';
die "'rm -rf xt/encode xt/source xt/video xt/queue xt/trash': $!"
    if $result >> 8;

my $media  = Media->new( 't/conf/trash.conf' );
my $source = 'xt/source';
mkpath $source;
copy( $input_file, $source )
    or die;

$media->queue_media( 
        "$source/ac3.vob",
        undef,
        undef,
        { type => 'Video' }
    );
$media->queue_media(
        "$source/ac3.vob",
        undef,
        {
            series => 'YouTube Favourites',
            title  => 'Charlie bit my finger',
        },
        { type => 'Video' }
    );
ok( $media->queue_count() == 2, 'queue created' );

# infinite wait without the queue job
die unless $media->queue_count() == 2;

my( $job, $payload ) = $media->next_queue_job();
isa_ok( $job, 'IPC::DirQueue::Job' );
is_deeply(
        $payload,
        {
            details => {
                audio   => [
                    '1:ac3pass:Unknown 5.1 ch AC3',
                    '1:dpl2:Unknown 5.1 ch',
                ],
                title => 'ac3',
            },
            input   => {
                media_conf => "$cwd/t/conf/trash.conf",
                file       => "$source/ac3.vob",
                title      => '1',
            },
            medium  => 'VideoFile',
            name    => 'ac3',
            type    => 'Video',
        }
    );


$media->encode_media( $payload );

# check the output
my $target_file = 'xt/video/ac3.m4v';
ok( -f $target_file, 'file installed' );
exit unless -f $target_file;

ok( ! -d 'xt/encode/ac3.vob',
    'encoder clears up after itself' );
ok( -f 'xt/trash/ac3.vob',
    'encoder trashes source files' );

my $handler  = $media->get_empty_handler( 'TV', 'VideoFile' );
my %metadata = $handler->extract_metadata( $target_file );
is_deeply(
        \%metadata,
        {
            title => 'ac3',
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
                kind => "ac-3",
                type => "soun",
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
            handbrake_version => "0.9.8",
            input_type        => "mov",
            1                 => {
                audio     => [
                    {
                        channels => '5.1 ch',
                        code     => 'und',
                        format   => 'AC3',
                        language => 'Unknown',
                        track    => '1',
                    },
                    {
                        channels => '2.0 ch',
                        code     => 'und',
                        format   => 'aac',
                        language => 'Unknown',
                        track    => '2',
                    },
                ],
                crop      => '0/0/0/0',
                duration  => '00:01:08',
                size      => '720x576, pixel aspect: 2048/1435, display '
                           . 'aspect: 1.78, 25.000 fps',
                subtitles => []
            },
        },
        'video file appears to have been encoded correctly',
    );



( $job, $payload ) = $media->next_queue_job();
isa_ok( $job, 'IPC::DirQueue::Job' );
is_deeply(
        $payload,
        {
            details => {
                audio  => [
                    '1:ac3pass:Unknown 5.1 ch AC3',
                    '1:dpl2:Unknown 5.1 ch',
                ],
                series => 'YouTube Favourites',
                title  => 'Charlie bit my finger',
            },
            input   => {
                media_conf => "$cwd/t/conf/trash.conf",
                file       => "$source/ac3.vob",
                title      => '1',
            },
            medium  => 'VideoFile',
            name    => 'Charlie bit my finger',
            type    => 'Video',
        }
    );

mkpath $source;
copy( $input_file, $source )
    or die;

$media->encode_media( $payload );

# check the output
$target_file = 'xt/tv/YouTube Favourites/Charlie bit my finger.m4v';
ok( -f $target_file, 'file installed' );
exit unless -f $target_file;

ok( ! -d 'xt/encode/ac3.vob',
    'encoder clears up after itself' );
ok( -f 'xt/trash/ac3.vob',
    'encoder trashes source files' );

$handler  = $media->get_empty_handler( 'TV', 'VideoFile' );
%metadata = $handler->extract_metadata( $target_file );
is_deeply(
        \%metadata,
        {
            kind       => 'TV Show',
            series     => 'YouTube Favourites',
            title      => 'Charlie bit my finger',
        },
        'metadata'
    );

@tracks = $handler->extract_tracks( $target_file );
is_deeply(
        \@tracks,
        [
            {
                kind => "avc1",
                type => "vide",
            },
            {
                kind => "ac-3",
                type => "soun",
            },
            {
                kind => "mp4a",
                type => "soun",
            }
        ],
        'tracks'
    );


$handbrake_output = $handler->scan_input( 0, $target_file );
%titles           = $handler->analyse_input( $handbrake_output );
is_deeply(
        \%titles,
        {
            handbrake_version => "0.9.8",
            input_type        => "mov",
            1                 => {
                audio     => [
                    {
                        channels => '5.1 ch',
                        code     => 'und',
                        format   => 'AC3',
                        language => 'Unknown',
                        track    => '1',
                    },
                    {
                        channels => '2.0 ch',
                        code     => 'und',
                        format   => 'aac',
                        language => 'Unknown',
                        track    => '2',
                    },
                ],
                crop      => '0/0/0/0',
                duration  => '00:01:08',
                size      => '720x576, pixel aspect: 2048/1435, display '
                           . 'aspect: 1.78, 25.000 fps',
                subtitles => []
            },
        },
        'tv episode appears to have been encoded correctly',
    );
