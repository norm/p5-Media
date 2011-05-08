use Modern::Perl;
use MooseX::Declare;

role Media::Medium::DVD {
    with 'Media::Encoder::HandBrake';
    with 'Media::Encoder::AtomicParsley';
    
    use Config::Std;
    use POSIX;
    
    my $numerically = sub {
        my $a_num = $a;
        my $b_num = $b;
        $a_num = -1 if !isdigit $a;
        $b_num = -1 if !isdigit $b;
        return $a_num <=> $b_num;
    };
    
    has medium => (
        isa     => 'Str',
        is      => 'ro',
        default => 'DVD',
    );
    has input => (
        isa      => 'HashRef',
        is       => 'ro',
        required => 1,
    );
    has titles => (
        isa     => 'Config::Std::Hash',
        is      => 'ro',
        builder => 'build_titles',
        lazy    => 1,
    );
    
    method build_titles {
        read_config $self->input->{'config'} => my %config;
        return \%config;
    }
    
    
    method list_titles {
        my @titles;
        
        foreach my $title ( keys %{ $self->titles } ) {
            next if ''  eq $title;
            
            my $ignore = $self->titles->{$title}{'ignore'};
            next if defined $ignore
                 and $ignore;
            
            push @titles, $title;
        }
        
        return sort $numerically @titles;
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
        # multiple videos in a single DVD image mean we can't delete it
    }
    
    method input_file {
        return $self->input->{'image'};
    }
    method can_use_medium ( $input ) {
        my $dvd_image = "$input/VIDEO_TS";
        my $config    = "$input/media.conf";
        
        if ( -d $dvd_image ) {
            if ( -f $config ) {
                return {
                    image  => $input,
                    config => $config,
                };
            }
            else {
                say STDERR "$input has no configuration file -- creating one";
                $self->create_config_file( $input );
            }
        }
        
        return;
    }
}
