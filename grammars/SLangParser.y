/**
 * Parser spec for SLang
 * Process with > GPPG /gplex SLangParser.y
 *
 * Known conflicts:
 *   shift/reduce of PLUS/MINUS/LPAREN when consequent Expression constructs may appear
 *   shift/reduce of WHEN (exception handling inside exception handling)
 *   shift/reduce of COLON_EQUALS (probably, when assignment appears as function body)
 */

%output=src\SLangParser.cs

%using LanguageElements
%using SLangLookaheadScanner
%using System.IO

%namespace SLangParser
%visibility internal

%start Module

%union
{
    internal string s;
    internal string[] sa;
    internal CompoundName cn;
    internal LanguageElements.Type t;
    internal UnitTypeName utn;
    internal Block bl;
    internal BlockMember bm;
    internal Statement st;
    internal LinkedList<BlockMember> llbm;
    internal LinkedList<Block> llb;
    internal VariableDeclaration vd;
    internal RoutineDeclaration rd;
    internal UnitDeclaration ud;
    internal LinkedList<UnitName> llun;
    internal UnitName un;
    internal LinkedList<Declaration> lld;
    internal Declaration dc;
}

// ========== TYPE ASSIGNMENTS ==========

%type <cn> CompoundName
%type <utn> CompoundType  // TODO: change when other types will be considered
%type <utn> Type  // TODO: change when other types will be considered
%type <utn> UnitType  // TODO: change when other types will be considered
%type <utn> UnitTypeName
%type <t> AnchorType
%type <bl> Block
%type <llbm> BlockMemberSeqOpt
%type <bm> BlockMember
%type <bl> NestedBlock
%type <llbm> NestedBlockMemberSeqOpt
%type <bm> NestedBlockMember
%type <st> Statement
%type <st> IfStatement
%type <llb> ElseIfClauseSeqOpt
%type <bl> ElseIfClause
%type <bl> ElseClauseOpt
%type <st> LoopStatement
%type <vd> VariableDeclaration
%type <rd> RoutineDeclaration
%type <rd> OperatorRoutineDeclaration
%type <rd> InitRoutineDeclaration
%type <s> RoutineName
%type <sa> OperatorRoutineName
%type <s> AliasNameOpt
%type <bl> RoutineBody
%type <ud> UnitDeclaration
%type <llun> UnitDeclarationAdditions  // TODO: change actual type
%type <llun> InheritClauseOpt
%type <llun> BaseUnitSeq
%type <un> BaseUnitName
%type <lld> UnitMemberSeqOpt
%type <dc> UnitMember
%type <rd> UnitMemberRoutineDeclaration

// =============== TOKENS ===============

// Separators
%token COMMA
%token DOT
%token SEMICOLON
%token COLON
%token LPAREN
%token RPAREN
%token LBRACKET
%token RBRACKET
//%token ASSIGNMENT
%token GENERATOR
%token SINGLE_ARROW  // TODO: add to specification
%token DOUBLE_ARROW
%token QUESTION

// Operators
%token <s> PLUS
%token <s> MINUS
%token <s> ASTERISK
%token <s> SLASH
%token <s> DBL_ASTERISK
%token <s> VERTICAL
%token <s> DBL_VERTICAL
%token <s> AMPERSAND
%token <s> DBL_AMPERSAND
%token <s> CARET
%token <s> TILDE
%token <s> LESS
%token <s> LESS_EQUALS
%token <s> GREATER
%token <s> GREATER_EQUALS
%token <s> EQUALS
%token <s> SLASH_EQUALS
%token <s> LESS_GREATER
%token <s> COLON_EQUALS

