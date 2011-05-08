package Media::Handler;

use Modern::Perl;
use Moose;
use Carp;

use Media::Handler::Object;
use namespace::autoclean;

sub new {
    my $class = shift;
    my %args  = @_;
    
    state %class_cache;
    
    my $type   = $args{'type'};
    my $medium = $args{'medium'};
    
    croak 'No type'
        unless defined $type;
    
    my @roles = ( "Media::Type::$type" );
    my $suffix = "with__${type}";
    
    if ( defined $medium ) {
        push @roles, "Media::Medium::$medium";
        $suffix .= "_$medium";
    }
    
    my $package = __PACKAGE__ . "::${suffix}";
    my $meta = $class_cache{$package};
    if ( !defined $meta ) {
        # create an anonymous class outfitted with the right role
        # (this is borrowed and heavily adapted from code in Net::Twitter)
        $meta = Media::Handler::Object->meta->create_anon_class(
                superclasses => [ 'Media::Handler::Object' ],
                roles        => \@roles,
                package      => $package,
            );
        # $meta->make_immutable(inline_constructor => 1);
    }
    
    # create the actual object, now that the right role is mixed in
    my $new = $meta->name->new(%args);
    
    return $new;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
