# RFC: Scedel Language Specification

# Version 0.14.2

---

# 1. Introduction

Scedel is a declarative schema and validation language designed for:

* structural typing
* validation constraints
* cross-field dependencies
* deterministic schema composition
* metadata-driven tooling integration

Scedel is:

* deterministic
* statically analyzable
* side-effect free
* context-aware

This document defines the normative behavior of Scedel version 0.14.2.

---

# 2. Lexical Conventions (Informal)

*(Formal grammar will be provided in a future version.)*

---

## 2.1 Identifiers

Identifiers:

* consist of letters (`A–Z`, `a–z`), digits (`0–9`), underscore `_`
* must not start with a digit
* are case-sensitive

---

## 2.2 Context-Sensitive Keywords

Scedel uses **context-sensitive (soft) keywords**.

The following words have special meaning only in specific syntactic positions:

```
type
validator
include
scedel-version
true
false
null
this
parent
root
and
or
not
when
then
else
absent
```

Outside their syntactic role, they MAY be used as identifiers.

Example:

```scedel
type Example = {
    include: String
}
```

---

## 2.3 Literals

### String

```
"text"
```

### Integer

```
123
```

### Boolean

```
true
false
```

### Null

```
null
```

### Duration

Duration literals use suffix notation:

```
3d
5h
-2w
30m
500ms
```

Supported units:

* `ms`
* `s`
* `m`
* `h`
* `d`
* `w`

Duration literals are distinct from strings.

---

## 2.4 Comments

```
// line comment
/* block comment */
```

---

# 3. File Structure

A file may contain:

* optional `scedel-version`
* include statements
* annotations
* type declarations
* validator declarations

Order is significant.

---

# 4. Include System

## 4.1 Syntax

```
include "path"
```

## 4.2 Resolution Rules

* Include graph MUST be acyclic (`CyclicInclude`)
* Diamond includes allowed
* Each canonical source processed once
* Type redeclaration forbidden
* Validator redeclaration forbidden

Relative include requires resolution context (`RelativeIncludeRequiresBase`).

---

# 5. Annotations

Annotations attach metadata to:

* types
* fields
* via targeted form

Annotations do not alter validation semantics.

---

## 5.1 Syntax

```
@group.key = "value"
@flag
```

Flag form equals `"true"`.

Annotation values are strings.

---

## 5.2 Targeted Annotations

```
@key = "value" on Target
```

Targets:

* `TypeName`
* `TypeName.field`
* `TypeName.{a,b}`
* `TypeName.field.subField`

---

## 5.3 Merge Rule

Annotations merge deterministically after include resolution.

If same key appears multiple times → last-wins.

---

# 6. Type System

---

## 6.1 Declaration

```
type TypeName = TypeExpr
```

Type names are globally unique.

Redeclaration → `TypeRedeclared`.

---

## 6.2 Built-in Types

Built-in scalar types are defined in **Appendix A (Normative)**.

Implementations MUST support all built-in types defined in Appendix A.

---

## 6.3 Record Types

```
{
    field: Type
    field?: Type
}
```

* `field?` — optional field
* `Type?` — nullable type

---

### Field Access

Allowed:

```
this.field
parent.field
root.field
```

Property access (e.g., `this.length`) is NOT supported.

Unknown field → `UnknownField`.

---

## 6.4 Array Types

```
Type[]
```

---

## 6.5 Dictionary Types

```
dict<KeyType, ValueType>
```

---

## 6.6 Union Types

```
A | B
```

---

## 6.7 Intersection Types

```
A & B
```

---

## 6.8 Conditional Types

```
when condition then TypeA else TypeB
```

### Special Case: `absent`

`absent` is a special conditional modifier.

It may appear only in the `then` or `else` branch of a conditional field type.

Example:

```scedel
type Example = {
    status: String
    reason: when this.status = "Rejected"
            then String
            else absent
}
```

### Semantics of `absent`

* `absent` is NOT a type.
* It is NOT a value.
* It indicates that the field MUST NOT be present.
* If the field exists when `absent` is required → `FieldMustBeAbsent`.

Using `absent` outside a conditional field context → `InvalidTypeUsage`.

---

# 7. Expression Model

Expressions are side-effect free.

Used in:

* validator bodies
* defaults
* constraints

---

## 7.1 Context References

Available in value context:

* `this`
* `parent`
* `root`

Using `parent` at root → `ParentUndefined`.

