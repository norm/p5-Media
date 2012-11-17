#!/usr/bin/env perl

use Modern::Perl;
use Capture::Tiny   qw( capture );
use IO::All;
use Media;
use Test::More;


my $input_file = "$ENV{'MEDIA_TESTING'}/dts.mkv";

if ( !-f $input_file ) {
    plan skip_all => "${input_file} file is missing";
    exit;
}

plan tests => 14;

my $media     = Media->new( 't/conf/media.conf' );
my @genres    = qw( Adventure Comedy Fantasy );
my @actors    = ( 'Jane Fonda', 'John Phillip Law', 'Anita Pallenberg' );
my @directors = ( 'Roger Vadim' );
my @writers   = ( 'Jean-Claude Forest', 'Claude Brulé' );
my $payload   = {
    details => {
        actor    => \@actors,
        audio   => [
            "1:dpl2:English",
            "1:ac3:English",
        ],
        director => \@directors,
        feature  => '1',
        genre    => \@genres,
        rating   => 'X',
        title    => 'Barbarella',
        writer   => \@writers,
        year     => '1968',
    },
    input => {
        file   => $input_file,
        poster => 'xt/poster.png',
        title  => '1',
    },
    medium  => 'VideoFile',
    name    => 'Batbarella - X (1968)',
    type    => 'Movie',
};
my $target_file = 'xt/movies/All/Barbarella - X (1968)/'
                . 'Barbarella - X (1968).m4v';
my $link_target = '../../All/Barbarella - X (1968)/'
                . 'Barbarella - X (1968).m4v';

# ensure a clean directory structure
my $result = system 'rm -rf xt/encode xt/movies';
die "'rm -rf xt/encode': $!"
    if $result >> 8;


$media->encode_media( $payload );


# check the output
ok( -f $target_file, 'file installed' );
ok( ! -d 'xt/encode/Barbarella - X (1968)',
    'encoder clears up after itself' );

exit unless -f $target_file;

foreach my $genre ( @genres ) {
    my $link = "xt/movies/Genre/$genre/Barbarella - X (1968).m4v";
    ok( readlink( $link ) eq $link_target, "Genre $genre" );
}
foreach my $actor ( @actors ) {
    my $link = "xt/movies/Actor/$actor/Barbarella - X (1968).m4v";
    ok( readlink( $link ) eq $link_target, "Actor $actor" );
}
foreach my $director ( @directors ) {
    my $link = "xt/movies/Director/$director/Barbarella - X (1968).m4v";
    ok( readlink( $link ) eq $link_target, "Director $director" );
}
foreach my $writer ( @writers ) {
    my $link = "xt/movies/Writer/$writer/Barbarella - X (1968).m4v";
    ok( readlink( $link ) eq $link_target, "Writer $writer" );
}
ok( readlink( 'xt/movies/Year/1968/Barbarella - X (1968).m4v' ) 
    eq $link_target, 'Year 1968' );

my $handler  = $media->get_empty_handler( 'Movie', 'VideoFile' );
my %metadata = $handler->extract_metadata( $target_file );
is_deeply(
        \%metadata,
        {
            artist        => 'Roger Vadim',
            artwork_count => 1,
            genre         => 'Adventure',
            kind          => 'Movie',
            title         => 'Barbarella',
            year          => '1968',
            rating        => 'X',
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
            },
        ],
        'tracks'
    );
