use strict;
use warnings;

use Algorithm::Combinatorics qw(combinations);
use Math::Combinatorics;
use Benchmark qw(cmpthese);

our @data = 1..10;
our $n = 7;

sub acomb {
   my $iter = combinations(\@data, $n);
   1 while $iter->next;
}

sub mcomb {
    my $iter = Math::Combinatorics->new(count => $n, data => \@data);
    1 while $iter->next_combination;
}

cmpthese(-5, {
    acomb => \&acomb,
    mcomb => \&mcomb,
});

#         Rate mcomb acomb
# mcomb 87.5/s    --  -96%
# acomb 2282/s 2506%    --
