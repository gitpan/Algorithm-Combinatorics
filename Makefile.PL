use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Algorithm::Combinatorics',
    AUTHOR              => 'Xavier Noria <FXN@cpan.org>',
    VERSION_FROM        => 'lib/Algorithm/Combinatorics.pm',
    ABSTRACT_FROM       => 'lib/Algorithm/Combinatorics.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'FindBin'      => 0,
        'Test::More'   => 0,
        'Scalar::Util' => 0,
        'Inline::C'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Algorithm-Combinatorics-*' },
);
