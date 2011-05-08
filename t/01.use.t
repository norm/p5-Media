use Modern::Perl;
use Test::More      tests => 2;



# can use the thing
use_ok( 'Media' );

my $media = Media->new();
isa_ok( $media, 'Media::Object' );
