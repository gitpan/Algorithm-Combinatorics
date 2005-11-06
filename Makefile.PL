use strict;
use warnings;
use Inline::MakeMaker;

WriteInlineMakefile(
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

# workaround for known error No rule to make target ... needed by `pure_all'
open my $mk, 'Makefile' or die $!;
my $text = do { local $/; <$mk> };
close $mk;

$text =~ s/^[.]pm[.]inl:/Combinatorics.inl:/xms;

open $mk, '>', 'Makefile' or die $!;
print $mk $text;
close $mk;
