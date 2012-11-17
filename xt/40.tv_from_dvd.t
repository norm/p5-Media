#!/usr/bin/env perl

use Modern::Perl;
use Capture::Tiny   qw( capture );
use Cwd;
use File::Copy;
use File::Path;
use IO::All;
use Media;
use Test::More;


my $input_image = "$ENV{'MEDIA_TESTING'}/DS9_S7D7";
my $config_file = "$input_image/media.conf";
my $cwd         = getcwd();

if ( !-d $input_image ) {
    plan skip_all => "${input_image} DVD rip is missing";
    exit;
}

plan tests => 20;

# ensure a clean directory structure
my $result = system 'rm -rf xt/encode xt/tv xt/queue xt/trash';
die "'rm -rf xt/encode xt/tv xt/queue xt/trash': $!"
    if $result >> 8;


my $media  = Media->new( 't/conf/trash.conf' );

unlink $config_file;
ok( ! -f $config_file, 'config does not exist' );
ok( $media->queue_count() == 0, 'queue is empty' );

# first attempt adds a config file if there isn't one
$media->queue_media( $input_image );
ok( -f $config_file, 'config has been created' );
ok( $media->queue_count() == 0, 'queue is still empty' );

my $default_config < io 'xt/conf/ds9_s7d7.conf';
my $created_config < io $config_file;
is( $default_config, $created_config, 'config created properly' );

# second attempt fails because the config hasn't been edited
$media->queue_media( $input_image );
ok( $media->queue_count() == 0, 'queue is still empty' );
my $ds9_conf < io 'xt/conf/ds9_s7d7.edited.conf';
$ds9_conf > io $config_file;

# third attempt adds every non-ignored item in the DVD to the queue
$media->queue_media( $input_image );
ok( $media->queue_count() == 3, 'queue now has 3 items' );

# infinite wait without the queue job
die unless $media->queue_count() >= 1;

my( $job, $payload ) = $media->next_queue_job();
isa_ok( $job, 'IPC::DirQueue::Job' );
is_deeply(
        $payload,
        {
            details => {
                audio   => [
                    "1:dpl2:English",
                    "1:ac3pass:English",
                ],
                crop    => '0/0/0/0',
                episode => '99',
                quality => '35',
                season  => '7',
                series  => 'Star Trek - Deep Space Nine',
                title   => 'Extras - Section 31 Hidden File 1',
            },
            input   => {
                media_conf => "$cwd/t/conf/trash.conf",
                config     => $config_file,
                image      => $input_image,
                title      => '7',
            },
            medium  => 'DVD',
            name    => 'Star Trek - Deep Space Nine - 7x99 - '
                     . 'Extras - Section 31 Hidden File 1',
            type    => 'TV',
        },
        'first job payload matches',
    );

# check the first job output
$media->encode_media( $payload );
$job->finish();
my $target_file = 'xt/tv/Star Trek - Deep Space Nine/Season 7/'
                . '99 - Extras - Section 31 Hidden File 1.m4v';
ok( -f $target_file, 'file installed' );

my $handler          = $media->get_empty_handler( undef, 'VideoFile' );
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
                        code     => 'eng',
                        format   => 'aac',
                        language => 'English',
                        track    => '1',
                    },
                    {
                        channels => 'Dolby Surround',
                        code     => 'eng',
                        format   => 'AC3',
                        language => 'English',
                        track    => '2',
                    },
                ],
                crop      => '0/0/8/10',
                duration  => '00:02:25',
                size      => '720x576, pixel aspect: 16/15, display '
                           . 'aspect: 1.33, 25.000 fps',
                subtitles => []
            },
        },
        'first file appears to have been encoded correctly',
    );


