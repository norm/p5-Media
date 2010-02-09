package Media::Handler;

use Modern::Perl;
use MooseX::FollowPBP;
use Moose;
use MooseX::Method::Signatures;

use File::Temp;
use IO::All             -utf8;
use IO::CaptureOutput   qw( capture_exec );
use Readonly;

Readonly my $CONVERSION_FILE     => 'Z-conversion.m4v';
Readonly my $CONVERTED_FILE      => 'Z-converted.m4v';
Readonly my @UNWANTED_FILE_TYPES => qw( .nfo .sfv .nzb .txt .srr );

has media => (
        isa => 'Media',
        is  => 'ro',
    );



method install_from ( Str $directory, Int $priority ) {
    opendir( my $handle, $directory );
    
    ENTRY:
    while ( my $entry = readdir $handle ) {
        next if $entry =~ m{^\.};
        
        my $target = "${directory}/${entry}";
        
        # remove unwanted files first
        if ( $self->is_unwanted_file( $entry ) ) {
            unlink $target
                or $self->write_log( "ERROR: unlink $target: $!" );
        }
        
        # television and movies get stored in specific locations,
        # (this then adds them to iTunes by _opening_ the file in iTunes)
        elsif ( $CONVERTED_FILE eq $entry ) {
            $self->install_file( $directory, $entry );
        }
        
        # add other video files to the conversion queue
        elsif ( $self->is_video_file( $entry ) ) {
            $self->convert_video( $directory, $entry, $priority );
        }
        
        # 
        elsif ( 'poster.jpg' eq $entry ) {
            next ENTRY;
        }
        
        else {
            $self->write_log( "UNKNOWN FILE '${directory}/${entry}'" );
        }
    }
    closedir $handle;
    
    # there is no error condition if this fails (as it
    # may contain files still to be processed)
    rmdir $directory;
}
method is_unwanted_file ( Str $filename ) {
    my $extension = $self->get_file_extension( $filename );
    
    # do not want encoding samples
    return 1 if $filename =~ m{\bsample\b};
    
    # do not want partly-converted files
    return 1 if $filename eq $CONVERSION_FILE;
    
    # do not want most anciliary files
    foreach my $unwanted ( @UNWANTED_FILE_TYPES ) {
        return 1 if $extension eq $unwanted;
    }
}
method is_video_file ( Str $filename ) {
    my $extension = $self->get_file_extension( $filename );
    
    return ( '.m4v' eq $extension ) ? 1
         : ( '.avi' eq $extension ) ? 1
         : ( '.mkv' eq $extension ) ? 1
                                    : 0;
}
method convert_video ( Str $directory, Str $file, Int $priority ) {
    my $extension = $self->get_file_extension( $file );
    my $media     = $self->get_media();
    my $target    = "${directory}/${file}";
    
    $self->write_log( "queue conversion: ${target}" );
    $media->queue_conversion( 
            {
                'filename'      => $target,
                'directory'     => $directory,
            },
            $priority,
        );
}
method add_to_itunes ( Str $file ) {
    my $add_to_itunes = $self->get_config( 'add_to_itunes' );
    
    if ( defined $add_to_itunes && $add_to_itunes ) {
        system( 'add-to-itunes', $file );
    }
}

method strip_type_hint ( Str $type ) {
    my ( $hint, $name ) = $self->parse_type_for_hint( $type );
    return $name;
}
method parse_type_for_hint ( Str $type ) {
    if ( $type =~ m{^ ( [A-Z]+ ) \s+ -- \s+ (.*) $}x ) {
        return( $1, $2 );
    }
    return( undef, $type );
}
method strip_leading_directories ( Str $path ) {
    # only attempt this on actual filenames that
    # contain more than one path element
    if ( index( $path, '/' ) > -1 ) {
        # strip trailing slashes
        $path =~ s{/$}{};
        
        # strip leading path elements
        $path =~ s{^ .*/ }{}x;
    }
    
    return $path;
}
method get_file_extension ( Str $filename ) {
    my( undef, undef, $extension ) = $self->get_path_segments( $filename );
    
    return $extension;
}
method get_path_segments ( Str $filename ) {
    $filename =~ m{
            ^ 
            ( .*/ )?            # optional dirname
            ( [^/]+? )          # file
            ( \. [^\./]+ )?     # optional extension
            $
        }x;
    
    return( $1, $2, $3 );
}

method safely_move_file ( Str $from, Str $directory, Str $to ) {
    my $media = $self->get_media();
    
    $media->safely_move_file( $from, $directory, $to );
}

method get_config ( Str $key, Str $block = '' ) {
    my $media = $self->get_media();
    return $media->get_config( $key, $block );
}
method write_log ( Str $text ) {
    my $media = $self->get_media();
    
    $media->write_log( $text );
}

1;
