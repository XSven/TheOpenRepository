#include <stdio.h>
#include <stdlib.h>

#include "tokenizer.h"

//=====================================
// AbstractTokenType
//=====================================

CharTokenizeResults AbstractTokenType::commit(Tokenizer *t, unsigned char c_char) { 
	t->_new_token(type);
	return my_char;
}

bool AbstractTokenType::isa( TokenTypeNames is_type ) const {
	return ( is_type == type );
}

Token *AbstractTokenType::GetNewToken( Tokenizer *t, TokensCacheMany& tc, ulong line_length ) {
	unsigned long needed_size = line_length - t->line_pos;
	if ( needed_size < 200 ) needed_size = 200;

	Token *tk = _get_from_cache(tc);

	if ( tk == NULL ) {
		tk = _alloc_from_cache(tc);
		if ( tk == NULL )
			return NULL; // die
		tk->text = NULL;
		tk->allocated_size = needed_size;
	} else {
		if ( tk->allocated_size < needed_size ) {
			free( tk->text );
			tk->text = NULL;
			tk->allocated_size = needed_size;
		}
	}

	if ( tk->text == NULL ) {
		tk->text = (char *)malloc(sizeof(char) * needed_size);
		if (tk->text == NULL) {
			free(tk);
			return NULL; // die
		}
	}

	tk->ref_count = 0;
	tk->length = 0;
	tk->next = NULL;
	_clean_token_fields( tk );
	return tk;
}

Token *AbstractTokenType::_get_from_cache(TokensCacheMany& tc) {
	return tc.standard.get();
}

Token *AbstractTokenType::_alloc_from_cache(TokensCacheMany& tc) {
	return tc.standard.alloc();
}

void AbstractTokenType::_clean_token_fields( Token *t ) {
}

void AbstractTokenType::FreeToken( TokensCacheMany& tc, Token *token ) {
	tc.standard.store( token );
}

//=====================================
// AbstractQuoteTokenType
//=====================================

Token *AbstractQuoteTokenType::_get_from_cache(TokensCacheMany& tc) {
	return tc.quote.get();
}

Token *AbstractQuoteTokenType::_alloc_from_cache(TokensCacheMany& tc) {
	return tc.quote.alloc();
}

void AbstractQuoteTokenType::_clean_token_fields( Token *t ) {
	QuoteToken *t2 = static_cast<QuoteToken*>( t );
	t2->seperator = 0;
	t2->state = 0;
	t2->current_section = 0;
}

void AbstractQuoteTokenType::FreeToken( TokensCacheMany& tc, Token *token ) {
	QuoteToken *t2 = static_cast<QuoteToken*>( token );
	tc.quote.store( t2 );
}

//=====================================
// Tokenizer
//=====================================

Token *Tokenizer::pop_one_token() {
	if (tokens_found_head == NULL)
		return NULL;
	Token *tk = tokens_found_head;
	tokens_found_head = tokens_found_head->next;
	if ( NULL == tokens_found_head )
		tokens_found_tail = NULL;
	return tk;
}

void Tokenizer::freeToken(Token *t) {
	if (t->ref_count > 0) {
		t->ref_count--;
		return;
	}
	t->ref_count = 0;
	t->length = 0;
	AbstractTokenType *type = t->type;
	t->type = NULL;
	type->FreeToken( this->m_TokensCache, t );
}

void Tokenizer::_new_token(TokenTypeNames new_type) {
	Token *tk;
	if (c_token == NULL) {
		tk = TokenTypeNames_pool[new_type]->GetNewToken(this, this->m_TokensCache, line_length);
	} else {
		if (c_token->length > 0) {
			_finalize_token();
			tk = TokenTypeNames_pool[new_type]->GetNewToken(this, this->m_TokensCache, line_length);
		} else {
			// FIXME - switch token type
			tk = c_token;
		}
	}
	tk->type = TokenTypeNames_pool[new_type];
	c_token = tk;
}

