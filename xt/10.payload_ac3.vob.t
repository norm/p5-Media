#!/usr/bin/env perl

use Modern::Perl;
use Capture::Tiny   qw( capture );
use IO::All;
use Media;
use Test::More;


my $input_file = "$ENV{'MEDIA_TESTING'}/ac3.vob";

if ( !-f $input_file ) {
    plan skip_all => "${input_file} file is missing";
    exit;
}

plan tests => 4;

my $media     = Media->new( 't/conf/media.conf' );
my $payload   = {
    details => {
        audio   => [
            "1:ac3pass:English",
            "1:dpl2:English",
        ],
        series  => 'Battlestar Galactica (2003)',
        season  => '1',
        episode => '03',
        title   => 'Bastille Day',
    },
    input   => {
        file  => $input_file,
        title => '1',
    },
    medium  => 'VideoFile',
    name    => 'Battlestar Galactica (2003) - 1x03 - Bastille Day',
    type    => 'TV',
};
my $target_file = 'xt/tv/Battlestar Galactica (2003)/Season 1/'
                . '03 - Bastille Day.m4v';

# ensure a clean directory structure
my $result = system 'rm -rf xt/encode xt/tv';
die "'rm -rf xt/encode xt/tv': $!"
    if $result >> 8;


$media->encode_media( $payload );


# check the output
ok( -f $target_file, 'file installed' );
ok( ! -d 'xt/encode/Battlestar Galactica (2003) - 1x03 - Bastille Day',
    'encoder clears up after itself' );

exit unless -f $target_file;

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
