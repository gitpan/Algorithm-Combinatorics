# -*- mode: CPerl -*-

use Algorithm::Combinatorics qw(variations_with_repetition);

use strict;
use warnings;

use Test::More qw(no_plan);

my (@result, @expected, $iter);

# ---------------------------------------------------------------------

eval { variations_with_repetition() };
ok($@, '');

eval { variations_with_repetition([1]) };
ok($@, '');

eval { variations_with_repetition(0, 0) };
ok($@, '');

eval { variations_with_repetition([1], 0) };
ok($@, '');

eval { variation_with_repetition([], 0) };
ok($@, '');


# ---------------------------------------------------------------------

@expected = (["foo"]);
@result = ();
$iter = variations_with_repetition(["foo"], 1);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = variations_with_repetition(["foo"], 1);
is_deeply(\@expected, \@result, "");


# ---------------------------------------------------------------------

@expected = (["foo"], ["bar"]);
@result = ();
$iter = variations_with_repetition(["foo", "bar"], 1);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = variations_with_repetition(["foo", "bar"], 1);
is_deeply(\@expected, \@result, "");


# ---------------------------------------------------------------------

@expected = (
    ["foo", "foo"],
    ["foo", "bar"],
    ["bar", "foo"],
    ["bar", "bar"],
);
@result = ();
$iter = variations_with_repetition(["foo", "bar"], 2);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = variations_with_repetition(["foo", "bar"], 2);
is_deeply(\@expected, \@result, "");


# ---------------------------------------------------------------------

@expected = (
    ["foo", "foo", "foo"],
    ["foo", "foo", "bar"],
    ["foo", "bar", "foo"],
    ["foo", "bar", "bar"],
    ["bar", "foo", "foo"],
    ["bar", "foo", "bar"],
    ["bar", "bar", "foo"],
    ["bar", "bar", "bar"],
);
@result = ();
$iter = variations_with_repetition(["foo", "bar"], 3);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = variations_with_repetition(["foo", "bar"], 3);
is_deeply(\@expected, \@result, "");


# ---------------------------------------------------------------------

@expected = (
    ["foo", "foo"],
    ["foo", "bar"],
    ["foo", "baz"],
    ["bar", "foo"],
    ["bar", "bar"],
    ["bar", "baz"],
    ["baz", "foo"],
    ["baz", "bar"],
    ["baz", "baz"],
);
@result = ();
$iter = variations_with_repetition(["foo", "bar", "baz"], 2);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = variations_with_repetition(["foo", "bar", "baz"], 2);
is_deeply(\@expected, \@result, "");


# ---------------------------------------------------------------------

@expected = (
    [0, 0, 0],
    [0, 0, 1],
    [0, 0, 2],
    [0, 0, 3],
    [0, 1, 0],
    [0, 1, 1],
    [0, 1, 2],
    [0, 1, 3],
    [0, 2, 0],
    [0, 2, 1],
    [0, 2, 2],
    [0, 2, 3],
    [0, 3, 0],
    [0, 3, 1],
    [0, 3, 2],
    [0, 3, 3],

    [1, 0, 0],
    [1, 0, 1],
    [1, 0, 2],
    [1, 0, 3],
    [1, 1, 0],
    [1, 1, 1],
    [1, 1, 2],
    [1, 1, 3],
    [1, 2, 0],
    [1, 2, 1],
    [1, 2, 2],
    [1, 2, 3],
    [1, 3, 0],
    [1, 3, 1],
    [1, 3, 2],
    [1, 3, 3],

    [2, 0, 0],
    [2, 0, 1],
    [2, 0, 2],
    [2, 0, 3],
    [2, 1, 0],
    [2, 1, 1],
    [2, 1, 2],
    [2, 1, 3],
    [2, 2, 0],
    [2, 2, 1],
    [2, 2, 2],
    [2, 2, 3],
    [2, 3, 0],
    [2, 3, 1],
    [2, 3, 2],
    [2, 3, 3],

    [3, 0, 0],
    [3, 0, 1],
    [3, 0, 2],
    [3, 0, 3],
    [3, 1, 0],
    [3, 1, 1],
    [3, 1, 2],
    [3, 1, 3],
    [3, 2, 0],
    [3, 2, 1],
    [3, 2, 2],
    [3, 2, 3],
    [3, 3, 0],
    [3, 3, 1],
    [3, 3, 2],
    [3, 3, 3],

);
@result = ();
$iter = variations_with_repetition([0..3], 3);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = variations_with_repetition([0..3], 3);
is_deeply(\@expected, \@result, "");


# ----------------------------------------------------------------------

# n^k
my $ncomb = 0;
$iter = variations_with_repetition([1..7], 5);
while (my @c = $iter->next) {
    ++$ncomb;
}
is($ncomb, 16807, "");

$ncomb = 0;
$iter = variations_with_repetition([1..4], 7);
while (my @c = $iter->next) {
    ++$ncomb;
}
is($ncomb, 16384, "");
