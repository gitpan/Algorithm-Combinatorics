package Algorithm::Combinatorics::Iterator;

sub new {
    my ($class, $coderef) = @_;
    return bless $coderef, $class;
}

sub next {
    my $self = shift;
    return $self->();
}

1;