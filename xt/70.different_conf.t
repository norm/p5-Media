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

plan tests => 9;

# ensure a clean directory structure
my $result  = system 'rm -rf xt/encode xt/add xt/queue xt/trash';
die "'rm -rf xt/encode xt/add xt/queue xt/trash': $!"
    if $result >> 8;


# two Media objects with different configurations
my $media   = Media->new( 't/conf/single_dir.conf' );
my $encoder = Media->new( 't/conf/media.conf' );
my $source  = 'xt/source/Battlestar Galactica (2003) - 1x03 - Bastille Day';
mkpath $source;
copy( $input_file, $source )
    or die;

# queue using the single_dir.conf Media
$media->queue_media( $source );
my( $job, $payload ) = $media->next_queue_job();
isa_ok( $job, 'IPC::DirQueue::Job' );
is_deeply(
        $payload,
        {
            details => {
                audio   => [
                    '1:dpl2:Unknown 5.1 ch',
                    '1:ac3pass:Unknown 5.1 ch AC3',
                ],
                episode => '03',
                season  => '1',
                series  => 'Battlestar Galactica (2003)',
                title   => 'Bastille Day',
            },
            input   => {
                media_conf => "$cwd/t/conf/single_dir.conf",
                file       => "$source/ac3.vob",
                title      => '1',
            },
            medium  => 'VideoFile',
            name    => 'Battlestar Galactica (2003) - 1x03 - Bastille Day',
            type    => 'TV',
        }
    );

# encode using the media.conf Media
$encoder->encode_media( $payload );


# ensure that the file has been processed using the single_dir.conf,
# even though the encoder was not using that config
my $target_file = 'xt/add/Battlestar Galactica (2003) - 1x03 - '
                . 'Bastille Day.m4v';
ok( -f $target_file, 'file installed' );
exit unless -f $target_file;

ok( ! -d 'xt/encode/Battlestar Galactica (2003) - 1x03 - Bastille Day',
    'encoder clears up after itself' );
ok( ! -f 'xt/trash/ac3.vob',
    'encoder does not trash source files' );
ok( -d $source, 
    'encoder does not clear up source directories' );

my $handler  = $media->get_empty_handler( 'TV', 'VideoFile' );
my %metadata = $handler->extract_metadata( $target_file );
is_deeply(
        \%metadata,
        {
            kind       => 'TV Show',
            series     => 'Battlestar Galactica (2003)',
            season     => '1',
            episode    => '3',
            episode_id => '1x03',
            title      => 'Bastille Day',
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
            },
            {
                kind => "ac-3",
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
                    {
                        channels => '5.1 ch',
                        code     => 'und',
                        format   => 'AC3',
                        language => 'Unknown',
                        track    => '2',
                    },
                ],
                crop      => '0/0/0/0',
                duration  => '00:01:08',
                size      => '720x576, pixel aspect: 2048/1435, display '
                           . 'aspect: 1.78, 25.000 fps',
                subtitles => []
            },
        },
        'tv episode appears to have been encoded correctly',
    );
