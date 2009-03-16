#!perl

use 5.010;
# variations on
# the example grammar in Aycock/Horspool "Practical Earley Parsing",
# _The Computer Journal_, Vol. 45, No. 6, pp. 620-630,

use strict;
use warnings;
use lib 'lib';
use lib 't/lib';
use Carp;

use Test::More tests => 8;
use Marpa::Test;

BEGIN {
	use_ok( 'Marpa' );
}

my $g = new Marpa::Grammar({
    start => 'S',
    strip => 0,

    # An arbitrary maximum is put on the number of parses -- this is for
    # debugging, and infinite loops happen.
    max_parses => 999,

    rules => [
        [ 'S', ['sequence'] ],
        [ 'sequence', [ 'sequence', 'piece' ] ],
        [ 'sequence', [ 'piece' ] ],
        [ 'piece', [ 'one' ] ],
        [ 'piece', [ 'two' ] ],
        [ 'piece', [ 'three' ] ],
        [ 'one', [qw/goddess/] ],
        [ 'two', [qw/goddess goddess/] ],
        [ 'three', [qw/goddess goddess goddess/] ],
        [ 'goddess', [ 'ishtar' ] ],
        [ 'goddess', [ 'ereshkigal' ] ],
        [ 'ishtar', [qw/a/] ],
        [ 'ereshkigal', [qw/a/] ],
    ],
    terminals => [ 'a' ],

});

my $recce = new Marpa::Recognizer({grammar => $g});

my $a = $g->get_symbol('a');
for (0 .. 4) { $recce->earleme([$a, 'a', 1]); }
$recce->end_input();

my $evaler = new Marpa::Evaluator( { clone=>0, recce => $recce, } );
croak("Cannot evaluate parse") unless $evaler;

say "Symbols:\n", $g->show_symbols();
say "Rules:\n",  $g->show_rules();
say "QDFA:\n",  $g->show_QDFA();

say "Earley Sets:\n", $recce->show_earley_sets();
say "Bocage:\n", $evaler->show_bocage(2);

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
