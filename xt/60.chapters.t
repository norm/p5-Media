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

my $default_config < io 'xt/conf/dr_no.conf';
my $created_config < io $config_file;
is( $default_config, $created_config, 'config created properly' );

# second attempt files because the config hasn't been edited
$media->queue_media( $input_image );
ok( $media->queue_count() == 0, 'queue is still empty' );
my $anewhope_conf < io 'xt/conf/dr_no.chapters.conf';
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
                actor     => [
                  'Sean Connery',
                  'Ursula Andress',
                  'Joseph Wiseman',
                  'Jack Lord',
                  'Bernard Lee',
                  'Anthony Dawson',
                  'Zena Marshall',
                  'John Kitzmiller',
                  'Eunice Gayson',
                  'Lois Maxwell',
                ],
                audio     => "1:stereo:English",
                company   => "Eon Productions",
                crop      => '0/0/6/4',
                director  => [
                    'Terence Young'
                ],
                extra     => 'Terence Young - Bond Vivant',
                genre     => [
                    'Action',
                    'Adventure',
                    'Thriller'
                ],
                markers   => 'chapters.csv',
                maxWidth  => '320',
                maxHeight => '240',
                plot      => "James Bond (007) is Britain's top agent and is on an exciting mission, to solve the mysterious murder of a fellow agent. The task sends him to Jamacia, where he joins forces with Quarrel and a loyal CIA agent, Felix Leiter. While dodging tarantulas, \"fire breathing dragons\" and a trio of assassins, known as the three blind mice. Bond meets up with the beautiful Honey Ryder and goes face to face with the evil Dr. No.",
                quality   => '50',
                rating    => 'PG',
                title     => 'Dr. No',
                writer    => [
                    'Richard Maibaum',
                    'Johanna Harwood',
                ],
                year      => '1962',
            },
            input   => {
                config     => $config_file,
                image      => $input_image,
                media_conf => "$cwd/t/conf/trash.conf",
                poster     => 'http://2.bp.blogspot.com/_VXNWSr1UpT4/'
                            . 'TEnXYI6S_CI/AAAAAAAAEQE/IYG3MS0DZX8/s1600/'
                            . 'Dr+No+poster.jpg',
                title      => '10',
            },
            medium  => 'DVD',
            name    => 'Dr. No - PG (1962) - Terence Young - Bond Vivant',
            type    => 'Movie',
        },
        'first job payload matches',
    );

$media->encode_media( $payload );

my $target_file = 'xt/movies/All/Dr. No - PG (1962)/'
                . 'Terence Young - Bond Vivant.m4v';
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
                audio         => [
                    {
                        channels => '2.0 ch',
                        code     => 'eng',
                        format   => 'AAC',
                        language => 'English',
                        track    => '1',
                    },
                ],
                chapter_count => '2',
                crop          => '0/0/0/0',
                duration      => '00:17:55',
                size          => '288x240, pixel aspect: 355/324, display '
                               . 'aspect: 1.31, 24.999 fps',
                # actually the chapters file
                subtitles     => [
                    {
                        code     => 'und',
                        language => 'Unknown',
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
            artist        => 'Terence Young',
            artwork_count => 1,
            description   => "James Bond (007) is Britain's top agent and is on an exciting mission, to solve the mysterious murder of a fellow agent. The task sends him to Jamacia, where he joins forces with Quarrel and a loyal CIA agent, Felix Leiter. While dodging tarantulas, \"fire breathing dragons\" and a trio of assassins, known as the three blind mice. Bond meets up with the beautiful Honey Ryder and goes face to face with the evil Dr. No.",
            genre         => 'Action',
            kind          => 'Movie',
            rating        => 'PG',
            summary       => "James Bond (007) is Britain's top agent and is on an exciting mission, to solve the mysterious murder of a fellow agent. The task sends him to Jamacia, where he joins forces with Quarrel and a loyal CIA agent, Felix Leiter. While dodging tarantulas, \"f …",
            title         => 'Terence Young - Bond Vivant',
            year          => '1962',
        },
        'metadata'
    );
