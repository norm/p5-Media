#!/usr/bin/env perl

use Modern::Perl;
use Capture::Tiny   qw( capture );
use File::Copy;
use File::Path;
use IO::All;
use Media;
use Test::More;


my $input_image = "$ENV{'MEDIA_TESTING'}/ANEWHOPE";
my $config_file = "$input_image/media.conf";

if ( !-d $input_image ) {
    plan skip_all => "${input_image} DVD rip is missing";
    exit;
}

plan tests => 1;
ok( 1 == 1, 'tests yet to be written' );

__END__


plan tests => 18;

# ensure a clean directory structure
my $result = system 'rm -rf xt/encode xt/tv xt/queue xt/trash';
die "'rm -rf xt/encode xt/tv xt/queue xt/trash': $!"
    if $result >> 8;


my $media = Media->new( 't/conf/trash.conf' );

unlink $config_file;
ok( ! -f $config_file, 'config does not exist' );
ok( $media->queue_count() == 0, 'queue is empty' );

# first attempt adds a config file if there isn't one
$media->queue_media( $input_image );
ok( -f $config_file, 'config has been created' );
ok( $media->queue_count() == 0, 'queue is still empty' );

# second attempt files because the config hasn't been edited
$media->queue_media( $input_image );
ok( $media->queue_count() == 0, 'queue is still empty' );
my $ds9_conf < io 'xt/conf/ds9_s7d7.conf';
$ds9_conf > io $config_file;

# third attempt adds every non-ignored item in the DVD to the queue
$media->queue_media( $input_image );
ok( $media->queue_count() == 3, 'queue now has 3 items' );

my( $job, $payload ) = $media->next_queue_job();
isa_ok( $job, 'IPC::DirQueue::Job' );
is_deeply(
        $payload,
        {
            details => {
                audio   => [
                    "1:ac3pass:English",
                    "1:dpl2:English",
                ],
                crop    => '0/0/0/0',
                episode => '99',
                quality => '35',
                season  => '7',
                series  => 'Star Trek - Deep Space Nine',
                title   => 'Extras - Section 31 Hidden File 1',
                track   => '7',
            },
            input   => {
                config => $config_file,
                image  => $input_image,
            },
            medium  => 'DVD',
            type    => 'TV',
        },
        'first job payload matches',
    );

# $media->encode_media( $payload );
my $target_file = 'xt/tv/Star Trek - Deep Space Nine/Season 7/'
                . '99 - Extras - Section 31 Hidden File 1.m4v';
ok( -f $target_file, 'file installed' );

my $handler          = $media->get_empty_handler( undef, 'VideoFile' );
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
                        channels => 'Dolby Surround',
                        code     => 'eng',
                        format   => 'AC3',
                        language => 'English',
                        track    => '1',
                    },
                    {
                        channels => '2.0 ch',
                        code     => 'eng',
                        format   => 'AAC',
                        language => 'English',
                        track    => '2',
                    },
                ],
                crop      => '70/68/8/8',       # crazy numbers!
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
                track   => '14',
            },
            input   => {
                config => $config_file,
                image  => $input_image,
            },
            medium  => 'DVD',
            type    => 'TV',
        },
        'second job payload matches',
    );

# $media->encode_media( $payload );
$target_file = 'xt/tv/Star Trek - Deep Space Nine/Season 7/'
                . '99 - Extras - Section 31 Hidden File 8.m4v';
ok( -f $target_file, 'file installed' );

$handler          = $media->get_empty_handler( undef, 'VideoFile' );
$handbrake_output = $handler->scan_input( 0, $target_file );
%titles           = $handler->analyse_input( $handbrake_output );
is_deeply(
        \%titles,
        {
            handbrake_version => "0.9.5",
            input_type        => "mov",
            1                 => {
                audio     => [
                    {
                        channels => '2.0 ch',
                        code     => 'eng',
                        format   => 'AAC',
                        language => 'English',
                        track    => '1',
                    },
                ],
                crop      => '0/2/12/20',
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
                chapters  => '1-4',
                crop      => '0/0/0/0',
                episode   => '25',
                markers   => 1,
                maxHeight => '240',
                maxWidth  => '320',
                quality   => '50',
                season    => '7',
                series    => 'Star Trek - Deep Space Nine',
                title     => 'What You Leave Behind',
                track     => '18',
            },
            input   => {
                config => $config_file,
                image  => $input_image,
            },
            medium  => 'DVD',
            type    => 'TV',
        },
        'third job payload matches',
    );

$media->encode_media( $payload );
$target_file = 'xt/tv/Star Trek - Deep Space Nine/Season 7/'
                . '25 - What You Leave Behind.m4v';
ok( -f $target_file, 'file installed' );

# check that this output is smaller, as specified in
# the media.conf rather than the global settings
$handler          = $media->get_empty_handler( undef, 'VideoFile' );
$handbrake_output = $handler->scan_input( 0, $target_file );
%titles           = $handler->analyse_input( $handbrake_output );

is_deeply(
        \%titles,
        {
            handbrake_version => "0.9.5",
            input_type        => "mov",
            1                 => {
                audio     => [
                    {
                        channels => '2.0 ch',
                        code     => 'eng',
                        format   => 'AAC',
                        language => 'English',
                        track    => '1',
                    },
                    {
                        channels => '2.0 ch',
                        code     => 'deu',
                        format   => 'AAC',
                        language => 'Deutsch',
                        track    => '2',
                    },
                ],
                chapters  => 4,
                crop      => '0/0/0/0',
                duration  => '00:22:21',
                size      => '304x240, pixel aspect: 20/19, '
                           . 'display aspect: 1.33, 25.000 fps',
                subtitles => []
            },
        },
        'third file appears to have been encoded correctly',
    );
