use strict;
use warnings;

use Algorithm::Combinatorics qw(derangements);
use Math::Combinatorics;
use Benchmark qw(cmpthese);

our @data = 1..8;

sub ader {
   my $iter = derangements(\@data);
   1 while $iter->next;
}

sub mder {
    my $iter = Math::Combinatorics->new(data => \@data);
    1 while $iter->next_derangement;
}

cmpthese(-5, {
    ader => \&ader,
    mder => \&mder,
});

#        Rate  mder  ader
# mder 1.45/s    --  -93%
# ader 19.9/s 1272%    --
