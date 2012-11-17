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
'' > io "$source/bones-sample.m4v";

my $handler = $media->get_empty_handler( undef, 'VideoFile' );
$handler->create_config_file( $source );

ok( -f "$source/file.nfo", 'nfo file exists' );
ok( -f "$source/file.srr", 'srr file exists' );
ok( -f "$source/bones-sample.m4v", 'sample file exists' );

my $default_config < io 'xt/conf/flibble.conf';
my $created_config < io $config_file;
is( $default_config, $created_config, 'config created properly' );

# unedited config file means queue should not occur
ok( $media->queue_count() == 0, 'queue is empty' );
$media->queue_media( $source );
ok( $media->queue_count() == 0, 'queue is still empty' );

# update config file means queue should occur
my $bones_conf < io 'xt/conf/bones.conf';
$bones_conf > io $config_file;
$created_config < io $config_file;
is( $bones_conf, $created_config, 'config updated properly' );

$media->queue_media( $source );
ok( $media->queue_count() == 1, 'queue created' );


# infinite wait without the queue job
die unless $media->queue_count() == 1;

ok( !-f "$source/file.nfo", 'nfo file removed' );
ok( !-f "$source/file.srr", 'srr file removed' );
ok( !-f "$source/bones-sample.m4v", 'sample file removed' );
ok( -f "$source/media.conf", 'config not removed' );

my( $job, $payload ) = $media->next_queue_job();
isa_ok( $job, 'IPC::DirQueue::Job' );
is_deeply(
        $payload,
        {
            details => {
                audio         => '1:stereo:English',
                first_episode => '01',
                last_episode  => '02',
                season        => '4',
                series        => 'Bones',
                title         => 'Yanks in the U.K.',
            },
            input   => {
                config     => "$source/media.conf",
                file       => "$source/ac3.vob",
                media_conf => "$cwd/t/conf/trash.conf",
                title      => '1',
            },
            medium  => 'VideoFile',
            name    => 'Bones - 4x01-02 - Yanks in the U.K.',
            type    => 'TV',
        }
    );

$media->encode_media( $payload );


# check the output
my $target_file = 'xt/tv/Bones/Season 4/01-02 - Yanks in the U.K..m4v';
ok( -f $target_file, 'file installed' );
exit unless -f $target_file;

ok( ! -d 'xt/encode/Bones - 4x01-02 - Yanks in the U.K.',
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
            series     => 'Bones',
            season     => '4',
            episode    => '1',
            episode_id => '4x01-02',
            title      => 'Yanks in the U.K.',
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
            handbrake_version => "0.9.8",
            input_type        => "mov",
            1                 => {
                audio     => [
                    {
                        channels => '2.0 ch',
                        code     => 'und',
                        format   => 'aac',
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
