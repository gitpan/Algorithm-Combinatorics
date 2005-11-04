package Tester;

use strict;

use Test::More;

sub __new {
	my ($class, $coderef) = @_;
	bless { to_test => $coderef }, $class;
}

sub __test {
	my ($self, $expected, @rest) = @_;

	my @result = ();
	my $iter = $self->{to_test}(@rest);
	while (my $c = $iter->next) {
	    push @result, $c;
	}
	Test::More::is_deeply($expected, \@result, "");

	@result = $self->{to_test}(@rest);
	Test::More::is_deeply($expected, \@result, "");
}

1;