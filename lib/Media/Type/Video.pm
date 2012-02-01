use Modern::Perl;
use MooseX::Declare;

role Media::Type::Video {
    use File::Basename;
    
    has type => (
        isa     => 'Str',
        is      => 'ro',
        default => 'Video',
    );
    has details => (
        isa      => 'HashRef',
        is       => 'ro',
        required => 1,
    );
    
    
    method get_tag_elements {
        my @elements = (
                '--title', $self->details->{'title'},
            );
        
        my $series = $self->details->{'series'};
        if ( defined $series ) {
            push @elements, '--TVShowName', $series,
                            '--stik',       'TV Show';
        }
        
        return @elements;
    }
    method post_install {}
    
    method get_default_priority {
        return 50;
    }
    method get_processing_directory {
        return $self->get_job_name();
    }
    method get_destination_directory {
        my $single = $self->get_config( 'single_directory' );
        return $single if defined $single;
        
        my $series = $self->details->{'series'};
        my $title  = $self->details->{'title'};
        my $dir    = $self->get_config( 'video_directory' );
        
        if ( defined $series ) {
            $dir = $self->get_config( 'tv_directory' );
            return "${dir}/${series}";
        }
        
        return $dir;
    }
    method get_destination_filename {
        my( $file, $path, $ext ) = fileparse $self->details->{'title'}, 
                                                qr{ \. [^\.]+ $}x;
        return "$file.m4v", ;
    }
    
    method get_job_name {
        my( $file, $path, $ext ) = fileparse $self->details->{'title'}, 
                                                qr{ \. [^\.]+ $}x;
        return $file;
    }
    method parse_title_string ( $title, $hints? ) {
        my( $file, $path, $ext ) = fileparse $title, qr{ \. [^\.]+ $}x;
        
        # never wins, but can be explicitly chosen
        my $score   = 0;
        my %details = ( title => $file );
        
        %details = (
                %details,
                %$hints,
            )
            if defined $hints;
        
        return( $score, %details );
    }
}
