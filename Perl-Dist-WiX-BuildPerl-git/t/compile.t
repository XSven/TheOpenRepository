use Test::More tests => 2;

BEGIN {
	use strict;
	$^W = 1;
	$| = 1;

    ok(($] > 5.008000), 'Perl version acceptable') or BAIL_OUT ('Perl version unacceptably old.');
    use_ok( 'Perl::Dist::WiX::BuildPerl::git' );
    diag( "Testing Perl::Dist::WiX::BuildPerl::git $Perl::Dist::WiX::BuildPerl::git::VERSION" );
}

