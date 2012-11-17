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

plan tests => 20;

# ensure a clean directory structure
my $result = system 'rm -rf xt/encode xt/movies xt/queue xt/trash';
die "'rm -rf xt/encode xt/movies xt/queue xt/trash': $!"
    if $result >> 8;


my $media       = Media->new( 't/conf/trash.conf' );
my $source      = 'xt/source/flibble';
my $config_file = "$source/media.conf";
mkpath $source;
copy( $input_file, $source )
    or die;

my $handler = $media->get_empty_handler( undef, 'VideoFile' );
$handler->create_config_file( $source );

# update config file means queue should occur
my $barbarella_conf < io 'xt/conf/barbarella.conf';
$barbarella_conf > io $config_file;
my $created_config < io $config_file;
is( $barbarella_conf, $created_config, 'config updated properly' );

$media->queue_media( $source );
ok( $media->queue_count() == 1, 'queue created' );

# infinite wait without the queue job
die unless $media->queue_count() == 1;

my $matrix_conf < io 'xt/conf/matrix_priority.conf';
$matrix_conf > io $config_file;
$created_config < io $config_file;
is( $matrix_conf, $created_config, 'config updated properly' );

$media->queue_media( $source );
ok( $media->queue_count() == 2, 'queue updated' );

my( $job, $payload ) = $media->next_queue_job();
my $id               = $job->{'jobid'};
my $priority         = substr( $id, 0, 2 ),
isa_ok( $job, 'IPC::DirQueue::Job' );
is( $priority, 10, 'priority is correct' );
is_deeply(
        $payload,
        {
            details => {
                actor    => [
                    'Keanu Reeves',
                    'Laurence Fishburne',
                    'Carrie-Anne Moss',
                    'Hugo Weaving',
                    'Gloria Foster',
                    'Joe Pantoliano',
                    'Marcus Chong',
                    'Julian Arahanga',
                    'Matt Doran',
                    'Belinda McClory',
                ],
                audio    => '1:stereo:English',
                company  => 'Warner Bros. Pictures',
                director => [
                    'Andy Wachowski',
                    'Lana Wachowski',
                ],
                feature  => '1',
                genre    => [
                    'Action',
                    'Adventure',
                    'Sci-Fi',
                ],
                plot     => "Thomas A. Anderson is a man living two lives. By day he is an average computer programmer and by night a hacker known as Neo. Neo has always questioned his reality, but the truth is far beyond his imagination. Neo finds himself targeted by the police when he is contacted by Morpheus, a legendary computer hacker branded a terrorist by the government. Morpheus awakens Neo to the real world, a ravaged wasteland where most of humanity have been captured by a race of machines that live off of the humans' body heat and electrochemical energy and who imprison their minds within an artificial reality known as the Matrix. As a rebel against the machines, Neo must return to the Matrix and confront the agents: super-powerful computer programs devoted to snuffing out Neo and the entire human rebellion.",
                rating   => '15',
                title    => 'The Matrix',
                writer   => [
                    'Andy Wachowski',
                    'Lana Wachowski',
                ],
                year     => '1999',
            },
            input   => {
                media_conf => "$cwd/t/conf/trash.conf",
                config     => "$source/media.conf",
                file       => "$source/ac3.vob",
                poster     => 'http://bumph.cackhanded.net/poster.png',
                title      => '1',
            },
            medium  => 'VideoFile',
            name    => 'The Matrix - 15 (1999)',
            type    => 'Movie',
        }
    );

is( $media->encode_media( $payload ), 1, 'successful encode' );
$job->finish();

my $target_file = 'xt/movies/All/The Matrix - 15 (1999)/'
                . 'The Matrix - 15 (1999).m4v';
ok( -f $target_file, 'file installed' );
exit unless -f $target_file;

ok( ! -d 'xt/encode/The Matrix - 15 (1999)',
    'encoder clears up after itself' );
ok( -f 'xt/trash/ac3.vob',
    'encoder trashes source files' );
