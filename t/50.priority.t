use Modern::Perl;
use Media;
use Test::More      tests => 4;



# check queue priorities can be controlled from the config for TV episodes
my $media = Media->new( 't/conf/media.conf' );

my $handler = $media->get_handler( 'TV', 'Empty', { series => 'House' } );
is( $handler->get_default_priority(),
    10 );

$handler = $media->get_handler( 'TV', 'Empty', { series => 'Police Squad' } );
is( $handler->get_default_priority(),
    50 );

$handler = $media->get_handler( 'Movie', 'Empty', { title => 'Barbarella' } );
is( $handler->get_default_priority(),
    50 );

$handler = $media->get_handler( 'MusicVideo', 'Empty', { artist => 'Madness' } );
is( $handler->get_default_priority(),
    50 );
