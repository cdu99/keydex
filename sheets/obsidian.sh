#!/bin/sh
# Prints Obsidian's hotkeys as a Keydex sheet (format: docs/SHEETS.md).
#
# Keydex runs it from obsidian.md, for Obsidian only, with KEYDEX_APP_PATH set to the running
# Obsidian.app. Obsidian's command line talks to the running app, so the sheet shows the
# hotkeys of the open vault: defaults, your custom ones and those of your plugins.
# Try it: KEYDEX_APP_PATH=/Applications/Obsidian.app sh sheets/obsidian.sh
set -eu

obsidian="${KEYDEX_APP_PATH:-/Applications/Obsidian.app}/Contents/MacOS/obsidian-cli"
names="$(mktemp)"
trap 'rm -f "$names"' EXIT

# "id<TAB>name" for every command, e.g. "graph:open	Graph view: Open graph view". Read-only.
# Optional: without it, titles are made from the command ids.
"$obsidian" eval code='Object.values(app.commands.commands).map(c => c.id + "\t" + c.name).join("\n")' \
    > "$names" 2>/dev/null || : > "$names"

# "id<TAB>hotkeys" for every command with a hotkey, e.g. "workspace:next-tab	⌃ Tab, ⌘ ⇧ ]".
"$obsidian" hotkeys | awk -F '\t' '
# The command names come first.
FILENAME != "-" {
    sub(/^=> /, "")
    if (index($0, "\t")) name[$1] = $2
    next
}

# Obsidian key names → names Keydex understands; "" for keys without a Mac keycap (Insert).
function key_name(token,    lower) {
    lower = tolower(token)
    if (lower == "enter") return "return"
    if (lower == "escape") return "esc"
    if (lower ~ /^(tab|space|backspace|delete|home|end|pageup|pagedown|f[0-9]+)$/) return lower
    if (token ~ /^(⌘|⌃|⌥|⇧|←|→|↑|↓)$/) return token
    if (length(token) == 1) return token
    return ""
}

# "⌘ ⇧ ]" → "⌘ ⇧ ]"; "" when a key cannot be written.
function keys_of(hotkey,    parts, count, i, key, keys) {
    count = split(hotkey, parts, " ")
    keys = ""
    for (i = 1; i <= count; i++) {
        key = key_name(parts[i])
        if (key == "") return ""
        keys = keys (keys == "" ? "" : " ") key
    }
    return keys
}

# "editor:toggle-bold" → "Toggle bold", when Obsidian did not give the name.
function humanize(id) {
    sub(/^[^:]*:/, "", id)
    gsub(/-/, " ", id)
    return toupper(substr(id, 1, 1)) substr(id, 2)
}

# Commands are grouped by theme, from their id; other plugins by plugin ("Excalidraw: …").
function section_of(id, title,    namespace) {
    namespace = id
    sub(/:.*/, "", namespace)
    if (namespace ~ /^(editor|markdown|insert-template|templater-obsidian)$/) return "Édition"
    if (namespace == "workspace") return "Onglets et fenêtres"
    if (namespace == "file-explorer") return "Fichiers"
    if (namespace ~ /^(app|command-palette|switcher|global-search)$/) return "Navigation et recherche"
    if (namespace ~ /^(graph|outline|backlink|outgoing-links|tag-pane|bookmarks|properties)$/) return "Panneaux"
    if (match(title, /^[^:]+: /)) return substr(title, 1, RLENGTH - 2)
    return "Autres"
}

$2 != "" {
    id = $1
    title = (id in name) ? name[id] : humanize(id)
    section = section_of(id, title)
    if (match(title, /^[^:]+: /)) title = substr(title, RLENGTH + 1)
    if (!(section in count)) order[++sections] = section
    count_of = split($2, hotkeys, ", ")
    for (i = 1; i <= count_of; i++) {
        keys = keys_of(hotkeys[i])
        if (keys == "" || keys in seen) continue
        seen[keys] = 1
        count[section]++
        entries[section, count[section]] = (index(keys, "`") ? "- " keys "  " : "- `" keys "` ") title
    }
}

END {
    # Themes first, in this order, then plugins in the order Obsidian lists them.
    themes = "Édition|Onglets et fenêtres|Navigation et recherche|Fichiers|Panneaux"
    count_of = split(themes, theme, "|")
    for (t = 1; t <= count_of; t++) print_section(theme[t])
    for (s = 1; s <= sections; s++) if (order[s] != "Autres") print_section(order[s])
    print_section("Autres")
}

function print_section(section,    i) {
    if (!count[section] || printed[section]) return
    printed[section] = 1
    print "## " section
    for (i = 1; i <= count[section]; i++) print entries[section, i]
    print ""
}
' "$names" -
