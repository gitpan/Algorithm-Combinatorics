package Algorithm::Combinatorics;

use strict;

our $VERSION = '0.07';

use Carp;
use Scalar::Util qw(reftype);
use Exporter;
use base 'Exporter';
our @EXPORT_OK = qw(
    combinations
    combinations_new
    combinations_with_repetition
    variations
    variations_with_repetition
    permutations
);

our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

use Algorithm::Combinatorics::C;
use Algorithm::Combinatorics::Iterator;

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

    my @indices = 0..($k-1);
    my %used    = map { $_ => $_ } @indices;
    my $iter = Algorithm::Combinatorics::Iterator->new(sub {
        __next_variation(\%used, \@indices, @$data-1) == -1 ? undef : [ @{$data}[@indices] ];
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

sub permutations {
	my ($data) = @_;
	__check_params($data, 0);	

	return __contextualize(__once_iter()) if @$data == 0;

    my @indices = 0..(@$data-1);
    my $iter = Algorithm::Combinatorics::Iterator->new(sub {
        __next_permutation(\@indices, @$data-1) == -1 ? undef : [ @{$data}[@indices] ];
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

1; # End of Algorithm::Combinatorics

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

This documentation refers to Algorithm::Combinatorics version 0.07.

=head1 DESCRIPTION

Algorithm::Combinatorics is an efficient generator of combinatorial sequences,
where I<efficient> means:

=over 4

=item * 

Speed: The core loops are written in C.

=item * 

Memory: No recursion and no stacks are used.

=back

Tuples are generated in lexicographic order.

=head1 SUBROUTINES

Algorithm::Combinatorics provides these subroutines:

    permutations(\@data)
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

If C<$k> is less than zero no tuple exists. Thus, the very first call to the iterator's C<next()> method returns C<undef>, and a call in list context returns the empty list. (See L</DIAGNOSTICS>.)

=item *

If C<$k> is zero we have one tuple, the empty tuple. This is a different case than the former: when C<$k> is negative there are no tuples at all, when C<$k> is zero there is a tuple. The rationale for this behaviour is the same rationale for (n choose 0) := 1: the empty tuple is a subset of data with C<$k = 0> elements, so it complies with the definition.

=item *

If C<$k> is greater than the size of C<@data>, and we are calling a subroutine that does not generate tuples with repetitions, no tuple exists. Thus, the very first call to the iterator's C<next()> method returns C<undef>, and a call in list context returns the empty list. (See L</DIAGNOSTICS>.)

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

Algorithm::Combinatorics uses L<Test::More> and L<FindBin> for testing,
L<Scalar::Util> for C<reftype()>, and L<Inline::C> for XS.

=head1 SEE ALSO

L<Math::Combinatorics> is a pure Perl module that offers similar features.

=head1 AUTHOR

Xavier Noria (FXN), E<lt>fxn@cpan.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-algorithm-combinatorics@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-Combinatorics>.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Xavier Noria, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

