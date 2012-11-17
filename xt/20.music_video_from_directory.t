#!/usr/bin/env perl

use Modern::Perl;
use Capture::Tiny   qw( capture );
use Cwd;
use File::Copy;
use File::Path;
use IO::All;
use Media;
use Test::More;


my $input_file = "$ENV{'MEDIA_TESTING'}/mp3.avi";
my $cwd        = getcwd();

if ( !-f $input_file ) {
    plan skip_all => "${input_file} file is missing";
    exit;
}

plan tests => 9;

# ensure a clean directory structure
my $result = system 'rm -rf xt/encode xt/music xt/queue xt/trash';
die "'rm -rf xt/encode xt/music xt/queue xt/trash': $!"
    if $result >> 8;


my $media  = Media->new( 't/conf/trash.conf' );
my $source = 'xt/source/(Waiting for) The Ghost Train [Madness] Utter Madness';
mkpath $source;
copy( $input_file, $source )
    or die;

$media->queue_media( $source );

my( $job, $payload ) = $media->next_queue_job();
isa_ok( $job, 'IPC::DirQueue::Job' );
is_deeply(
        $payload,
        {
            details => {
                album  => 'Utter Madness',
                artist => 'Madness',
                audio  => [
                    '1:stereo:Unknown Stereo',
                ],
                title  => '(Waiting for) The Ghost Train',
            },
            input   => {
                media_conf => "$cwd/t/conf/trash.conf",
                file       => "$source/mp3.avi",
                title      => 1,
            },
            medium  => 'VideoFile',
            name    => '(Waiting for) The Ghost Train '
                     . '[Madness] Utter Madness',
            type    => 'MusicVideo',
        },
        'payload is correct'
    );


$media->encode_media( $payload );


# check the output
my $target_file = 'xt/music/Madness/Utter Madness/'
                . '(Waiting for) The Ghost Train.m4v';
ok( -f $target_file, 'file installed' );
exit unless -f $target_file;

ok( ! -d 'xt/encode/(Waiting for) The Ghost Train [Madness] Utter Madness',
    'encoder clears up after itself' );
ok( -f 'xt/trash/mp3.avi',
    'encoder trashes source files' );
ok( ! -d $source, 
    'encoder clears up source directories' );

my $handler  = $media->get_empty_handler( 'MusicVideo', 'VideoFile' );
my %metadata = $handler->extract_metadata( $target_file );
is_deeply(
        \%metadata,
        {
            kind   => 'Music Video',
            artist => 'Madness',
            album  => 'Utter Madness',
            title  => '(Waiting for) The Ghost Train',
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
                duration  => '00:03:01',
                size      => '688x384, pixel aspect: 1/1, display '
                           . 'aspect: 1.79, 25.000 fps',
                subtitles => []
            },
        },
        'music video appears to have been encoded correctly',
    );

