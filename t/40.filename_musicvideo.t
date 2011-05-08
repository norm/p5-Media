use Modern::Perl;
use Media;
use Test::More      tests => 12;



# check the filenames created for music video encodes
my $media = Media->new( 't/conf/media.conf' );

{
    my %details = (
            title  => '(Waiting for) The Ghost Train',
            artist => 'Madness',
        );
    my $handler = $media->get_handler( 'MusicVideo', 'Empty', \%details );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/(Waiting for) The Ghost Train [Madness]) );
    is( $handler->get_destination_directory(),
        q(xt/music/Madness) );
    is( $handler->get_destination_filename(),
        q((Waiting for) The Ghost Train.m4v) );
    is( $handler->get_job_name(),
        q((Waiting for) The Ghost Train [Madness]) );
    
    $details{'album'} = 'Utter Madness';
    $handler = $media->get_handler( 'MusicVideo', 'Empty', \%details );
    is( $handler->get_conversion_directory(),
        q(xt/encode/(Waiting for) The Ghost Train [Madness] Utter Madness) );
    is( $handler->get_destination_directory(),
        q(xt/music/Madness/Utter Madness) );
    is( $handler->get_destination_filename(),
        q((Waiting for) The Ghost Train.m4v) );
    is( $handler->get_job_name(),
        q((Waiting for) The Ghost Train [Madness] Utter Madness) );
}
{
    my %details = (
            title  => 'Thriller',
            artist => 'Michael Jackson',
        );
    my $handler = $media->get_handler( 'MusicVideo', 'Empty', \%details );
    
    is( $handler->get_conversion_directory(),
        q(xt/encode/Thriller [Michael Jackson]) );
    is( $handler->get_destination_directory(),
        q(xt/music/Michael Jackson) );
    is( $handler->get_destination_filename(),
        q(Thriller.m4v) );
    is( $handler->get_job_name(),
        q(Thriller [Michael Jackson]) );
}