# second job
( $job, $payload ) = $media->next_queue_job();
isa_ok( $job, 'IPC::DirQueue::Job' );
is_deeply(
        $payload,
        {
            details => {
                audio   => "1:stereo:English",
                crop    => '0/0/0/0',
                episode => '99',
                quality => '35',
                season  => '7',
                series  => 'Star Trek - Deep Space Nine',
                title   => 'Extras - Section 31 Hidden File 8',
            },
            input   => {
                config     => $config_file,
                image      => $input_image,
                media_conf => "$cwd/t/conf/trash.conf",
                title      => '14',
            },
            medium  => 'DVD',
            name    => 'Star Trek - Deep Space Nine - 7x99 - '
                     . 'Extras - Section 31 Hidden File 8',
            type    => 'TV',
        },
        'second job payload matches',
    );

$media->encode_media( $payload );
$job->finish();
$target_file = 'xt/tv/Star Trek - Deep Space Nine/Season 7/'
                . '99 - Extras - Section 31 Hidden File 8.m4v';
ok( -f $target_file, 'file installed' );

$handler          = $media->get_empty_handler( undef, 'VideoFile' );
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
                        channels => '2.0 ch',
                        code     => 'eng',
                        format   => 'aac',
                        language => 'English',
                        track    => '1',
                    },
                ],
                crop      => '0/2/8/10',
                duration  => '00:02:24',
                size      => '720x576, pixel aspect: 16/15, display '
                           . 'aspect: 1.33, 25.000 fps',
                subtitles => []
            },
        },
        'second file appears to have been encoded correctly',
    );


# last job
( $job, $payload ) = $media->next_queue_job();
isa_ok( $job, 'IPC::DirQueue::Job' );
is_deeply(
        $payload,
        {
            details => {
                audio     => [
                    "1:stereo:English",
                    "2:stereo:German",
                ],
                chapters  => '4-5',
                crop      => '0/0/0/0',
                episode   => '25',
                markers   => 1,
                maxHeight => '240',
                maxWidth  => '320',
                quality   => '50',
                season    => '7',
                series    => 'Star Trek - Deep Space Nine',
                title     => 'What You Leave Behind',
            },
            input   => {
                config     => $config_file,
                image      => $input_image,
                media_conf => "$cwd/t/conf/trash.conf",
                title      => '18',
            },
            medium  => 'DVD',
            name    => 'Star Trek - Deep Space Nine - 7x25 - '
                     . 'What You Leave Behind',
            type    => 'TV',
        },
        'third job payload matches',
    );

$media->encode_media( $payload );
$job->finish();
$target_file = 'xt/tv/Star Trek - Deep Space Nine/Season 7/'
                . '25 - What You Leave Behind.m4v';
ok( -f $target_file, 'file installed' );

ok( $media->queue_count() == 0, 'queue is empty again' );

# check that the output file has smaller dimensions, as specified in 
# the media.conf within the dvd image, rather than the global settings
$handler          = $media->get_empty_handler( undef, 'VideoFile' );
$handbrake_output = $handler->scan_input( 0, $target_file );
%titles           = $handler->analyse_input( $handbrake_output );
is_deeply(
        \%titles,
        {
            handbrake_version => "0.9.8",
            input_type        => "mov",
            1                 => {
                audio         => [
                    {
                        channels => '2.0 ch',
                        code     => 'eng',
                        format   => 'aac',
                        language => 'English',
                        track    => '1',
                    },
                    {
                        channels => '2.0 ch',
                        code     => 'deu',
                        format   => 'aac',
                        language => 'Deutsch',
                        track    => '2',
                    },
                ],
                chapter_count => 2,
                crop          => '0/0/0/0',
                duration      => '00:10:13',
                size          => '304x240, pixel aspect: 20/19, '
                           . 'display aspect: 1.33, 25.000 fps',
                
                # not a subtitle -- this is the chapters file
                subtitles     => [
                    {
                        code     => 'und',
                        language => 'Unknown',
                        track    => 1,
                        type     => 'Text',
                    },
                ],
            },
        },
        'third file appears to have been encoded correctly',
    );
