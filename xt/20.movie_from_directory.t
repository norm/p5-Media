#!/usr/bin/env perl

use Modern::Perl;
use Capture::Tiny   qw( capture );
use Cwd;
use File::Copy;
use File::Path;
use IO::All;
use Media;
use Test::More;


my $input_file = "$ENV{'MEDIA_TESTING'}/dts.mkv";
my $cwd        = getcwd();

if ( !-f $input_file ) {
    plan skip_all => "${input_file} file is missing";
    exit;
}

plan tests => 22;

# ensure a clean directory structure
my $result = system 'rm -rf xt/encode xt/movies xt/queue xt/trash';
die "'rm -rf xt/encode xt/movies xt/queue xt/trash': $!"
    if $result >> 8;


my $media  = Media->new( 't/conf/trash.conf' );
my $source = 'xt/source/Serenity - 15 (2005)';
mkpath $source;
copy( $input_file, $source )
    or die;
copy( 'xt/poster.png', $source )
    or die;

# create some files that should be deleted when the directory is queued
'' > io "$source/file.nfo";
'' > io "$source/file.srr";
'' > io "$source/serenity-sample.m4v";
ok( -f "$source/file.nfo", 'nfo exists' );
ok( -f "$source/file.srr", 'srr exists' );
ok( -f "$source/serenity-sample.m4v", 'sample exists' );
ok( -f "$source/poster.png", 'poster exists' );

$media->queue_media( $source );

ok( !-f "$source/file.nfo", 'nfo removed' );
ok( !-f "$source/file.srr", 'srr removed' );
ok( !-f "$source/serenity-sample.m4v", 'sample removed' );
ok(  -f "$source/poster.png", 'poster still exists' );


# check the queue job
my( $job, $payload ) = $media->next_queue_job();
isa_ok( $job, 'IPC::DirQueue::Job' );
is_deeply(
        $payload,
        {
            details => {
                # taken from source file
                audio => [
                    '1:ac3:English 5.1 ch AC3',
                    '1:dpl2:English 5.1 ch',
                ],
                
                # taken from filename, should remain static
                title   => 'Serenity',
                year    => '2005',
                rating  => '15',
                feature => 1,
                
                # from IMDB, may change
                actor        => [
                    'Nathan Fillion',
                    'Gina Torres',
                    'Alan Tudyk',
                    'Morena Baccarin',
                    'Adam Baldwin',
                    'Jewel Staite',
                    'Sean Maher',
                    'Summer Glau',
                    'Ron Glass',
                    'Chiwetel Ejiofor',
                ],
                company      => 'Universal Pictures',
                director     => [
                    'Joss Whedon',
                ],
                genre        => [
                    'Action',
                    'Adventure',
                    'Sci-Fi',
                    'Thriller',
                ],
                plot         => 'In the future, a spaceship called Serenity is harboring a passenger with a deadly secret. Six rebels on the run. An assassin in pursuit. When the renegade crew of Serenity agrees to hide a fugitive on their ship, they find themselves in an awesome action-packed battle between the relentless military might of a totalitarian regime who will destroy anything - or anyone - to get the girl back and the bloodthirsty creatures who roam the uncharted areas of space. But, the greatest danger of all may be on their ship.',
                writer       => [
                  "Joss Whedon"
                ],
            },
            input   => {
                media_conf => "$cwd/t/conf/trash.conf",
                file       => "$source/dts.mkv",
                poster     => "$source/poster.png",
                title      => '1',
            },
            medium  => 'VideoFile',
            name    => 'Serenity - 15 (2005)',
            type    => 'Movie',
        },
        'payload is correct'
    );


$media->encode_media( $payload );


# check the output
my $target_file = 'xt/movies/All/Serenity - 15 (2005)/'
                . 'Serenity - 15 (2005).m4v';
ok( -f $target_file, 'file installed' );
exit unless -f $target_file;

ok( ! -d 'xt/encode/Serenity - 15 (2005)',
    'encoder clears up after itself' );
ok( -f 'xt/trash/dts.mkv',
    'encoder trashes source files' );
ok( ! -d $source, 
    'encoder clears up source directories' );

my $handler  = $media->get_empty_handler( 'Movie', 'VideoFile' );
my %metadata = $handler->extract_metadata( $target_file );
is_deeply(
        \%metadata,
        {
            artwork_count => 1,
            artist        => 'Joss Whedon',
            description   => 'In the future, a spaceship called Serenity is harboring a passenger with a deadly secret. Six rebels on the run. An assassin in pursuit. When the renegade crew of Serenity agrees to hide a fugitive on their ship, they find themselves in an awesome action-packed battle between the relentless military might of a totalitarian regime who will destroy anything - or anyone - to get the girl back and the bloodthirsty creatures who roam the uncharted areas of space. But, the greatest danger of all may be on their ship.',
            genre         => 'Action',
            kind          => 'Movie',
            rating        => '15',
            summary       => 'In the future, a spaceship called Serenity is harboring a passenger with a deadly secret. Six rebels on the run. An assassin in pursuit. When the renegade crew of Serenity agrees to hide a fugitive on their ship, they find themselves in an awesome acti …',
            title         => 'Serenity',
            year          => '2005',
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

my $link_target = '../../All/Serenity - 15 (2005)/Serenity - 15 (2005).m4v';
ok( readlink( 'xt/movies/Year/2005/Serenity - 15 (2005).m4v' ) 
    eq $link_target, 
        'Year 2005 link' );
ok( readlink( 'xt/movies/Actor/Nathan Fillion/Serenity - 15 (2005).m4v' ) 
    eq $link_target, 
        'Nathan Fillion link' );
ok( readlink( 'xt/movies/Genre/Sci-Fi/Serenity - 15 (2005).m4v' ) 
    eq $link_target, 
        'Sci-Fi link' );
ok( readlink( 'xt/movies/Writer/Joss Whedon/Serenity - 15 (2005).m4v' ) 
    eq $link_target, 
        'Joss Whedon as writer link' );
ok( readlink( 'xt/movies/Director/Joss Whedon/Serenity - 15 (2005).m4v' ) 
    eq $link_target, 
        'Joss Whedon as director link' );

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
                        code     => 'eng',
                        format   => 'AC3',
                        language => 'English',
                        track    => '1',
                    },
                    {
                        channels => '2.0 ch',
                        code     => 'eng',
                        format   => 'aac',
                        language => 'English',
                        track    => '2',
                    },
                ],
                crop      => '0/0/0/0',
                duration  => '00:00:43',
                size      => '1280x528, pixel aspect: 99/100, display '
                           . 'aspect: 2.40, 24.004 fps',
                subtitles => []
            },
        },
        'movie appears to have been encoded correctly',
    );
