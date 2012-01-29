#!/usr/bin/env perl

use Modern::Perl;
use Capture::Tiny   qw( capture );
use Cwd;
use File::Copy;
use File::Path;
use IO::All;
use Media;
use Test::More;


my $input_image = "$ENV{'MEDIA_TESTING'}/SW4_ANH";
my $config_file = "$input_image/media.conf";
my $cwd         = getcwd();

if ( !-d $input_image ) {
    plan skip_all => "${input_image} DVD rip is missing";
    exit;
}

plan tests => 12;

# ensure a clean directory structure
my $result = system 'rm -rf xt/encode xt/movies xt/queue xt/trash';
die "'rm -rf xt/encode xt/movies xt/queue xt/trash': $!"
    if $result >> 8;


my $media = Media->new( 't/conf/trash.conf' );

unlink $config_file;
ok( ! -f $config_file, 'config does not exist' );
ok( $media->queue_count() == 0, 'queue is empty' );

# first attempt adds a config file if there isn't one
$media->queue_media( $input_image );
ok( -f $config_file, 'config has been created' );
ok( $media->queue_count() == 0, 'queue is still empty' );

my $default_config < io 'xt/conf/anewhope.conf';
my $created_config < io $config_file;
is( $default_config, $created_config, 'config created properly' );

# second attempt files because the config hasn't been edited
$media->queue_media( $input_image );
ok( $media->queue_count() == 0, 'queue is still empty' );
my $anewhope_conf < io 'xt/conf/anewhope.edited.conf';
$anewhope_conf > io $config_file;

# third attempt adds every non-ignored item in the DVD to the queue
$media->queue_media( $input_image );
is( 1, $media->queue_count(), 'queue now has 1 item' );

# infinite wait without the queue job
die unless $media->queue_count() >= 1;

my( $job, $payload ) = $media->next_queue_job();
isa_ok( $job, 'IPC::DirQueue::Job' );
is_deeply(
        $payload,
        {
            details => {
                actor    => [
                    'Mark Hamill',
                    'Harrison Ford',
                    'Carrie Fisher',
                    'Peter Cushing',
                    'Alec Guinness',
                    'Anthony Daniels',
                    'Kenny Baker',
                    'Peter Mayhew',
                    'David Prowse',
                    'James Earl Jones',
                ],
                audio    => [
                    "1:ac3pass:English",
                    "1:dpl2:English",
                    "2:ac3pass:English",
                    "2:dpl2:English",
                    "3:ac3pass:English",
                    "3:dpl2:English"
                ],
                chapters => '22-22',
                company  => 'Lucasfilm',
                crop     => '72/72/0/0',
                director => [
                    'George Lucas',
                ],
                feature  => '1',
                genre => [
                    'Action',
                    'Adventure',
                    'Fantasy',
                    'Sci-Fi',
                ],
                plot     => "Part IV in George Lucas' epic, Star Wars: A New Hope opens with a Rebel ship being boarded by the tyrannical Darth Vader. The plot then follows the life of a simple farm boy, Luke Skywalker, as he and his newly met allies (Han Solo, Chewbacca, Obi-Wan Kenobi, C-3PO, R2-D2) attempt to rescue a Rebel leader, Princess Leia, from the clutches of the Empire. The conclusion is culminated as the Rebels, including Skywalker and flying ace Wedge Antilles make an attack on the Empire's most powerful and ominous weapon, the Death Star.",
                rating   => 'U',
                subtitle => [
                    'burn:8',
                    'eng:english.srt',
                ],
                title    => "Star Wars - Episode IV - A New Hope",
                writer   => [
                    'George Lucas',
                ],
                year     => '1977',
            },
            input   => {
                config     => $config_file,
                image      => $input_image,
                media_conf => "$cwd/t/conf/trash.conf",
                poster     => 'http://getvideoartwork.com/gallery/main.php?'
                            . 'g2_view=core.DownloadItem&g2_itemId=6887&'
                            . 'g2_serialNumber=1',
                title      => 1
            },
            medium  => 'DVD',
            name    => 'Star Wars - Episode IV - A New Hope - U (1977)',
            type    => 'Movie',
        },
        'first job payload matches',
    );

$media->encode_media( $payload );

my $title       = 'Star Wars - Episode IV - A New Hope - U (1977)';
my $target_file = sprintf 'xt/movies/All/%s/%s.m4v', $title, $title;
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
                        channels => '5.1 ch',
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
                    {
                        channels => 'Dolby Surround',
                        code     => 'eng',
                        format   => 'AC3',
                        language => 'English',
                        track    => '3',
                    },
                    {
                        channels => '2.0 ch',
                        code     => 'eng',
                        format   => 'AAC',
                        language => 'English',
                        track    => '4',
                    },
                    {
                        channels => 'Dolby Surround',
                        code     => 'eng',
                        format   => 'AC3',
                        language => 'English',
                        track    => '5',
                    },
                    {
                        channels => '2.0 ch',
                        code     => 'eng',
                        format   => 'AAC',
                        language => 'English',
                        track    => '6',
                    },
                ],
                crop      => '0/0/18/0',
                duration  => '00:01:13',
                size      => '720x432, pixel aspect: 64/45, display '
                           . 'aspect: 2.37, 24.973 fps',
                subtitles => [
                    {
                        code     => 'eng',
                        language => 'English',
                        track    => '1',
                        type     => 'Text',
                    },
                ]
            },
        },
        'first file appears to have been encoded correctly',
    );

my %metadata = $handler->extract_metadata( $target_file );
is_deeply(
        \%metadata,
        {
            artist        => "George Lucas",
            artwork_count => 1,
            description   => "Part IV in George Lucas' epic, Star Wars: A New Hope opens with a Rebel ship being boarded by the tyrannical Darth Vader. The plot then follows the life of a simple farm boy, Luke Skywalker, as he and his newly met allies (Han Solo, Chewbacca, Obi-Wan Kenobi, C-3PO, R2-D2) attempt to rescue a Rebel leader, Princess Leia, from the clutches of the Empire. The conclusion is culminated as the Rebels, including Skywalker and flying ace Wedge Antilles make an attack on the Empire's most powerful and ominous weapon, the Death Star.",
            genre         => 'Action',
            kind          => 'Movie',
            rating        => 'U',
            summary       => "Part IV in George Lucas' epic, Star Wars: A New Hope opens with a Rebel ship being boarded by the tyrannical Darth Vader. The plot then follows the life of a simple farm boy, Luke Skywalker, as he and his newly met allies (Han Solo, Chewbacca, Obi-Wan  \342\200\246",
            title         => 'Star Wars - Episode IV - A New Hope',
            year          => '1977',
        },
        'metadata'
    );