void Tokenizer::keep_significant_token(Token *t) {
	unsigned char oldest = ( m_nLastSignificantPos + 1 ) % NUM_SIGNIFICANT_KEPT;
	if (m_LastSignificant[oldest] != NULL) {
		freeToken(m_LastSignificant[oldest]);
	}
	t->ref_count++;
	m_LastSignificant[oldest] = t;
	m_nLastSignificantPos = oldest;
}

TokenTypeNames Tokenizer::_finalize_token() {
	if (c_token == NULL)
		return zone;

	if (c_token->length != 0) {
		c_token->text[c_token->length] = '\0';
		c_token->next = NULL;
		if ( NULL == tokens_found_tail ) {
			tokens_found_head = c_token;
		} else {
			tokens_found_tail->next = c_token;
		}
		tokens_found_tail = c_token;
		if (c_token->type->significant) {
			keep_significant_token(c_token);
		}
	} else {
		freeToken(c_token);
	}

	c_token = NULL;
	return zone;
}

Tokenizer::Tokenizer() 
	: 
	c_token(NULL),
	c_line(NULL),
	line_pos(0),
	line_length(0),
	local_newline('\n'),
	tokens_found_head(NULL), 
	tokens_found_tail(NULL),
	zone(Token_WhiteSpace),
	m_nLastSignificantPos(0)
{
	for (int ix = 0; ix < Token_LastTokenType; ix++) {
		TokenTypeNames_pool[Token_NoType] = NULL;
	}
	TokenTypeNames_pool[Token_NoType] = NULL;
	TokenTypeNames_pool[Token_WhiteSpace] = &m_WhiteSpaceToken;
	TokenTypeNames_pool[Token_Comment] = &m_CommentToken;
	TokenTypeNames_pool[Token_Structure] = &m_StructureToken;
	TokenTypeNames_pool[Token_Magic] = &m_MagicToken;
	TokenTypeNames_pool[Token_Operator] = &m_OperatorToken;
	TokenTypeNames_pool[Token_Unknown] = &m_UnknownToken;
	TokenTypeNames_pool[Token_Symbol] = &m_SymbolToken;
	TokenTypeNames_pool[Token_Operator_Attribute] = &m_AttributeOperatorToken;
	TokenTypeNames_pool[Token_Quote_Double] = &m_DoubleQuoteToken;
	TokenTypeNames_pool[Token_Quote_Single] = &m_SingleQuoteToken;
	TokenTypeNames_pool[Token_QuoteLike_Backtick] = &m_BacktickQuoteToken;
	TokenTypeNames_pool[Token_Word] = &m_WordToken;
	TokenTypeNames_pool[Token_Quote_Literal] = &m_LiteralQuoteToken;
	TokenTypeNames_pool[Token_Quote_Interpolate] = &m_InterpolateQuoteToken;
	TokenTypeNames_pool[Token_QuoteLike_Words] = &m_WordsQuoteLikeToken;
	TokenTypeNames_pool[Token_QuoteLike_Command] = &m_CommandQuoteLikeToken;
	TokenTypeNames_pool[Token_QuoteLike_Readline] = &m_ReadlineQuoteLikeToken;
	TokenTypeNames_pool[Token_Regexp_Match] = &m_MatchRegexpToken;
	TokenTypeNames_pool[Token_Regexp_Match_Bare] = &m_BareMatchRegexpToken;
	TokenTypeNames_pool[Token_QuoteLike_Regexp] = &m_RegexpQuoteLikeToken;
	TokenTypeNames_pool[Token_Regexp_Substitute] = &m_SubstituteRegexpToken;
	TokenTypeNames_pool[Token_Regexp_Transliterate] = &m_TransliterateRegexpToken;
	TokenTypeNames_pool[Token_Number] = &m_NumberToken;
	TokenTypeNames_pool[Token_Number_Float] = &m_FloatNumberToken;
	TokenTypeNames_pool[Token_Number_Hex] = &m_HexNumberToken;
	TokenTypeNames_pool[Token_Number_Binary] = &m_BinaryNumberToken;
	TokenTypeNames_pool[Token_Number_Octal] = &m_OctalNumberToken;
	for (int ix = 0; ix < NUM_SIGNIFICANT_KEPT; ix++) {
		m_LastSignificant[ix] = NULL;
	}
}

