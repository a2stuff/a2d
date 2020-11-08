# Contributing To The Effort

Contributions welcome! Preliminaries:

* Please review the [README](README.md).
* Read and adhere to the [Code of Conduct](CODE_OF_CONDUCT.md).
* Read the [Coding Style](docs/Coding_Style.md) guide.

## Sub-Projects

### Desk Accessories

These are pretty easy to write. See the bug tracker (links below) for examples, but anything is welcome. Look at existing DA code for examples, and see the [API](desk.acc/API.md) and [MGTK](mgtk/MGTK.md) docs for more details.

### Disassembly

Pure disassembly changes take place in the `disasm` branch, which builds identically to the original. The `main` branch is based on `disasm`. (NOTE: Some disassembly has been done in `main` and should be 'upstreamed', time permitting.)

Disassembly efforts include:

1. DeskTop itself
   * The core bits of DeskTop (mostly done)
   * The various overlays (mostly done)
   * The DiskCopy overlay is basically a stand-alone app (barely started)
1. Selector (mostly done)
1. DeskTop.system launcher (lots of dead code?)

### Bug Fixes & Enhancements

* [Bugs in DeskTop](https://github.com/a2stuff/a2d/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+label%3A%22bug%22+label%3ADeskTop)
* [Bugs in Selector](https://github.com/a2stuff/a2d/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+label%3A%22bug%22+label%3ASelector)
* [Bugs in MGTK](https://github.com/a2stuff/a2d/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+label%3A%22bug%22+label%3AMGTK)
* [Bugs in Desk Accessories](https://github.com/a2stuff/a2d/issues?q=is%3Aissue+is%3Aopen+label%3Abug+label%3A%22Desk+Accessories%22)

* [Feature requests for DeskTop](https://github.com/a2stuff/a2d/issues?q=is%3Aissue+is%3Aopen+label%3A%22feature+request%22+label%3ADeskTop)
* [Feature requests for DeskTop](https://github.com/a2stuff/a2d/issues?q=is%3Aissue+is%3Aopen+label%3A%22feature+request%22+label%3ASelector)
* [Feature requests for Desk Accessories](https://github.com/a2stuff/a2d/issues?q=is%3Aissue+is%3Aopen+label%3A%22feature+request%22+label%3A%22Desk+Accessories%22)
* [Feature requests for Control Panel](https://github.com/a2stuff/a2d/issues?q=is%3Aissue+is%3Aopen+label%3A%22Control+Panel+DA%22)


## DeskTop Disassembly Burn-Down

To feel confident about making additions and fixes to DeskTop, we need to
make sure we're not breaking things. That can be done in some cases by
relying on API boundaries, such as between MGTK and the DeskTop application.
But DeskTop itself is a big, monolithic application with multiple overlays,
so we need to understand nearly all of it before we can start moving code
around.

The `bin/stats.pl` tool provides is a quick and dirty analysis of the
progress in turning raw da65 output into something we can confidently
modify. Here's a snapshot of the output for some files that could use
attention:

```
desktop.system/desktop.system.s  unscoped:   21  scoped:   15  raw:    3  unrefed:    0
desktop/desktop_aux.s            unscoped:    3  scoped:   97  raw:    0  unrefed:    3
desktop/desktop_main.s           unscoped:    2  scoped:  303  raw:   31  unrefed:    1
desktop/ovl_disk_copy3.s         unscoped:  170  scoped:   74  raw:   15  unrefed:    8
desktop/ovl_disk_copy4.s         unscoped:  162  scoped:   17  raw:    7  unrefed:    0
desktop/ovl_file_dialog.s        unscoped:   29  scoped:  209  raw:    8  unrefed:    3
desktop/ovl_format_erase.s       unscoped:  194  scoped:   11  raw:    3  unrefed:    2
desktop/ovl_selector_edit.s      unscoped:    0  scoped:   20  raw:    0  unrefed:    0
desktop/ovl_selector_pick.s      unscoped:  190  scoped:    0  raw:    1  unrefed:    0
selector/app.s                   unscoped:    5  scoped:   75  raw:    0  unrefed:    0
selector/ovl_file_copy.s         unscoped:  125  scoped:   20  raw:    0  unrefed:    0
selector/ovl_file_dialog.s       unscoped:   12  scoped:  200  raw:    0  unrefed:    0
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
