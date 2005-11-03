# -*- mode: CPerl -*-

use Algorithm::Combinatorics qw(combinations);

use strict;
use warnings;

use Test::More qw(no_plan);

my (@result, @expected, $iter);

# ---------------------------------------------------------------------

eval { combinations() };
ok($@, '');

eval { combinations([1]) };
ok($@, '');

eval { combinations(0, 0) };
ok($@, '');

eval { combinations([1], 0) };
ok($@, '');

eval { combinations([], 0) };
ok($@, '');

eval { combinations([1], 2) };
ok($@, '');


# ---------------------------------------------------------------------

@expected = (["foo"]);
@result = ();
$iter = combinations(["foo"], 1);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = combinations(["foo"], 1);
is_deeply(\@expected, \@result, "");

# ---------------------------------------------------------------------

@expected = (["foo"], ["bar"]);
@result = ();
$iter = combinations(["foo", "bar"], 1);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = combinations(["foo", "bar"], 1);
is_deeply(\@expected, \@result, "");


# ---------------------------------------------------------------------

@expected = (["foo", "bar"]);
@result = ();
$iter = combinations(["foo", "bar"], 2);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = combinations(["foo", "bar"], 2);
is_deeply(\@expected, \@result, "");


# ---------------------------------------------------------------------

@expected = (
    ["foo", "bar"],
    ["foo", "baz"],
    ["bar", "baz"],
);
@result = ();
$iter = combinations(["foo", "bar", "baz"], 2);
while (my @c = $iter->next) {
    push @result, [@c];
}


is_deeply(\@expected, \@result, "");

@result = combinations(["foo", "bar", "baz"], 2);
is_deeply(\@expected, \@result, "");

# ---------------------------------------------------------------------

@expected = (
    ["foo", "bar", "baz"],
    ["foo", "bar", "zoo"],
    ["foo", "baz", "zoo"],
    ["bar", "baz", "zoo"],
);
@result = ();
$iter = combinations(["foo", "bar", "baz", "zoo"], 3);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = combinations(["foo", "bar", "baz", "zoo"], 3);
is_deeply(\@expected, \@result, "");


# ----------------------------------------------------------------------

@expected = (
    [1, 2, 3],
    [1, 2, 4],
    [1, 2, 5],
    [1, 3, 4],
    [1, 3, 5],
    [1, 4, 5],
    [2, 3, 4],
    [2, 3, 5],
    [2, 4, 5],
    [3, 4, 5],
);
@result = ();
$iter = combinations([1..5], 3);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = combinations([1..5], 3);
is_deeply(\@expected, \@result, "");


# ----------------------------------------------------------------------

my $ncomb = 0;
$iter = combinations([1..20], 15);
while (my @c = $iter->next) {
    ++$ncomb;
}
is($ncomb, 15504, "");
