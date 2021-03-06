use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Media',
    AUTHOR              => 'Mark Norman Francis <norm@cackhanded.net>',
    VERSION_FROM        => 'lib/Media.pm',
    ABSTRACT_FROM       => 'lib/Media.pm',
    PL_FILES            => {},
    EXE_FILES           => [ 
        'bin/add-to-itunes',
        'bin/clean-srt',
        'bin/encoder',
        'bin/queue',
    ],
    PREREQ_PM => {
        'Capture::Tiny'           => 0,
        'Config::Std'             => 0,
        'Data::Dumper::Concise'   => 0,
        'HTTP::Lite'              => 0,
        'IMDB::Film'              => 0.49,
        'IO::All'                 => 0,
        'IPC::DirQueue'           => 0,
        'Modern::Perl'            => 0,
        'MooseX::Declare'         => 0,
        'Net::Discident'          => 0,
        'Storable'                => 0,
        'String::Approx'          => 0,
        'Term::ReadKey'           => 0,
        'Test::More'              => 0,
        'Text::Aspell'            => 0,
        'Text::Iconv'             => 0,
        'Time::Elapsed'           => 0,
        'version'                 => 0,
        'WebService::MusicBrainz' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Media-*' },
);
