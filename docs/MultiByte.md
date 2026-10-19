# Multi-Byte Macro Library

The reconstructed and updated Apple II DeskTop [ca65](https://cc65.github.io/doc/ca65.html) 6502 assembly source code makes extensive use of macros, including a bespoke library of multi-byte constructs for manipulating values larger than 8 bits, and even some helpers for 8-bit values, for consistency.

The [Flow](Flow.md) macro library relies on several of these.

The macros are named in lowercase (e.g. `add16`), since they are like "pseudo-opcodes" rather than control flow constructs. It's a subtle distinction.

The macros are unevenly distributed, based on actual need. For example, there are far more 16-bit helpers are these are much more commonly used within the project than 8-bit helpers (since direct opcodes satisfy most of those needs) or 24- and 32-bit helpers (since most most math is just 16-bit).

In general, the macros are crafted to allow passing arguments in any addressing mode, including immediate (`#$1234`), absolute (`$1234`), and indexed (`$1234,x`) without needing special syntax. So it's fine to call a macro like `copy16 buf1,x, buf2,y` with 4 actual arguments (`buf1`, `x`, `buf2`, `y`); it will be treated as 2 effective arguments (`buf1,x`, `buf2,y`).

Indirect addressing modes (e.g. `($12),y`) require using dedicated macros that increment Y.

Most macros use the accumulator.

## 8-bit Operations

These primarily exist for consistency with the 16-bit macros, although they do result in more compact code.

### `copy8 source, destination`

Copy the source to the target.

### `swap8 arg1, arg2`

Swaps the source and the target. Uses the stack for temporary storage.

### `ucmp8 arg1, arg2`

Compares the two arguments as unsigned 8-bit values. Just `LDA` ... `CMP` in a single line. Sets 'C' for ordering, 'Z' for equality.

### `add8 arg1, arg2, destination`

Add `arg2` to `arg1`, store result in `destination`.

### `sub8 arg1, arg2, destination`

Subtract `arg2` from `arg1`, store result in `destination`.

## 16-bit Operations - Dual-Register

Treating two 6502 registers as a single 16-bit value is common.

### `ldax arg`
### `lday arg`
### `ldya arg`
### `ldxy arg`
### `stax arg`
### `styx arg`
### `stxy arg`

Load/store - pretty straightforward. The second register is the high byte.

### `inxy`
### `phax`
### `plax`

Increment, push-to-stack, pull-from-stack.

### `addax arg1 [, arg2]`

Add `arg1` to A,X. A,X is dirtied. The result is stored to `arg2` if given, otherwise `arg1`.

### `subax arg1 [, arg2]`

Subtract `arg1` from A,X. A,X is dirtied. The result is stored to `arg2` if given, otherwise `arg1`.

### `addax8 arg1 [, arg2]`

Add `arg1` to A,X. The result remains in A,X, and stored in `arg2` is given.

### `subax8 arg1 [, arg2]`

Subtract `arg1` from A,X. The result remains in A,X, and stored in `arg2` is given.

### `addxy arg1 [, arg2]`

Add `arg1` to X,Y. X,Y is dirtied. The result is stored to `arg2` if given, otherwise `arg1`.

## 16-Bit Operations

### `add16 arg1, arg2, destination`

Add `arg2` to `arg1`, store result in `destination`.

If any argument uses indirect indexed addressing mode (i.e. `(zp),y`), the Y register is incremented between processing the low and high bytes.

### `sub16 arg1, arg2, destination`

Subtract `arg2` from `arg1`, store result in `destination`.

If any argument uses indirect indexed addressing mode (i.e. `(zp),y`), the Y register is incremented between processing the low and high bytes.

### `add16_8 arg1, arg2 [, destination]`

Add 8-bit value `arg2` to `arg1`, store result in `destination` if given, `arg1` otherwise.

If `destination` is provided and `arg2` is an immediate value then the generated code is identical to `add16`.

### `sub16_8 arg1, arg2 [, destination]`

Subtract 8-bit value `arg2` from `arg1`, store result in `destination` if given, `arg1` otherwise.

If `destination` is provided and `arg2` is an immediate value then the generated code is identical to `sub16`.

### `copy16 source, destination`

Copy the 16-bit value from `source` to `destination`

If any argument uses indirect indexed addressing mode (i.e. `(zp),y`), the Y register is incremented between processing the low and high bytes.

### `copylohi lo, hi, destination`

Typically used when a 16-bit value is stored in two tables, e.g. `copylohi table_lo,x, table_hi,x, dest`

### `ucmp16 arg1, arg2`

Perform a 16-bit unsigned compare. Sets `C` (for ordering) but *not* `Z` (for equality).

### `scmp16 arg1, arg2`

Perform a 16-bit signed compare. Sets `N` (for ordering) but *not* `C` or `Z`.

### `ecmp16 arg1, arg2`

Perform a 16-bit equality compare. Sets `Z` (for equality) but not `C` or `Z`.

### `lsr16 arg`

Right shift. 0 is rotated into high bit.

### `asl16 arg`

Left shift. 0 is rotated into low bit.

### `asr16 arg`

Right shift, with sign extension. i.e. signed divide-by-two.

### `inc16 arg`
### `dec16 arg`
### `push16 arg`

Increment/decrement/push-to-stack.

## 24-bit Operations

These are just like their 16-bit equivalents, although indexed addressing modes are not supported. Lack of coverage corresponds to lack of need in the project; filling the gaps is straightforward.

### copy24 arg1, arg2
### inc24 arg
### ucmp24 arg1, arg2
### ecmp24 arg1, arg2

## 32-bit Operations

These are just like their 16-bit equivalents, although indexed addressing modes are not supported. Lack of coverage corresponds to lack of need in the project; filling the gaps is straightforward.

### `add32 arg1, arg2, destination`
### `sub32 arg1, arg2, destination`
### `copy32 arg1, arg2`
### `asl32 arg`
### `lsr32 arg`