// Keywords
%token AND_THEN  // TODO: consider (no concrete specification given)
%token OR_ELSE  // TODO: consider (no concrete specification given)
%token ABSTRACT
%token ALIAS
%token AS
%token BREAK
%token CHECK  // TODO: remove from the specification
%token CONCURRENT
%token CONST
%token DEEP
%token DO
%token ELSE
%token ELSIF
%token END
%token ENSURE
%token EXTEND
%token EXTERNAL  // TODO: remove from the specification
%token FINAL
%token FOREIGN
%token HIDDEN
%token IF
%token IN  // TODO: consider (no concrete specification given)
%token INIT
%token INVARIANT
%token IS
%token LOOP
%token NEW
%token NONE  // TODO: add to specification
//%token NOT  // TODO: remove
%token OLD
%token OVERRIDE
%token PURE
%token RAISE
%token REF
%token REQUIRE
%token RETURN
%token ROUTINE
%token SAFE
%token SUPER
%token THEN
%token THIS
%token UNIT
%token USE
%token VAL
%token WHEN
%token WHILE

// Value-dependent tokens
%token <s> IDENTIFIER
%token <s> LITERAL

// Tokens for lookahead
%token NEW_LINE  // does not appear in any rule
%token CONTRACT_LABEL  // to distinct IDENTIFIER inside Expression with the name of the contract
%token LOOP_LABEL  // to distinct IDENTIFIER inside Expression with the name of the loop
%token WHILE_POSTTEST  // is WHILE keyword inside loop body either inner loop or do-while's condition?
%token JUST_BREAK  // does next IDENTIFIER belong to the BREAK keyword?
%token JUST_RETURN  // does next Expression belong to the RETURN keyword?
%token JUST_RAISE  // does next Expression belong to the RAISE keyword?
%token <s> FUNCTION_ID  // is next IDENTIFIER - RoutineName?
%token <s> OP_AS_ROUTINE_NAME  // is next operator inside UnitDeclaration - RoutineName?

// ===== ASSOCIATIVITY & PRECEDENCE =====

// Lower priority

// Unit may be member of another Unit (each UnitMember may have specifier FINAL),
// but UnitDeclaration may have keyword FINAL itself.
%nonassoc JUST_HIDDEN
%nonassoc FINAL

// Make Expression explicitly part of the next assignment (if appears)
%nonassoc JUST_EXPRESSION
%nonassoc COLON_EQUALS

// Expression binary operators' precedence
%left LESS_GREATER
%left DBL_VERTICAL
%left DBL_AMPERSAND
%left VERTICAL
%left CARET
%left AMPERSAND
%left EQUALS SLASH_EQUALS
%left LESS LESS_EQUALS GREATER GREATER_EQUALS
%left PLUS MINUS
%left ASTERISK SLASH
%left DBL_ASTERISK

// Higher priority

%%

// General /////////////////////////////////////////////////////////////////////////////////////////////////////////////

Module
    : UseDirectiveSeqOpt BlockMemberSeqOpt
    {
        // UseDirectiveSeqOpt is not used for now
        this.parsedProgram = new Module($2);
    }
    ;

// Primitives ***

IdentifierSeq
    :                     IDENTIFIER
    | IdentifierSeq COMMA IDENTIFIER
    ;

CompoundName
    :                  IDENTIFIER
    {
        $$ = new CompoundName($1);
    }
    | CompoundName DOT IDENTIFIER
    {
        $1.AddLast($3);
        $$ = $1;
    }
    ;

// Use directive ***

UseDirectiveSeqOpt
    : /* empty */
    | UseDirectiveSeqOpt USE UsedUnitSeq
    ;

UseClauseOpt
    : /* empty */
    | USE       UsedUnitSeq
    | USE CONST UsedUnitSeq
    ;

UsedUnitSeq
    :                   UsedUnit
    | UsedUnitSeq COMMA UsedUnit
    ;

UsedUnit
    : CompoundType
    | CompoundType AS IDENTIFIER
    ;

// Generic formals ***

GenericFormalsOpt
    : /* empty */
    | LBRACKET GenericFormalSeq RBRACKET
    ;

GenericFormalSeq
    :                            GenericFormal
    | GenericFormalSeq COMMA     GenericFormal
    | GenericFormalSeq SEMICOLON GenericFormal
    ;

