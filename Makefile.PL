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
        'bin/convert',
        'bin/encoder',
        'bin/media', 
    ],
    PREREQ_PM => {
        'Config::Std'                => 0,
        'Data::Dumper::Concise'      => 0,
        'IMDB::Film'                 => 0,
        'IO::All'                    => 0,
        'IO::CaptureOutput'          => 0,
        'IPC::DirQueue'              => 0,
        'LWP::UserAgent'             => 0,
        'Modern::Perl'               => 0,
        'Moose'                      => 0,
        'MooseX::FollowPBP'          => 0,
        'MooseX::Method::Signatures' => 0,
        'Readonly'                   => 0,
        'Storable'                   => 0,
        'Term::ReadKey'              => 0,
        'Test::More'                 => 0,
        'Text::Aspell'               => 0,
        'Text::Iconv'                => 0,
        'Time::Elapsed'              => 0,
        'TryCatch'                   => 0,
        'version'                    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Media-*' },
);
