#include <stdio.h>
#include <stdlib.h>

#include "tokenizer.h"


TokenTypeNames commit_map[128] = {
	Token_NoType, /* 0 */ Token_NoType, /* 1 */ Token_NoType, /* 2 */ Token_NoType, /* 3 */ 
	Token_NoType, /* 4 */ Token_NoType, /* 5 */ Token_NoType, /* 6 */ Token_NoType, /* 7 */ 
	Token_NoType, /* 8 */ Token_WhiteSpace, /* '9' */ Token_WhiteSpace, /* '10' */ Token_NoType, /* 11 */ 
	Token_NoType, /* 12 */ Token_WhiteSpace, /* '13' */ Token_NoType, /* 14 */ Token_NoType, /* 15 */ 
	Token_NoType, /* 16 */ Token_NoType, /* 17 */ Token_NoType, /* 18 */ Token_NoType, /* 19 */ 
	Token_NoType, /* 20 */ Token_NoType, /* 21 */ Token_NoType, /* 22 */ Token_NoType, /* 23 */ 
	Token_NoType, /* 24 */ Token_NoType, /* 25 */ Token_NoType, /* 26 */ Token_NoType, /* 27 */ 
	Token_NoType, /* 28 */ Token_NoType, /* 29 */ Token_NoType, /* 30 */ Token_NoType, /* 31 */ 
	Token_WhiteSpace, /* '32' */ Token_Operator, /* '!' */ Token_Quote_Double, /* '"' */ Token_Comment, /* '#' */ 
	Token_Unknown, /* '$' */ Token_Unknown, /* '%' */ Token_Unknown, /* '&' */ Token_Quote_Single, /* ''' */ 
	Token_NoType, /* 40 */ Token_Structure, /* ')' */ Token_Unknown, /* '*' */ Token_Operator, /* '+' */ 
	Token_Operator, /* ',' */ Token_NoType, /* 45 */ Token_Operator, /* '.' */ Token_NoType, /* 47 */ 
	Token_Number, /* '0' */ Token_Number, /* '1' */ Token_Number, /* '2' */ Token_Number, /* '3' */ 
	Token_Number, /* '4' */ Token_Number, /* '5' */ Token_Number, /* '6' */ Token_Number, /* '7' */ 
	Token_Number, /* '8' */ Token_Number, /* '9' */ Token_Unknown, /* ':' */ Token_Structure, /* ';' */ 
	Token_NoType, /* 60 */ Token_Operator, /* '=' */ Token_Operator, /* '>' */ Token_Operator, /* '?' */ 
	Token_Unknown, /* '@' */ Token_Word, /* 'A' */ Token_Word, /* 'B' */ Token_Word, /* 'C' */ 
	Token_Word, /* 'D' */ Token_Word, /* 'E' */ Token_Word, /* 'F' */ Token_Word, /* 'G' */ 
	Token_Word, /* 'H' */ Token_Word, /* 'I' */ Token_Word, /* 'J' */ Token_Word, /* 'K' */ 
	Token_Word, /* 'L' */ Token_Word, /* 'M' */ Token_Word, /* 'N' */ Token_Word, /* 'O' */ 
	Token_Word, /* 'P' */ Token_Word, /* 'Q' */ Token_Word, /* 'R' */ Token_Word, /* 'S' */ 
	Token_Word, /* 'T' */ Token_Word, /* 'U' */ Token_Word, /* 'V' */ Token_Word, /* 'W' */ 
	Token_Word, /* 'X' */ Token_Word, /* 'Y' */ Token_Word, /* 'Z' */ Token_Structure, /* '[' */ 
	Token_Cast, /* '\' */ Token_Structure, /* ']' */ Token_Operator, /* '^' */ Token_Word, /* '_' */ 
	Token_QuoteLike_Backtick, /* '`' */ Token_Word, /* 'a' */ Token_Word, /* 'b' */ Token_Word, /* 'c' */ 
	Token_Word, /* 'd' */ Token_Word, /* 'e' */ Token_Word, /* 'f' */ Token_Word, /* 'g' */ 
	Token_Word, /* 'h' */ Token_Word, /* 'i' */ Token_Word, /* 'j' */ Token_Word, /* 'k' */ 
	Token_Word, /* 'l' */ Token_Word, /* 'm' */ Token_Word, /* 'n' */ Token_Word, /* 'o' */ 
	Token_Word, /* 'p' */ Token_Word, /* 'q' */ Token_Word, /* 'r' */ Token_Word, /* 's' */ 
	Token_Word, /* 't' */ Token_Word, /* 'u' */ Token_Word, /* 'v' */ Token_Word, /* 'w' */ 
	Token_NoType, /* 120 */ Token_Word, /* 'y' */ Token_Word, /* 'z' */ Token_Structure, /* '{' */ 
	Token_Operator, /* '|' */ Token_Structure, /* '}' */ Token_Operator, /* '~' */ Token_NoType, /* 127 */
};

CharTokenizeResults WhiteSpaceToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
    if ( c_char < 128 ) {
        if ( commit_map[c_char] == Token_WhiteSpace ) {
			return my_char;
		}
        if ( commit_map[c_char] != Token_NoType ) {
            // this is the first char of some token
			return t->TokenTypeNames_pool[commit_map[c_char]]->commit(t, c_char);
        }
    }
	// TODO
    return error_fail;
}
