# Contributing To The Effort

Contributions welcome! Preliminaries:

* Please review the [README](README.md).
* Read and adhere to the [Code of Conduct](CODE_OF_CONDUCT.md).
* Read the [Coding Style](CodingStyle.md) guide.

## Sub-Projects

1. Disassembly of the MouseGraphics ToolKit
   * Continue the effort to understand this powerful GUI library.
   * Make it relocatable, work on C bindings for cc65.
1. Disassembly of DeskTop itself
   * The core bits of DeskTop.
   * The various overlays.
   * The DiskCopy overlay is basically a stand-alone app. Could be fun.
1. Disassembly of [Selector](https://github.com/inexorabletash/a2d/issues/63)
1. Bug fixes
   * Try and tackle some of the bugs in the [issue tracker](https://github.com/inexorabletash/a2d/issues?q=is%3Aissue+is%3Aopen+label%3Abug-in-original).
   * Bug fixes will alter the binary, so should occur in branches. There's a `fixes` branch with some already.
1. Add new Desk Accessories
   * List of ideas in the [issue tracker](https://github.com/inexorabletash/a2d/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+label%3A%22Desk+Accessories%22+label%3A%22feature+request%22)

## DeskTop Disassembly Burn-Down

To feel confident about making additions and fixes to DeskTop, we need to
make sure we're not breaking things. That can be done in some cases by
relying on API boundaries, such as between MGTK and the DeskTop application.
But DeskTop itself is a big, monolithic application with multiple overlays,
so we need to understand nearly all of it before we can start moving code
around.

The `res/stats.pl` tool provides is a quick and dirty analysis of the
progress in turning raw da65 output into something we can confidently
modify. Here's a snapshot of the output for some files:

```
Stats:
sys.s          unscoped:   20  scoped:   15  raw:    4  unrefed:    0
desktop_main.s unscoped:  246  scoped: 1109  raw:   60  unrefed:   29
desktop_res.s  unscoped:   64  scoped:    0  raw:    4  unrefed:   64
desktop_aux.s  unscoped:   83  scoped:  301  raw:    2  unrefed:   32
loader.s       unscoped:    1  scoped:    0  raw:   20  unrefed:    0
mgtk.s         unscoped:    0  scoped:   10  raw:   13  unrefed:    0
invoker.s      unscoped:    0  scoped:    0  raw:    2  unrefed:    0
```

* **unscoped** counts the number of auto-generated labels like `L1234`
    produced by da65 which are _not_ in _two_ nested scopes. A scope is
    used for the overall structure of a module, and a nested scope
    is used for procedures. This counts labels which are not in either,
    and thus may have some affinity for a particular address
    and therefore can't be safely moved.

* **scoped** counts the number of auto-generated labels like `L1234`
    produced by da65 which _are_ inside two nested scopes. Once a label
    is local to a procedure it is generally safe to move, although
    actually understanding the purpose and giving it a more meaningful
    label is even better.

* **raw** counts the number of 16-bit addresses (`$1234`) in the code;
    these usually refer to routines, resources, or occasionally
    buffer locations that need to be understood and replaced with
    labels.

* **unrefed** counts the number of auto-generated labels like `L1234`
    that lack references within the source file. Early on, these often
    hint at bogus disassembly but can also signal that the code to
    use a routine or resource has not yet been identified.
