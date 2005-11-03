# -*- mode: CPerl -*-

use Algorithm::Combinatorics qw(variations);

use strict;
use warnings;

use Test::More qw(no_plan);

my (@result, @expected, $iter);


# ---------------------------------------------------------------------

eval { variations() };
ok($@, '');

eval { variations([1]) };
ok($@, '');

eval { variations(0, 0) };
ok($@, '');

eval { variations([1], 0) };
ok($@, '');

eval { variations([1], 2) };
ok($@, '');

eval { variations([], 0) };
ok($@, '');


# ---------------------------------------------------------------------

@expected = (["foo"]);
@result = ();
$iter = variations(["foo"], 1);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = variations(["foo"], 1);
is_deeply(\@expected, \@result, "");


# ---------------------------------------------------------------------

@expected = (["foo"], ["bar"]);
@result = ();
$iter = variations(["foo", "bar"], 1);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = variations(["foo", "bar"], 1);
is_deeply(\@expected, \@result, "");


# ---------------------------------------------------------------------

@expected = (
    ["foo", "bar"],
    ["bar", "foo"],
);
@result = ();
$iter = variations(["foo", "bar"], 2);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = variations(["foo", "bar"], 2);
is_deeply(\@expected, \@result, "");


# ---------------------------------------------------------------------

@expected = (
    ["foo", "bar"],
    ["foo", "baz"],
    ["bar", "foo"],
    ["bar", "baz"],
    ["baz", "foo"],
    ["baz", "bar"],
);
@result = ();
$iter = variations(["foo", "bar", "baz"], 2);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = variations(["foo", "bar", "baz"], 2);
is_deeply(\@expected, \@result, "");


# ---------------------------------------------------------------------

@expected = (
    [0, 1, 2],
    [0, 1, 3],
    [0, 2, 1],
    [0, 2, 3],
    [0, 3, 1],
    [0, 3, 2],

    [1, 0, 2],
    [1, 0, 3],
    [1, 2, 0],
    [1, 2, 3],
    [1, 3, 0],
    [1, 3, 2],

    [2, 0, 1],
    [2, 0, 3],
    [2, 1, 0],
    [2, 1, 3],
    [2, 3, 0],
    [2, 3, 1],

    [3, 0, 1],
    [3, 0, 2],
    [3, 1, 0],
    [3, 1, 2],
    [3, 2, 0],
    [3, 2, 1],
);
@result = ();
$iter = variations([0..3], 3);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = variations([0..3], 3);
is_deeply(\@expected, \@result, "");


# ----------------------------------------------------------------------

# n*(n-1)*(n-2)* ... *(n-p+1)
my $ncomb = 0;
$iter = variations([1..9], 5);
while (my @c = $iter->next) {
    ++$ncomb;
}
is($ncomb, 15120, "");

