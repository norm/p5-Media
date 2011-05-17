use Modern::Perl;
use MooseX::Declare;

role Media::Type::MusicVideo {
    use WebService::MusicBrainz::Artist;
    use WebService::MusicBrainz::Release;
    use WebService::MusicBrainz::Track;
    
    has type => (
        isa     => 'Str',
        is      => 'ro',
        default => 'MusicVideo',
    );
    has details => (
        isa      => 'HashRef',
        is       => 'ro',
        required => 1,
    );
    
    
    method get_tag_elements {
        my @elements = (
                '--artist',         $self->details->{'artist'},
                '--album',          $self->details->{'album'},
                '--title',          $self->details->{'title'},
                '--stik',           'Music Video',
            );
        
        return @elements;
    }
    method post_install {}
    
    method get_default_priority {
        return 50;
    }
    method get_processing_directory {
        return $self->get_full_track_name();
    }
    method get_destination_directory {
        my $single = $self->get_config( 'single_directory' );
        return $single if defined $single;
        
        my $dir    = $self->get_config( 'music_directory' );
        my $subdir = $self->get_artist_album_directory();
        return "${dir}/${subdir}";
    }
    method get_destination_filename {
        return sprintf "%s.m4v", $self->details->{'title'};
    }
    method get_job_name {
        return $self->get_full_track_name();
    }
    
    method get_full_track_name {
        my $album = $self->details->{'album'} // '';
        $album = " $album"
            if length $album;
        
        return sprintf "%s [%s]%s",
                $self->details->{'title'},
                $self->details->{'artist'},
                $album;
    }
    method get_artist_album_directory {
        my $directory = $self->details->{'artist'};
        my $album     = $self->details->{'album'};
        
        $directory .= "/$album"
            if defined $album;
        
        return $directory;
    }
    
    method parse_title_string ( $title, $hints? ) {
        my $type = $hints->{'type'};
        return if defined $type && $type ne 'MusicVideo';
        
        # strip a potential pathname into the last element
        $title =~ s{ (?: .*? / )? ([^/]+) (?: / )? $}{$1}x;
        
        if ( defined $hints and defined $hints->{'strip_extension'} ) {
            $title =~ s{ \. [^\.]+ $}{}x;
            delete $hints->{'strip_extension'};
        }
        
        my $confidence = 0;
        my %details;
        
        # hints affect confidence
        $confidence += 2 if defined $hints->{'album'};
        $confidence += 2 if defined $hints->{'artist'};
        
        # music video title looks like:
        # (Waiting for) The Ghost Train [Madness]
        # Frontier Psychiatrist [The Avalanches] Since I Left You
        my $video_title = qr{
                ^
                    (?<title> .*? )
                    (?:
                        \s+ \[ (?<artist> .* ) \]
                        (?:
                            \s+ (?<album> .*? )
                        )?
                    )?
                $
            }x;
        
        if ( $title =~ $video_title ) {
            %details = %+;
            
            if ( defined %$hints ) {
                %details = (
                        %details,
                        %$hints,
                    );
            }
            
            return unless defined $details{'title'}
                       && defined $details{'artist'};
            
            $confidence += 1;
            
            my $search  = WebService::MusicBrainz::Artist->new();
            my $results = $search->search({ NAME => $details{'artist'} });
            my $artist  = $results->artist();
            
            $confidence += $artist->score * 0.025
                if defined $artist;
            
            $search   = WebService::MusicBrainz::Track->new();
            $results  = $search->search({
                    TITLE  => $details{'title'},
                    ARTIST => $details{'artist'},
                });
            my $track = $results->track();
            
            $confidence += $track->score * 0.025
                if defined $track;
            
            if ( defined $details{'album'} ) {
                $search   = WebService::MusicBrainz::Release->new();
                $results  = $search->search({
                        TITLE  => $details{'title'},
                        ARTIST => $details{'artist'},
                    });
                my $album = $results->release();
                
                $confidence += $album->score * 0.025
                    if defined $album;
            }
            
            return( $confidence, %details );
        }
        
        return;
    }
}
