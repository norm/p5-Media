use Modern::Perl;


use Data::Dumper;
use Media;
use Test::More          tests => 91;


my $media   = Media->new();
my $handler = $media->get_handler_type( 'TV' );
my %details;
my %check;
my $title;
my @location;



# basic episode format
$title = q(House - 1x01 - Pilot);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'House',
            season  => '1',
            episode => '01',
            title   => 'Pilot',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/House/Season 1',
            '01 - Pilot.avi'
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



# episode without a title
$title = q(The Kevin Bishop Show - 1x05);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'The Kevin Bishop Show',
            season  => '1',
            episode => '05',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/The Kevin Bishop Show/Season 1',
            '05 - Episode 05.avi'
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
$details{'title'} = 'Episode 05';
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



# multiple episodes in one file
$title = q(Bones - 4x01-02 - Yanks in the U.K.);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series        => 'Bones',
            season        => '4',
            first_episode => '01',
            last_episode  => '02',
            episodes      => [ '01', '02' ],
            title         => 'Yanks in the U.K.',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/Bones/Season 4',
            '01-02 - Yanks in the U.K..avi'
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



$title = q(Tyler Perry's Meet the Browns - 1x10-01x20);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series        => q(Tyler Perry's Meet the Browns),
            season        => '1',
            first_episode => '10',
            last_episode  => '20',
            episodes      => [ 
                '10', '11', '12', '13', '14', '15', 
                '16', '17', '18', '19', '20', 
             ],
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
$details{'title'} = 'Episodes 10-20';
is_deeply(
        \@location, 
        [
            "/files/tv/Tyler Perry's Meet the Browns/Season 1",
            '10-20 - Episodes 10-20.avi'
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



# do not choke on apostrophes in the title
$title = q(House - 2x23 - Who's Your Daddy);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'House',
            season  => '2',
            episode => '23',
            title   => q(Who's Your Daddy),
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/House/Season 2',
            "23 - Who's Your Daddy.avi"
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



# do not choke on apostrophes in the series name
$title = q(Grey's Anatomy - 5x03 - Here Comes the Flood);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => q(Grey's Anatomy),
            season  => '5',
            episode => '03',
            title   => 'Here Comes the Flood',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            "/files/tv/Grey's Anatomy/Season 5",
            '03 - Here Comes the Flood.avi'
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



# sports
$title = q(NASCAR Nationwide Series 2009 - Round 01 - Daytona (Race));
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'NASCAR Nationwide Series',
            season  => '2009',
            episode => '01',
            title   => 'Daytona (Race)',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/NASCAR Nationwide Series/Season 2009',
            '01 - Daytona (Race).avi'
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



# shows by date not season
$title = q(The Daily Show - 2009-08-13 - Rachel McAdams);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'The Daily Show',
            season  => '2009',
            episode => '08.13',
            title   => 'Rachel McAdams',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/The Daily Show/Season 2009',
            '08.13 - Rachel McAdams.avi'
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



# shows by date not season
$title = q(Vil Du Bli Millionr Hot Seat - 2010.01.04);
# $title = q(Vil Du Bli Millionr Hot Seat - 2010-01-04 - Blah);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'Vil Du Bli Millionr Hot Seat',
            season  => '2010',
            episode => '01.04',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/Vil Du Bli Millionr Hot Seat/Season 2010',
            '01.04 - Episode 01.04.avi'
        ]
    ) or print "$title location:\n" . Dumper \@location;
$details{'title'} = 'Episode 01.04';
%check = $handler->details_from_location( join '/', @location );
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;


# entire season
$title = q(John Doe - Season 1);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'John Doe',
            season  => '1',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/John Doe/Season 1',
            ''
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



# entire season
$title = q(Are You Afraid Of The Dark? - Season Two);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'Are You Afraid Of The Dark?',
            season  => '2',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/Are You Afraid Of The Dark?/Season 2',
            ''
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



# dvd-based television
$title = q(Battlestar Galactica (2004) - Season 4 [BD 4]);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'Battlestar Galactica (2004)',
            season  => '4',
            disk    => '4',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/Battlestar Galactica (2004)/Season 4',
            ''
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
delete $details{'disk'};
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;


# assume season 1 for mini-series
$title = q(You're Hired [DVD 6]);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => q(You're Hired),
            season  => '1',
            disk    => '6',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            "/files/tv/You're Hired/Season 1",
            ''
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
delete $details{'disk'};
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



# capture episodes from mini-series
$title = q(You're Hired - 19-22 [DVD 5/5]);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series        => q(You're Hired),
            season        => '1',
            first_episode => '19',
            last_episode  => '22',
            episodes      => [ '19', '20', '21', '22' ],
            disk          => '5',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            "/files/tv/You're Hired/Season 1",
            '19-22 - Episodes 19-22.avi'
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
$details{'title'} = 'Episodes 19-22';
delete $details{'disk'};
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



# 
$title = q(Futurama Season 1 (DVD 1));
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'Futurama',
            season  => '1',
            disk    => '1',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/Futurama/Season 1',
            ''
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
delete $details{'disk'};
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



$title = q(Invader Zim Vol. 1 [DVD 1]);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series => 'Invader Zim',
            season => '1',
            disk   => '1',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/Invader Zim/Season 1',
            ''
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
delete $details{'disk'};
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



$title = q(Generation Kill (Mini-Series) [DVD 2/3]);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series => 'Generation Kill',
            disk   => '2',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/Generation Kill',
            ''
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
delete $details{'disk'};
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



$title = q(Looney Tunes Golden Collection (Vol. 2) [DVD 3]);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'Looney Tunes Golden Collection',
            season  => '2',
            disk    => '3',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/Looney Tunes Golden Collection/Season 2',
            ''
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
delete $details{'disk'};
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;


$title = q(Sherlock Holmes (1984) - Season 1 (DVD 4));
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'Sherlock Holmes (1984)',
            season  => '1',
            disk    => '4',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/Sherlock Holmes (1984)/Season 1',
            ''
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
delete $details{'disk'};
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



$title = q(30 Rock - Season 3 [DVD 2A]);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => '30 Rock',
            season  => '3',
            disk    => '2A',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/30 Rock/Season 3',
            ''
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
delete $details{'disk'};
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



$title = q(The Big Bang Theory - Season 2 (Subpack));
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'The Big Bang Theory',
            season  => '2',
            extra   => 'Subpack',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/The Big Bang Theory/Season 2',
            ''
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
delete $details{'extra'};
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;


$title = q(Star Trek: Deep Space Nine - Season 2 (DVD Extras));
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'Star Trek: Deep Space Nine',
            season  => '2',
            extra   => 'DVD Extras',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/Star Trek: Deep Space Nine/Season 2',
            ''
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
delete $details{'extra'};
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



$title = q(UFC 109: Relentless);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'UFC',
            episode => '109',
            title   => 'Relentless',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/UFC',
            '109 - Relentless.avi'
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



$title = q(Bundesliga 2010 - Week 20: Highlights);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'Bundesliga',
            season  => '2010',
            title   => 'Week 20: Highlights',
            special => '1',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/Bundesliga/Season 2010',
            'Week 20: Highlights.avi'
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



$title = q(2010 AMA Supercross Series - Supercross Class Round 5);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'AMA Supercross Series',
            season  => '2010',
            title   => 'Supercross Class Round 5',
        }
    ) or print "$title becomes:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/AMA Supercross Series/Season 2010',
            'Supercross Class Round 5.avi'
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
$details{'special'} = 1;
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



