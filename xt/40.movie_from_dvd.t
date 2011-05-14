#!/usr/bin/env perl

use Modern::Perl;
use Capture::Tiny   qw( capture );
use Cwd;
use File::Copy;
use File::Path;
use IO::All;
use Media;
use Test::More;


my $input_image = "$ENV{'MEDIA_TESTING'}/JB1_DRNO";
my $config_file = "$input_image/media.conf";
my $cwd         = getcwd();

if ( !-d $input_image ) {
    plan skip_all => "${input_image} DVD rip is missing";
    exit;
}


plan tests => 20;

# ensure a clean directory structure
my $result = system 'rm -rf xt/encode xt/movies xt/queue xt/trash';
die "'rm -rf xt/encode xt/movies xt/queue xt/trash': $!"
    if $result >> 8;


my $media  = Media->new( 't/conf/trash.conf' );

unlink $config_file;
ok( ! -f $config_file, 'config does not exist' );
ok( $media->queue_count() == 0, 'queue is empty' );

# first attempt adds a config file if there isn't one
$media->queue_media( $input_image );
ok( -f $config_file, 'config has been created' );
ok( $media->queue_count() == 0, 'queue is still empty' );

my $default_config < io 'xt/conf/dr_no.conf';
my $created_config < io $config_file;
is( $default_config, $created_config, 'config created properly' );

# second attempt fails because the config hasn't been edited
$media->queue_media( $input_image );
ok( $media->queue_count() == 0, 'queue is still empty' );
my $drno_conf < io 'xt/conf/dr_no.edited.conf';
$drno_conf > io $config_file;

# third attempt adds every non-ignored item in the DVD to the queue
$media->queue_media( $input_image );
ok( $media->queue_count() == 3, 'queue now has 3 items' );

my( $job, $payload ) = $media->next_queue_job();
isa_ok( $job, 'IPC::DirQueue::Job' );
is_deeply(
        $payload,
        {
            details => {
                audio    => [
                    "1:stereo:English",
                    "2:stereo:Director, Cast and Crew Commentary",
                ],
                chapters => '8-9',
                crop     => '0/0/6/10',
                feature  => '1',
                quality  => '50',
                rating   => 'PG',
                title    => 'Dr. No',
                year     => '1962',
            },
            input   => {
                media_conf => "$cwd/t/conf/trash.conf",
                config     => $config_file,
                image      => $input_image,
                poster     => 'http://2.bp.blogspot.com/_VXNWSr1UpT4/'
                            . 'TEnXYI6S_CI/AAAAAAAAEQE/IYG3MS0DZX8/'
                            . 's1600/Dr+No+poster.jpg',
                title      => '2',
            },
            medium  => 'DVD',
            name    => 'Dr. No - PG (1962)',
            type    => 'Movie',
        },
        'first job payload matches',
    );

$media->encode_media( $payload );
$job->finish();
my $target_file = 'xt/movies/All/Dr. No - PG (1962)/Dr. No - PG (1962).m4v';
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
                        channels => '2.0 ch',
                        code     => 'eng',
                        format   => 'AAC',
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
                crop      => '0/0/0/2',
                duration  => '00:04:39',
                size      => '704x576, pixel aspect: 64/45, display '
                           . 'aspect: 1.74, 24.988 fps',
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
                crop    => '0/0/34/34',
                extra   => 'Trailer 1',
                quality => '50',
                rating   => 'PG',
                title    => 'Dr. No',
                year     => '1962',
            },
            input   => {
                media_conf => "$cwd/t/conf/trash.conf",
                config     => $config_file,
                image      => $input_image,
                poster     => 'http://2.bp.blogspot.com/_VXNWSr1UpT4/'
                            . 'TEnXYI6S_CI/AAAAAAAAEQE/IYG3MS0DZX8/'
                            . 's1600/Dr+No+poster.jpg',
                title      => '12',
            },
            medium  => 'DVD',
            name    => 'Dr. No - PG (1962) - Trailer 1',
            type    => 'Movie',
        },
        'second job payload matches',
    );

$media->encode_media( $payload );
$job->finish();
$target_file = 'xt/movies/All/Dr. No - PG (1962)/Trailer 1.m4v';
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
                crop      => '0/0/0/0',
                duration  => '00:03:12',
                size      => '656x576, pixel aspect: 652/615, display '
                           . 'aspect: 1.21, 25.000 fps',
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
                audio   => "1:stereo:English",
                crop    => '8/4/0/2',
                extra   => 'Trailer 2',
                quality => '50',
                rating   => 'PG',
                title    => 'Dr. No',
                year     => '1962',
            },
            input   => {
                media_conf => "$cwd/t/conf/trash.conf",
                config     => $config_file,
                image      => $input_image,
                poster     => 'http://2.bp.blogspot.com/_VXNWSr1UpT4/'
                            . 'TEnXYI6S_CI/AAAAAAAAEQE/IYG3MS0DZX8/'
                            . 's1600/Dr+No+poster.jpg',
                title      => '13',
            },
            medium  => 'DVD',
            name    => 'Dr. No - PG (1962) - Trailer 2',
            type    => 'Movie',
        },
        'third job payload matches',
    );

$media->encode_media( $payload );
$job->finish();
$target_file = 'xt/movies/All/Dr. No - PG (1962)/Trailer 2.m4v';
ok( -f $target_file, 'file installed' );

ok( $media->queue_count() == 0, 'queue is empty again' );

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
                ],
                crop      => '8/0/0/0',
                duration  => '00:03:08',
                size      => '720x560, pixel aspect: 20104/19035, '
                           . 'display aspect: 1.36, 25.000 fps',
                subtitles => [],
            },
        },
        'third file appears to have been encoded correctly',
    );
