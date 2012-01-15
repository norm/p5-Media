use Modern::Perl;
use Capture::Tiny   qw( capture_merged );
use Test::More      tests => 5;



# check the dependent software versions
my $output;
my $return;

{
    $output = capture_merged {
        system( 'HandBrakeCLI -t0 -i /dev/null' );
        $return = $? >> 8;
    };
    
    is( 0, $return, 'HandBrakeCLI installed' );
    
    # Check the version of HandbrakeCLI releases
    SKIP: {
        skip "HandbrakeCLI is built from source",
             1 if $output =~ m{^HandBrake rev([\d]+)}m;
        
        $output =~ m{^HandBrake ([\d\.]+)}m;
        is( '0.9.5', $1, 'HandBrakeCLI is the right version' );
    }
    # Check the version of HandbrakeCLI built from source
    SKIP: {
        skip "HandbrakeCLI is an official release",
             1 if $output =~ m{^HandBrake ([\d\.]+)}m;
        
        $output =~ m{^HandBrake rev([\d\.]+)}m;
        cmp_ok( '3736', '<=', $1, 'HandBrakeCLI is the right version' );
    }
}
{
    $output = capture_merged {
        system( 'AtomicParsley -h' );
        $return = $? >> 8;
    };
    
    is( 0, $return, 'AtomicParsley installed' );
    
    $output =~ m{^AtomicParsley version: ([\d\.]+)}m;
    is( '0.9.4', $1, 'AtomicParsley is the right version' );
}
