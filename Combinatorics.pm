package Algorithm::Combinatorics;

use 5.006002;
use strict;

our $VERSION = '0.13';

use XSLoader;
XSLoader::load('Algorithm::Combinatorics', $VERSION);

use Carp;
use Scalar::Util qw(reftype);
use Exporter;
use base 'Exporter';
our @EXPORT_OK = qw(
    combinations
    combinations_with_repetition
    variations
    variations_with_repetition
    permutations
    derangements
);

our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

sub combinations {
    my ($data, $k) = @_;
	__check_params($data, $k);

	if ($k < 0) {
		carp("Parameter k is negative");
		return __contextualize(__null_iter());
	} elsif ($k > @$data) {
		carp("Parameter k is greater than the size of data");
		return __contextualize(__null_iter());
	}

	return __contextualize(__once_iter()) if $k == 0;

    my @indices = 0..($k-1);
    my $iter = Algorithm::Combinatorics::Iterator->new(sub {
        __next_combination(\@indices, @$data-1) == -1 ? undef : [ @{$data}[@indices] ];
    }, [ @{$data}[@indices] ]);

    return __contextualize($iter);
}


sub combinations_with_repetition {
    my ($data, $k) = @_;
	__check_params($data, $k);

	if ($k < 0) {
		carp("Parameter k is negative");
		return __contextualize(__null_iter());
	}

	return __contextualize(__once_iter()) if $k == 0;

    my @indices = (0) x $k;
    my $iter = Algorithm::Combinatorics::Iterator->new(sub {
        __next_combination_with_repetition(\@indices, @$data-1) == -1 ? undef : [ @{$data}[@indices] ];
    }, [ @{$data}[@indices] ]);

    return __contextualize($iter);
}


sub variations {
    my ($data, $k) = @_;
	__check_params($data, $k);

	if ($k < 0) {
		carp("Parameter k is negative");
		return __contextualize(__null_iter());
	} elsif ($k > @$data) {
		carp("Parameter k is greater than the size of data");
		return __contextualize(__null_iter());
	}

	return __contextualize(__once_iter()) if $k == 0;

    # permutations() is more efficient because it knows
    # all indices are always used
    return permutations($data) if @$data == $k;

    my @indices = 0..($k-1);
    my @used = ((1) x $k, (0) x (@$data-$k));
    my $iter = Algorithm::Combinatorics::Iterator->new(sub {
        __next_variation(\@indices, \@used, @$data-1) == -1 ? undef : [ @{$data}[@indices] ];
    }, [ @{$data}[@indices] ]);

    return __contextualize($iter);
}


sub variations_with_repetition {
    my ($data, $k) = @_;
	__check_params($data, $k);

	if ($k < 0) {
		carp("Parameter k is negative");
		return __contextualize(__null_iter());
	}

	return __contextualize(__once_iter()) if $k == 0;

    my @indices = (0) x $k;
    my $iter = Algorithm::Combinatorics::Iterator->new(sub {
        __next_variation_with_repetition(\@indices, @$data-1) == -1 ? undef : [ @{$data}[@indices] ];
    }, [ @{$data}[@indices] ]);

    return __contextualize($iter);
}


sub __variations_with_repetition_gray_code {
    my ($data, $k) = @_;
	__check_params($data, $k);

	if ($k < 0) {
		carp("Parameter k is negative");
		return __contextualize(__null_iter());
	}

	return __contextualize(__once_iter()) if $k == 0;

    my @indices        = (0) x $k;
    my @focus_pointers = 0..$k; # yeah, length $k+1
    my @directions     = (1) x $k;
    my $iter = Algorithm::Combinatorics::Iterator->new(sub {
        __next_variation_with_repetition_gray_code(
            \@indices,
            \@focus_pointers,
            \@directions,
            @$data-1,
        ) == -1 ? undef : [ @{$data}[@indices] ];
    }, [ @{$data}[@indices] ]);

    return __contextualize($iter);
}