GenericFormal
    : IDENTIFIER
    | IDENTIFIER SINGLE_ARROW UnitTypeName
    | IDENTIFIER SINGLE_ARROW UnitTypeName INIT
    | IDENTIFIER SINGLE_ARROW UnitTypeName INIT RoutineFormals
    | IDENTIFIER COLON UnitTypeName
    ;

// Contracts ***

PreconditionOpt
    : /* empty */
    | REQUIRE      ContractEntranceFlagSetter PredicateSeq
    | REQUIRE ELSE ContractEntranceFlagSetter PredicateSeq
    ;

PostconditionOpt
    : /* empty */
    | ENSURE      ContractEntranceFlagSetter PredicateSeq
    | ENSURE THEN ContractEntranceFlagSetter PredicateSeq
    ;

InvariantOpt
    : /* empty */
    | INVARIANT ContractEntranceFlagSetter PredicateSeq
    ;

ContractEntranceFlagSetter  // XXX: important for lookahead
    : /* empty */  { scannerFlags.isInsideContract = true; }
    ;

PredicateSeq
    :                        Predicate
    | PredicateSeq COMMA     Predicate
//  | PredicateSeq SEMICOLON Predicate
    ;  // TODO: check, shift/reduce of semicolon

Predicate
    :                      Expression
    | CONTRACT_LABEL COLON Expression
    ;

// Type ***

CompoundType
    :                  Type
    {
        $$ = $1;
    }
    | CompoundType DOT Type
    {
        $1.AppendName($3.name);
        $$ = $1;
    }
    ;

Type
    : UnitType  { $$ = $1; }
    | AnchorType  { $$ = null; }
    | MultiType  { $$ = null; }
    | TupleType  { $$ = null; }
//  | RangeType  // TODO: introduce
//  | RoutineType  // TODO: introduce
    ;

UnitType
    :            UnitTypeName  { $$ = $1; }
    | REF        UnitTypeName  { $$ = $2; }
    | VAL        UnitTypeName  { $$ = $2; }
    | CONCURRENT UnitTypeName  { $$ = $2; }
    ;

UnitTypeName
    : IDENTIFIER
    {
        $$ = new UnitTypeName($1, null);
    }
    | IDENTIFIER GenericArgumentClause
    {
        $$ = new UnitTypeName($1, null);  // TODO: generics
    }
    ;

GenericArgumentClause
    : LBRACKET GenericArgumentSeq RBRACKET
    ;

GenericArgumentSeq
    :                          Expression
//  |                          Type
    | GenericArgumentSeq COMMA Expression
//  | GenericArgumentSeq COMMA Type
    ;

AnchorType
    : AS THIS
    | AS IDENTIFIER
//  | AS IDENTIFIER RoutineParameters  // TODO: review
    ;

MultiType
    :  UnitType VERTICAL UnitType
    | MultiType VERTICAL UnitType
    ;

TupleType
    : LPAREN                 RPAREN
    | LPAREN TupleElementSeq RPAREN
    ;

TupleElementSeq
    :                           TupleElement
    | TupleElementSeq COMMA     TupleElement
    | TupleElementSeq SEMICOLON TupleElement
    ;

TupleElement
    : Expression
    | Expression TypeAndInit
//  | VariableDeclaration  // shift/reduce (cannot decide what to do with IdentifierSeq)
    ;
/*
RangeType
    : Expression GENERATOR Expression
    ;  // TODO: review

RoutineType
    : RoutineFormals Block
    ;  // TODO: introduce; return type?
*/
// Expression //////////////////////////////////////////////////////////////////////////////////////////////////////////

Expression
    : UnaryExpression
