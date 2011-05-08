use Modern::Perl;
use Capture::Tiny   qw( capture_merged );
use Test::More      tests => 4;



# check the dependent software versions
my $output;
my $return;

{
    $output = capture_merged {
        system( 'HandBrakeCLI -t0 -i /dev/null' );
        $return = $? >> 8;
    };
    
    is( 0, $return, 'HandBrakeCLI installed' );
    
    $output =~ m{^HandBrake ([\d\.]+)}m;
    is( '0.9.5', $1, 'HandBrakeCLI is the right version' );
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
