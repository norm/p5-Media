use Modern::Perl;
use Media;
use Test::More      tests => 26;



# check the parsing of music video titles
my $media   = Media->new( 't/conf/media.conf' );
my $handler = $media->get_empty_handler( 'MusicVideo' );

{
    my $title = q((Waiting for) The Ghost Train [Madness]);
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 6,                                  $confidence );
    is( '(Waiting for) The Ghost Train',    $details{'title'} );
    is( 'Madness',                          $details{'artist'} );
    is( undef,                              $details{'album'} );
    
    $title = q((Waiting for) The Ghost Train [Madness] Utter Madness);
    ( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 8.5,                                $confidence );
    is( '(Waiting for) The Ghost Train',    $details{'title'} );
    is( 'Madness',                          $details{'artist'} );
    is( 'Utter Madness',                    $details{'album'} );
}
{
    my $title = q(Thriller [Michael Jackson]);
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 6,                                  $confidence );
    is( 'Thriller',                         $details{'title'} );
    is( 'Michael Jackson',                  $details{'artist'} );
    is( undef,                              $details{'album'} );
    
    $title = q(Thriller);
    ( $confidence, %details ) = $handler->parse_title_string( $title );
    is( undef,                              $confidence );
    is_deeply( \%details, {} );
}
{
    my $title = q(Jizz In My Pants [The Lonely Island] Incredibad);
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 8.5,                                $confidence );
    is( 'Jizz In My Pants',                 $details{'title'} );
    is( 'The Lonely Island',                $details{'artist'} );
    is( 'Incredibad',                       $details{'album'} );
}

# hinted detection
{
    my $title = q((Waiting for) The Ghost Train.avi);
    my $hints = {
            artist          => 'Madness',
            strip_extension => 1,
        };
    
    my( $confidence, %details )
        = $handler->parse_title_string( $title, $hints );
    
    is( 8,                                  $confidence );
    is( '(Waiting for) The Ghost Train',    $details{'title'} );
    is( 'Madness',                          $details{'artist'} );
    is( undef,                              $details{'album'} );
}
{
    my $title = q(ghost_train.avi);
    my $hints = {
            title  => '(Waiting for) The Ghost Train',
            artist => 'Madness',
            album  => 'Utter Madness',
        };
    
    my( $confidence, %details )
        = $handler->parse_title_string( $title, $hints );
    
    is( 12.5,                               $confidence );
    is( '(Waiting for) The Ghost Train',    $details{'title'} );
    is( 'Madness',                          $details{'artist'} );
    is( 'Utter Madness',                    $details{'album'} );
}