//  | UnaryExpression IS UnitTypeName  // TODO: introduce
//  | UnaryExpression IN UnitTypeName  // TODO: introduce
//  | UnaryExpression IN Range  // TODO: introduce
    | Expression PLUS           Expression
    | Expression MINUS          Expression
    | Expression ASTERISK       Expression
    | Expression SLASH          Expression
    | Expression DBL_ASTERISK   Expression
    | Expression VERTICAL       Expression
    | Expression DBL_VERTICAL   Expression
    | Expression AMPERSAND      Expression
    | Expression DBL_AMPERSAND  Expression
    | Expression CARET          Expression
    | Expression LESS           Expression
    | Expression LESS_EQUALS    Expression
    | Expression GREATER        Expression
    | Expression GREATER_EQUALS Expression
    | Expression EQUALS         Expression
    | Expression SLASH_EQUALS   Expression
    | Expression LESS_GREATER   Expression
    ;  // TODO: probably bit shift operations

UnaryExpression
    : SecondaryExpression
    | TILDE UnaryExpression
    | PLUS  UnaryExpression
    | MINUS UnaryExpression
    ;  // FIXME: shift/reduce of PLUS and MINUS

SecondaryExpression
    : PrimaryExpression
    | SecondaryExpression LPAREN RPAREN
    | SecondaryExpression Tuple
    | SecondaryExpression DOT PrimaryExpression
    ;  // FIXME: shift/reduce of function call

PrimaryExpression
    : LITERAL  // TODO
    | TypeOrIdentifier
//  | OperatorSign  // TODO: consider later
    | INIT  // TODO: review
    | THIS
    | SUPER
//  | SUPER UnitTypeName  // TODO
//  | RETURN  // TODO: review
    | OLD IDENTIFIER  // TODO: review, Expression was used in the specification
    | Tuple
//  | LPAREN Expression RPAREN  // reduce/reduce with Tuple
    ;

TypeOrIdentifier
    : UnitTypeName  // TODO: review
//  | IDENTIFIER  // reduce/reduce conflict with `Type: IDENTIFIER;`
    ;

Tuple
    : TupleType
//  | TupleValue  // reduce/reduce, all tuples are types
    ;
/*
Range
    : Expression GENERATOR Expression
    ;  // TODO: introduce
*/
// Statement ///////////////////////////////////////////////////////////////////////////////////////////////////////////

Block
    : PreconditionOpt DO
        { scannerFlags.isInsideUnit = false; }  // XXX: important for lookahead
      BlockMemberSeqOpt PostconditionOpt ExceptionHandlerSeqOpt END
    {
        scannerFlags.isInsideContract = false;  // XXX: important for lookahead
        $$ = new Block($4);
    }
    ;

BlockMemberSeqOpt
    : /* empty */
    {
        $$ = new LinkedList<BlockMember>();
    }
    | BlockMemberSeqOpt BlockMember
    {
        $1.AddLast($2);
        $$ = $1;
    }
    ;

BlockMember
    : NestedBlockMember  { $$ = $1; }
    | Block  { $$ = $1; }  // Because `Statement: Block;` was removed (see NestedBlock)
    ;

ExceptionHandlerSeqOpt
    : /* empty */
    | ExceptionHandlerSeqOpt ExceptionHandler
    ;

ExceptionHandler
    : WHEN Expression DO NestedBlock
    ;  // FIXME: shift/reduce when nested exception handling

NestedBlock
    : PreconditionOpt    NestedBlockMemberSeqOpt PostconditionOpt ExceptionHandlerSeqOpt
    {
        scannerFlags.isInsideContract = false;  // XXX: important for lookahead
        $$ = new Block($2);
    }
    | PreconditionOpt DO NestedBlockMemberSeqOpt PostconditionOpt ExceptionHandlerSeqOpt
    {
        scannerFlags.isInsideContract = false;  // XXX: important for lookahead
        $$ = new Block($3);
    }
    ;

NestedBlockMemberSeqOpt
    : /* empty */
    {
        $$ = new LinkedList<BlockMember>();
    }
    | NestedBlockMember BlockMemberSeqOpt
    {
        $2.AddFirst($1);
        $$ = $2;
    }
    ;

NestedBlockMember
    : Statement  { $$ = $1; }
    | UnitDeclaration  { $$ = $1; }
    | RoutineDeclaration  { $$ = $1; }
    | VariableDeclaration  { $$ = $1; }
    ;

