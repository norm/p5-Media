use Modern::Perl;
use Media;
use Test::More      tests => 48;
use utf8;



# check the parsing of TV episodes
my $media   = Media->new( 't/conf/media.conf' );
my $handler = $media->get_empty_handler( 'TV' );

# basic episode format
{
    my $title = q(House - 1x01 - Pilot);
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 6, $confidence );
    is_deeply( 
            \%details,
            {
                series       => 'House',
                season       => '1',
                episode      => '01',
                title        => 'Pilot',
            },
        );
}
{
    my $title = q(House - 2x23 - Who's Your Daddy?);
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 6, $confidence );
    is_deeply( 
            \%details,
            {
                series       => 'House',
                season       => '2',
                episode      => '23',
                title        => q(Who's Your Daddy?),
            },
        );
}
{
    my $title = q(Grey's Anatomy - 5x03 - Here Comes the Flood);
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 6, $confidence );
    is_deeply( 
            \%details,
            {
                series       => q(Grey's Anatomy),
                season       => '5',
                episode      => '03',
                title        => 'Here Comes the Flood',
            },
        );
}
{
    my $title = q(The Kevin Bishop Show - 1x05);    
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 6, $confidence );
    is_deeply( 
            \%details,
            {
                series       => 'The Kevin Bishop Show',
                season       => '1',
                episode      => '05',
            },
        );
}
{
    my $title = q(American Dad! - 5x12 - May the Best Stan Win);
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 6, $confidence );
    is_deeply( 
            \%details,
            {
                series       => 'American Dad!',
                season       => '5',
                episode      => '12',
                title        => 'May the Best Stan Win',
            },
        );
}
{
    my $title = q(Battlestar Galactica - 1x01 - 33);
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 6, $confidence );
    is_deeply( 
            \%details,
            {
                series       => 'Battlestar Galactica',
                season       => '1',
                episode      => '01',
                title        => '33',
            },
        );
}
{
    my $title = q(Battlestar Galactica (2003) - 1x01 - 33);
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 6, $confidence );
    is_deeply( 
            \%details,
            {
                series       => 'Battlestar Galactica (2003)',
                season       => '1',
                episode      => '01',
                title        => '33',
            },
        );
}

# multiple episodes in one
{
    my $title = q(Bones - 4x01-02 - Yanks in the U.K.);
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 6, $confidence );
    is_deeply( 
            \%details,
            {
                series        => 'Bones',
                season        => '4',
                first_episode => '01',
                last_episode  => '02',
                title         => 'Yanks in the U.K.',
            },
        );
}
{
    my $title = q(Tyler Perry's Meet the Browns - 1x10-01x20);
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 6, $confidence );
    is_deeply( 
            \%details,
            {
                series        => q(Tyler Perry's Meet the Browns),
                season        => '1',
                first_episode => '10',
                last_episode  => '20',
            },
        );
}

# specials
{
    my $title = q(Top Gear - The Great Adventures Vietnam Special);
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 5, $confidence );
    is_deeply( 
            \%details,
            {
                series       => 'Top Gear',
                special      => '1',
                title        => 'The Great Adventures Vietnam Special',
            },
        );
}
{
    my $title = q(Time Team - Sx18 - Londinium, Greater London - Edge of Empire);
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 6, $confidence );
    is_deeply( 
            \%details,
            {
                series       => 'Time Team',
                special      => '1',
                episode      => '18',
                title        => 'Londinium, Greater London - Edge of Empire',
            },
        );
}

# dated episodes
{
    my $title = q(The Daily Show - 2009-08-13 - Rachel McAdams);
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 6, $confidence );
    is_deeply( 
            \%details,
            {
                series       => 'The Daily Show',
                season       => '2009',
                episode      => '08.13',
                dated        => 1,
                title        => 'Rachel McAdams',
            },
        );
    
    $title = q(The Daily Show - 2009.08.13 - Rachel McAdams);
    ( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 6, $confidence );
    is_deeply( 
            \%details,
            {
                series       => 'The Daily Show',
                season       => '2009',
                episode      => '08.13',
                dated        => 1,
                title        => 'Rachel McAdams',
            },
        );
}
{
    my $title = q(Vil du bli millionær - 2010.01.04);
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 5.71428571428571, $confidence );
    is_deeply( 
            \%details,
            {
                series       => 'Vil du bli millionær',
                season       => '2010',
                dated        => 1,
                episode      => '01.04',
            },
        );
}

# sports events
{
    my $title = q(UFC 52: Couture vs. Liddell 2);
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 2.3, $confidence );
    is_deeply( 
            \%details,
            {
                series       => 'UFC',
                episode      => '52',
                title        => 'Couture vs. Liddell 2',
            },
        );
    
    $title = q(UFC 52 - Couture vs. Liddell 2);
    ( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 2.3, $confidence );
    is_deeply( 
            \%details,
            {
                series       => 'UFC',
                episode      => '52',
                title        => 'Couture vs. Liddell 2',
            },
        );
}
{
    my $title = q(NASCAR Nationwide Series 2009 - Round 01 - Daytona (Race));
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 2, $confidence );
    is_deeply( 
            \%details,
            {
                series       => 'NASCAR Nationwide Series',
                season       => '2009',
                episode      => '01',
                rounds       => 1,
                title        => 'Daytona (Race)',
            },
        );
}
{
    my $title = q(2010 AMA Supercross Series - Supercross Class Round 5);
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 1, $confidence );
    is_deeply( 
            \%details,
            {
                series       => 'AMA Supercross Series',
                season       => '2010',
                title        => 'Supercross Class Round 5',
            },
        );
}
{
    my $title = q(Bundesliga 2010 - Week 20: Highlights);
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 4.15384615384615, $confidence );
    is_deeply( 
            \%details,
            {
                series       => 'Bundesliga',
                season       => '2010',
                special      => '1',
                title        => 'Week 20: Highlights',
            },
        );
}

# named episodes with no other info
{
    my $title = q(Howard Stern On Demand (Heidi Baron));
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 4, $confidence );
    is_deeply( 
            \%details,
            {
                series       => 'Howard Stern On Demand',
                title        => 'Heidi Baron',
            },
        );
}
{
    my $title = q(Howard Stern On Demand - Heidi Baron);
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    is( 4, $confidence );
    is_deeply( 
            \%details,
            {
                series       => 'Howard Stern On Demand',
                title        => 'Heidi Baron',
            },
        );
}

# hinted detection
{
    my $title = q(1x01 - Pilot);
    my $hints = { series => 'House' };
    my( $confidence, %details )
        = $handler->parse_title_string( $title, $hints );
    
    is( 9, $confidence );
    is_deeply( 
            \%details,
            {
                series       => 'House',
                season       => '1',
                episode      => '01',
                title        => 'Pilot',
            },
        );
}
{
    my $title = q(1x19 - EBEs.avi);
    my $hints = {
            series          => 'Seven Days',
            strip_extension => 1
        };
    my( $confidence, %details )
        = $handler->parse_title_string( $title, $hints );
    
    is( 5, $confidence );
    is_deeply(
            \%details,
            {
                series       => 'Seven Days',
                season       => '1',
                episode      => '19',
                title        => 'EBEs',
            },
        );
}
{
    my $title = q(Pilot.avi);
    my $hints = { 
            series          => 'House',
            season          => 1,
            episode         => 1,
            strip_extension => 1
        };
    my( $confidence, %details )
        = $handler->parse_title_string( $title, $hints );
    
    is( 11, $confidence );
    is_deeply( 
            \%details,
            {
                series       => 'House',
                season       => '1',
                episode      => '1',
                title        => 'Pilot',
            },
        );
}