sub permutations {
	my ($data) = @_;
	__check_params($data, 0);

	return __contextualize(__once_iter()) if @$data == 0;

    my @indices = 0..(@$data-1);
    my $iter = Algorithm::Combinatorics::Iterator->new(sub {
        __next_permutation(\@indices) == -1 ? undef : [ @{$data}[@indices] ];
	}, [ @{$data}[@indices] ]);

    return __contextualize($iter);
}


sub __permutations_heap {
	my ($data) = @_;
	__check_params($data, 0);

	return __contextualize(__once_iter()) if @$data == 0;

    my @a = 0..(@$data-1);
    my @c = (0) x (@$data+1); # yeah, there's an spurious $c[0] to make the notation coincide
    my $iter = Algorithm::Combinatorics::Iterator->new(sub {
        __next_permutation_heap(\@a, \@c) == -1 ? undef : [ @{$data}[@a] ];
	}, [ @{$data}[@a] ]);

    return __contextualize($iter);
}

sub derangements {
	my ($data) = @_;
	__check_params($data, 0);

	return __contextualize(__once_iter()) if @$data == 0;
    return __contextualize(__null_iter()) if @$data == 1;

    my @indices = 0..(@$data-1);
    @indices[$_, $_+1] = @indices[$_+1, $_] for map { 2*$_ } 0..((@$data-2)/2);
    @indices[-1, -2] = @indices[-2, -1] if @$data % 2;
    my $iter = Algorithm::Combinatorics::Iterator->new(sub {
        __next_derangement(\@indices) == -1 ? undef : [ @{$data}[@indices] ];
	}, [ @{$data}[@indices] ]);

    return __contextualize($iter);
}

sub __check_params {
	my ($data, $k) = @_;
	if (not defined $data) {
		croak("Missing parameter data");
	}
	if (not defined $k) {
		croak("Missing parameter k");
	}

	my $type = reftype $data;
	if (!defined($type) || $type ne "ARRAY") {
		croak("Parameter data is not an arrayref");
	}
}


sub __contextualize {
    my $iter = shift;
    my $w = wantarray;
    if (defined $w) {
        if ($w) {
            my @result = ();
            while (my $c = $iter->next) {
                push @result, $c;
            }
            return @result;
        } else {
            return $iter;
        }
    } else {
        my $sub = (caller(1))[3];
        carp("Useless use of $sub in void context");
    }
}


sub __null_iter {
	return Algorithm::Combinatorics::Iterator->new(sub { return });
}


sub __once_iter {
	Algorithm::Combinatorics::Iterator->new(sub { return }, []);
}



# This is a bit dirty by now, the objective is to be able to
# pass an initial sequence to the iterator and avoid a test
# in each iteration saying whether the sequence was already
# returned or not.
#
# Note that the public contract is that responds to next(), no
# iterator class name is documented.

package Algorithm::Combinatorics::Iterator;

sub new {
    my ($class, $coderef, $first_seq) = @_;
	if (defined $first_seq) {
    	return bless [$coderef, $first_seq], $class;
    } else {
		return bless $coderef, 'Algorithm::Combinatorics::JustCoderef';
	}
}

sub next {
    my ($self) = @_;
    $_[0] = $self->[0];
    bless $_[0], 'Algorithm::Combinatorics::JustCoderef';
    return $self->[1];
}

package Algorithm::Combinatorics::JustCoderef;

sub next {
	my ($self) = @_;
	return $self->();
}


1;

__END__



=head1 NAME

Algorithm::Combinatorics - Efficient generation of combinatorial sequences

=head1 SYNOPSIS

 use Algorithm::Combinatorics qw(permutations);

 my @data = qw(a b c);

 # scalar context gives an iterator
 my $iter = permutations(\@data);
 while (my $p = $iter->next) {
     # ...
 }

 # list context slurps
 my @all_permutations = permutations(\@data);

=head1 VERSION

This documentation refers to Algorithm::Combinatorics version 0.13.

=head1 DESCRIPTION

Algorithm::Combinatorics is an efficient generator of combinatorial sequences.
Algorithms are selected from the literature (work in progress, see L</REFERENCES>),
and written in C for speed.