Statement
    : SEMICOLON  { $$ = null; }
    | NONE  { $$ = null; }
//  | Block  // Conflicts when used in NestedBlock
    | Assignment  { $$ = null; }
    | Expression %prec JUST_EXPRESSION  // TODO: change to function call
    | IfStatement  { $$ = $1; }
    | LoopStatement  { $$ = $1; }
    | BreakStatement  { $$ = null; }
    | ValueLossStatement  { $$ = null; }
    | ReturnStatement  { $$ = null; }
    | RaiseStatement  { $$ = null; }
    ;  // TODO: review

Assignment
    : SecondaryExpression COLON_EQUALS Expression
    ;  // FIXME: shift/reduce of COLON_EQUALS when `RoutineBody: DOUBLE_ARROW Statement;`

IfStatement
    : IF Expression            Block ElseIfClauseSeqOpt ElseClauseOpt END
    {
        $$ = new IfStatement($3, $4, $5);
    }
    | IF Expression THEN NestedBlock ElseIfClauseSeqOpt ElseClauseOpt END
    {
        $$ = new IfStatement($4, $5, $6);
    }
    ;

ElseIfClauseSeqOpt
    : /* empty */
    {
        $$ = new LinkedList<Block>();
    }
    | ElseIfClauseSeqOpt ElseIfClause
    {
        $1.AddLast($2);
        $$ = $1;
    }
    ;

ElseIfClause
    : ELSIF Expression            Block  { $$ = $3; }
    | ELSIF Expression THEN NestedBlock  { $$ = $4; }
    ;

ElseClauseOpt
    : /* empty */  { $$ = null; }
    | ELSE NestedBlock  { $$ = $2; }
    ;

LoopStatement
    : LoopLabelOpt                  LOOP NestedBlock END
    {
        $$ = new LoopStatement($3);
    }
    | LoopLabelOpt WHILE Expression LOOP NestedBlock END
    {
        $$ = new LoopStatement($5);
    }
    | LoopLabelOpt WHILE Expression      Block
    {
        $$ = new LoopStatement($4);
    }
    | LoopLabelOpt LOOP NestedBlock WHILE_POSTTEST Expression END
    {
        $$ = new LoopStatement($3);
    }
    ;

LoopLabelOpt
    : /* empty */
    | LOOP_LABEL COLON
    ;

BreakStatement
    : JUST_BREAK
    | BREAK IDENTIFIER
    ;

ValueLossStatement
    : QUESTION IDENTIFIER
    ;

ReturnStatement
    : JUST_RETURN
    | RETURN Expression
    ;

RaiseStatement
    : JUST_RAISE
    | RAISE Expression
    ;

// Variable ////////////////////////////////////////////////////////////////////////////////////////////////////////////

VariableDeclaration
    :                   IdentifierSeq TypeAndInit
    {
        $$ = new VariableDeclaration();
    }
    | VariableSpecifier IdentifierSeq TypeAndInit
    {
        $$ = new VariableDeclaration();
    }
    ;  // TODO: content consideration

VariableSpecifier
    : CONST
    | CONST DEEP
    ;

TypeAndInit
    :                             IS Expression
    | COLON          CompoundType
    | COLON QUESTION UnitType
    | COLON          CompoundType IS Expression
    | COLON QUESTION UnitType     IS Expression
    ;  // TODO: review

// Routine /////////////////////////////////////////////////////////////////////////////////////////////////////////////

RoutineDeclaration
    :                  RoutineName GenericFormalsOpt RoutineFormals ReturnTypeOpt UseDirectiveSeqOpt RoutineBody
    {
        $$ = new RoutineDeclaration($1, null, $6);
    }
    | RoutineSpecifier RoutineName GenericFormalsOpt RoutineFormals ReturnTypeOpt UseDirectiveSeqOpt RoutineBody
    {
        $$ = new RoutineDeclaration($2, null, $7);
    }
    ;  // TODO: change UseDirectiveSeqOpt to UseClauseOpt?

