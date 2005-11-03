package Algorithm::Combinatorics;

use strict;
use warnings;

our $VERSION = '0.01';

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
);

our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

use Algorithm::Combinatorics::C;
use Algorithm::Combinatorics::Iterator;

sub combinations {
    my ($data, $k) = @_;
	__check_params_le($data, $k);

    my @indices = (0..($k-2), $k-2);
    my @out     = @{$data}[0..($k-1)];

    my $iter = Algorithm::Combinatorics::Iterator->new(sub {
        __next_combination(\@indices, $data, \@out) == -1 ? () : @out;
    });

    return __wanted($iter);
}

sub combinations_with_repetition {
    my ($data, $k) = @_;
	__check_params($data, $k);

    my @indices = ((0) x ($k-1), -1);
    my @out     = ($data->[0]) x $k;

    my $iter = Algorithm::Combinatorics::Iterator->new(sub {
        __next_combination_with_repetition(\@indices, $data, \@out) == -1 ? () : @out;
    });

    return __wanted($iter);
}

sub variations {
    my ($data, $k) = @_;
	__check_params_le($data, $k);

    my @indices = (0..($k-2), -1);
    my %used    = map { $_ => $_ } @indices[0..($k-2)];
    my @out     = @{$data}[0..($k-1)];

    my $iter = Algorithm::Combinatorics::Iterator->new(sub {
        __next_variation(\%used, \@indices, $data, \@out) == -1 ? () : @out;
    });

    return __wanted($iter);
}

sub variations_with_repetition {
    my ($data, $k) = @_;
	__check_params($data, $k);

    my @indices = ((0) x ($k-1), -1);
    my @out     = ($data->[0]) x $k;

    my $iter = Algorithm::Combinatorics::Iterator->new(sub {
        __next_variation_with_repetition(\@indices, $data, \@out) == -1 ? () : @out;
    });

    return __wanted($iter);
}

sub permutations {
    my ($data) = @_;
    return variations($data, scalar @$data);
}

sub __check_params {
	my ($data, $k) = @_;
	if (not defined $data) {
		croak("missing parameter data");
	}
	if (not defined $k) {
		croak("missing parameter k");
	}
	
	my $type = reftype $data;
	if (!defined($type) || $type ne "ARRAY") {
		croak("parameter data is not an arrayref");
	}
	if (@$data == 0) {
		croak("parameter data cannot be empty");
	}
	if ($k < 1) {
		croak("parameter k must be greater than or equal to 1");
	}
		
}

sub __check_params_le {
	&__check_params;
	my ($data, $k) = @_;
	if ($k > @$data) {
		croak('parameter k is greater than the length of data');
	}
}


sub __wanted {
    my $iter = shift;
    my $w = wantarray;
    if (defined $w) {
        if ($w) {
            my @result = ();
            while (my @c = $iter->next) {
                push @result, [ @c ];
            }
            return @result;
        } else {
            return $iter;
        }
    } else {
        my $sub = (caller(1))[3];
        carp("$sub called in void context\n");
    }
}

1; # End of Algorithm::Combinatorics

__END__

=head1 NAME

Algorithm::Combinatorics - Efficient generation of combinatorial sequences

=head1 SYNOPSIS

 use Algorithm::Combinatorics qw(permutations);

 my @data = ("a", "b", "c");

 # scalar context gives an iterator
 my $iter = permutations(\@data);
 while (my @p = $iter->next) {
     # ...
 }

 # list context slurps
 my @all_permutations = permutations(\@data);

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

=head1 USAGE

Algorithm::Combinatorics provides these subroutines:

    permutations(\@data)
    variations(\@data, $k)
    variations_with_repetition(\@data, $k)
    combinations(\@data, $k)
    combinations_with_repetition(\@data, $k);

All of them are context-sensitive:

=over 4

=item * 

In scalar context the subroutines return an iterator that responds to the C<next> method. Using this object you can iterate over the sequence of tuples one by one. Since no recursion and no stacks are used in each iteration the memory usage is minimal.

=item * 

In list context the subroutines slurp the entire set of tuples. This behaviour is offered for convenience, but take into account that the array may be huge.

=back


=head2 permutations(\@data)

The permutations of C<@data> are all its reorderings. For example, the permutations of C<@data = (1, 2, 3)> are:

    (1, 2, 3)
    (1, 3, 2)
    (2, 1, 3)
    (2, 3, 1)
    (3, 1, 2)
    (3, 2, 1)

=head2 variations(\@data, $k)

The variations of length C<$k> of C<@data> are all the tuples of length C<$k> consisting of elements of C<@data>. For example, for C<@data = (1, 2, 3)> and C<$k = 2>:

    (1, 2)
    (1, 3)
    (2, 1)
    (2, 3)
    (3, 1)
    (3, 2)

For this to make sense, C<$k> has to be less than or equal to the length of C<@data>. 

Note that the

    permutations(\@data);

is equivalent to

    variations(\@data, scalar @data);

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

=head2 combinations(\@data, $k)

The combinations of length C<$k> of C<@data> are all the sets of size C<$k> consisting of elements of C<@data>. For example, for C<@data = (1, 2, 3, 4)> and C<$k = 3>:

    (1, 2, 3)
    (1, 2, 4)
    (1, 3, 4)
    (2, 3, 4)

For this to make sense, C<$k> has to be less than or equal to the length of C<@data>. 

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


=head1 EXPORT

Algorithm::Combinatorics exports nothing by default. Each of the subroutines can be exported on demand, as in

    use Algorithm::Combinatorics qw(combinations);

and the tag C<all> exports them all:

    use Algorithm::Combinatorics qw(:all);

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

