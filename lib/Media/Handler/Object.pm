use Modern::Perl;
use MooseX::Declare;

class Media::Handler::Object {
    use File::Basename;
    use File::Copy;
    use File::Path          qw( mkpath );
    use String::Approx      qw( adistr );
    
    has config => (
        isa      => 'HashRef',
        is       => 'ro',
        required => 1,
    );
    
    
    method get_config ( Str $key, Str $section='' ) {
        return $self->config->{$section}{$key};
    }
    method get_conversion_directory {
        return sprintf "%s/%s",
            $self->config->{''}{'encode_directory'},
            $self->get_processing_directory();
    }
    method add_to_itunes {
        my $add = $self->get_config( 'add_to_itunes' );
        return unless defined $add and $add;
        
        my $destination = $self->get_destination_directory();
        my $filename    = $self->get_destination_filename();
        
        if ( $destination !~ m{^/} ) {
            say STDERR 'To add to iTunes, '
                     . 'destination paths must be absolute.';
            return;
        }
        
        system(
                'osascript',
                '-e',
                qq(
                    set new_file to POSIX file "$destination/$filename"
                    tell application "iTunes"
                        add new_file to playlist "Library" of source "Library"
                    end tell
                )
            );
    }
    
    method compare_titles ( $title, $imdb ) {
        $title = lc $title;
        $title =~ s{[^\w\s]+}{}g;
        $title =~ s{\s+}{ }g;
        
        my $imdb_title = lc $imdb->title();
        $imdb_title =~ s{[^\w\s]+}{}g;
        $imdb_title =~ s{\s+}{ }g;
        
        return abs adistr( $imdb_title, $title );
    }
    method move_file_with_unique_filename ( $source, $dir, $target? ) {
        $target = basename $source
            if !defined $target;
        
        my( $filename, $ext ) = $self->split_extension_filename( $target );
        
        my $destination = "${dir}/${target}";
        my $count       = 2;
        while ( -f $destination ) {
            $destination = "${dir}/${filename} (v${count}).${ext}";
            $count++;
        }
        
        mkpath $dir;
        move $source, $destination
            or die "move '${source}' '${destination}': $!";
        
        return $destination;
    }
    method split_extension_filename ( $filename ) {
        $filename =~ m{^ (.*?) (?: \. ([^\.]+) )? $}x;
        return( $1, $2 );
    }
    method get_handler ( $type, $medium, $details, $input='' ) {
        return Media::Handler->new(
                type        => $type,
                medium      => $medium,
                details     => $details,
                input       => $input,
                config      => $self->config,
            );
    }
}
