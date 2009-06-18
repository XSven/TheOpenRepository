#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif

#include "src/tokenizer.cpp"
#include "src/numbers.cpp"
#include "src/operator.cpp"
#include "src/quotes.cpp"
#include "src/structure.cpp"
#include "src/symbol.cpp"
#include "src/unknown.cpp"
#include "src/whitespace.cpp"
#include "src/word.cpp"

#include "const-c.inc"


MODULE = PPI::XS::Tokenizer		PACKAGE = PPI::XS::Tokenizer

INCLUDE: xspp --typemap=typemap.xsp XS/Tokenizer.xsp |
INCLUDE: xspp --typemap=typemap.xsp XS/Token.xsp |


MODULE = PPI::XS::Tokenizer		PACKAGE = PPI::XS::Tokenizer::Constants

INCLUDE: const-xs.inc


