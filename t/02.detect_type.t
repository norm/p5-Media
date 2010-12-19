use Modern::Perl;

use Data::Dumper::Concise;
use Media;
use Test::More  tests => 15;

my $media = Media->new( config_file => 't/test_media.conf' );



# the following should all be recognised as episodes of TV shows
check_type( 'TV',  q(House - 1x01 - Pilot)                                  );
check_type( 'TV',  q(The Kevin Bishop Show - 1x05)                          );
check_type( 'TV',  q(Bones - 4x01-02 - Yanks in the U.K.)                   );
check_type( 'TV',  q(The Daily Show - 2009-08-13 - Rachel McAdams)          );
check_type( 'TV',  q(John Doe - Season 1)                                   );
check_type( 'TV',  q(You're Hired [DVD 6])                                  );
check_type( 'TV',  q(UFC 109: Relentless)                                   );
check_type( 'TV',  q(Bundesliga 2010 - Week 20: Highlights)                 );
check_type( 'TV',  q(Top Gear - The Great Adventures Vietnam Special)       );
check_type( 'TV',  q(Battlestar Galactica (2004) - Season 4 [BD 4])         );
check_type( 'TV',  q(The Eloquent Ji Xiaolan IV - 18)                       );
check_type( 'TV',  q(Battlestar Galactica (2003) - 1x01 - 33)               );

# the following should all be recognised as Movies
check_type( 'Movie',  q(Barbarella (1968))                                  );
check_type( 'Movie',  q(Serenity - 15 (2005))                               );
check_type( 'Movie',  q(Serenity - 15 (2005) - Deleted Scenes)              );
check_type( 'Movie',  q(Interstate 60 - 12 (2002))                          );

exit;



sub check_type {
    my $required = shift;
    my $title    = shift;
    
    my $type = $media->determine_type( $title )
               // 'undefined';
    
    ok( $required eq $type )
        or say "$title: should be $required, is $type";
}