Tokenizer::~Tokenizer() {
	Token *t;
	while ( ( t = pop_one_token() ) != NULL ) {
		freeToken( t );
	}
}

Token *Tokenizer::_last_significant_token(unsigned int n) {
	if (( n < 1) || (n > NUM_SIGNIFICANT_KEPT ))
		return NULL;
	unsigned int ix = ( m_nLastSignificantPos + NUM_SIGNIFICANT_KEPT - n + 1 ) % NUM_SIGNIFICANT_KEPT;
	return m_LastSignificant[ix];
}

OperatorOperandContext Tokenizer::_opcontext() {
	Token *t0 = _last_significant_token(1);
	if ( t0 == NULL )
		return ooc_Operand;
	TokenTypeNames p_type = t0->type->type;
	if ( ( p_type == Token_Symbol ) || ( p_type == Token_Magic ) || 
		 ( p_type == Token_Number ) || ( p_type == Token_ArrayIndex ) ||
		 ( p_type == Token_Quote_Single ) || ( p_type == Token_Quote_Double ) ||
		 ( p_type == Token_Quote_Interpolate ) || ( p_type == Token_Quote_Literal ) ||
		 ( p_type == Token_QuoteLike_Backtick ) || ( p_type == Token_QuoteLike_Readline ) ||
		 ( p_type == Token_QuoteLike_Command ) || ( p_type == Token_QuoteLike_Regexp ) ||
		 ( p_type == Token_QuoteLike_Words ) ) {
		return ooc_Operator;
	}
	if ( p_type == Token_Operator )
		return ooc_Operand;
	
	// FIXME: Are we searching for Structure tokens?
	if ( t0->length != 1 )
		return ooc_Unknown;

	uchar c_char = t0->text[0];
	if ( ( c_char == '(' ) || ( c_char == '{' ) || ( c_char == '[' ) ||  ( c_char == ';' ) ) {
		return ooc_Operand;
	}
	if ( c_char == '}' )
		return ooc_Operator;

	return ooc_Unknown;
}

//=====================================

LineTokenizeResults Tokenizer::tokenizeLine(char *line, ulong line_length) {
	line_pos = 0;
	c_line = line;
	this->line_length = line_length;
	if (c_token == NULL)
		_new_token(zone);

    while (line_length > line_pos) {
		CharTokenizeResults rv = c_token->type->tokenize(this, c_token, line[line_pos]);
        switch (rv) {
            case my_char:
				c_token->text[c_token->length++] = line[line_pos++];
                break;
            case done_it_myself:
                break;
            case error_fail:
                return tokenizing_fail;
        };
    }
    return reached_eol;
}

void Tokenizer::changeTokenType(TokenTypeNames new_type) {
	AbstractTokenType *oldType = c_token->type;
	AbstractTokenType *newType = TokenTypeNames_pool[new_type];

	if (oldType->isa(isToken_Extended) != newType->isa(isToken_Extended)) {
		Token *newToken = newType->GetNewToken( this, m_TokensCache, line_pos + 1 );
		char *temp_text = c_token->text;
		c_token->text = newToken->text;
		newToken->text = temp_text;

		newToken->length = c_token->length;
		c_token->length = 0;

		ulong aSize = c_token->allocated_size;
		c_token->allocated_size = newToken->allocated_size;
		newToken->allocated_size = aSize;

		freeToken( c_token );
		c_token = newToken;
	}
	c_token->type = newType;
}