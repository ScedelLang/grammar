// RFC 0.14.2
grammar Scedel;

file : versionDirective? includeStatement* fileItem* EOF;

versionDirective : scedelVersionKw VersionLiteral;

fileItem : targetedAnnotationStatement | annotatedDecl;

annotatedDecl : inlineAnnotation* decl;

decl : typeDeclaration | validatorDeclaration;

includeStatement : includeKw StringLiteral;

inlineAnnotation : AT annotationKey (EQUAL StringLiteral)?;

targetedAnnotationStatement : AT annotationKey (EQUAL StringLiteral)? onKw annotationTarget;

annotationKey : identifier (DOT identifier)*;

annotationTarget
    : identifier
    | identifier DOT identifier (DOT identifier)*
    | identifier DOT LBRACE identifier (COMMA identifier)* RBRACE
    ;

typeDeclaration : typeKw identifier EQUAL typeExpr;

validatorDeclaration
    : validatorKw identifier LPAREN identifier (COMMA paramList)? RPAREN EQUAL validatorBody
    ;

typeExpr : unionExpr;

unionExpr : intersectExpr (PIPE intersectExpr)*;

intersectExpr : postfixExpr (AMP postfixExpr)*;

postfixExpr : atomExpr arraySuffix* nullableSuffix?;

nullableSuffix : QMARK;

absentKw : ABSENT;
atomExpr
    : literal
    | absentKw
    | identifier (LPAREN constraintList? RPAREN)?
    | recordType
    | dictType
    | conditionalType
    | LPAREN typeExpr RPAREN
    | nullableBaseOrId
    ;

nullableBaseOrId : QMARK identifier;

arraySuffix : LBRACK constraintList? RBRACK;

recordType : LBRACE fieldList? RBRACE;

fieldList : fieldDecl ( COMMA? fieldDecl )* COMMA?;

fieldDecl : inlineAnnotation* field;

field : identifier QMARK? COLON typeExpr (DEFAULT defaultExpr)?;

defaultExpr : expression;

nullKw : NULL;

dictKw : DICT;
dictType
    : dictKw LBRACE typeExpr COLON typeExpr RBRACE
    | dictKw LESS typeExpr COMMA typeExpr MOR
    ;

whenKw : WHEN;
thenKw : THEN;
elseKw : ELSE;
conditionalType : whenKw condExpr thenKw typeExpr elseKw typeExpr;

condExpr : expression;

predicate : predicateOrExpr;

matchesKw : MATCHES;
andKw : AND;
orKw : OR;
notKw : NOT;

predicateOrExpr : predicateAndExpr (orKw predicateAndExpr)*;

predicateAndExpr : predicateNotExpr (andKw predicateNotExpr)*;

predicateNotExpr
    : notKw predicateNotExpr
    | predicatePrimaryExpr
    ;

predicatePrimaryExpr
    : additiveExpr compareOp additiveExpr
    | additiveExpr matchesKw RegexLiteral
    | additiveExpr
    ;

expression : predicate;

additiveExpr : multiplicativeExpr ((PLUS | MINUS) multiplicativeExpr)*;

multiplicativeExpr : unaryExpr ((STAR | SLASH) unaryExpr)*;

unaryExpr
    : (PLUS | MINUS) unaryExpr
    | valueExpr
    ;

valueExpr
    : literal
    | path
    | functionCall
    | emptyArrayExpr
    | LPAREN expression RPAREN
    ;

functionCall : identifier LPAREN expressionList? RPAREN;

expressionList : expression ( COMMA expression )*;

emptyArrayExpr : LBRACK RBRACK;

thisKw : THIS;
parentKw : PARENT;
rootKw : ROOT;
path : (thisKw | parentKw | rootKw | VariableIdentifier | identifier) (DOT identifier)*;

compareOp : EQUAL | NOT_EQUAL | LESS | LESS_OR_EQUAL | MOR | MORE_OR_EQUAL;

paramList : param ( COMMA param )*;

param : identifier (COLON identifier)? (EQUAL expression)?;

