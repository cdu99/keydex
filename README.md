# Keydex

Hold **⌘** to see the keyboard shortcuts of the app you are using. Double-tap **⌘** and hold to search them and trigger an action.

A native macOS (26+) menu bar app. Nothing leaves your machine.

## Build & run

```sh
brew install xcodegen   # once
make run                # generates the Xcode project, builds and launches Keydex
make test               # unit tests of the core package
```

Keydex needs the **Accessibility** permission to read the menus of other apps. See `logs.md` for the plan, progress, and signing tips.
