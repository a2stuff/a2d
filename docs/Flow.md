# Flow Macro Library

The reconstructed and updated Apple II DeskTop [ca65](https://cc65.github.io/doc/ca65.html) 6502 assembly source code makes extensive use of macros, including a bespoke library of [control flow](https://en.wikipedia.org/wiki/Control_flow) constructs called "Flow". Flow introduces statements for conditional branching and looping, as well as function calls.

These macros allow writing compact and readable code that is more maintainable and resilient to refactoring errors than hand-crafted assembly.

The macros fall into these categories:

* [Branching and Looping](#branching-and-looping) with [Conditions](#conditions)
* [Function Calls](#function-calls)
* [Typed Assignments](#typed-assignments)

For example:
```
  IF bit flag : NS AND s16 left > right
    CALL ShowAlert, AX=#str_err_message
    RETURN A=#kStatusError
  END_IF

  SET u16 width = right - left

  DO
    CALL UpdateLine, A=index
    RTS_IF CS
  WHILE u8 ++index < count

  FALL_THROUGH_TO NextProc, A=
```

There are [🖥️ Slides](https://docs.google.com/presentation/d/1y72_wSc56TZOk5YtloPLcDa4d26GfsjWRUelq9rCI4w/edit?usp=sharing) that explain more of the rationale behind the library, its evolution, and the code generation.

The library relies heavily on the [Multi-Byte](MultiByte.md) macro library.

## Branching and Looping

We'll start off introducing the branching statements. See below for the micro-syntax for conditions.

### `IF` statements

The most basic structured branching is an `IF` statement:
```
  IF condition
    ...
  ELSE_IF condition
    ...
  ELSE
    ...
  END_IF
```

Depending on the conditions used, this might assemble to something like:
```asm
  bit flag
  bpl else1
  ...
  jmp endif

else1:
  lda myvar
  cmp #$41
  bne else2
  ...
  jmp endif

else2:
  ...

endif
```

* Forward branches always use the 6502 branch opcodes like `BEQ`, `BCC`, etc. Therefore code blocks must be shorter than 127 bytes. Reverse branches will use `JMP` if necessary.
* The code base targets the 6502 processor, not 65C02, so for `JMP` is used instead of `BRA` to skip forward at the end of blocks.

#### Shortcut `IF` statements

There is also a shortcut form for unstructured branching:
```
IF condition GOTO label
```

If the target label is too far away for a branch, `JUMP` can be used instead of `GOTO` to force

```
IF condition JUMP label
```

### `DO` ... `WHILE` statements

Structured looping starts with a `DO` statement and typically ends with a `WHILE` statement, and generates code that repeats until the condition is false.

```
  DO
    ...
  WHILE condition
```

Depending on the condition used, this might assemble to something like:
```
loop:
  ...
  bit flag
  bmi loop
```

Within the loop body, these statements can be used:
* `REDO_IF condition` - conditionally jumps back to the start of the loop.
* `CONTINUE_IF condition` - conditionally jumps to the end of the loop body; the loop may repeat or exit depending on the `WHILE` statement's condition.
* `BREAK_IF condition` - conditionally exits the loop.

Additionally:
* `REPEAT` is an alias for `DO`
* Instead of `WHILE condition` a loop can end with:
  * `UNTIL condition` generates code that loops until the condition is true.
  * `FOREVER` has an unconditional jump to the start of the loop. (e.g. `REPEAT` ... `FOREVER`)
  * `DONE` just exits without repeating. (e.g. `DO` ... `DONE`)

### Conditions

The various forms of `IF` and `WHILE` statements take *conditions* determine the actual code to generate. There are several forms of conditions, listed here in order from least complex to most complex.

#### Flag Tests

These test the 6502 processor flags: Carry, Zero, Negative, and Overflow. The assumption is that the preceding code has set flag(s) to signal some result, e.g. after a ProDOS MLI call or a math operation.

* Carry: `CC` / `CS`, with aliases `LT` and `GE`
* Zero: `ZC` / `ZS`, with aliases `NE` and `EQ` (also `ZERO`)
* Negative: `NC` / `NS`, with aliases `POS` and `NEG`
* Overflow: `VC` / `VS`

For example:
```
  jsr TryWritingFile
  IF CS
    jmp ShowErrorMessage
  END_IF
```

#### Register Comparisons

Since flags are often set by doing comparisons against registers (i.e. `CMP`, `CPX`, `CPY`) that can be done directly in the comparison, using a more readable syntax:

_register_ _operator_ _argument_

For example:
```
  IF A >= #12
    ...
  END_IF
```

* Registers are `A`, `X`, and `Y`
* Operators are `=`, `<>`, `<`, `>=`
* Arguments can be immediate values (e.g. `#123` or `#kConst`) or labels (e.g. `my_var`, and can include indexed addressing modes (e.g. `my_var,x` or `(ptr),y`). To be helpful, specifying a non-immediate number literal results in an error, because it is too easy to type `IF A = 0` when you mean `IF A = #0`.

For extra convenience, a few more operators are supported:

* `IN` which takes a list of possibilities e.g. `IF A IN #1, #3, #5`.
* `BETWEEN` which takes a low and high value, e.g. `IF A BETWEEN #'A', #'Z'`.
* `NOT_IN` and `NOT_BETWEEN` reverse the conditions.

#### Typed Comparisons

The most powerful comparison form goes even further.

_type_ _arg1_ _operator_ _arg2_

* Type is one of: `u8`, `u16`, `s16`, or `u24` where the `u` or `s` stands for unsigned or signed, and the number is the size in bits. So `u8` is an unsigned byte, `s16` is a signed two-byte value, etc.
* Operators are `=`, `<>`, `<`, `<=`, `>`, `>=`.
* Arguments have the same rules as register comparisons.

For example:
```
  IF s16 left > right
    ...
  END_IF
```

The `A` register is implicitly used.

In addition, the first argument can be prefixed with `++` or `--` to pre-increment or pre-decrement the value.

For example:
```
  DO
    ...
  WHILE u8 ++index < limit
```

#### Compound Conditions

A condition can be prefixed with `NOT` to invert the sense of the condition.

Conditions can be joined with `OR` and `AND`. `AND` has the highest precedence.

Note that parentheses (`(`, `)`) are not supported, and only a single `NOT` can be used at the start of the overall condition expression.

For example:
```
  IF NS OR A = #37
    ...
  ELSE_IF s16 left > right OR s16 top > bottom
    ...
  END_IF
```

#### Pre-Statements

A condition can be preceded by zero or more statements, separated with `:`. These are emitted verbatim by the macro. So instead of writing:
```
  bit flag
  IF NS
    ...
  END_IF

  ldx #9
  DO
    ...
    dex
  WHILE POS
```
You can write:
```
  IF bit flag : NS
    ...
  END_IF

  ldx #9
  DO
    ...
  WHILE dex : POS
```

## Function Calls

Function calls are another control flow mechanism, and the library provides another set of statements to improve readability and maintainability.

The syntax here allows specifying register and flag states in the same line as a `JSR` subroutine call (for arguments) or `RTS` subroutine return (for return values) by providing a list of _reg_ = _value_ pairs. Registers can be simple registers (`A`, `X`, `Y`), common register pairs for 16-bit values (`AX`, `AY`, `XY`, `YA`), and flags (`C`, `D`) which can be set to 0 or 1.

For indexed loads, surround the argument with `{` `}`, e.g. `CALL CRC, {AX=proc_table,y}, Y=#kChecksumLength`.

The `CALL` statement emits a `JSR` preceded by the register loads, for example:
```
  CALL ShowErrorMessage, AX=#str_err
```

The `RETURN` statement emits an `RTS` preceded by the register loads, for example:
```
  RETURN A=#kErrorNum, C=1
```

A common 6502 optimization is to replace a `JSR` followed by an `RTS` with just a `JMP`. To give that more compact syntax and document that this is an optimization, the `TAIL_CALL` statement emits a `JMP` preceded by the register loads, for example:
```
  CALL ShowErrorMessage, AX=#str_err
```

And finally, it is common to let one procedure simply "fall through" to a subsequent block of code. The `FALL_THROUGH_TO` statement doesn't emit anything on its own, it simply asserts that the next statement is the specified target. This defends against code changes that might move procedure implementations around, rendering the optimization invalid. If falling into a general purpose routine, the register loading syntax can also be used, for example:
```
.proc Something
   ...
   FALL_THROUGH_TO ShowErrorMessage, AX=#str_error
.endproc

.proc ShowErrorMessage
   ...
.endproc
```

## Typed Assignments

Reusing the same type-prefixed syntax from typed conditions, `SET` expressions can be used:
```
   SET u16 varA = varB          ; same as copy16 varB, varA
   SET u16 varA += varB         ; same as add16 varA, varB, varA
   SET u16 varA -= varB         ; same as sub16 varA, varB, varA
   SET u16 varA = varB + varC   ; same as add16 varB, varC, varA
   SET u16 varA = varB - varC   ; same as sub16 varB, varC, varA
```
... and similarly with `u8`, `s16`, `u24`, and `u32` types.

The `A` register is implicitly used.

These are no more compact than the corresponding [Multi-Byte](MultiByte.md) macros, but can be more readable.

Use parentheses (`(`, `)`) to disambiguate the binary operator when using an offset within an expression, e.g. `SET u16 tmp = (pt1+Point::ycoord) + (pt2+Point::ycoord)`.

There is no difference between `s16` and `u16` for typed assignment since signed numbers are represented as two's complement, but both are supported for readability and consistency with [typed comparisons](#typed-comparisons).

Shift-assignments are supported as well, with several caveats:
```
   SET u16 varA <<= #const
   SET u16 varA >>= #const
```
The shift count *must* be what ca65 considers a constant so that the value is known at assemble-time. If the value is 1 then just an `asl16` (etc) is emitted, otherwise a loop using the `X` register is emitted. The count is required to be immediate mode (i.e. prefixed with `#`) to dissuade passing a symbol (e.g. `varB`) because that might be a constant but the loop count should not be based on the *address*. While it would be possible to support non-constant shifts, these are exceedingly rare; the current syntax allows this in the future.

## Extras

The `RTS_IF` statement is the odd one out; it allows conditional returning from a procedure. Note that it doesn't support register loads.

`RTS_IF condition`