validatorBody : expression;

constraintList : constraint ( COMMA constraint )*;

constraint
    : identifier (COLON notKw? argValue | LPAREN constraintCallArgList? RPAREN)?
    ;

constraintCallArgList : constraintCallArg (COMMA constraintCallArg)*;

constraintCallArg : (identifier COLON)? expression;

argValue
    : expression
    | LBRACK expression (COMMA expression)* RBRACK
    ;

trueKw : TRUE;
falseKw : FALSE;
literal
    : DurationLiteral
    | StringLiteral
    | VersionLiteral
    | NumberLiteral
    | UnsignedInt
    | trueKw
    | falseKw
    | nullKw
    ;

identifier
    : Identifier
    | SCedelVersionKw
    | INCLUDE
    | TYPE
    | VALIDATOR
    | ABSENT
    | DEFAULT
    | NULL
    | DICT
    | WHEN
    | THEN
    | ELSE
    | MATCHES
    | AND
    | OR
    | NOT
    | THIS
    | PARENT
    | ROOT
    | ON
    | TRUE
    | FALSE
    ;

scedelVersionKw : SCedelVersionKw;
includeKw : INCLUDE;
typeKw : TYPE;
validatorKw : VALIDATOR;
onKw : ON;

/* ===== LEXER ===== */

DurationLiteral
    : '\'' '-'? [0-9]+ [ \t]+ DurationWordUnit '\''
    | '-'? [0-9]+ DurationUnit
    ;
StringLiteral   : ('"' (~["\\] | '\\' .)* '"') | ('\'' (~['\\] | '\\' .)* '\'');
VersionLiteral  : [0-9]+ '.' [0-9]+ ('.' [0-9]+)? ;
UnsignedInt     : [0-9]+ ;
NumberLiteral   : [0-9]+ ('.' [0-9]+)? ;
RegexLiteral    : '/' ~[*](~[/\r\n] | '\\' .)* '/' ;
LineComment     : '//' ~[\r\n]* -> channel(HIDDEN) ;
BlockComment    : '/*' .*? '*/' -> channel(HIDDEN) ;
WS              : [ \t\r\n]+ -> channel(HIDDEN) ;

fragment DurationUnit
    : 'ms'
    | 's'
    | 'm'
    | 'h'
    | 'd'
    | 'w'
    ;

fragment DurationWordUnit
    : DurationUnit
    | 'millisecond' 's'?
    | 'second' 's'?
    | 'minute' 's'?
    | 'hour' 's'?
    | 'day' 's'?
    | 'week' 's'?
    ;

// === PUNCTUATION / OPERATORS ===
AT        : '@';
LBRACE    : '{';
RBRACE    : '}';
LPAREN    : '(';
RPAREN    : ')';
LBRACK    : '[';
RBRACK    : ']';
COLON     : ':';
COMMA     : ',';
PIPE      : '|';
AMP       : '&';
QMARK     : '?';
EQUAL     : '=';
NOT_EQUAL : '!=';
LESS      : '<';
MOR       : '>';
LESS_OR_EQUAL : '<=';
MORE_OR_EQUAL : '>=';
PLUS      : '+';
MINUS     : '-';
STAR      : '*';
SLASH     : '/';
DOT       : '.';

SCedelVersionKw : 'scedel-version';
INCLUDE   : 'include';
TYPE      : 'type';
VALIDATOR : 'validator';
ABSENT    : 'absent';
DEFAULT   : 'default';
NULL      : 'null';
DICT      : 'dict';
WHEN      : 'when';
THEN      : 'then';
ELSE      : 'else';
MATCHES   : 'matches';
AND       : 'and';
OR        : 'or';
NOT       : 'not';
THIS      : 'this';
PARENT    : 'parent';
ROOT      : 'root';
ON        : 'on';
TRUE      : 'true';
FALSE     : 'false';

VariableIdentifier : '$' [a-zA-Z_][a-zA-Z0-9_]* ;
Identifier : [a-zA-Z_][a-zA-Z0-9_]* ;