ok( -f 'xt/trash/flibble-media.conf',
    'encoder trashes media.conf, but keeps the dirname as a hint' );
ok( ! -d $source, 
    'encoder clears up source directories' );

$handler = $media->get_empty_handler( 'Movie', 'VideoFile' );
my %metadata = $handler->extract_metadata( $target_file );
is_deeply(
        \%metadata,
        {
            artist        => "Andy Wachowski",
            artwork_count => '1',
            description   => "Thomas A. Anderson is a man living two lives. By day he is an average computer programmer and by night a hacker known as Neo. Neo has always questioned his reality, but the truth is far beyond his imagination. Neo finds himself targeted by the police when he is contacted by Morpheus, a legendary computer hacker branded a terrorist by the government. Morpheus awakens Neo to the real world, a ravaged wasteland where most of humanity have been captured by a race of machines that live off of the humans' body heat and electrochemical energy and who imprison their minds within an artificial reality known as the Matrix. As a rebel against the machines, Neo must return to the Matrix and confront the agents: super-powerful computer programs devoted to snuffing out Neo and the entire human rebellion.",
            genre         => 'Action',
            kind          => 'Movie',
            rating        => '15',
            summary       => "Thomas A. Anderson is a man living two lives. By day he is an average computer programmer and by night a hacker known as Neo. Neo has always questioned his reality, but the truth is far beyond his imagination. Neo finds himself targeted by the police w \342\200\246",
            title         => 'The Matrix',
            year          => '1999',
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
        'movie appears to have been encoded correctly',
    );


( $job, $payload ) = $media->next_queue_job();
$id                = $job->{'jobid'};
$priority          = substr( $id, 0, 2 ),
isa_ok( $job, 'IPC::DirQueue::Job' );
is( $priority, 50, 'priority is correct' );
is_deeply(
        $payload,
        {
            details => {
                actor    => [
                    "Jane Fonda",
                    "John Phillip Law",
                    "Anita Pallenberg",
                    "Milo O'Shea",
                    "Marcel Marceau",
                    "Claude Dauphin",
                    "V\351ronique Vendell",
                    "Giancarlo Cobelli",
                    "Serge Marquand",
                    "Nino Musco",
                ],
                audio    => '1:stereo:English',
                company  => "Dino de Laurentiis Cinematografica",
                director => [
                    "Roger Vadim",
                ],
                feature  => '1',
                genre    => [
                    "Action",
                    "Adventure",
                    "Comedy",
                    "Fantasy",
                    "Sci-Fi",
                ],
                plot     => "After an in-flight anti-gravity striptease (masked by the film's opening titles), Barbarella, a 41st century astronaut, lands on the planet Lythion and sets out to find the evil Durand Durand in the city of Sogo, where a new sin is invented every hour. There, she encounters such objects as the Exessive Machine, a genuine sex organ on which an accomplished artist of the keyboard, in this case, Durand Durand himself, can drive a victim to death by pleasure, a lesbian queen who, in her dream chamber, can make her fantasies take form, and a group of ladies smoking a giant hookah which, via a poor victim struggling in its glass globe, dispenses Essance of Man. You can't help but be impressed by the special effects crew and the various ways that were found to tear off what few clothes our heroine seemed to possess. Based on the popular French comic strip.",
                rating   => '15',
                title    => 'Barbarella',
                writer   => [
                    "Jean-Claude Forest",
                    "Claude Brul\351",
                ],
                year     => '1968',
            },
            input   => {
                media_conf => "$cwd/t/conf/trash.conf",
                config     => "$source/media.conf",
                file       => "$source/ac3.vob",
                poster     => 'http://bumph.cackhanded.net/poster.png',
                title      => '1',
            },
            medium  => 'VideoFile',
            name    => 'Barbarella - 15 (1968)',
            type    => 'Movie',
        }
    );

is( $media->encode_media( $payload ), undef, 'file has disappeared' );
$job->finish();
