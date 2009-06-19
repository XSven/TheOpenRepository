use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('PPI::XS::Tokenizer') };

SCOPE: {
  my $t = PPI::XS::Tokenizer->new("Test");
  isa_ok($t, 'PPI::XS::Tokenizer');
  #ok($t->tokenizeLine("Test") == PPI::XS::Tokenizer::reached_eol, 'simple tokenizeLine call returns reached_eol');
  my $token = $t->get_token();
}



