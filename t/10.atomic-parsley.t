use Modern::Perl;
use IO::All;
use Media;
use Test::More      tests => 6;



# check the parsing of AtomicParsley output
my $media   = Media->new( 't/conf/media.conf' );
my $handler = $media->get_empty_handler( 'Movie', 'VideoFile' );

{
    my $content < io 't/atomic-parsley/barbarella_tags.txt';
    my %metadata = $handler->parse_metadata( $content );
    
    is_deeply(
            \%metadata,
            {
                artist        => 'Roger Vadim',
                artwork_count => '1',
                genre         => 'Adventure',
                kind          => 'Movie',
                rating        => 'X',
                title         => 'Barbarella',
                year          => '1968',
            }
        );
}
{
    my $content < io 't/atomic-parsley/barbarella_atom.txt';
    my @atoms = $handler->parse_atom_tree( $content );
    
    is_deeply(
            \@atoms,
            [
                {
                    kind => 'avc1',
                    type => 'vide',
                },
                {
                    kind => 'ac-3',
                    type => 'soun',
                },
                {
                    kind => 'mp4a',
                    type => 'soun',
                },
            ]
        );
}
{
    my $content < io 't/atomic-parsley/serenity_tags.txt';
    my %metadata = $handler->parse_metadata( $content );
    
    is_deeply(
            \%metadata,
            {
                artwork_count => 1,
                artist        => 'Joss Whedon',
                description   => 'In the future, a spaceship called Serenity is harboring a passenger with a deadly secret. Six rebels on the run. An assassin in pursuit. When the renegade crew of Serenity agrees to hide a fugitive on their ship, they find themselves in an awesome action-packed battle between the relentless military might of a totalitarian regime who will destroy anything - or anyone - to get the girl back and the bloodthirsty creatures who roam the uncharted areas of space. But, the greatest danger of all may be on their ship.',
                genre         => 'Action',
                kind          => 'Movie',
                rating        => '15',
                summary       => 'In the future, a spaceship called Serenity is harboring a passenger with a deadly secret. Six rebels on the run. An assassin in pursuit. When the renegade crew of Serenity agrees to hide a fugitive on their ship, they find themselves in an awesome action-p',
                title         => 'Serenity',
                year          => '2005',
            }
        );
}

$handler = $media->get_empty_handler( 'TV', 'VideoFile' );
{
    my $content < io 't/atomic-parsley/bsg_tags.txt';
    my %metadata = $handler->parse_metadata( $content );
    
    is_deeply(
            \%metadata,
            {
                kind       => 'TV Show',
                series     => 'Battlestar Galactica (2003)',
                season     => '1',
                episode    => '3',
                episode_id => '1x03',
                title      => 'Bastille Day',
            }
        );
    
}
{
    my $content < io 't/atomic-parsley/bsg_atom.txt';
    my @atoms = $handler->parse_atom_tree( $content );
    
    is_deeply(
            \@atoms,
            [
                {
                    kind => 'avc1',
                    type => 'vide',
                },
                {
                    kind => 'ac-3',
                    type => 'soun',
                },
                {
                    kind => 'mp4a',
                    type => 'soun',
                },
            ]
        );
    
}

$handler = $media->get_empty_handler( 'MusicVideo', 'VideoFile' );
{
    my $content < io 't/atomic-parsley/ghost_train_tags.txt';
    my %metadata = $handler->parse_metadata( $content );
    
    is_deeply(
            \%metadata,
            {
                artist => 'Madness',
                album  => 'Utter Madness',
                title  => '(Waiting for) The Ghost Train',
                kind   => 'Music Video',
            }
        );
    
}