OperatorRoutineDeclaration
    :                  OperatorRoutineName GenericFormalsOpt RoutineFormals ReturnTypeOpt UseDirectiveSeqOpt RoutineBody
    {
        $$ = new RoutineDeclaration($1[0], $1[1], $6);
    }
    | RoutineSpecifier OperatorRoutineName GenericFormalsOpt RoutineFormals ReturnTypeOpt UseDirectiveSeqOpt RoutineBody
    {
        $$ = new RoutineDeclaration($2[0], $2[1], $7);
    }
    ;  // TODO: review; change UseDirectiveSeqOpt to UseClauseOpt?

InitRoutineDeclaration
    :                  INIT GenericFormalsOpt RoutineFormals ReturnTypeOpt UseDirectiveSeqOpt RoutineBody
    {
        $$ = new RoutineDeclaration("init", null, $6);  // TODO: remove constant string
    }
    | RoutineSpecifier INIT GenericFormalsOpt RoutineFormals ReturnTypeOpt UseDirectiveSeqOpt RoutineBody
    {
        $$ = new RoutineDeclaration("init", null, $7);  // TODO: remove constant string
    }
    ;  // TODO: review; change UseDirectiveSeqOpt to UseClauseOpt?

RoutineSpecifier
    : PURE
    | SAFE
    | OVERRIDE
    | PURE OVERRIDE
    | SAFE OVERRIDE
    ;  // TODO: review

RoutineName
    : FUNCTION_ID  { $$ = $1; }
//  | OP_AS_ROUTINE_NAME AliasNameOpt
//  | COLON_EQUALS
    | LPAREN RPAREN  { $$ = "()"; }  // TODO: review
    ;

OperatorRoutineName
    : OP_AS_ROUTINE_NAME AliasNameOpt  { $$ = new string[] {$1, $2}; }
    | COLON_EQUALS  { $$ = new string[] {":=", null}; }
    ;

AliasNameOpt
    : /* empty */  { $$ = null; }
    | ALIAS FUNCTION_ID  { $$ = $2; }
    ;

RoutineFormals
    : LPAREN                     RPAREN
    | LPAREN RoutineParameterSeq RPAREN
    ;

RoutineParameterSeq
    :                               VariableDeclaration
    | RoutineParameterSeq COMMA     VariableDeclaration
    | RoutineParameterSeq SEMICOLON VariableDeclaration
    ;

ReturnTypeOpt
    : /* empty */
    | COLON CompoundType
    ;

RoutineBody
    : Block
    {
        $$ = $1;
    }
    | DOUBLE_ARROW Statement  // TODO: review (conflicts with Assignment and Expression content)
    {
        LinkedList<BlockMember> list = new LinkedList<BlockMember>();
        list.AddFirst($2);
        $$ = new Block(list);
    }
    | IS ABSTRACT  // TODO: consider contracts
    {
        $$ = null;
    }
    | IS FOREIGN  // TODO: consider contracts
    {
        $$ = null;
    }
    ;

// Unit ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

UnitDeclaration
    : UnitSpecifiersOpt UNIT
        UnitEntranceFlagSetter  // XXX: important for lookahead
      CompoundName UnitDeclarationAdditions    UnitMemberSeqOpt InvariantOpt END
    {
        scannerFlags.isInsideUnit = false;  // XXX: important for lookahead
        scannerFlags.isInsideContract = false;  // XXX: important for lookahead
        $$ = new UnitDeclaration($4, $5, $6);
    }
    | UnitSpecifiersOpt UNIT
        UnitEntranceFlagSetter  // XXX: important for lookahead
      CompoundName UnitDeclarationAdditions IS UnitMemberSeqOpt InvariantOpt END
    {
        scannerFlags.isInsideUnit = false;  // XXX: important for lookahead
        scannerFlags.isInsideContract = false;  // XXX: important for lookahead
        $$ = new UnitDeclaration($4, $5, $7);
    }
    ;  // TODO: specifiers and invariant consideration

UnitEntranceFlagSetter
    : /* empty */  { scannerFlags.isInsideUnit = true; }
    ;

