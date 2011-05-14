use Modern::Perl;
use Media;
use Test::More      tests => 42;



# check the filenames created for movie encodes
my $media    = Media->new( 't/conf/media.conf' );
my $media_tv = Media->new( 't/conf/movie_extras_as_tv.conf' );

# Barbarella (1968)
{
    my %details = (
            title   => 'Barbarella',
            year    => '1968',
            rating  => 'X',
            feature => 1,
        );
    my $handler    = $media->get_handler( 'Movie', 'Empty', \%details );
    my $handler_tv = $media_tv->get_handler( 'Movie', 'Empty', \%details );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/Barbarella - X (1968)) );
    is( $handler->get_destination_directory(),
        q(xt/movies/All/Barbarella - X (1968)) );
    is( $handler->get_destination_filename(),
        q(Barbarella - X (1968).m4v) );
    is( $handler_tv->get_conversion_directory(),
        q(xt/encode/Barbarella - X (1968)) );
    is( $handler_tv->get_destination_directory(),
        q(xt/movies/All) );
    is( $handler_tv->get_destination_filename(),
        q(Barbarella - X (1968).m4v) );
    is( $handler->get_job_name(),
        q(Barbarella - X (1968)) );
    
    %details = (
            title   => 'Barbarella',
            feature => 1,
        );
    $handler    = $media->get_handler( 'Movie', 'Empty', \%details );
    $handler_tv = $media_tv->get_handler( 'Movie', 'Empty', \%details );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/Barbarella) );
    is( $handler->get_destination_directory(),
        q(xt/movies/All/Barbarella) );
    is( $handler->get_destination_filename(),
        q(Barbarella.m4v) );
    is( $handler_tv->get_conversion_directory(),
        q(xt/encode/Barbarella) );
    is( $handler_tv->get_destination_directory(),
        q(xt/movies/All) );
    is( $handler_tv->get_destination_filename(),
        q(Barbarella.m4v) );
    is( $handler->get_job_name(),
        q(Barbarella) );
}

# Star Trek II: The Wrath of Khan (1982)
{
    my %details = (
            title   => 'Star Trek II - The Wrath of Khan',
            year    => '1982',
            rating  => '12',
            feature => 1,
        );
    my $handler    = $media->get_handler( 'Movie', 'Empty', \%details );
    my $handler_tv = $media_tv->get_handler( 'Movie', 'Empty', \%details );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/Star Trek II - The Wrath of Khan - 12 (1982)) );
    is( $handler->get_destination_directory(),
        q(xt/movies/All/Star Trek II - The Wrath of Khan - 12 (1982)) );
    is( $handler->get_destination_filename(),
        q(Star Trek II - The Wrath of Khan - 12 (1982).m4v) );
    is( $handler_tv->get_conversion_directory(),
        q(xt/encode/Star Trek II - The Wrath of Khan - 12 (1982)) );
    is( $handler_tv->get_destination_directory(),
        q(xt/movies/All) );
    is( $handler_tv->get_destination_filename(),
        q(Star Trek II - The Wrath of Khan - 12 (1982).m4v) );
    is( $handler->get_job_name(),
        q(Star Trek II - The Wrath of Khan - 12 (1982)) );
}

# DVD extras from Serenity (2005)
{
    my %details = (
            title   => 'Serenity',
            year    => '2005',
            rating  => '15',
            feature => 1,
        );
    my $handler    = $media->get_handler( 'Movie', 'Empty', \%details );
    my $handler_tv = $media_tv->get_handler( 'Movie', 'Empty', \%details );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/Serenity - 15 (2005)) );
    is( $handler->get_destination_directory(),
        q(xt/movies/All/Serenity - 15 (2005)) );
    is( $handler->get_destination_filename(),
        q(Serenity - 15 (2005).m4v) );
    is( $handler_tv->get_conversion_directory(),
        q(xt/encode/Serenity - 15 (2005)) );
    is( $handler_tv->get_destination_directory(),
        q(xt/movies/All) );
    is( $handler_tv->get_destination_filename(),
        q(Serenity - 15 (2005).m4v) );
    is( $handler->get_job_name(),
        q(Serenity - 15 (2005)) );

    delete $details{'feature'};
    $details{'extra'} = 'Deleted Scenes';
    $handler    = $media->get_handler( 'Movie', 'Empty', \%details );
    $handler_tv = $media_tv->get_handler( 'Movie', 'Empty', \%details );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/Serenity - 15 (2005) - Deleted Scenes) );
    is( $handler->get_destination_directory(),
        q(xt/movies/All/Serenity - 15 (2005)) );
    is( $handler->get_destination_filename(),
        q(Deleted Scenes.m4v) );
    is( $handler_tv->get_conversion_directory(),
        q(xt/encode/Serenity - 15 (2005) - Deleted Scenes) );
    is( $handler_tv->get_destination_directory(),
        q(xt/tv/DVD Extras/Serenity - 15 (2005)) );
    is( $handler_tv->get_destination_filename(),
        q(Deleted Scenes.m4v) );
    is( $handler->get_job_name(),
        q(Serenity - 15 (2005) - Deleted Scenes) );

    delete $details{'year'};
    delete $details{'rating'};
    $details{'extra'} = 'Gag Reel';
    $handler    = $media->get_handler( 'Movie', 'Empty', \%details );
    $handler_tv = $media_tv->get_handler( 'Movie', 'Empty', \%details );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/Serenity - Gag Reel) );
    is( $handler->get_destination_directory(),
        q(xt/movies/All/Serenity) );
    is( $handler->get_destination_filename(),
        q(Gag Reel.m4v) );
    is( $handler_tv->get_conversion_directory(),
        q(xt/encode/Serenity - Gag Reel) );
    is( $handler_tv->get_destination_directory(),
        q(xt/tv/DVD Extras/Serenity) );
    is( $handler_tv->get_destination_filename(),
        q(Gag Reel.m4v) );
    is( $handler->get_job_name(),
        q(Serenity - Gag Reel) );
}
