# -*- mode: CPerl -*-

use Algorithm::Combinatorics qw(combinations_with_repetition);

use strict;

use Test::More qw(no_plan);

my (@result, @expected, $iter);


# ---------------------------------------------------------------------

eval { combinations_with_repetition() };
ok($@, '');

eval { combinations_with_repetition([1]) };
ok($@, '');

eval { combinations_with_repetition(0, 0) };
ok($@, '');

eval { combinations_with_repetition([1], 0) };
ok($@, '');

eval { combinations_with_repetition([], 0) };
ok($@, '');


# ---------------------------------------------------------------------

@expected = (["foo"]);
@result = ();
$iter = combinations_with_repetition(["foo"], 1);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = combinations_with_repetition(["foo"], 1);
is_deeply(\@expected, \@result, "");


# ---------------------------------------------------------------------

@expected = (["foo"], ["bar"]);
@result = ();
$iter = combinations_with_repetition(["foo", "bar"], 1);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = combinations_with_repetition(["foo", "bar"], 1);
is_deeply(\@expected, \@result, "");


# ---------------------------------------------------------------------

@expected = (
    ["foo", "foo"],
    ["foo", "bar"],
    ["bar", "bar"],
);
@result = ();
$iter = combinations_with_repetition(["foo", "bar"], 2);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = combinations_with_repetition(["foo", "bar"], 2);
is_deeply(\@expected, \@result, "");


# ---------------------------------------------------------------------

@expected = (
    ["foo", "foo", "foo"],
    ["foo", "foo", "bar"],
    ["foo", "bar", "bar"],
    ["bar", "bar", "bar"],
);
@result = ();
$iter = combinations_with_repetition(["foo", "bar"], 3);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = combinations_with_repetition(["foo", "bar"], 3);
is_deeply(\@expected, \@result, "");


# ---------------------------------------------------------------------

@expected = (
    ["foo", "foo"],
    ["foo", "bar"],
    ["foo", "baz"],
    ["bar", "bar"],
    ["bar", "baz"],
    ["baz", "baz"],
);
@result = ();
$iter = combinations_with_repetition(["foo", "bar", "baz"], 2);
while (my @c = $iter->next) {
    push @result, [@c];
}


is_deeply(\@expected, \@result, "");

@result = combinations_with_repetition(["foo", "bar", "baz"], 2);
is_deeply(\@expected, \@result, "");


# ---------------------------------------------------------------------

@expected = (
    [0, 0, 0],
    [0, 0, 1],
    [0, 0, 2],
    [0, 0, 3],
    [0, 1, 1],
    [0, 1, 2],
    [0, 1, 3],
    [0, 2, 2],
    [0, 2, 3],
    [0, 3, 3],
    [1, 1, 1],
    [1, 1, 2],
    [1, 1, 3],
    [1, 2, 2],
    [1, 2, 3],
    [1, 3, 3],
    [2, 2, 2],
    [2, 2, 3],
    [2, 3, 3],
    [3, 3, 3],
);
@result = ();
$iter = combinations_with_repetition([0..3], 3);
while (my @c = $iter->next) {
    push @result, [@c];
}
is_deeply(\@expected, \@result, "");

@result = combinations_with_repetition([0..3], 3);
is_deeply(\@expected, \@result, "");


# ----------------------------------------------------------------------

# n+k-1 over k
my $ncomb = 0;
$iter = combinations_with_repetition([1..15], 5);
while (my @c = $iter->next) {
    ++$ncomb;
}
is($ncomb, 11628, "");

$ncomb = 0;
$iter = combinations_with_repetition([1..7], 11);
while (my @c = $iter->next) {
    ++$ncomb;
}
is($ncomb, 12376, "");
