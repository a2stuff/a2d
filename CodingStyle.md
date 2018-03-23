# Coding Style

Review the [ca65 Users Guide](http://cc65.github.io/doc/ca65.html) for
syntax details.


## Formatting

* Spaces, not tabs
* "Tab" stops for alignment are 8 characters (Emacs asm-mode default)
* `res/asmfmt.pl` can be used for formatting
* No trailing whitespace


## Assembly

* Use lowercase opcodes (`lda`, `rts`)
* All A2D code is 6502 not 65C02


## Comments

* Comments are **encouraged**.
* End-of-line comments: `;` at a tab stop or aligned with nearby code
* Indented stand-alone comments: `;;` at first tab stop (8 chars)
* Major comments: `;;;` at start of line


## Naming

* Prefer `snake_case` for procedures and labels

NOTE: MGTK uses `TitleCase` for procedures, so that is used in limited
cases, e.g. `HideCursor`, `HideCursorImpl`, etc.

* Equates from ROM (Applesoft, Monitor, Firmware, etc) and ProDOS are in
`UPPERCASE`.


## Flow control

* **Do** make use of [unnamed labels](http://cc65.github.io/doc/ca65.html#ss6.6) for
   local loops and forward branches to avoid pointless names. Only use one level.

```
        ;; Copy the thing
        ldy     #7
:       lda     (src),y
        sta     (dst),y
        dey
        bpl     :-

        lda     flag
        bne     :+
        inc     count
:       rts
```

## Literals

* Use binary `%00110110` for bit patterns
* Use decimal for numbers (counts, dimensions, etc)
* Use hex for geeky values, e.g. $7F (bit mask), $80 (high bit),
   $FF (all bits set) when bits would be less readble.
* Avoid magic numbers where possible:
   * Define local variables (e.g. `ptr := $06`)
   * Define offsets, constants, etc.
   * Use math where necessary (e.g. `ldy #offset2 - offset1`)


## Structure

* Delimit code blocks with `.proc`:

```
.proc some_routine
        lda     $06
        rol
        rts
.endproc
```

* Try to encapssulate locally used data as much as possible.

```
.proc some_routine
        ptr := $06
        lda     ptr
        sta     stash
        rts

stash:  .byte   0
.endproc
```

* Use `impl` if the entry point is not at the start:

```
.proc some_routine_impl
stash:  .byte   0

        ptr := $06

start:  lda     ptr
        sta     stash
        rts

.endproc
        some_routine := some_routine_impl::start
```

## Macros

* Macro use is **encouraged**.
* Use local macros to avoid repeating code.
* Use `macros.inc` and extend as needed to capture patterns such as
   16-bit operations
* API calls such as ProDOS MLI calls should be done with macros


## Param Blocks

Parameter blocks are used for ProDOS MLI calls and MGTK calls.

* Wrap param data in `.proc` blocks:

```
.proc textwidth_params
textptr:        .addr   text_buffer
textlen:        .byte   0
result:         .word   0
.endproc

        ;; elsewhere...
        MGTK_CALL MGTK::TextWidth, textwidth_params
```

## Namespaces

Currently, only MGTK constants are wrapped in a `.scope` to provide
a namespace. We may want to do that for ProDOS and DeskTop stuff as
well in the future.
