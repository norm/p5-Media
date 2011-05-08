use Modern::Perl;
use MooseX::Declare;

role Media::Type::ConfigFile {
    use Config::Std;
    
    use constant MATCH_DEFAULT_VALUE => qr{^ \w+ _ \w+ }x;
    
    has details => (
        isa => 'HashRef',
        is  => 'rw',
    );
    has config_hash => (
        isa => 'Config::Std::Hash',
        is  => 'rw',
    );
    has type => (
        isa     => 'Str',
        is      => 'rw',
        default => 'ConfigFile',
    );
    
    
    method get_default_priority {
        my $handler = $self->get_handler(
                $self->type,
                'Empty',
                $self->details,
                $self->input,
            );
        
        return $handler->get_default_priority();
    }
    method get_job_name {
        my $handler = $self->get_handler(
                $self->type,
                'Empty',
                $self->details,
                $self->input,
            );
        
        return $handler->get_job_name();
    }
    method get_details ( $title ) {
        my $config_file = $self->input->{'config'};
        return unless defined $config_file && -f $config_file;
        
        read_config $config_file => my %config;
        my %details = (
                %{ $config{''} },
                %{ $config{ $title } },
            );
        
        $self->type( delete $details{'type'} );
        $self->input->{'title'}  = $title;
        $self->input->{'poster'} = delete $details{'poster'}
            if defined $details{'poster'};
        
        $self->details( \%details );
        
        return \%details;
    }
    
    method parse_title_string ( $title, $hints? ) {
        my $config_file = "$title/media.conf";
        return unless -f $config_file;
        
        read_config $config_file => my %config;
        if ( $self->unedited_config( %config ) ) {
            say STDERR "$config_file: has not been edited";
            return -1;
        }
        
        # win all arguments over type
        return( 100 );
    }
    method unedited_config ( %config ) {
        foreach my $key ( qw( poster rating season series title ) ) {
            return 1 if defined $config{''}{$key}
                     and $config{''}{$key} =~ MATCH_DEFAULT_VALUE;
        }
        
        foreach my $title ( keys %config ) {
            foreach my $key ( qw( episode title extra ) ) {
                return 1 if defined $config{$title}{$key}
                         and $config{$title}{$key} =~ MATCH_DEFAULT_VALUE;
            }
            return 1 if defined $config{$title}{'feature'} 
                     and defined $config{$title}{'extra'};
        }
        
        return 0;
    }
}
