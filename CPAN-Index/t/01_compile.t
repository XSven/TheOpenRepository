#!/usr/bin/perl -w

# Test that CPAN::Data loads and compiles

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			catdir('lib'),
			);
	}
}

use Test::More tests => 3;

ok( $] >= 5.005, "Your perl is new enough" );
use_ok( 'CPAN::Data'         );
use_ok( 'CPAN::Data::Loader' );

exit(0);