Tuples are generated in lexicographic order.

=head1 SUBROUTINES

Algorithm::Combinatorics provides these subroutines:

    permutations(\@data)
    derangements(\@data)
    variations(\@data, $k)
    variations_with_repetition(\@data, $k)
    combinations(\@data, $k)
    combinations_with_repetition(\@data, $k)

All of them are context-sensitive:

=over 4

=item *

In scalar context the subroutines return an iterator that responds to the C<next()> method. Using this object you can iterate over the sequence of tuples one by one this way:

    my $iter = combinations(\@data, $k);
    while (my $c = $iter->next) {
        # ...
    }

The C<next()> method returns an arrayref to the next tuple, if any, or C<undef> if the sequence is exhausted.

Since no recursion and no stacks are used the memory usage is minimal. Thus, we can iterate over sequences of virtually any size.

=item *

In list context the subroutines slurp the entire set of tuples. This behaviour is offered for convenience, but take into account that the resulting array may be really huge:

    my @all_combinations = combinations(\@data, $k);

=back

=head2 permutations(\@data)

The permutations of C<@data> are all its reorderings. For example, the permutations of C<@data = (1, 2, 3)> are:

    (1, 2, 3)
    (1, 3, 2)
    (2, 1, 3)
    (2, 3, 1)
    (3, 1, 2)
    (3, 2, 1)

The number of permutations of C<n> elements is:

    n! = 1,                  if n = 0
    n! = n*(n-1)*...*1,      if n > 0

=head2 derangements(\@data)

The derangements of C<@data> are those reorderings that have no element
in its original place. In jargon those are the permutations of C<@data>
which have no fixed point. For example, the derangements of C<@data =
(1, 2, 3)> are:

    (2, 3, 1)
    (3, 1, 2)

The number of derangements of C<n> elements is:

    d(n) = 1,                       if n = 0
    d(n) = n*d(n-1) + (-1)**n,      if n > 0

=head2 variations(\@data, $k)

The variations of length C<$k> of C<@data> are all the tuples of length C<$k> consisting of elements of C<@data>. For example, for C<@data = (1, 2, 3)> and C<$k = 2>:

    (1, 2)
    (1, 3)
    (2, 1)
    (2, 3)
    (3, 1)
    (3, 2)

For this to make sense, C<$k> has to be less than or equal to the length of C<@data>.

Note that

    permutations(\@data);

is equivalent to

    variations(\@data, scalar @data);

The number of variations of C<n> elements taken in groups of C<k> is:

    v(n, k) = 1,                        if k = 0
    v(n, k) = n*(n-1)*...*(n-k+1),      if 0 < k <= n

=head2 variations_with_repetition(\@data, $k)

The variations with repetition of length C<$k> of C<@data> are all the tuples of length C<$k> consisting of elements of C<@data>, including repetitions. For example, for C<@data = (1, 2, 3)> and C<$k = 2>:

    (1, 1)
    (1, 2)
    (1, 3)
    (2, 1)
    (2, 2)
    (2, 3)
    (3, 1)
    (3, 2)
    (3, 3)

Note that C<$k> can be greater than the length of C<@data>. For example, for C<@data = (1, 2)> and C<$k = 3>:

    (1, 1, 1)
    (1, 1, 2)
    (1, 2, 1)
    (1, 2, 2)
    (2, 1, 1)
    (2, 1, 2)
    (2, 2, 1)
    (2, 2, 2)

The number of variations with repetition of C<n> elements taken in groups of C<< k >= 0 >> is:

    vr(n, k) = n**k

=head2 combinations(\@data, $k)

The combinations of length C<$k> of C<@data> are all the sets of size C<$k> consisting of elements of C<@data>. For example, for C<@data = (1, 2, 3, 4)> and C<$k = 3>:

    (1, 2, 3)
    (1, 2, 4)
    (1, 3, 4)
    (2, 3, 4)

For this to make sense, C<$k> has to be less than or equal to the length of C<@data>.

