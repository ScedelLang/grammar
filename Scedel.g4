grammar Scedel;

@header {
package org.pilov.scedel.antlr;
}

file : (importStatement | annotatedDecl)* EOF;

annotatedDecl : annotationLine* decl;

decl : typeDeclaration | validatorDeclaration;

importStatement : IMPORT StringLiteral;

annotationLine : AT annotationKey EQUAL StringLiteral;

annotationKey : Identifier (DOT Identifier)*;

typeDeclaration : TYPE Identifier (EQUAL typeExpr)?;

validatorDeclaration : VALIDATOR Identifier LPAREN paramList? RPAREN EQUAL validatorBody;

typeExpr : unionExpr;

unionExpr : intersectExpr (PIPE intersectExpr)*;

intersectExpr : postfixExpr (AMP postfixExpr)*;

postfixExpr : atomExpr arraySuffix*;

atomExpr
    : literal
    | Identifier (LPAREN constraintList? RPAREN)?
    | recordType
    | dictType
    | conditionalType
    | LPAREN typeExpr RPAREN
    | ABSENT
    | nullableBaseOrId
    ;

nullableBaseOrId : QMARK Identifier;

arraySuffix : LBRACK constraintList? RBRACK;

recordType : LBRACE fieldList? RBRACE;

fieldList : field ( COMMA? field )* COMMA?;

field : Identifier (QMARK)? COLON typeExpr (DEFAULT defaultExpr)?;

defaultExpr
    : literal
    | LBRACK RBRACK
    | NULL
    ;

dictType : DICT LBRACE typeExpr COLON typeExpr RBRACE;

conditionalType : WHEN condExpr THEN typeExpr ELSE typeExpr;

condExpr : predicate;

predicate
    : path compareOp literal
    | path MATCHES RegexLiteral
    | NOT predicate
    | LPAREN predicate RPAREN
    | predicate (AND | OR) predicate
    ;

path : ('this' | '$root' | Identifier) (DOT Identifier)*;

compareOp : EQUAL | NOT_EQUAL | LESS | LESS_OR_EQUAL | MOR | MORE_OR_EQUAL;

paramList : param ( COMMA param )* ;
param : Identifier (COLON Identifier)? (EQUAL literal)?;

validatorBody
    : RegexLiteral
    | NOT RegexLiteral
    | LBRACE RULE COLON ruleExpr COMMA? MESSAGE COLON StringLiteral RBRACE
    ;

ruleExpr
    : predicate
    | RegexLiteral
    | NOT RegexLiteral
    ;

constraintList : constraint ( COMMA constraint )*;
constraint : Identifier (COLON argValue)?;

argValue : literal| Identifier;

literal
    : StringLiteral
    | NumberLiteral
    | TRUE
    | FALSE
    | NULL
    ;

StringLiteral   : ('"' (~["\\] | '\\' .)* '"') | ('\'' (~['\\] | '\\' .)* '\'');
NumberLiteral   : '-'? [0-9]+ ('.' [0-9]+)? ;
IntLiteral      : [0-9]+ ;
RegexLiteral    : '/' (~[/\r\n] | '\\' .)* '/' ;
LineComment     : '//' ~[\r\n]* -> channel(HIDDEN) ;
BlockComment    : '/*' .*? '*/' -> channel(HIDDEN) ;
WS              : [ \t\r\n]+ -> channel(HIDDEN) ;

// === KEYWORDS ===
IMPORT    : 'import';
TYPE      : 'type';
RULE      : 'rule';
VALIDATOR : 'validator';
DEFAULT   : 'default';
MESSAGE   : 'message';
WHEN      : 'when';
THEN      : 'then';
ELSE      : 'else';
MATCHES   : 'matches';
DICT      : 'dict';
ABSENT    : 'absent';
TRUE      : 'true';
FALSE     : 'false';
NULL      : 'null';
NOT       : 'not';
AND       : 'and';
OR        : 'or';
THIS      : 'this';
ROOT      : '$root';

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
LESS_OR_EQUAL : '>=';
MORE_OR_EQUAL : '<=';
DOT       : '.';

Identifier      : [a-zA-Z_][a-zA-Z0-9_]* ;
