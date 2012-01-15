package Media;

use Modern::Perl;
use Cwd;
use Media::Config;
use Media::Object;

use version;
our $VERSION = qv( 0.10.5 );

sub new {
    my $class       = shift;
    my $config_file = shift;
    
    if ( !defined $config_file ) {
        $config_file = $ENV{'MEDIA_CONFIG'}
                       // "$ENV{'HOME'}/etc/media.conf";
    }
    
    if ( $config_file !~ m{^/} ) {
        $config_file = sprintf '%s/%s',
                        getcwd(),
                        $config_file;
    }
    
    my %config = get_configuration $config_file;
    
    return Media::Object->new(
        %{ $config{''} },
        full_configuration => \%config,
        config_file        => $config_file,
    );
}

1;
