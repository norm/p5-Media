use Modern::Perl;
use Media;
use Test::More      tests => 112;
use utf8;



# check the filenames created for TV episode encodes
my $media = Media->new( 't/conf/media.conf' );

# basic episode format
{
    my %details = (
            series  => 'House',
            season  => '1',
            episode => '1',
            title   => 'Pilot',
        );
    my $handler = $media->get_handler( 'TV', 'Empty', \%details, undef );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/House - 1x01 - Pilot) );
    is( $handler->get_full_episode_filename(),
        q(House - 1x01 - Pilot.m4v) );
    is( $handler->get_episode_location(),
        q(House/Season 1) );
    is( $handler->get_short_episode_filename(),
        q(01 - Pilot.m4v) );
    is( $handler->get_episode_id(),
        q(1x01) );
    is( $handler->get_job_name(),
        q(House - 1x01 - Pilot) );
    is( $handler->get_priority_name(),
        q(House) );
}
{
    my %details = (
            series  => 'House',
            season  => '2',
            episode => '23',
            title   => q(Who's Your Daddy?),
        );
    my $handler = $media->get_handler( 'TV', 'Empty', \%details, undef );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/House - 2x23 - Who's Your Daddy?) );
    is( $handler->get_full_episode_filename(),
        q(House - 2x23 - Who's Your Daddy?.m4v) );
    is( $handler->get_episode_location(),
        q(House/Season 2) );
    is( $handler->get_short_episode_filename(),
        q(23 - Who's Your Daddy?.m4v) );
    is( $handler->get_episode_id(),
        q(2x23) );
    is( $handler->get_job_name(),
        q(House - 2x23 - Who's Your Daddy?) );
    is( $handler->get_priority_name(),
        q(House) );
}
{
    my %details = (
            series  => q(Grey's Anatomy),
            season  => '5',
            episode => '3',
            title   => 'Here Comes the Flood',
        );
    my $handler = $media->get_handler( 'TV', 'Empty', \%details, undef );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/Grey's Anatomy - 5x03 - Here Comes the Flood) );
    is( $handler->get_full_episode_filename(),
        q(Grey's Anatomy - 5x03 - Here Comes the Flood.m4v) );
    is( $handler->get_episode_location(),
        q(Grey's Anatomy/Season 5) );
    is( $handler->get_short_episode_filename(),
        q(03 - Here Comes the Flood.m4v) );
    is( $handler->get_episode_id(),
        q(5x03) );
    is( $handler->get_job_name(),
        q(Grey's Anatomy - 5x03 - Here Comes the Flood) );
    is( $handler->get_priority_name(),
        q(Grey's Anatomy) );
}
{
    my %details = (
            series  => 'The Kevin Bishop Show',
            season  => '1',
            episode => '05',
        );
    my $handler = $media->get_handler( 'TV', 'Empty', \%details, undef );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/The Kevin Bishop Show - 1x05) );
    is( $handler->get_full_episode_filename(),
        q(The Kevin Bishop Show - 1x05.m4v) );
    is( $handler->get_episode_location(),
        q(The Kevin Bishop Show/Season 1) );
    is( $handler->get_short_episode_filename(),
        q(05 - Episode 05.m4v) );
    is( $handler->get_episode_id(),
        q(1x05) );
    is( $handler->get_job_name(),
        q(The Kevin Bishop Show - 1x05) );
    is( $handler->get_priority_name(),
        q(The Kevin Bishop Show) );
}
{
    my %details = (
            series  => 'Battlestar Galactica (2003)',
            season  => '1',
            episode => '01',
            title   => '33',
        );
    my $handler = $media->get_handler( 'TV', 'Empty', \%details, undef );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/Battlestar Galactica (2003) - 1x01 - 33) );
    is( $handler->get_full_episode_filename(),
        q(Battlestar Galactica (2003) - 1x01 - 33.m4v) );
    is( $handler->get_episode_location(),
        q(Battlestar Galactica (2003)/Season 1) );
    is( $handler->get_short_episode_filename(),
        q(01 - 33.m4v) );
    is( $handler->get_episode_id(),
        q(1x01) );
    is( $handler->get_job_name(),
        q(Battlestar Galactica (2003) - 1x01 - 33) );
    is( $handler->get_priority_name(),
        q(Battlestar Galactica (2003)) );
}

# multitple episodes in one
{
    my %details = (
            series        => 'Bones',
            season        => '4',
            first_episode => '01',
            last_episode  => '02',
            title         => 'Yanks in the U.K.',
        );
    my $handler = $media->get_handler( 'TV', 'Empty', \%details, undef );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/Bones - 4x01-02 - Yanks in the U.K.) );
    is( $handler->get_full_episode_filename(),
        q(Bones - 4x01-02 - Yanks in the U.K..m4v) );
    is( $handler->get_episode_location(),
        q(Bones/Season 4) );
    is( $handler->get_short_episode_filename(),
        q(01-02 - Yanks in the U.K..m4v) );
    is( $handler->get_episode_id(),
        q(4x01-02) );
    is( $handler->get_job_name(),
        q(Bones - 4x01-02 - Yanks in the U.K.) );
    is( $handler->get_priority_name(),
        q(Bones) );
}
{
    my %details = (
            series        => 'Bones',
            series        => q(Tyler Perry's Meet the Browns),
            season        => '1',
            first_episode => '10',
            last_episode  => '20',
        );
    my $handler = $media->get_handler( 'TV', 'Empty', \%details, undef );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/Tyler Perry's Meet the Browns - 1x10-20) );
    is( $handler->get_full_episode_filename(),
        q(Tyler Perry's Meet the Browns - 1x10-20.m4v) );
    is( $handler->get_episode_location(),
        q(Tyler Perry's Meet the Browns/Season 1) );
    is( $handler->get_short_episode_filename(),
        q(10-20 - Episodes 10 to 20.m4v) );
    is( $handler->get_episode_id(),
        q(1x10-20) );
    is( $handler->get_job_name(),
        q(Tyler Perry's Meet the Browns - 1x10-20) );
    is( $handler->get_priority_name(),
        q(Tyler Perry's Meet the Browns) );
}

# specials
{
    my %details = (
            series  => 'Top Gear',
            special => '1',
            title   => 'The Great Adventures Vietnam Special',
        );
    my $handler = $media->get_handler( 'TV', 'Empty', \%details, undef );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/Top Gear - The Great Adventures Vietnam Special) );
    is( $handler->get_full_episode_filename(),
        q(Top Gear - The Great Adventures Vietnam Special.m4v) );
    is( $handler->get_episode_location(),
        q(Top Gear/Specials) );
    is( $handler->get_short_episode_filename(),
        q(The Great Adventures Vietnam Special.m4v) );
    is( $handler->get_episode_id(),
        q(The Great Adventures Vietnam Special) );
    is( $handler->get_job_name(),
        q(Top Gear - The Great Adventures Vietnam Special) );
    is( $handler->get_priority_name(),
        q(Top Gear) );
}
{
    my %details = (
            series  => 'Time Team',
            special => '1',
            episode => '18',
            title   => 'Londinium, Greater London - Edge of Empire',
        );
    my $handler = $media->get_handler( 'TV', 'Empty', \%details, undef );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/Time Team - Sx18 - Londinium, Greater London - Edge of Empire) );
    is( $handler->get_full_episode_filename(),
        q(Time Team - Sx18 - Londinium, Greater London - Edge of Empire.m4v) );
    is( $handler->get_episode_location(),
        q(Time Team/Specials) );
    is( $handler->get_short_episode_filename(),
        q(18 - Londinium, Greater London - Edge of Empire.m4v) );
    is( $handler->get_episode_id(),
        q(Sx18) );
    is( $handler->get_job_name(),
        q(Time Team - Sx18 - Londinium, Greater London - Edge of Empire) );
    is( $handler->get_priority_name(),
        q(Time Team) );
}

# dated episodes
{
    my %details = (
            series  => 'The Daily Show',
            season  => '2009',
            episode => '08.13',
            dated   => 1,
            title   => 'Rachel McAdams',
        );
    my $handler = $media->get_handler( 'TV', 'Empty', \%details, undef );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/The Daily Show - 2009.08.13 - Rachel McAdams) );
    is( $handler->get_full_episode_filename(),
        q(The Daily Show - 2009.08.13 - Rachel McAdams.m4v) );
    is( $handler->get_episode_location(),
        q(The Daily Show/Season 2009) );
    is( $handler->get_short_episode_filename(),
        q(08.13 - Rachel McAdams.m4v) );
    is( $handler->get_episode_id(),
        q(2009.08.13) );
    is( $handler->get_job_name(),
        q(The Daily Show - 2009.08.13 - Rachel McAdams) );
    is( $handler->get_priority_name(),
        q(The Daily Show) );
}
{
    my %details = (
            series  => 'Vil du bli millionær',
            season  => '2010',
            dated   => 1,
            episode => '01.04',
        );
    my $handler = $media->get_handler( 'TV', 'Empty', \%details, undef );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/Vil du bli millionær - 2010.01.04) );
    is( $handler->get_full_episode_filename(),
        q(Vil du bli millionær - 2010.01.04.m4v) );
    is( $handler->get_episode_location(),
        q(Vil du bli millionær/Season 2010) );
    is( $handler->get_short_episode_filename(),
        q(01.04 - Episode 01.04.m4v) );
    is( $handler->get_episode_id(),
        q(2010.01.04) );
    is( $handler->get_job_name(),
        q(Vil du bli millionær - 2010.01.04) );
    is( $handler->get_priority_name(),
        q(Vil du bli millionær) );
}

# sports events
{
    my %details = (
            series  => 'UFC',
            episode => '52',
            title   => 'Couture vs. Liddell 2',
        );
    my $handler = $media->get_handler( 'TV', 'Empty', \%details, undef );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/UFC 52 - Couture vs. Liddell 2) );
    is( $handler->get_full_episode_filename(),
        q(UFC 52 - Couture vs. Liddell 2.m4v) );
    is( $handler->get_episode_location(),
        q(UFC) );
    is( $handler->get_short_episode_filename(),
        q(52 - Couture vs. Liddell 2.m4v) );
    is( $handler->get_episode_id(),
        q(52) );
    is( $handler->get_job_name(),
        q(UFC 52 - Couture vs. Liddell 2) );
    is( $handler->get_priority_name(),
        q(UFC) );
}
{
    my %details = (
            series  => 'NASCAR Nationwide Series',
            season  => '2009',
            episode => '01',
            rounds  => 1,
            title   => 'Daytona (Race)',
        );
    my $handler = $media->get_handler( 'TV', 'Empty', \%details, undef );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/NASCAR Nationwide Series - 2009 - Round 01 - Daytona (Race)) );
    is( $handler->get_full_episode_filename(),
        q(NASCAR Nationwide Series - 2009 - Round 01 - Daytona (Race).m4v) );
    is( $handler->get_episode_location(),
        q(NASCAR Nationwide Series/Season 2009) );
    is( $handler->get_short_episode_filename(),
        q(01 - Daytona (Race).m4v) );
    is( $handler->get_episode_id(),
        q(2009 - Round 01) );
    is( $handler->get_job_name(),
        q(NASCAR Nationwide Series - 2009 - Round 01 - Daytona (Race)) );
    is( $handler->get_priority_name(),
        q(NASCAR Nationwide Series) );
}
{
    my %details = (
            series => 'AMA Supercross Series',
            season => '2010',
            title  => 'Supercross Class Round 5',
        );
    my $handler = $media->get_handler( 'TV', 'Empty', \%details, undef );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/AMA Supercross Series - 2010 - Supercross Class Round 5) );
    is( $handler->get_full_episode_filename(),
        q(AMA Supercross Series - 2010 - Supercross Class Round 5.m4v) );
    is( $handler->get_episode_location(),
        q(AMA Supercross Series/Season 2010) );
    is( $handler->get_short_episode_filename(),
        q(Supercross Class Round 5.m4v) );
    is( $handler->get_episode_id(),
        q(2010) );
    is( $handler->get_job_name(),
        q(AMA Supercross Series - 2010 - Supercross Class Round 5) );
    is( $handler->get_priority_name(),
        q(AMA Supercross Series) );
}
{
    my %details = (
            series  => 'Bundesliga',
            season  => '2010',
            special => '1',
            title   => 'Week 20: Highlights',
        );
    my $handler = $media->get_handler( 'TV', 'Empty', \%details, undef );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/Bundesliga - 2010 - Week 20 Highlights) );
    is( $handler->get_full_episode_filename(),
        q(Bundesliga - 2010 - Week 20 Highlights.m4v) );
    is( $handler->get_episode_location(),
        q(Bundesliga/Season 2010) );
    is( $handler->get_short_episode_filename(),
        q(Week 20 Highlights.m4v) );
    is( $handler->get_episode_id(),
        q(2010) );
    is( $handler->get_job_name(),
        q(Bundesliga - 2010 - Week 20 Highlights) );
    is( $handler->get_priority_name(),
        q(Bundesliga) );
}

# named episodes with no other info
{
    my %details = (
            series => 'Howard Stern On Demand',
            title  => 'Heidi Baron',
        );
    my $handler = $media->get_handler( 'TV', 'Empty', \%details, undef );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/Howard Stern On Demand - Heidi Baron) );
    is( $handler->get_full_episode_filename(),
        q(Howard Stern On Demand - Heidi Baron.m4v) );
    is( $handler->get_episode_location(),
        q(Howard Stern On Demand) );
    is( $handler->get_short_episode_filename(),
        q(Heidi Baron.m4v) );
    is( $handler->get_episode_id(),
        q(Heidi Baron) );
    is( $handler->get_job_name(),
        q(Howard Stern On Demand - Heidi Baron) );
    is( $handler->get_priority_name(),
        q(Howard Stern On Demand) );
}
