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
use base 'Algorithm::Combinatorics::Iterator'; # for isa() in the caller

sub new {
	my ($class, $coderef) = @_;
	
}

sub next {
	my ($self) = @_;
	return $self->();
}

1;