The number of combinations of C<n> elements taken in groups of C<< 0 <= k <= n >> is:

    n choose k = n!/(k!*(n-k)!)

=head2 combinations_with_repetition(\@data, $k);

The combinations of length C<$k> of an array C<@data> are all the bags of size C<$k> consisting of elements of C<@data>, with repetitions. For example, for C<@data = (1, 2, 3)> and C<$k = 2>:

    (1, 1)
    (1, 2)
    (1, 3)
    (2, 2)
    (2, 3)
    (3, 3)

Note that C<$k> can be greater than the length of C<@data>. For example, for C<@data = (1, 2, 3)> and C<$k = 4>:

    (1, 1, 1, 1)
    (1, 1, 1, 2)
    (1, 1, 1, 3)
    (1, 1, 2, 2)
    (1, 1, 2, 3)
    (1, 1, 3, 3)
    (1, 2, 2, 2)
    (1, 2, 2, 3)
    (1, 2, 3, 3)
    (1, 3, 3, 3)
    (2, 2, 2, 2)
    (2, 2, 2, 3)
    (2, 2, 3, 3)
    (2, 3, 3, 3)
    (3, 3, 3, 3)

The number of combinations with repetition of C<n> elements taken in groups of C<< k >= 0 >> is:

    n+k-1 over k = (n+k-1)!/(k!*(n-1)!)

=head1 CORNER CASES

Since version 0.05 subroutines are more forgiving for unsual values of C<$k>:

=over 4

=item *

If C<$k> is less than zero no tuple exists. Thus, the very first call to
the iterator's C<next()> method returns C<undef>, and a call in list
context returns the empty list. (See L</DIAGNOSTICS>.)

=item *

If C<$k> is zero we have one tuple, the empty tuple. This is a different
case than the former: when C<$k> is negative there are no tuples at all,
when C<$k> is zero there is one tuple. The rationale for this behaviour
is the same rationale for n choose 0 = 1: the empty tuple is a subset of
C<@data> with C<$k = 0> elements, so it complies with the definition.

=item *

If C<$k> is greater than the size of C<@data>, and we are calling a
subroutine that does not generate tuples with repetitions, no tuple
exists. Thus, the very first call to the iterator's C<next()> method
returns C<undef>, and a call in list context returns the empty
list. (See L</DIAGNOSTICS>.)

=back

In addition, since 0.05 empty C<@data>s are supported as well.


=head1 EXPORT

Algorithm::Combinatorics exports nothing by default. Each of the subroutines can be exported on demand, as in

    use Algorithm::Combinatorics qw(combinations);

and the tag C<all> exports them all:

    use Algorithm::Combinatorics qw(:all);


=head1 DIAGNOSTICS

=head2 Warnings

The following warnings may be issued:

=over

=item Useless use of %s in void context

A subroutine was called in void context.

=item Parameter k is negative

A subroutine was called with a negative k.

=item Parameter k is greater than the size of data

A subroutine that does not generate tuples with repetitions was called with a k greater than the size of data.

=back

=head2 Errors

The following errors may be thrown:

=over

=item Missing parameter data

A subroutine was called with no parameters.

=item Missing parameter k

A subroutine that requires a second parameter k was called without one.

=item Parameter data is not an arrayref

The first parameter is not an arrayref (tested with "reftype()" from Scalar::Util.)

=back

=head1 DEPENDENCIES

Algorithm::Combinatorics is known to run under perl 5.6.2. The
distribution uses L<Test::More> and L<FindBin> for testing,
L<Scalar::Util> for C<reftype()>, and L<XSLoader> for XS.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-algorithm-combinatorics@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-Combinatorics>.

=head1 SEE ALSO

L<Math::Combinatorics> is a pure Perl module that offers similar features.

=head1 REFERENCES

[1] Donald E. Knuth, I<The Art of Computer Programming, Volume 4, Fascicle 2: Generating All Tuples and Permutations>. Addison Wesley Professional, 2005. ISBN 0201853930.

=head1 AUTHOR

Xavier Noria (FXN), E<lt>fxn@cpan.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2005 Xavier Noria, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

