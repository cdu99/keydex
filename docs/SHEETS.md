# Shortcut sheets

Keydex reads shortcuts from each app's **menus**. Many shortcuts are in no menu, though: shell line editing (zsh), most terminal keybindings, much of IntelliJ IDEA's keymap, system shortcuts (Spaces, screenshots…).

**Sheets** fill that gap. A sheet is a small Markdown file listing shortcuts for one or more apps, or for every app. Keydex shows sheet shortcuts apart from menu shortcuts, marked with a document icon (they can be read and searched, but Keydex cannot run them for you).

## Where sheets come from

| Source | Location | Notes |
|---|---|---|
| Bundled sheets | [`sheets/`](../sheets) in this repository | Shipped with the app (zsh, macOS…). |
| Your sheets | `~/.config/keydex/*.md` | Reloaded as soon as you save, without relaunching Keydex. |
| Generated | From the app itself | Ghostty: read live from `ghostty +list-keybinds`, so it always matches your config. |

A file in `~/.config/keydex` with the same name as a bundled sheet (e.g. `zsh.md`) **replaces** it: copy the bundled sheet there to customize it.

## Format

```markdown
# zsh

apps: Ghostty, Terminal, iTerm2

Free text is allowed anywhere and ignored by Keydex: use it to explain things.

## Words
- `⌃W` Delete the previous word
- `⌥D` Delete the next word

## Line
| Keys | Action |
|---|---|
| `⌃A` | Beginning of line |
| ctrl+e | End of line |
```

- `# Title`: the sheet's name, shown before each section ("zsh · Words"). Defaults to the file name.
- `apps:`: names (as in the menu bar) or bundle identifiers, comma-separated, case-insensitive. **Without `apps:`, the sheet applies to every app.** Such system-wide sheets are left out of the glance, to keep it about the current app, and are found by searching.
- `## Section`: groups entries. Entries before any section form an untitled one.
- **Entries** are list items (keys in backticks, or separated from the title by two spaces) or table rows.

### Writing keys

Symbols and words both work, glued or separated by spaces or `+`:

| Write | Means |
|---|---|
| `⌘` `cmd` `command` | Command |
| `⌃` `ctrl` `control` | Control |
| `⌥` `opt` `option` `alt` | Option |
| `⇧` `shift` `maj` | Shift |
| `fn` `🌐` | Function / Globe |
| `↩` `return` `enter`, `⎋` `esc`, `⇥` `tab`, `space`, `⌫` `delete` `backspace`, `⌦` `del` | Special keys |
| `←` `left`, `→` `right`, `↑` `up`, `↓` `down`, `home`, `end`, `pageup`, `pagedown`, `f1`…`f20` | Navigation and function keys |

Examples: `⌃W`, `ctrl+w`, `cmd shift f`, `⌥⌘←`, `fn ctrl left`, `⌘+`.

One entry is one key combination. Sequences ("⌃X then ⌃K") are not supported yet.

### Priorities

When the same keys appear in several places, the first one wins:
1. the app's menus;
2. sheets written for the app (including Ghostty's own keybindings);
3. sheets for every app.

So in a terminal, `⌃K` shows what zsh does, not what macOS text fields do.

## Checking a sheet

```sh
cd Packages/KeydexCore
swift run keydex-dump --check-sheet ~/.config/keydex/my-app.md
```

This prints what Keydex understands (title, apps, sections, keys) and every line it could not read. It exits with an error if there is any, so it can also check a contribution.

## Contributing a sheet

Sheets are the easiest way to contribute: no Swift needed.

1. Write the sheet and check it with `--check-sheet`.
2. Add it to [`sheets/`](../sheets), named after the app or tool (`tmux.md`, `vim.md`…).
3. Open a pull request.
