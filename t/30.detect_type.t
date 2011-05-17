use Modern::Perl;
use Media;
use Test::More      tests => 23;



# check that common titles are identified as the correct type
my $media = Media->new( 't/conf/media.conf' );

# no type
check_type( 'undefined', '' );

check_type( 'TV',  q(House - 1x01 - Pilot)                            );
check_type( 'TV',  q(The Kevin Bishop Show - 1x05)                    );
check_type( 'TV',  q(Bones - 4x01-02 - Yanks in the U.K.)             );
check_type( 'TV',  q(The Daily Show - 2009-08-13 - Rachel McAdams)    );
check_type( 'TV',  q(UFC 109: Relentless)                             );
check_type( 'TV',  q(Bundesliga 2010 - Week 20: Highlights)           );
check_type( 'TV',  q(Top Gear - The Great Adventures Vietnam Special) );
check_type( 'TV',  q(Battlestar Galactica (2003) - 1x01 - 33)         );

check_type( 'Movie',  q(Barbarella)                                   );
check_type( 'Movie',  q(The Wrath of Khan)                            );
check_type( 'Movie',  q(The Matrix - 15 (1999))                       );
check_type( 'Movie',  q(Serenity - 15 (2005))                         );
check_type( 'Movie',  q(Serenity - 15 (2005) - Deleted Scenes)        );
check_type( 'Movie',  q(Serenity - Gag Reel)                          );
check_type( 'Movie',  q(Interstate 60 - 12 (2002))                    );

check_type( 'MusicVideo', q((Waiting for) The Ghost Train [Madness])  );
check_type( 'MusicVideo', q(Thriller [Michael Jackson])               );
check_type( 'MusicVideo', q(Jizz In My Pants [The Lonely Island])     );

check_type( 'ConfigFile', q(t/hinted) );

# hinted checks
check_type(
        'TV',
        '1x20 - Walter',
        { series => 'Seven Days' },
    );
check_type(
        'TV',
        '/Volumes/asimov/not-done/Seven Days/Season 1/1x20 - Walter',
        { series => 'Seven Days' },
    );
check_type(
        'TV',
        'Serenity - Gag Reel',
        { type => 'TV', },
    );
exit;



sub check_type {
    my $required = shift;
    my $title    = shift;
    my $hints    = shift;
    
    my( $type, $details ) = $media->determine_type( $title, $hints );
    $type = 'undefined' unless defined $type;
    
    ok( $required eq $type )
        or say "$title: should be $required, is $type";
}
