# Contributing to Keydex

Thanks for your interest! Contributions of every size are welcome.

## The easiest one: a shortcut sheet

Know the shortcuts of an app or a tool that are not in its menus (tmux, vim, a terminal, an IDE)? Write them down as a **sheet**, a small Markdown file, and add it to [`sheets/`](sheets). If the tool can list its own shortcuts, the sheet can **generate** them with a small script instead. No Swift needed. See [docs/SHEETS.md](docs/SHEETS.md).

Keydex's code is generic on purpose: please keep app-specific knowledge in sheets, not in Swift.

## Code

- Build and test with `make run` and `make test` (see the README's *Development* section).
- The architecture is layered (`KeydexDomain` → `KeydexInfrastructure` / `KeydexPresentation` → app). Business rules belong in the domain, which has no AppKit and is unit-tested.
- Add tests for what you change. The test suite uses Swift Testing.
- Commits follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat(panel): …`, `fix(domain): …`, `docs: …`), one logical change per commit, each one building and passing tests.

## Bugs and ideas

Open an issue with your macOS version and the app concerned. If Keydex shows wrong keys for an app, the output of `swift run keydex-dump <app> --raw` (in `Packages/KeydexCore`) helps a lot. Remove anything personal from it first: menus can contain document names or your account name.
