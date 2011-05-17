use Modern::Perl;
use Media;
use Test::More      tests => 98;



# check the parsing of movie titles
my $media   = Media->new( 't/conf/media.conf' );
my $handler = $media->get_empty_handler( 'Movie' );

# Barbarella (1968)
{
    my $title = q(Barbarella (1968));
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 4,                  $confidence );
    is( 'Barbarella',       $details{'title'} );
    is( '1968',             $details{'year'} );
    is( 'X',                $details{'rating'} );
    ok( defined $details{'feature'} );
    
    $title = q(Barbarella);
    ( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 3,                  $confidence );
    is( 'Barbarella',       $details{'title'} );
    is( '1968',             $details{'year'} );
    is( 'X',                $details{'rating'} );
    ok( defined $details{'feature'} );
    
    $title = q(Barbarella - 12 (1970));
    ( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 5,                  $confidence );
    is( 'Barbarella',       $details{'title'} );
    is( '1968',             $details{'year'} );
    is( 'X',                $details{'rating'} );
    ok( defined $details{'feature'} );
    
    $title = q(Barbarlla);
    ( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 2.66666666666667,   $confidence );
    is( 'Barbarella',       $details{'title'} );
    is( '1968',             $details{'year'} );
    is( 'X',                $details{'rating'} );
    ok( defined $details{'feature'} );
    
    $title = q(Berbirella);
    ( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 2.4,                $confidence );
    is( 'Barbarella',       $details{'title'} );
    is( '1968',             $details{'year'} );
    is( 'X',                $details{'rating'} );
    ok( defined $details{'feature'} );
}

# Star Trek II: The Wrath of Khan (1982)
{
    my $title = q(Star Trek II: The Wrath of Khan (1982));
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 4,                                      $confidence );
    is( 'Star Trek II - The Wrath of Khan',     $details{'title'} );
    is( '1982',                                 $details{'year'} );
    is( '12',                                   $details{'rating'} );
    ok( defined $details{'feature'} );
    
    $title = q(Star Trek 2 The Wrath of Khan);
    ( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 2.79310344827586,                       $confidence );
    is( 'Star Trek II - The Wrath of Khan',     $details{'title'} );
    is( '1982',                                 $details{'year'} );
    is( '12',                                   $details{'rating'} );
    ok( defined $details{'feature'} );
    
    $title = q(Star Trek Wrath of Khan);
    ( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 2.21739130434783,                       $confidence );
    is( 'Star Trek II - The Wrath of Khan',     $details{'title'} );
    is( '1982',                                 $details{'year'} );
    is( '12',                                   $details{'rating'} );
    ok( defined $details{'feature'} );
    
    $title = q(The Wrath of Khan);
    ( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 3,                                      $confidence );
    is( 'Star Trek II - The Wrath of Khan',     $details{'title'} );
    is( '1982',                                 $details{'year'} );
    is( '12',                                   $details{'rating'} );
    ok( defined $details{'feature'} );
    
    $title = q(Star Trek Wrath Khan);
    ( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 1.95,                                   $confidence );
    is( 'Star Trek II - The Wrath of Khan',     $details{'title'} );
    is( '1982',                                 $details{'year'} );
    is( '12',                                   $details{'rating'} );
    ok( defined $details{'feature'} );
    
    $title = q(Wrath Khan);
    ( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 2.1,                                    $confidence );
    is( 'Star Trek II - The Wrath of Khan',     $details{'title'} );
    is( '1982',                                 $details{'year'} );
    is( '12',                                   $details{'rating'} );
    ok( defined $details{'feature'} );
}

# DVD extras from Serenity (2005)
{
    my $title = q(Serenity - 15 (2005));
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 5,                  $confidence );
    is( 'Serenity',         $details{'title'} );
    is( '2005',             $details{'year'} );
    is( '15',               $details{'rating'} );
    ok( defined $details{'feature'} );
    
    $title = q(Serenity);
    ( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 3,                  $confidence );
    is( 'Serenity',         $details{'title'} );
    is( '2005',             $details{'year'} );
    is( '15',               $details{'rating'} );
    ok( defined $details{'feature'} );
    
    $title = q(Serenity - 15 (2005) - Deleted Scenes);
    ( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 5,                  $confidence );
    is( 'Serenity',         $details{'title'} );
    is( '2005',             $details{'year'} );
    is( '15',               $details{'rating'} );
    is( 'Deleted Scenes',   $details{'extra'} );
    ok( !defined $details{'feature'} );
    
    $title = q(Serenity - 15 (2005) - Gag Reel);
    ( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 5,                  $confidence );
    is( 'Serenity',         $details{'title'} );
    is( '2005',             $details{'year'} );
    is( '15',               $details{'rating'} );
    is( 'Gag Reel',         $details{'extra'} );
    ok( !defined $details{'feature'} );
    
    $title = q(Serenity - Gag Reel);
    ( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 3,                  $confidence );
    is( 'Serenity',         $details{'title'} );
    is( '2005',             $details{'year'} );
    is( '15',               $details{'rating'} );
    is( 'Gag Reel',         $details{'extra'} );
    ok( !defined $details{'feature'} );
}

# hinted detection
{
    my $title = q(Barbarella);
    my $hints = { 
            year => '1968',
        };
    
    my( $confidence, %details )
        = $handler->parse_title_string( $title, $hints );
    
    is( 6,                  $confidence );
    is( 'Barbarella',       $details{'title'} );
    is( '1968',             $details{'year'} );
    is( 'X',                $details{'rating'} );
    ok( defined $details{'feature'} );
}
{
    my $title = q(twister.m2ts);
    my $hints = { 
            rating => 'PG',
            title  => 'Twister',
            year   => '1996',
        };
    
    my( $confidence, %details )
        = $handler->parse_title_string( $title, $hints );
    
    is( 9,                  $confidence );
    is( 'Twister',          $details{'title'} );
    is( '1996',             $details{'year'} );
    is( 'PG',               $details{'rating'} );
    ok( defined $details{'feature'} );
}

# Movie name containing hyphens
{
    my $title = q(Harry Potter and the Deathly Hallows - Part 1 - 12A (2010));
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 5,          $confidence );
    is( 'Harry Potter and the Deathly Hallows - Part 1',
                    $details{'title'} );
    is( '2010',     $details{'year'} );
    is( '12A',      $details{'rating'} );
    ok( defined $details{'feature'} );
}
