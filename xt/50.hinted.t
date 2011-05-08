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

plan tests => 22;

# ensure a clean directory structure
my $result = system 'rm -rf xt/encode xt/tv xt/queue xt/trash';
die "'rm -rf xt/encode xt/tv xt/queue xt/trash': $!"
    if $result >> 8;


my $media       = Media->new( 't/conf/trash.conf' );
my $source      = 'xt/source/flibble';
my $config_file = "$source/media.conf";
mkpath $source;
copy( $input_file, $source )
    or die;

# these files should be deleted by the queue process
'' > io "$source/file.nfo";
'' > io "$source/file.srr";
'' > io "$source/bsg-sample.m4v";

my $handler = $media->get_empty_handler( undef, 'VideoFile' );
$handler->create_config_file( $source );

ok( -f "$source/file.nfo", 'nfo file exists' );
ok( -f "$source/file.srr", 'srr file exists' );
ok( -f "$source/bsg-sample.m4v", 'sample file exists' );

my $default_config < io 'xt/conf/flibble.conf';
my $created_config < io $config_file;
is( $default_config, $created_config, 'config created properly' );

# unedited config file means queue should not occur
ok( $media->queue_count() == 0, 'queue is empty' );
$media->queue_media( $source );
ok( $media->queue_count() == 0, 'queue is still empty' );

# update config file means queue should occur
my $bsg_conf < io 'xt/conf/bsg.conf';
$bsg_conf > io $config_file;
$created_config < io $config_file;
is( $bsg_conf, $created_config, 'config updated properly' );

$media->queue_media( $source );
ok( $media->queue_count() == 1, 'queue created' );

# infinite wait without the queue job
die unless $media->queue_count() == 1;

ok( !-f "$source/file.nfo", 'nfo file removed' );
ok( !-f "$source/file.srr", 'srr file removed' );
ok( !-f "$source/bsg-sample.m4v", 'sample file removed' );
ok( -f "$source/media.conf", 'config not removed' );

my( $job, $payload ) = $media->next_queue_job();
isa_ok( $job, 'IPC::DirQueue::Job' );
is_deeply(
        $payload,
        {
            details => {
                audio   => '1:stereo:English',
                episode => '3',
                season  => '1',
                series  => 'Battlestar Galactica (2003)',
                title   => 'Bastille Day',
            },
            input   => {
                config     => "$source/media.conf",
                file       => "$source/ac3.vob",
                media_conf => "$cwd/t/conf/trash.conf",
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
ok( -f 'xt/trash/ac3.vob',
    'encoder trashes source files' );
ok( -f 'xt/trash/flibble-media.conf',
    'encoder trashes media.conf, but keeps the dirname as a hint' );
ok( ! -d $source, 
    'encoder clears up source directories' );

$handler = $media->get_empty_handler( 'TV', 'VideoFile' );
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
                duration  => '00:01:08',
                size      => '720x576, pixel aspect: 2048/1435, display '
                           . 'aspect: 1.78, 25.000 fps',
                subtitles => [],
            },
        },
        'tv episode appears to have been encoded correctly',
    );
