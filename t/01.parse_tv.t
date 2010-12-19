use Modern::Perl;


use Data::Dumper::Concise;
use Media;
use Test::More          tests => 128;


my $media   = Media->new( config_file => 't/test_media.conf' );
my $handler = $media->get_handler_type( 'TV' );
my $details;
my $confidence;
my %check;
my $title;
my $location;


# create some directories to test against (affects confidences)
mkdir q(t/tv/American Dad!);
mkdir q(t/tv/Bones);
mkdir q(t/tv/Grey's Anatomy);
mkdir q(t/tv/House);


# basic episode format
$title      = q(House - 1x01 - Pilot);
$confidence = 4;
$details    = {
        series  => 'House',
        season  => '1',
        episode => '01',
        title   => 'Pilot',
    };
$location   = [
        't/tv/House/Season 1',
        '01 - Pilot.avi'
    ];
check_parser( $title, $confidence, $details, $location );


$title      = q(The Kevin Bishop Show - 1x05);
$confidence = 2;
$details    = {
        series  => 'The Kevin Bishop Show',
        season  => '1',
        episode => '05',
    };
$location   = [
        't/tv/The Kevin Bishop Show/Season 1',
        '05 - Episode 05.avi'
    ];
%check = %{ $details };
$check{'title'} = 'Episode 05';
check_parser( $title, $confidence, $details, $location, \%check );


$title      = q(Bones - 4x01-02 - Yanks in the U.K.);
$confidence = 4;
$details    = {
        series        => 'Bones',
        season        => '4',
        first_episode => '01',
        last_episode  => '02',
        episodes      => [ '01', '02' ],
        title         => 'Yanks in the U.K.',
    };
$location   = [
        't/tv/Bones/Season 4',
        '01-02 - Yanks in the U.K..avi'
    ];
check_parser( $title, $confidence, $details, $location );


$title      = q(Tyler Perry's Meet the Browns - 1x10-01x20);
$confidence = 2;
$details    = {
        series        => q(Tyler Perry's Meet the Browns),
        season        => '1',
        first_episode => '10',
        last_episode  => '20',
        episodes      => [ 
            '10', '11', '12', '13', '14', '15', 
            '16', '17', '18', '19', '20', 
         ],
    };
$location   = [
        "t/tv/Tyler Perry's Meet the Browns/Season 1",
        '10-20 - Episodes 10-20.avi'
    ];
%check = %{ $details };
$check{'title'} = 'Episodes 10-20';
check_parser( $title, $confidence, $details, $location, \%check );


# do not choke on punctuation in titles
$title      = q(House - 2x23 - Who's Your Daddy);
$confidence = 4;
$details    = {
        series  => 'House',
        season  => '2',
        episode => '23',
        title   => q(Who's Your Daddy),
    };
$location   = [
        't/tv/House/Season 2',
        q(23 - Who's Your Daddy.avi)
    ];
check_parser( $title, $confidence, $details, $location );


# do not choke on punctuation in series names
$title      = q(Grey's Anatomy - 5x03 - Here Comes the Flood);
$confidence = 4;
$details    = {
        series  => q(Grey's Anatomy),
        season  => '5',
        episode => '03',
        title   => 'Here Comes the Flood',
    };
$location   = [
        q(t/tv/Grey's Anatomy/Season 5),
        '03 - Here Comes the Flood.avi'
    ];
check_parser( $title, $confidence, $details, $location );


$title      = q(American Dad! - 5x12 - May the Best Stan Win);
$confidence = 4;
$details    = {
        series  => 'American Dad!',
        season  => '5',
        episode => '12',
        title   => 'May the Best Stan Win',
    };
$location   = [
        't/tv/American Dad!/Season 5',
        '12 - May the Best Stan Win.avi',
    ];
check_parser( $title, $confidence, $details, $location );


# sports series
$title      = q(NASCAR Nationwide Series 2009 - Round 01 - Daytona (Race));
$confidence = 3;
$details    = {
        series  => 'NASCAR Nationwide Series',
        season  => '2009',
        episode => '01',
        title   => 'Daytona (Race)',
    };
$location   = [
        't/tv/NASCAR Nationwide Series/Season 2009',
        '01 - Daytona (Race).avi'
    ];
check_parser( $title, $confidence, $details, $location );


# shows done by broadcast date, not season
$title      = q(The Daily Show - 2009-08-13 - Rachel McAdams);
$confidence = 3;
$details    = {
        series  => 'The Daily Show',
        season  => '2009',
        episode => '08.13',
        title   => 'Rachel McAdams',
    };
$location   = [
        't/tv/The Daily Show/Season 2009',
        '08.13 - Rachel McAdams.avi'
    ];
check_parser( $title, $confidence, $details, $location );


$title      = q(Vil Du Bli Millionr Hot Seat - 2010.01.04);
$confidence = 2;
$details    = {
        series  => 'Vil Du Bli Millionr Hot Seat',
        season  => '2010',
        episode => '01.04',
    };
$location   = [
        't/tv/Vil Du Bli Millionr Hot Seat/Season 2010',
        '01.04 - Episode 01.04.avi'
    ];
%check = %{ $details };
$check{'title'} = 'Episode 01.04';
check_parser( $title, $confidence, $details, $location, \%check );


# entire seasons
$title      = q(John Doe - Season 1);
$confidence = 1;
$details    = {
        series  => 'John Doe',
        season  => '1',
    };
$location   = [
        't/tv/John Doe/Season 1',
        ''
    ];
check_parser( $title, $confidence, $details, $location );


$title      = q(Are You Afraid Of The Dark? - Season Two);
$confidence = 1;
$details    = {
        series  => 'Are You Afraid Of The Dark?',
        season  => '2',
    };
$location   = [
        't/tv/Are You Afraid Of The Dark?/Season 2',
        ''
    ];
check_parser( $title, $confidence, $details, $location );


$title      = q(Battlestar Galactica (2004) - Season 4 [BD 4]);
$confidence = 2;
$details    = {
        series  => 'Battlestar Galactica (2004)',
        season  => '4',
        disk    => '4',
    };
$location   = [
        't/tv/Battlestar Galactica (2004)/Season 4',
        ''
    ];
%check = %{ $details };
delete $check{'disk'};
check_parser( $title, $confidence, $details, $location, \%check );


# mini-series have no season
$title      = q(Generation Kill (Mini-Series) [DVD 2/3]);
$confidence = 1;
$details    = {
        series => 'Generation Kill',
        disk   => '2',
    };
$location   = [
        't/tv/Generation Kill',
        ''
    ];
%check = %{ $details };
delete $check{'disk'};
check_parser( $title, $confidence, $details, $location, \%check );


$title      = q(You're Hired [DVD 6]);
$confidence = 1;
$details    = {
        series  => q(You're Hired),
        disk    => '6',
    };
$location   = [
        q(t/tv/You're Hired),
        ''
    ];
%check = %{ $details };
delete $check{'disk'};
check_parser( $title, $confidence, $details, $location, \%check );


$title      = q(You're Hired - 19-22 [DVD 5/5]);
$confidence = 2;
$details    = {
        series        => q(You're Hired),
        first_episode => '19',
        last_episode  => '22',
        episodes      => [ '19', '20', '21', '22' ],
        disk          => '5',
    };
$location   = [
        q(t/tv/You're Hired),
        '19-22 - Episodes 19-22.avi'
    ];
%check = %{ $details };
delete $check{'disk'};
$check{'title'} = 'Episodes 19-22';
check_parser( $title, $confidence, $details, $location, \%check );


$title      = q(Futurama Season 1 (DVD 1));
$confidence = 2;
$details    = {
        series  => 'Futurama',
        season  => '1',
        disk    => '1',
    };
$location   = [
        't/tv/Futurama/Season 1',
        ''
    ];
%check = %{ $details };
delete $check{'disk'};
check_parser( $title, $confidence, $details, $location, \%check );


# assume "Volume 1" means "Season 1"
$title      = q(Invader Zim Vol. 1 [DVD 1]);
$confidence = 2;
$details    = {
        series => 'Invader Zim',
        season => '1',
        disk   => '1',
    };
$location   = [
        't/tv/Invader Zim/Season 1',
        ''
    ];
%check = %{ $details };
delete $check{'disk'};
check_parser( $title, $confidence, $details, $location, \%check );


$title      = q(Looney Tunes Golden Collection (Vol. 2) [DVD 3]);
$confidence = 2;
$details    = {
        series  => 'Looney Tunes Golden Collection',
        season  => '2',
        disk    => '3',
    };
$location   = [
        't/tv/Looney Tunes Golden Collection/Season 2',
        ''
    ];
%check = %{ $details };
delete $check{'disk'};
check_parser( $title, $confidence, $details, $location, \%check );


$title      = q(Sherlock Holmes (1984) - Season 1 (DVD 4));
$confidence = 2;
$details    = {
        series  => 'Sherlock Holmes (1984)',
        season  => '1',
        disk    => '4',
    };
$location   = [
        't/tv/Sherlock Holmes (1984)/Season 1',
        ''
    ];
%check = %{ $details };
delete $check{'disk'};
check_parser( $title, $confidence, $details, $location, \%check );


$title      = q(30 Rock - Season 3 [DVD 2A]);
$confidence = 2;
$details    = {
        series  => '30 Rock',
        season  => '3',
        disk    => '2A',
    };
$location   = [
        't/tv/30 Rock/Season 3',
        ''
    ];
%check = %{ $details };
delete $check{'disk'};
check_parser( $title, $confidence, $details, $location, \%check );


# parse extras
$title      = q(The Big Bang Theory - Season 2 (Subpack));
$confidence = 1;
$details    = {
        series  => 'The Big Bang Theory',
        season  => '2',
        extra   => 'Subpack',
    };
$location   = [
        't/tv/The Big Bang Theory/Season 2',
        ''
    ];
%check = %{ $details };
delete $check{'extra'};
check_parser( $title, $confidence, $details, $location, \%check );


$title      = q(Star Trek: Deep Space Nine - Season 2 (DVD Extras));
$confidence = 1;
$details    = {
        series  => 'Star Trek: Deep Space Nine',
        season  => '2',
        extra   => 'DVD Extras',
    };
$location   = [
        't/tv/Star Trek: Deep Space Nine/Season 2',
        ''
    ];
%check = %{ $details };
delete $check{'extra'};
check_parser( $title, $confidence, $details, $location, \%check );


$title      = q(UFC 109: Relentless);
$confidence = 2;
$details    = {
        series  => 'UFC',
        episode => '109',
        title   => 'Relentless',
    };
$location   = [
        't/tv/UFC',
        '109 - Relentless.avi'
    ];
check_parser( $title, $confidence, $details, $location );


$title      = q(Bundesliga 2010 - Week 20: Highlights);
$confidence = 3;
$details    = {
        series  => 'Bundesliga',
        season  => '2010',
        title   => 'Week 20: Highlights',
        special => '1',
    };
$location   = [
        't/tv/Bundesliga/Season 2010',
        'Week 20: Highlights.avi'
    ];
check_parser( $title, $confidence, $details, $location );


$title      = q(2010 AMA Supercross Series - Supercross Class Round 5);
$confidence = 2;
$details    = {
        series  => 'AMA Supercross Series',
        season  => '2010',
        title   => 'Supercross Class Round 5',
    };
$location   = [
        't/tv/AMA Supercross Series/Season 2010',
        'Supercross Class Round 5.avi'
    ];
%check = %{ $details };
$check{'special'} = 1;
check_parser( $title, $confidence, $details, $location, \%check );


$title      = q(The Adventures of Pete and Pete - Complete Series);
$confidence = 1;
$details    = {
        series  => 'The Adventures of Pete and Pete',
        season  => '1',
    };
$location   = [
        't/tv/The Adventures of Pete and Pete/Season 1',
        ''
    ];
check_parser( $title, $confidence, $details, $location );


$title
    = q(Time Team - Sx18 - Londinium, Greater London - Edge of Empire);
$confidence = 3;
$details    = {
        series  => 'Time Team',
        episode => '18',
        title   => 'Londinium, Greater London - Edge of Empire',
        special => '1',
    };
$location   = [
        't/tv/Time Team/Specials',
        '18 - Londinium, Greater London - Edge of Empire.avi'
    ];
check_parser( $title, $confidence, $details, $location );


$title      = q(Top Gear - The Great Adventures Vietnam Special);
$confidence = 2;
$details    = {
        series  => 'Top Gear',
        title   => 'The Great Adventures Vietnam Special',
        special => '1',
    };
$location   = [
        't/tv/Top Gear/Specials',
        'The Great Adventures Vietnam Special.avi'
    ];
check_parser( $title, $confidence, $details, $location );


$title      = q(Howard Stern On Demand (Heidi Baron));
$confidence = 1;
$details    = {
        series  => 'Howard Stern On Demand',
        title   => 'Heidi Baron',
    };
$location   = [
        't/tv/Howard Stern On Demand',
        'Heidi Baron.avi'
    ];
check_parser( $title, $confidence, $details, $location );


$title      = q(Crop To Shop - Jimmy's Supermarket Secrets);
$confidence = 1;
$details    = {
        series  => 'Crop To Shop',
        title   => "Jimmy's Supermarket Secrets",
    };
$location   = [
        't/tv/Crop To Shop',
        "Jimmy's Supermarket Secrets.avi"
    ];
check_parser( $title, $confidence, $details, $location );


$title      = q(The Eloquent Ji Xiaolan IV - 18);
$confidence = 1;
$details    = {
        series  => 'The Eloquent Ji Xiaolan IV',
        episode => '18',
    };
$location   = [
        't/tv/The Eloquent Ji Xiaolan IV',
        "18 - Episode 18.avi"
    ];
%check = %{ $details };
$check{'title'} = 'Episode 18';
check_parser( $title, $confidence, $details, $location, \%check );

exit;



sub check_parser {
    my $title      = shift;
    my $confidence = shift;
    my $details    = shift;
    my $location   = shift;
    my $re_check   = shift 
                     // $details;
    
    # say "TITLE $title";
    # say "CONF  $confidence";
    # say "DETAILS\n" . Dumper $details;
    # say "LOCATION\n" . Dumper $location;
    # say "CHECK\n" . Dumper $re_check;
    
    my( $points, %details ) = $handler->parse_title_string( $title );
    ok( $points eq $confidence )
        or say "$title gives $points confidence, not $confidence";
    is_deeply( \%details, $details )
        or say "$title details:\n" . Dumper \%details;
    
    my @location = $handler->get_episode_location( \%details, '.avi' );
    is_deeply( \@location, $location )
        or say "$title location:\n" . Dumper \@location;
    
    my %check = $handler->details_from_location( join '/', @location );
    is_deeply( \%check, $re_check )
        or say "$title check:\n" . Dumper \%check;
}
