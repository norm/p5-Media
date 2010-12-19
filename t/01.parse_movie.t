use Modern::Perl;

use Data::Dumper::Concise;
use Media;
use Test::More      tests => 9;


my $media   = Media->new( config_file => 't/test_media.conf' );
my $handler = $media->get_handler_type( 'Movie' );
my $title;
my $details;
my $location;
my $confidence;



# $title   = q(Barbarella (1968));
# $details = {
#         title   => 'Barbarella',
#         rating  => 'X',              # this will be filled in by IMDB
#         year    => '1968',
#         feature => 1,
#     };
# $location = [
#         '/files/movies/All/Barbarella - X (1968)',
#         'Barbarella - X (1968).avi',
#     ];
# $confidence = 2;
# check_parser( $title, $details, $location, $confidence );


$title   = q(Serenity - 15 (2005));
$details = {
        title   => 'Serenity',
        rating  => '15',
        year    => '2005',
        feature => 1,
    };
$location = [
        '/files/movies/All/Serenity - 15 (2005)',
        'Serenity - 15 (2005).avi',
    ];
$confidence = 3;
check_parser( $title, $details, $location, $confidence );


$title   = q(Serenity - 15 (2005) - Deleted Scenes);
$details = {
        title  => 'Serenity',
        rating => '15',
        year   => '2005',
        extra  => 'Deleted Scenes',
    };
$location = [
        '/files/movies/All/Serenity - 15 (2005)',
        'Deleted Scenes.avi',
    ];
$confidence = 3;
check_parser( $title, $details, $location, $confidence );


$title   = q(Interstate 60 - 12 (2002));
$details = {
        title   => 'Interstate 60',
        rating  => '12',
        year    => '2002',
        feature => 1,
    };
$location = [
        '/files/movies/All/Interstate 60 - 12 (2002)',
        'Interstate 60 - 12 (2002).avi',
    ];
$confidence = 3;
check_parser( $title, $details, $location, $confidence );

exit;



sub check_parser {
    my $title    = shift;
    my $details  = shift;
    my $location = shift;
    
    # getting details fills in information from IMDB, but that is hard
    # to test, when it could vary over time
    my( $confidence, %details ) = $handler->parse_title_string( $title );
    delete $details{'actor'};
    delete $details{'company'};
    delete $details{'director'};
    delete $details{'writer'};
    delete $details{'genre'};
    delete $details{'plot'};
    
    is_deeply( \%details, $details )
        or say "$title details:\n" . Dumper \%details;
    
    my @location = $handler->get_movie_location( \%details, '.avi' );
    is_deeply( \@location, $location )
        or say "$title location:\n" . Dumper \@location;
    
    my %check = $handler->details_from_location( join '/', @location );
    is_deeply( \%check, \%details )
        or say "$title check:\n" . Dumper \%check;
}
