# Keydex

Hold **⌘** to see the keyboard shortcuts of the app you are using. Double-tap **⌘** and hold to search them and trigger an action, without leaving the keyboard.

A native macOS 26 menu bar app. Nothing leaves your Mac: no data collection, no network access.

## Use

| Gesture | Result |
|---|---|
| Hold **⌘** alone (0.5 s) | Shows the shortcuts of the frontmost app, grouped by menu. Release to hide. |
| Double-tap **⌘**, hold the second press | Search panel: type an action or keys (`copy`, `⌘⇧F`, `ctrl alt t`, `f5`), ↑↓ to choose, ↩ to run it, Escape to go back. |

Regular shortcuts (⌘C, ⌘Tab, ⌘-click…) never show the panel. Delays can be changed in **Réglages…** (menu bar icon).

## Build & install

Requirements: Xcode 26+, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
make run       # generate the Xcode project, build (Debug) and launch
make test      # unit tests of the core package
make install   # Release build copied to /Applications (needed for launch at login)
```

Keydex needs the **Accessibility** permission (System Settings › Privacy & Security › Accessibility) to read other apps' menus, detect ⌘ and trigger actions. It explains this on first launch.

To keep the permission across rebuilds, sign with your (free) Apple development team: create `Config/Signing.local.xcconfig` (git-ignored) with `DEVELOPMENT_TEAM = <team ID>` and `CODE_SIGN_IDENTITY = Apple Development`.

## Architecture

Clean architecture, in a local Swift package plus a thin app target:

- `KeydexDomain`: pure model and rules (shortcuts, Mac key notation, search, the ⌘ gesture state machine, the catalog cache) and ports.
- `KeydexInfrastructure`: macOS adapters (Accessibility menus reading and pressing, NSEvent monitors, user defaults, launch at login).
- `KeydexPresentation`: view models, panel layout, SwiftUI views.
- `Keydex` (app): composition root, menu bar item, the floating `NSPanel`.

Developer tool: `swift run keydex-dump <app> [--raw] [--runs N] [--pause MS] [--perform TITLE]` (in `Packages/KeydexCore`) prints what Keydex reads from an app.

See [`logs.md`](logs.md) for the plan, decisions, measurements and progress.
