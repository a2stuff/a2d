# Contributing To The Effort

Contributions welcome! Preliminaries:

* Please review the [README](README.md).
* Read and adhere to the [Code of Conduct](CODE_OF_CONDUCT.md).
* Read the [Coding Style](docs/Coding_Style.md) guide.
* See [APIs](APIs.md) for an overview of the APIs used.

## Sub-Projects

### Desk Accessories

These are pretty easy to write. See the bug tracker (links below) for examples, but anything is welcome. Look at existing DA code for examples, and see the [API](desk_acc/API.md) and [MGTK](mgtk/MGTK.md) docs for more details.

### Bug Fixes & Enhancements

* [Bugs in DeskTop](https://github.com/a2stuff/a2d/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+label%3A%22bug%22+label%3ADeskTop)
* [Bugs in Selector](https://github.com/a2stuff/a2d/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+label%3A%22bug%22+label%3ASelector)
* [Bugs in MGTK](https://github.com/a2stuff/a2d/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+label%3A%22bug%22+label%3AMGTK)
* [Bugs in Desk Accessories](https://github.com/a2stuff/a2d/issues?q=is%3Aissue+is%3Aopen+label%3Abug+label%3A%22Desk+Accessories%22)

* [Feature requests for DeskTop](https://github.com/a2stuff/a2d/issues?q=is%3Aissue+is%3Aopen+label%3A%22feature+request%22+label%3ADeskTop)
* [Feature requests for Selector](https://github.com/a2stuff/a2d/issues?q=is%3Aissue+is%3Aopen+label%3A%22feature+request%22+label%3ASelector)
* [Feature requests for Desk Accessories](https://github.com/a2stuff/a2d/issues?q=is%3Aissue+is%3Aopen+label%3A%22feature+request%22+label%3A%22Desk+Accessories%22)
* [Feature requests for Control Panel](https://github.com/a2stuff/a2d/issues?q=is%3Aissue+is%3Aopen+label%3A%22Control+Panel+DA%22)

Issues marked [Good First Bug](https://github.com/a2stuff/a2d/issues?q=is%3Aissue+is%3Aopen+label%3A%22Good+First+Bug%22) might be good starter projects to learn about the code. New Desk Accessories in particular should be easy to start with.

### Localization

MouseDesk originally shipped in French, English, German, Italian. The
project has been structured to allow localization into additional
languages. Since then, support for Spanish, Portuguese, Swedish,
Danish and Dutch have been added. The work involved for most
contributions is just to add an additional column to a spreadsheet
which contains translations for each string.

[DeskTop Localization Spreadsheet](https://docs.google.com/spreadsheets/d/1NIZQM4ua6ruLJk_P7MfTKN9S5LNwHwYJM_UhvY-ep3A/edit?usp=sharing)

If you want to contribute a localization, please contact a project
maintainer.


## Disassembly

> NOTE: This section is historical. The bulk of the disassembly is complete, with only some procedures that have not been fully analyzed and commented.

Pure disassembly changes take place in the `disasm` branch, which builds identically to the original. The `main` branch is based on `disasm`.

> NOTE: As time has gone on, much of the remaining disassembly has been done in `main` and the `disasm` branch abandoned.

Disassembly efforts include:

1. DeskTop itself
   * The core bits of DeskTop
   * The various overlays
   * The DiskCopy overlay (basically a stand-alone app)
1. Selector
1. DeskTop.system launcher

### DeskTop Disassembly Burn-Down

To feel confident about making additions and fixes to DeskTop, we need to
make sure we're not breaking things. That can be done in some cases by
relying on API boundaries, such as between MGTK and the DeskTop application.
But DeskTop itself is a big, monolithic application with multiple overlays,
so we need to understand nearly all of it before we can start moving code
around.

> NOTE: As noted above, this is no longer a concern.

The `bin/stats.pl` tool provides is a quick and dirty analysis of the
progress in turning raw da65 output into something we can confidently
modify. Here's a snapshot of the output for some files that could use
attention:

```

desktop/main.s                 unscoped:  0  scoped:  7  raw: 13
desktop/ovl_selector_pick.s    unscoped: 12  scoped:  0  raw: 0
lib/formatdiskii.s             unscoped: 43  scoped: 15  raw: 0
mgtk/mgtk.s                    unscoped:  0  scoped: 10  raw: 7
selector/ovl_file_copy.s       unscoped:  0  scoped: 12  raw: 0

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
