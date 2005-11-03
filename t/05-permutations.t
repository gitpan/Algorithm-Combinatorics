# -*- mode: CPerl -*-

use Algorithm::Combinatorics qw(permutations);

use strict;
use warnings;

use Test::More qw(no_plan);

my (@result, @expected, $iter);


# ---------------------------------------------------------------------

eval { permutations() };
ok($@, '');

eval { permutations(0) };
ok($@, '');

eval { permutations([]) };
ok($@, '');


# ---------------------------------------------------------------------

@expected = (["foo"]);
@result = ();
$iter = permutations(["foo"]);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = permutations(["foo"]);
is_deeply(\@expected, \@result, "");


# ---------------------------------------------------------------------

@expected = (
    ["foo", "bar"],
    ["bar", "foo"],
);
@result = ();
$iter = permutations(["foo", "bar"]);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = permutations(["foo", "bar"]);
is_deeply(\@expected, \@result, "");

# ---------------------------------------------------------------------

@expected = (
    ["foo", "bar", "baz"],
    ["foo", "baz", "bar"],
    ["bar", "foo", "baz"],
    ["bar", "baz", "foo"],
    ["baz", "foo", "bar"],
    ["baz", "bar", "foo"],
);
@result = ();
$iter = permutations(["foo", "bar", "baz"]);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = permutations(["foo", "bar", "baz"]);
is_deeply(\@expected, \@result, "");


# ----------------------------------------------------------------------

# n!
my $ncomb = 0;
$iter = permutations([1..7]);
while (my @c = $iter->next) {
    ++$ncomb;
}
is($ncomb, 5040, "");

