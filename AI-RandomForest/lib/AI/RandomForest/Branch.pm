package AI::RandomForest::Branch;

use 5.16.0;
use strict;
use warnings;

our $VERSION = '0.01';





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	return $self;
}

sub feature {
	$_[0]->{feature};
}

sub separator {
	$_[0]->{separator};
}

sub left {
	$_[0]->{left};
}

sub right {
	$_[0]->{right};
}





######################################################################
# Main Methods

sub as_string {
	print "Branch: $_[0]->{feature} > $_[0]->{separator}";
}

1;
