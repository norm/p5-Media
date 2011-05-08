p5-Media
========
Perl modules and scripts for handling the conversion and storage of bulky
media files, such as Movies, TV series and more.


Work in progress
----------------
This is still a work in progress and a little rough around the edges.
Documentation is definitely lacking. An (incomplete) todo list can be found 
in the file p5-Media.taskpaper.


Rationale
---------
You would use Media if most of the following is true:

*   you have a lot of TV/Movies on DVD, or in AVI, MKV, WMV, etc. formats
    that you want converted to a single format (typically MP4, compatible
    with iTunes, Apple TV, iPad and iPhone)
*   you want to be able to manage the conversions with a queue, using
    different priorities for different content
*   you want encoded files to be automatically added to iTunes for you
*   you want metadata such as genre, director and writer pulled from
    IMDb automatically and added to the converted file
*   you want your converted video to be stored in an organised directory
    structure, such as:
    -   /files/tv/House/Season 1/01 - Pilot.m4v
    -   /files/movies/Barbarella - X (1968)/Barbarella - X (1968).m4v


Typical use
-----------
After ripping a DVD using an application such as [RipIt][ripit] or
[DVD2One][dvd2one], I run `queue <dvdimage>` to produce a config file, then
edit that to name the Movie/TV show and tweak video, audio and subtitle
settings. I then run `queue <dvdimage>` again to add it to the queue.

Alternatively, if I have an existing video file (such as something previously
ripped into another format, or obtained from the internet), I name a directory
something suitable (eg. 'House - 1x01 - Pilot') and put the video file inside,
then run `queue <dirname>` to add it to the queue.

Once queueing some jobs, I run `encoder`. This will poll the queue for jobs
and re-encode them. It is a long-running process, so I typically run it under
[screen][screen]. More jobs can be added whilst `encoder` is running.

If I want to see what is currently being encoded, and what will be done next,
I just run `queue` without any other arguments. If I change my mind about a
job, I run `queue remove <name>` (where name can be a regexp pattern).

If I still have jobs in the queue, but want to stop encoding for some reason,
I will run either `encoder stop` to let the current encode finish first, or
`encoder abort`.

[ripit]:http://thelittleappfactory.com/ripit/
[dvd2one]:http://dvd2one.com/
[screen]:http://www.gnu.org/software/screen/


Installing
----------
Media requires [HandBrakeCLI][handbrake] 0.9.5,
[AtomicParsley][atomicparsley] 0.9.4,
and a _lot_ of other perl modules to be installed.

If you are not comfortable installing perl modules from CPAN, I would 
unequivocally recommend you do it using [cpanminus][cpanm], which makes
it trivial to install CPAN modules. First, install cpanminus:

    curl -L http://cpanmin.us | sudo perl - --self-upgrade

then use it to install Media and all of its dependencies:

    sudo cpanm https://github.com/norm/p5-Media/tarball/master


### Patching `IMDB::Film`

There is a long-standing bug in the CPAN module `IMDB::Film` used by Media
which means it cannot find ratings/certifications information. If this 
matters to you, replace the existing `certifications` method in the Film.pm
(found at /Library/Perl/5.10.0/IMDB/Film.pm on a Mac) with:

    sub certifications {
    	my CLASS_NAME $self = shift;
    	my $forced = shift || 0;
    	
    	my (%cert_list, $tag);
    	my $url = "http://". $self->{host} . "/" . $self->{query} .  $self->code . "/parentalguide#certification";
    	my $data = LWP::Simple::get($url);
    	my $parser = new HTML::TokeParser(\$data) or croak "[CRITICAL] Cannot create HTML parser: $!!";
    
    	while ($tag = $parser->get_tag('h5')) {
    		my $txt = $parser->get_text;
    		if ($txt =~ /certification/i) {
    			$parser->get_tag('div');
    			while ($tag = $parser->get_tag()) {
    				last if ($tag->[0] eq 'h3');
    				if ($tag->[0] eq 'a') {
    					$txt = $parser->get_text;
    					my($country, $range) = split /\:/, $txt;
    					$cert_list{$country} = $range;
    				}
    			}
    			$self->{_certifications} = \%cert_list;
    		}
    	}
    	return $self->{_certifications};
    }

Slightly altered from code found at
<https://rt.cpan.org/Public/Bug/Display.html?id=65201>.

[handbrake]:http://handbrake.fr/
[atomicparsley]:https://bitbucket.org/wez/atomicparsley/overview/
[cpanm]:https://github.com/miyagawa/cpanminus/


Read more
---------
Once installed, more documentation is available:

* `perldoc encoder`
* `perldoc queue`
* `perldoc Media::Tutorial`
* `perldoc Media::Config`
