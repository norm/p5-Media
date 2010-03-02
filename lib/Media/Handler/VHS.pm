package Media::Handler::VHS;

use Modern::Perl;
use MooseX::FollowPBP;
use Moose;
use MooseX::Method::Signatures;

extends 'Media::Handler';

use Config::Std;
use File::Path;
use FileHandle;
use IO::CaptureOutput   qw( capture_exec );



method is_type ( Str $name ) {
    # there are no clues to what makes a VHS file, other than deliberately
    # marking the type with a hint: "VHS -- Midnight Caller - 1x01 - Pilot"
    # (the code for which lives in Handler.pm not here)
    return;
}

method install_from ( Str $directory, Int $priority ) {
    # VHS movies/tv shows should be dealt with the same as those from other
    # sources, but just with extra options to the encoder
    my $name = $self->strip_type_hint( $directory );
    
    my $media = $self->get_media();
    my $type  = $media->determine_type( $name );
    
    if ( !defined $type ) {
        $self->write_log( "ERROR: $name has no known type" );
        return;
    }
    
    my $handler = $media->get_handler_type( $type );
    $handler->install_from( 
            $directory,
            $priority,
            {
                source_type => 'VHS',
            }
        );
}

1;
