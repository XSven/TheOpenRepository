#!/usr/bin/perl

# Test that all modules have a version number.

use strict;

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Pod::Spell::CommonMistakes 0.01',
	'Test::Pod::Spelling::CommonMistakes 0.01',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" );
	}
}

TODO: {

	local $TODO = 'csjewell@cpan.org is still working through this.';

	all_pod_files_ok();
}