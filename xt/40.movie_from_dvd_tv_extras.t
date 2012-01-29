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


plan tests => 24;

# ensure a clean directory structure
my $result = system 'rm -rf xt/encode xt/movies xt/tv xt/queue xt/trash';
die "'rm -rf xt/encode xt/movies xt/tv xt/queue xt/trash': $!"
    if $result >> 8;


my $media = Media->new( 't/conf/movie_extras_as_tv.conf' );

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
                audio     => [
                    "1:stereo:English",
                    "2:stereo:Director, Cast and Crew Commentary",
                ],
                company   => "Eon Productions",
                chapters  => '8-9',
                crop      => '0/0/6/10',
                director  => [
                    'Terence Young'
                ],
                feature   => '1',
                genre     => [
                    'Action',
                    'Adventure',
                    'Thriller'
                ],
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
                media_conf => "$cwd/t/conf/movie_extras_as_tv.conf",
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
my $target_file = 'xt/movies/All/Dr. No - PG (1962).m4v';
ok( -f $target_file, 'file installed' );
ok( readlink( 'xt/movies/Year/1962/Dr. No - PG (1962).m4v' ) 
    eq '../../All/Dr. No - PG (1962).m4v',
        'Year 1962 symlink' );

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
                crop      => '0/0/0/0',
                duration  => '00:04:39',
                size      => '288x240, pixel aspect: 352/243, display '
                           . 'aspect: 1.74, 24.988 fps',
                subtitles => []
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
            title         => 'Dr. No',
            year          => '1962',
        },
        "first file's metadata is correct"
    );


# second job
( $job, $payload ) = $media->next_queue_job();
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
                crop      => '0/0/34/34',
                director  => [
                    'Terence Young'
                ],
                extra     => 'Trailer 1',
                genre     => [
                    'Action',
                    'Adventure',
                    'Thriller'
                ],
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
                media_conf => "$cwd/t/conf/movie_extras_as_tv.conf",
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
$target_file = 'xt/tv/DVD Extras/Dr. No - PG (1962)/Trailer 1.m4v';
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
                size      => '272x240, pixel aspect: 163/153, display '
                           . 'aspect: 1.21, 25.000 fps',
                subtitles => []
            },
        },
        'second file appears to have been encoded correctly',
    );

%metadata = $handler->extract_metadata( $target_file );
is_deeply(
        \%metadata,
        {
            artwork_count => 1,
            genre         => 'Documentary',
            kind          => 'TV Show',
            series        => 'DVD Extras - Dr. No - PG (1962)',
            title         => 'Trailer 1',
        },
        "second file's metadata is correct"
    );


# last job
( $job, $payload ) = $media->next_queue_job();
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
                crop      => '8/4/0/2',
                director  => [
                    'Terence Young'
                ],
                extra     => 'Trailer 2',
                genre     => [
                    'Action',
                    'Adventure',
                    'Thriller'
                ],
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
                media_conf => "$cwd/t/conf/movie_extras_as_tv.conf",
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
$target_file = 'xt/tv/DVD Extras/Dr. No - PG (1962)/Trailer 2.m4v';
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
                crop      => '0/0/0/0',
                duration  => '00:03:08',
                size      => '304x240, pixel aspect: 2872/2679, '
                           . 'display aspect: 1.36, 25.000 fps',
                subtitles => [],
            },
        },
        'third file appears to have been encoded correctly',
    );

%metadata = $handler->extract_metadata( $target_file );
is_deeply(
        \%metadata,
        {
            artwork_count => 1,
            genre         => 'Documentary',
            kind          => 'TV Show',
            series        => 'DVD Extras - Dr. No - PG (1962)',
            title         => 'Trailer 2',
        },
        "third file's metadata is correct"
    );