Using `this` outside value context → `ThisUndefined`.

---

## 7.2 Arithmetic

### Numeric

```
+ - * /
```

### Duration

```
Duration + Duration
Duration - Duration
Duration * number
number * Duration
Duration / number
```

Division by zero → `InvalidArithmetic`.

### Date/Time

```
DateTime + Duration
DateTime - Duration
DateTime - DateTime -> Duration
Date - Duration
Date - Date -> Duration
```

Invalid combinations → `InvalidArithmetic`.

---

## 7.3 Comparison Operators

```
= != < <= > >=
```

Allowed for:

* numeric
* Date
* DateTime
* Duration
* String (lexicographic)
* Bool (`=` and `!=` only)

Type mismatch → `TypeMismatch`.

---

## 7.4 Boolean Operators

```
and
or
not
```

---

## 7.5 Built-in Functions

```
now()
midnight()
pi()
```

---

# 8. Validators

---

## 8.1 Declaration

```
validator BaseType(
    Name
    [, param: Type [= DefaultExpr]]*
) = Expression
```

Example:

```
validator Int(range, from:Int = 0, to:Int = 100) =
    this > $from and this < $to
```

---

## 8.2 Uniqueness

Validator uniquely identified by `(BaseType, Name)`.

Redeclaration → `ValidatorRedeclared`.

Built-in constraint names are reserved for that BaseType.

Overriding is forbidden.

---

## 8.3 Constraint Invocation

Inside:

```
BaseType(...)
```

Constraint may be:

* built-in constraint (`min: 10`)
* validator (`range(10, 20)`)
* validator without arguments (`odd`)

---

## 8.4 Argument Binding Rules

* Positional bind left-to-right
* Named bind by name
* Mixing allowed only positional first
* Duplicate → `DuplicateArgument`
* Too many → `TooManyArguments`
* Unknown name → `UnknownArgumentName`
* Missing required → `MissingArgument`

Defaults applied when omitted.

---

## 8.5 Parameter Scope

Inside validator body:

* parameters available as `$param`
* `this`, `parent`, `root` available

---

# 9. Constraint Resolution

Inside `BaseType(...)`:

1. If matches built-in constraint → built-in
2. Else if matches validator → validator
3. Else → `UnknownConstraint`

Built-in names are reserved.

---

# 10. Error Model

Every error MUST contain:

* `code`
* `category`
* `message`

Categories:

* ParseError
* IncludeResolutionError
* SemanticError
* TypeError
* ValidationError

---

## 10.1 Standard Error Codes

Include:

* CyclicInclude
* RelativeIncludeRequiresBase

Version:

* InvalidVersionDirective
* IncompatibleScedelVersion

Semantic:

* TypeRedeclared
* ValidatorRedeclared
* ReservedValidatorName
* UnknownType
* UnknownField
* UnknownConstraint
* MissingArgument
* DuplicateArgument
* TooManyArguments
* UnknownArgumentName
* InvalidTypeUsage

Type:

* TypeMismatch
* InvalidArithmetic
* ThisUndefined
* ParentUndefined

Validation:

* FieldMissing
* FieldMustBeAbsent
* ConstraintViolation
* ValidatorFailed

---

# 11. Versioning

## 11.1 RFC Versioning

```
MAJOR.MINOR.PATCH
```

PATCH — clarification
MINOR — backward-compatible feature
MAJOR — breaking change

---

## 11.2 Library Versioning

Library version independent of RFC version.

Library MUST declare supported RFC version.

---

# 12. Schema Version Directive

```
scedel-version 1.0
```

Optional. Must be first statement.

All files in include graph must share same MAJOR.

Effective version:

* MAJOR = common
* MINOR.PATCH = maximum declared
* If none declared → implementation MUST default to highest supported stable version.

---

# 13. Appendix A — Built-in Types and Constraints (Normative)

Defines:

* built-in scalar types
* built-in constraints
* semantics per type

Implementations MUST support all definitions for RFC 0.14.2.

---

# 14. Not Included in 0.14.2

* property access (`this.length`)
* composite duration literals
* user-defined functions
* namespaces
* dict constraints
* reflection

---

# 15. Conclusion

Scedel 0.14.2 restores and formalizes:

* `absent` conditional semantics
* deterministic validation rules
* stable validator model
* context-sensitive keyword behavior
* explicit error semantics

The language is now internally consistent and prepared for formal grammar specification in a future release.
