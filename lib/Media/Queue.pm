use Modern::Perl;
use MooseX::Declare;

role Media::Queue {
    use IPC::DirQueue;
    use POSIX;
    use Storable        qw( freeze thaw );
    
    use constant LOWEST_PRIORITY  => 99;
    use constant HIGHEST_PRIORITY => 2;
    
    has queue_directory => (
        isa      => 'Str',
        is       => 'ro',
        required => 1,
    );
    has queue => (
        isa     => 'IPC::DirQueue',
        is      => 'ro',
        lazy    => 1,
        builder => 'build_queue',
    );
    
    method build_queue {
        return IPC::DirQueue->new({
            dir                  => $self->queue_directory,
            active_file_lifetime => ( 6 * 3600 ),
        });
    }
    
    
    method queue_conversion ( $handler, $priority, $extra_args? ) {
        my @titles = $handler->list_titles();
        
        foreach my $title ( @titles ) {
            # populate this before the next use of $handler so values are set 
            # correctly when using a config file rather than the title string
            my $source_details;
            if ( $handler->can( 'get_details' ) ) {
                $source_details = $handler->get_details( $title );
            }
            else {
                $source_details = $handler->get_input_track_details();
            }
            
            my %input = %{ $handler->input };
            $input{'media_conf'} = $self->config_file;
            
            $extra_args = {}
                if !defined $extra_args;
            
            my %details = (
                    %$source_details,
                    %$extra_args,
                );
            
            my $name    = $handler->get_job_name();
            my %payload = (
                    details    => \%details,
                    input      => \%input,
                    medium     => $handler->medium,
                    name       => $name,
                    type       => $handler->type,
                );
            
            $priority = $handler->get_default_priority()
                if !defined $priority or !isdigit $priority;
            $priority = HIGHEST_PRIORITY
                if $priority < HIGHEST_PRIORITY;
            $priority = LOWEST_PRIORITY
                if $priority > LOWEST_PRIORITY;
            
            $self->queue->enqueue_string(
                    freeze( \%payload ),
                    undef,
                    $priority
                );
            
            say " -> queued [$priority] $name";
        }
    }
    method queue_stop_command {
        my %payload  = ( stop_encoder => 1 );
        $self->queue->enqueue_string( 
                freeze( \%payload ),
                undef,
                1
            );
    }
    
    method next_queue_job {
        my $job     = $self->queue->wait_for_queued_job();
        my $payload = $job->get_data();
        
        return( $job, thaw $payload );
    }
    method queue_count {
        my $queue   = $self->queue;
        my $count   = 0;
        my $visitor = sub { $count++; };
        
        $queue->visit_all_jobs( $visitor );
        
        return $count;
    }
    method queue_list_jobs {
        my $queue = $self->queue;
        my @jobs;
        
        my $visitor = sub {
                my $context = shift;
                my $job     = shift;
                my $payload = $job->get_data();
                my $id      = $job->{'jobid'};
                my $handler = $job->{'active_pid'};
                my $running = 0;
                
                $running = 1
                    if defined $handler && kill 0, $handler;
                
                push @jobs, {
                        handler  => $handler,
                        running  => $running,
                        priority => substr( $id, 0, 2 ),
                        payload  => thaw( $payload ),
                        path     => $job->{'pathqueue'},
                    };
            };
        
        $queue->visit_all_jobs( $visitor );
        
        return @jobs;
    }
    method remove_from_queue ( $match ) {
        my $queue = $self->queue;
        
        my $visitor = sub {
                my $context = shift;
                my $job     = shift;
                my $payload = thaw $job->get_data();
                my $path    = $job->{'pathqueue'};
                my $handler = $job->{'active_pid'};
                my $running = 0;
                
                $running = 1
                    if defined $handler && kill 0, $handler;
                
                # can't remove what is being processed
                return if $running;
                
                if ( $payload->{'name'} =~ $match ) {
                    my $pickup = $queue->pickup_queued_job( path => $path );
                    
                    if ( defined $pickup ) {
                        $pickup->finish();
                        say STDERR " -> remove " . $payload->{'name'};
                    }
                }
            };
        
        $queue->visit_all_jobs( $visitor );
    }
    method queue_clear {
        my $verbose = shift;
        
        my $queue = $self->queue;
        
        while ( 1 ) {
            my $job = $queue->pickup_queued_job();
            last unless defined $job;
            
            my $payload = thaw $job->get_data();
            say STDERR " -> removing " . $payload->{'name'}
                if defined $verbose;
            
            $job->finish();
        }
    }
}