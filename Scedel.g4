grammar Scedel;

file : (importStatement | annotatedDecl)* EOF;

annotatedDecl : annotationLine* decl;

decl : typeDeclaration | validatorDeclaration;

importStatement : 'import' StringLiteral;

annotationLine : '@' annotationKey '=' StringLiteral;

annotationKey : Identifier ('.' Identifier)*;

typeDeclaration : 'type' Identifier ('=' typeExpr)?;

validatorDeclaration : 'validator' Identifier '(' paramList? ')' '=' validatorBody;

typeExpr : unionExpr;

unionExpr : intersectExpr ('|' intersectExpr)*;

intersectExpr : postfixExpr ('&' postfixExpr)*;

postfixExpr : atomExpr arraySuffix*;

atomExpr
    : literal
    | Identifier ('(' constraintList? ')')?
    | recordType
    | dictType
    | conditionalType
    | '(' typeExpr ')'
    | ABSENT
    | nullableBaseOrId
    ;

nullableBaseOrId : '?' Identifier;

arraySuffix : '[' constraintList? ']';

recordType : '{' fieldList? '}';

fieldList : field ( ','? field )* ','?;

field : Identifier ('?')? ':' typeExpr ('default' defaultExpr)?;

defaultExpr
    : literal
    | '[' ']'
    | 'null'
    ;

dictType : 'dict' '{' typeExpr ':' typeExpr '}';

conditionalType : 'when' condExpr 'then' typeExpr 'else' typeExpr;

condExpr : predicate;

predicate
    : path compareOp literal
    | path 'matches' RegexLiteral
    | 'not' predicate
    | '(' predicate ')'
    | predicate ('and' | 'or') predicate
    ;

path : ('this' | '$root' | Identifier) ('.' Identifier)*;

compareOp : '=' | '!=' | '<' | '<=' | '>' | '>=';

paramList : param ( ',' param )* ;
param : Identifier (':' Identifier)? ('=' literal)?;

validatorBody
    : RegexLiteral
    | 'not' RegexLiteral
    | '{' 'rule' ':' ruleExpr ','? 'message' ':' StringLiteral '}'
    ;

ruleExpr
    : predicate
    | RegexLiteral
    | 'not' RegexLiteral
    ;

constraintList : constraint ( ',' constraint )*;
constraint : Identifier (':' argValue)?;

argValue : literal| Identifier;

literal
    : StringLiteral
    | NumberLiteral
    | 'true'
    | 'false'
    | 'null'
    ;

StringLiteral   : ('"' (~["\\] | '\\' .)* '"') | ('\'' (~['\\] | '\\' .)* '\'');
NumberLiteral   : '-'? [0-9]+ ('.' [0-9]+)? ;
IntLiteral      : [0-9]+ ;
RegexLiteral    : '/' (~[/\\] | '\\/')* '/' ;
LineComment     : '//' ~[\r\n]* -> skip ;
BlockComment    : '/*' .*? '*/' -> skip ;
Identifier      : [a-zA-Z_][a-zA-Z0-9_]* ;
WS              : [ \t\r\n]+ -> skip ;
ABSENT          : 'absent';
