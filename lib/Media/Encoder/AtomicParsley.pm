use Modern::Perl;
use MooseX::Declare;
use utf8;

role Media::Encoder::AtomicParsley {
    use Capture::Tiny   qw( capture tee );
    use File::Temp;
    use HTTP::Lite;
    use IO::All;
    
    use constant MATCH_ATOM      => qr{
        ^
            Atom \s+
            (?:
                "----" \s+ \[ ([^\]]+) \]
                |
                "([^"]+)"
            )
            \s+ contains: \s+ (.*)
    }x;
    use constant MATCH_SEPARATOR => qr{^\-+$};
    use constant MATCH_TRACK     => qr{
        ^
            \d+ \s+             # number
            (\w+) \s+           # type
            (.*?) \s+           # handler
            ([\w-]+) \s+        # kind
            (\w+) \s+           # lang
            (\d+) \s*           # bytes
        $
    }x;
    
    
    method add_metadata_to_content {
        my @elements = $self->get_tag_elements();
        my $file     = $self->converted_file();
        
        my $poster = $self->input->{'poster'};
        
        if ( defined $poster ) {
            if ( $poster =~ m{^ http\:\/\/ }x ) {
                $poster =~ m{ ( \. [^\.]+ ) $}x;
                my $temp = tmpnam() . $1;
                my $http = HTTP::Lite->new();
                my $code = $http->request( $poster );
                
                if ( 200 == $code ) {
                    $http->body() > io $temp;
                    $poster = $temp;
                }
                else {
                    undef $poster;
                }
            }
            
            push @elements, '--artwork', $poster
                if defined $poster;
        }
        
        system(
            'AtomicParsley',
            $file,
            '--overWrite',
            @elements,
        ) if scalar @elements;
    }
    
    method extract_metadata ( $file ) {
        my $output = capture {
            system(
                    'AtomicParsley',
                    $file,
                    '-t',
                    '+'
                );
        };
        
        return $self->parse_metadata( $output );
    }
    method parse_metadata ( $input ) {
        my %metadata;
        
        foreach my $line ( split( m/\n/, $input ) ) {
            given ( $line ) {
                when ( MATCH_ATOM ) {
                    my $atom  = $1 // $2;
                    my $value = $3;
                    
                    given ( $atom ) {
                        when ( 'stik' ) { $metadata{'kind'} = $value; }
                        when ( /.nam/ ) { $metadata{'title'} = $value; }
                        when ( /.gen/ ) { $metadata{'genre'} = $value; }
                        when ( /.day/ ) { $metadata{'year'} = $value; }
                        when ( /.alb/ ) { $metadata{'album'} = $value; }
                        when ( /.ART/ ) { $metadata{'artist'} = $value; }
                        when ( 'tvsh' ) { $metadata{'series'} = $value; }
                        when ( 'tvsn' ) { $metadata{'season'} = $value; }
                        when ( 'tves' ) { $metadata{'episode'} = $value; }
                        when ( 'tven' ) { $metadata{'episode_id'} = $value; }
                        when ( 'desc' ) { $metadata{'summary'} = $value; }
                        when ( 'ldes' ) { $metadata{'description'} = $value; }
                        when ( 'com.apple.iTunes;iTunEXTC' ) {
                            $metadata{'rating'} = $self->fix_rating( $value );
                        }
                        when ( 'covr' ) {
                            $value =~ m{^(\d+) };
                            $metadata{'artwork_count'} = $1;
                        }
                        when ( /.too/ ) {
                            # ignored -- encoder
                        }
                        when ( /com.apple.iTunes;iTunMOVI/ ) {
                            # ignored -- XML description file
                        }
                        default {
                            say "unknown atom - $atom: $value";
                        }
                    }
                }
                default {
                    # say $line;
                }
            }
        }
        return %metadata;
    }
    method fix_rating ( $rating ) {
        my @bits = split m{\|}, $rating;
        
        return $bits[1]
            if 3 == scalar @bits;
        return $bits[0];
    }
    method extract_tracks ( $file ) {
        my $output = capture {
            system(
                    'AtomicParsley',
                    $file,
                    '-T',
                    '1'
                );
        };
        
        return $self->parse_atom_tree( $output );
    }
    method parse_atom_tree ( $input ) {
        my @tracks;
        my $count = 0;
        
        foreach my $line ( split( m/\n/, $input ) ) {
            if ( $count < 2 ) {
                $count++
                    if $line =~ MATCH_SEPARATOR;
            }
            else {
                given ( $line ) {
                    when ( MATCH_TRACK ) {
                        push @tracks, {
                                type => $1,
                                kind => $3,
                            };
                    }
                    default {
                        # say " ** $line";
                    }
                }
            }
        }
        
        return @tracks;
    }
}