UnitSpecifiersOpt
    : /* empty */
    |       UnitSpecifier
    | FINAL UnitSpecifier
    ;

UnitSpecifier
    : REF
    | VAL
    | CONCURRENT
    | ABSTRACT
    ;

UnitDeclarationAdditions
    : UnitAliasNameOpt GenericFormalsOpt InheritClauseOpt UseClauseOpt
    {
        $$ = $3;  // TODO: other declaration additions
    }
    ;

UnitAliasNameOpt
    : /* empty */
    | ALIAS IDENTIFIER
    ;

InheritClauseOpt
    : /* empty */  { $$ = null; }
    | EXTEND BaseUnitSeq  { $$ = $2; }
    ;

BaseUnitSeq
    :                   BaseUnitName
    {
        LinkedList<UnitName> list = new LinkedList<UnitName>();
        list.AddFirst($1);
        $$ = list;
    }
    | BaseUnitSeq COMMA BaseUnitName
    {
        $1.AddLast($3);
        $$ = $1;
    }
    ;

BaseUnitName
    :       CompoundType
    {
        if ($1 == null)  // TODO: remove nulls
        {
            $$ = null;
        }
        else
        {
            $$ = new UnitName($1, true);
        }
    }
    | TILDE CompoundType
    {
        if ($2 == null)  // TODO: remove nulls
        {
            $$ = null;
        }
        else
        {
            $$ = new UnitName($2, true);
        }
    }
    ;

UnitMemberSeqOpt
    : /* empty */
    {
        $$ = new LinkedList<Declaration>();
    }
    | UnitMemberSeqOpt                     UnitMember
    {
        scannerFlags.isInsideUnit = true;  // XXX: important for lookahead
        $1.AddLast($2);
        $$ = $1;
    }
    | UnitMemberSeqOpt UnitMemberSpecifier UnitMember
    {
        scannerFlags.isInsideUnit = true;  // XXX: important for lookahead
        $1.AddLast($3);  // TODO: specifiers
        $$ = $1;
    }
    ;

UnitMemberSpecifier
    : HIDDEN %prec JUST_HIDDEN
    | HIDDEN FINAL
    ;

UnitMember
    : SEMICOLON  { $$ = null; }  // All other statements are restricted
    | UnitDeclaration  { $$ = $1; }
    | UnitMemberRoutineDeclaration  { $$ = $1; }
    | VariableDeclaration  { $$ = $1; }
    | ConstObjectDeclaration  { $$ = null; }
    ;  // FIXME: shift/reduce of OperatorRoutineDeclaration with Expression

UnitMemberRoutineDeclaration
    : RoutineDeclaration  { $$ = $1; }
    | InitRoutineDeclaration  { $$ = $1; }
    | OperatorRoutineDeclaration  { $$ = $1; }
    ;

ConstObjectDeclaration
    : CONST IS
        { scannerFlags.isInsideUnit = false; }  // XXX: important for lookahead
      ConstObjectSeqOpt END
    ;

ConstObjectSeqOpt
    : /* empty */
    | ConstObjectSeq
    ;

ConstObjectSeq
    :                      Expression
    | ConstObjectSeq COMMA Expression
    ;

%%

private Module parsedProgram;
private ScannerFlags scannerFlags;

private Parser(Scanner scanner, ref ScannerFlags scannerFlags) : base(scanner)
{
    this.parsedProgram = null;
    this.scannerFlags = scannerFlags;
}

internal static Module parseProgram(String filePath)
{
    FileStream file = new FileStream(filePath, FileMode.Open);
    ScannerFlags scannerFlags = new ScannerFlags();
    Scanner scanner = new Scanner(file, ref scannerFlags);
    Parser parser = new Parser(scanner, ref scannerFlags);
    bool res = parser.Parse();
    file.Close();
    if (parser.parsedProgram != null)
    {
        parser.parsedProgram.ssMetrics = scanner.ssMetrics;
    }
    return res ? parser.parsedProgram : null;
}
