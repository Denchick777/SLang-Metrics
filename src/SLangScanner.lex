/**
 * SLangScanner.lex file, Version 0.1.0
 *
 * Expected file format is Unicode. In the event that no
 * byte order mark prefix is found, revert to raw bytes.
 */
%option classes, codepage:raw, stack, unicode, out:src\SLangScanner.cs

%using SLangParser;

%namespace SLangScanner
%visibility internal

%x COMMENT

WS	    [\u0020\u0009\u000D\u000A]

ND      [[:IsLetter:]_]
D       [[:IsDigit:]]
ID      {ND}({ND}|{D}|$)*

DEC     {D}({D}|_)*
INT     (0[ob])?{DEC}|0x({D}|[A-Fa-f])({D}|[A-Fa-f_])*

EXP     [Ee][+\-]?{DEC}
REAL    {DEC}({EXP}|\.{DEC}({EXP})?)

CHAR    '(\\.|[^\\'])+'
STR     \"(\\.|[^\\"])*\"

%%

{WS}               { /* ignore whitespaces */ }

// ============== COMMENTS ==============

"//"[^\n\r]*$      { /* ignore inline comment */ }

"/*"               { yy_push_state(COMMENT); }
<COMMENT> {
  "/*"             { yy_push_state(COMMENT); }
  "*/"             { yy_pop_state(); }
  (.|\n)           { /* ignore block comment content */ }
}

// ============= SEPARATORS =============

","                { return (int)Tokens.COMMA; }
"."                { return (int)Tokens.DOT; }
";"                { return (int)Tokens.SEMICOLON; }
":"                { return (int)Tokens.COLON; }
"("                { return (int)Tokens.LPAREN; }
")"                { return (int)Tokens.RPAREN; }
"["                { return (int)Tokens.LBRACKET; }
"]"                { return (int)Tokens.RBRACKET; }
".."               { return (int)Tokens.GENERATOR; }
"->"               { return (int)Tokens.SINGLE_ARROW; }
"=>"               { return (int)Tokens.DOUBLE_ARROW; }
"?"                { return (int)Tokens.QUESTION; }

// ============= OPERATORS ==============

"+"                { return (int)Tokens.PLUS; }
"-"                { return (int)Tokens.MINUS; }
"*"                { return (int)Tokens.ASTERISK; }
"/"                { return (int)Tokens.SLASH; }
"**"               { return (int)Tokens.DBL_ASTERISK; }
"|"                { return (int)Tokens.VERTICAL; }
"||"               { return (int)Tokens.DBL_VERTICAL; }
"&"                { return (int)Tokens.AMPERSAND; }
"&&"               { return (int)Tokens.DBL_AMPERSAND; }
"^"                { return (int)Tokens.CARET; }
"~"                { return (int)Tokens.TILDE; }
"<"                { return (int)Tokens.LESS; }
"<="               { return (int)Tokens.LESS_EQUALS; }
">"                { return (int)Tokens.GREATER; }
">="               { return (int)Tokens.GREATER_EQUALS; }
"="                { return (int)Tokens.EQUALS; }
"/="               { return (int)Tokens.SLASH_EQUALS; }
"<>"               { return (int)Tokens.LESS_GREATER; }
":="               { return (int)Tokens.COLON_EQUALS; }

// ============== KEYWORDS ==============

"and"{WS}+"then"   { return (int)Tokens.AND_THEN; }
"or"{WS}+"else"    { return (int)Tokens.OR_ELSE; }

"abstract"         { return (int)Tokens.ABSTRACT; }
"alias"            { return (int)Tokens.ALIAS; }
"as"               { return (int)Tokens.AS; }
"break"            { return (int)Tokens.BREAK; }
"check"            { return (int)Tokens.CHECK; }
"concurrent"       { return (int)Tokens.CONCURRENT; }
"const"            { return (int)Tokens.CONST; }
"deep"             { return (int)Tokens.DEEP; }
"do"               { return (int)Tokens.DO; }
"else"             { return (int)Tokens.ELSE; }
"elsif"            { return (int)Tokens.ELSIF; }
"end"              { return (int)Tokens.END; }
"ensure"           { return (int)Tokens.ENSURE; }
"extend"           { return (int)Tokens.EXTEND; }
"external"         { return (int)Tokens.EXTERNAL; }
"final"            { return (int)Tokens.FINAL; }
"foreign"          { return (int)Tokens.FOREIGN; }
"hidden"           { return (int)Tokens.HIDDEN; }
"if"               { return (int)Tokens.IF; }
"in"               { return (int)Tokens.IN; }
"init"             { return (int)Tokens.INIT; }
"invariant"        { return (int)Tokens.INVARIANT; }
"is"               { return (int)Tokens.IS; }
"loop"             { return (int)Tokens.LOOP; }
"new"              { return (int)Tokens.NEW; }
"none"             { return (int)Tokens.NONE; }
"not"              { return (int)Tokens.NOT; }
"old"              { return (int)Tokens.OLD; }
"override"         { return (int)Tokens.OVERRIDE; }
"pure"             { return (int)Tokens.PURE; }
"raise"            { return (int)Tokens.RAISE; }
"ref"              { return (int)Tokens.REF; }
"require"          { return (int)Tokens.REQUIRE; }
"return"           { return (int)Tokens.RETURN; }
"routine"          { return (int)Tokens.ROUTINE; }
"safe"             { return (int)Tokens.SAFE; }
"super"            { return (int)Tokens.SUPER; }
"then"             { return (int)Tokens.THEN; }
"this"             { return (int)Tokens.THIS; }
"unit"             { return (int)Tokens.UNIT; }
"use"              { return (int)Tokens.USE; }
"val"              { return (int)Tokens.VAL; }
"when"             { return (int)Tokens.WHEN; }
"while"            { return (int)Tokens.WHILE; }

// ============= IDENTIFIER =============

{ID}               {
    yylval = yytext;
    return (int)Tokens.IDENTIFIER;
}

// ============== LITERALS ==============

{INT}              |
{REAL}             |
{CHAR}             |
{STR}              {
    yylval = yytext;
    return (int)Tokens.LITERAL;
}

// =========== LEXICAL ERRORS ===========

<COMMENT><<EOF>>   |
.                  { return (int)Tokens.error; }

%%