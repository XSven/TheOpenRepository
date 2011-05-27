#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;
use File::Spec::Functions ':ALL';
use EVE::Macro::Object ();

# Data files
my $config = rel2abs(catfile( 'data', 'EVE-Macro.conf' ));
ok( -f $config, "Found test config at $config" );

# Bootstrap the game
my $object = EVE::Macro::Object->start(
	# config_file => $config,
	# username    => 'Algorithm2',
	# password    => 'phlegm3{#}',
);
isa_ok( $object, 'EVE::Macro::Object' );
isa_ok( $object->process, 'Win32::Process' );
ok( $object->window, '->window ok' );

# Can we see it?
isa_ok( $object->screenshot, 'Imager::Search::Screenshot' );

# Login and then kill the game quickly
ok( $object->login, '->login  ok' );
ok( $object->stop,  '->stop ok'   );