$title = q(The Adventures of Pete and Pete - Complete Series);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'The Adventures of Pete and Pete',
            season  => '1',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/The Adventures of Pete and Pete/Season 1',
            ''
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



$title = q(Time Team - Sx18 - Londinium, Greater London - Edge of Empire);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'Time Team',
            episode => '18',
            title   => 'Londinium, Greater London - Edge of Empire',
            special => '1',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/Time Team/Specials',
            '18 - Londinium, Greater London - Edge of Empire.avi'
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



$title = q(Top Gear - The Great Adventures Vietnam Special);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'Top Gear',
            title   => 'The Great Adventures Vietnam Special',
            special => '1',
        }
    ) or print "$title details:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/Top Gear/Specials',
            'The Great Adventures Vietnam Special.avi'
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



$title = q(Howard Stern On Demand (Heidi Baron));
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'Howard Stern On Demand',
            title   => 'Heidi Baron',
        }
    ) or print "$title becomes:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/Howard Stern On Demand',
            'Heidi Baron.avi'
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



$title = q(Crop To Shop - Jimmy's Supermarket Secrets);
%details = $handler->parse_title_string( $title );
is_deeply( 
        \%details,
        {
            series  => 'Crop To Shop',
            title   => "Jimmy's Supermarket Secrets",
        }
    ) or print "$title becomes:\n" . Dumper \%details;
@location = $handler->get_episode_location( \%details, '.avi' );
is_deeply(
        \@location, 
        [
            '/files/tv/Crop To Shop',
            "Jimmy's Supermarket Secrets.avi"
        ]
    ) or print "$title location:\n" . Dumper \@location;
%check = $handler->details_from_location( join '/', @location );
is_deeply( \%details, \%check ) 
    or print "$title check:\n" . Dumper \%check;



# should not recognise as a TV show
%details = $handler->parse_title_string( 'Barbarella (1968)' );
is_deeply( \%details, {} );
