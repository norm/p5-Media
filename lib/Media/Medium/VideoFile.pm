use Modern::Perl;
use MooseX::Declare;

role Media::Medium::VideoFile {
    with 'Media::Encoder::HandBrake';
    with 'Media::Encoder::AtomicParsley';
    
    use File::Basename;
    
    use constant UNWANTED_FILE_TYPES => qw( nfo sfv nzb txt srr );
    use constant VIDEO_EXTENSIONS    => qw( 
        m4v  avi  mkv  mp4  mpg  wmv  vob  m2ts
    );
    
    has medium => (
        isa     => 'Str',
        is      => 'ro',
        default => 'VideoFile',
    );
    has input => (
        isa      => 'HashRef',
        is       => 'ro',
        required => 1,
    );
    
    
    method list_titles {
        my @titles = ( 1 );
        return @titles;
    }
    method install_content {
        my $converted   = $self->converted_file();
        my $destination = $self->get_destination_directory();
        my $filename    = $self->get_destination_filename();
        
        my $installed = $self->move_file_with_unique_filename(
                $converted,
                $destination,
                $filename,
            );
    }
    method clean_up_input {
        my $trash = $self->get_config('trash_files');
        
        if ( defined $trash && $trash ) {
            my $trash_dir = $self->get_config('trash_directory');
            
            if ( defined $trash_dir && $trash_dir ) {
                # get the last directory part of the input
                my $dir = dirname $self->input->{'file'};
                $dir =~ s{^ .*?/ ([^/]+) $}{$1}x;
            
                $self->move_file_with_unique_filename(
                        $self->input->{'file'},
                        $trash_dir,
                    );
                $self->move_file_with_unique_filename(
                        $self->input->{'poster'},
                        $trash_dir,
                    ) if defined $self->input->{'poster'}
                         && $self->input->{'poster'} !~ m{^ http\:\/\/ }x;
                $self->move_file_with_unique_filename(
                        $self->input->{'config'},
                        $trash_dir,
                        "${dir}-media.conf",
                    ) if defined $self->input->{'config'};
                
                rmdir dirname $self->input->{'file'};
            }
        }
    }
    
    method input_file {
        return $self->input->{'file'};
    }
    method input_title {
        return 1;
    }
    method can_use_medium ( $input ) {
        my $file;
        my $poster;
        my $config;
        
        if ( $self->is_video_file( $input ) ) {
            $file = $input;
        }
        else {
            $file = $self->directory_containing_video_file( $input );
            $poster = "$input/poster.png"
                if -f "$input/poster.png";
            $poster = "$input/poster.jpg"
                if -f "$input/poster.jpg";
            $config = "$input/media.conf"
                if -f "$input/media.conf";
        }
        
        my %details = (
                file   => $file,
                title  => 1,
            );
        $details{'poster'} = $poster
            if defined $poster;
        $details{'config'} = $config
            if defined $config;
        
        return \%details if defined $file;
    }
    method directory_containing_video_file ( $directory ) {
        return unless -d $directory;
        
        opendir my $handle, $directory
            or die "opendir $directory: $!";
        
        my $video;
        while ( my $file = readdir $handle ) {
            next if $file =~ m{^\.};
            my $target = "$directory/$file";
            
            unlink $target
                if $self->is_unwanted_file( $target );
            
            $video = $target
                if $self->is_video_file( $target );
        }
        
        return $video;
    }
    method is_video_file ( $file ) {
        return unless -f $file;
        
        if ( $file =~ m{ \. ([^\.]+) $}x ) {
            my $extension = $1;
            
            foreach my $try ( VIDEO_EXTENSIONS ) {
                return 1 if $try eq $extension;
            }
        }
        
        return 0;
    }
    method is_unwanted_file ( Str $filename ) {
        return 0 unless -f $filename;
        
        # do not want encoding samples
        return 1 if $filename =~ m{\bsample\b};
        
        if ( $filename =~ m{ \. ([^\.]+) $}x ) {
            my $extension = $1;
            
            # do not want partly-converted files
            return 1 if $filename eq $self->conversion_filename();
            
            # do not want most anciliary files
            foreach my $unwanted ( UNWANTED_FILE_TYPES ) {
                return 1 if $extension eq $unwanted;
            }
        }
        
        return 0;
    }
}
