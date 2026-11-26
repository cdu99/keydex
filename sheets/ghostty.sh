#!/bin/sh
# Prints Ghostty's keybindings as a Keydex sheet (format: docs/SHEETS.md).
#
# Keydex runs it from ghostty.md, for Ghostty only, with KEYDEX_APP_PATH set to the running
# Ghostty.app. It reads the current configuration, so the sheet follows your keybinds.
# Try it: KEYDEX_APP_PATH=/Applications/Ghostty.app sh sheets/ghostty.sh
set -eu

ghostty="${KEYDEX_APP_PATH:-/Applications/Ghostty.app}/Contents/MacOS/ghostty"

# One "keybind = trigger=action" line per keybinding, e.g. "keybind = super+shift+arrow_up=jump_to_prompt:-1".
"$ghostty" +list-keybinds | awk '
# Ghostty key names → names Keydex understands (super → cmd, arrow_left → left, digit_1 → 1…).
function key_name(token) {
    if (token == "super") return "cmd"
    if (token == "alt") return "opt"
    if (token ~ /^arrow_(left|right|up|down)$/) return substr(token, 7)
    if (token == "page_up") return "pageup"
    if (token == "page_down") return "pagedown"
    if (token ~ /^digit_[0-9]$/) return substr(token, 7)
    return token
}

function is_modifier(name) { return name ~ /^(cmd|ctrl|opt|shift)$/ }

function is_key(name) {
    return length(name) == 1 || name ~ /^(left|right|up|down|home|end|pageup|pagedown|enter|escape|tab|space|backspace|delete|f[0-9]+)$/
}

# "super+shift+arrow_up" → "cmd shift up"; "" for sequences ("ctrl+a>n") and keys without a Mac keycap.
function keys_of(trigger,    parts, count, i, name, keys, plus_key) {
    if (index(trigger, ">") > 0) return ""
    plus_key = (trigger ~ /\+\+$/)
    if (plus_key) trigger = substr(trigger, 1, length(trigger) - 2)
    count = split(trigger, parts, "+")
    keys = ""
    for (i = 1; i <= count; i++) {
        name = key_name(parts[i])
        if (i == count && !plus_key && (is_modifier(name) || !is_key(name))) return ""
        keys = keys (keys == "" ? "" : " ") name
    }
    return plus_key ? keys " +" : keys
}

function direction(value) {
    if (value == "left") return "à gauche"
    if (value == "right") return "à droite"
    if (value == "up") return "en haut"
    if (value == "down") return "en bas"
    return value
}

function hex_value(digits,    i, value) {
    value = 0
    for (i = 1; i <= length(digits); i++) value = value * 16 + index("0123456789abcdef", tolower(substr(digits, i, 1))) - 1
    return value
}

# text:\x01 sends a control character to the shell, which gives it its meaning.
function sent_text_title(text,    code) {
    if (text == "\\x01") return "Début de ligne (envoie ⌃A)"
    if (text == "\\x05") return "Fin de ligne (envoie ⌃E)"
    if (text == "\\x15") return "Effacer jusqu’au début de la ligne (envoie ⌃U)"
    if (text == "\\x0b") return "Effacer jusqu’à la fin de la ligne (envoie ⌃K)"
    if (text == "\\x17") return "Effacer le mot précédent (envoie ⌃W)"
    if (text ~ /^\\x[0-9a-fA-F][0-9a-fA-F]$/) {
        code = hex_value(substr(text, 3))
        if (code >= 1 && code <= 26) return "Envoie ⌃" substr("ABCDEFGHIJKLMNOPQRSTUVWXYZ", code, 1)
    }
    return "Envoie « " text " »"
}

# esc:b sends Escape then a key, which is Meta+key for the shell.
function escape_title(key) {
    if (key == "b") return "Mot précédent (envoie ⌥B)"
    if (key == "f") return "Mot suivant (envoie ⌥F)"
    if (key == "d") return "Effacer le mot suivant (envoie ⌥D)"
    return "Envoie ⎋ " key
}

function humanize(name) {
    gsub(/_/, " ", name)
    return toupper(substr(name, 1, 1)) substr(name, 2)
}

function title_of(action,    name, value, colon) {
    colon = index(action, ":")
    name = colon ? substr(action, 1, colon - 1) : action
    value = colon ? substr(action, colon + 1) : ""
    if (name == "text") return sent_text_title(value)
    if (name == "esc") return escape_title(value)
    if (name == "new_window") return "Nouvelle fenêtre"
    if (name == "new_tab") return "Nouvel onglet"
    if (name == "close_surface") return "Fermer le terminal"
    if (name == "close_tab") return "Fermer l’onglet"
    if (name == "close_window") return "Fermer la fenêtre"
    if (name == "close_all_windows") return "Fermer toutes les fenêtres"
    if (name == "quit") return "Quitter Ghostty"
    if (name == "toggle_fullscreen") return "Plein écran"
    if (name == "previous_tab") return "Onglet précédent"
    if (name == "next_tab") return "Onglet suivant"
    if (name == "last_tab") return "Dernier onglet"
    if (name == "goto_tab") return "Aller à l’onglet " value
    if (name == "new_split") return "Nouveau split " direction(value)
    if (name == "goto_split" && value == "previous") return "Split précédent"
    if (name == "goto_split" && value == "next") return "Split suivant"
    if (name == "goto_split") return "Aller au split " direction(value)
    if (name == "resize_split") { sub(/,.*/, "", value); return "Redimensionner le split " direction(value) }
    if (name == "equalize_splits") return "Égaliser les splits"
    if (name == "toggle_split_zoom") return "Agrandir ou rétablir le split"
    if (name == "scroll_to_top") return "Défiler tout en haut"
    if (name == "scroll_to_bottom") return "Défiler tout en bas"
    if (name == "scroll_page_up") return "Page précédente"
    if (name == "scroll_page_down") return "Page suivante"
    if (name == "scroll_to_selection") return "Défiler jusqu’à la sélection"
    if (name == "jump_to_prompt") return value ~ /^-/ ? "Prompt précédent" : "Prompt suivant"
    if (name == "clear_screen") return "Effacer l’écran"
    if (name == "select_all") return "Tout sélectionner"
    if (name == "adjust_selection") { gsub(/_/, " ", value); return "Étendre la sélection " direction(value) }
    if (name == "copy_to_clipboard") return "Copier"
    if (name == "paste_from_clipboard") return "Coller"
    if (name == "paste_from_selection") return "Coller la sélection"
    if (name == "start_search") return "Rechercher"
    if (name == "search_selection") return "Rechercher la sélection"
    if (name == "end_search") return "Fermer la recherche"
    if (name == "navigate_search") return value == "next" ? "Résultat suivant" : "Résultat précédent"
    if (name == "increase_font_size") return "Agrandir le texte"
    if (name == "decrease_font_size") return "Réduire le texte"
    if (name == "reset_font_size") return "Taille du texte par défaut"
    if (name == "reload_config") return "Recharger la configuration"
    if (name == "open_config") return "Ouvrir la configuration"
    if (name == "toggle_command_palette") return "Palette de commandes"
    if (name == "inspector") return "Inspecteur du terminal"
    if (name == "undo") return "Annuler"
    if (name == "redo") return "Rétablir"
    if (name == "write_screen_file" && value ~ /^copy/) return "Copier le contenu de l’écran (fichier)"
    if (name == "write_screen_file" && value ~ /^paste/) return "Coller le contenu de l’écran (fichier)"
    if (name == "write_screen_file" && value ~ /^open/) return "Ouvrir le contenu de l’écran"
    return humanize(name) (value == "" ? "" : " (" value ")")
}

# Sections, in display order: line editing first, as those keys are in no menu at all.
function section_of(action,    name) {
    name = action
    sub(/:.*/, "", name)
    if (name == "text" || name == "esc" || name == "csi") return 1
    if (name ~ /tab/) return 2
    if (name ~ /split/) return 3
    if (name ~ /^scroll/ || name == "jump_to_prompt" || name == "clear_screen") return 4
    if (name ~ /^(adjust_selection|select_all|copy_to_clipboard|paste_from_clipboard|paste_from_selection)$/) return 5
    if (name ~ /search/) return 6
    if (name ~ /^(new_window|close_window|close_all_windows|close_surface|quit|toggle_fullscreen)$/) return 7
    return 8
}

BEGIN {
    split("Ligne de commande|Onglets|Splits|Défilement et prompts|Sélection et presse-papiers|Recherche|Fenêtres|Autres", section_titles, "|")
}

/^keybind = / {
    binding = substr($0, length("keybind = ") + 1)
    # The trigger may itself end with "=" ("super+==increase_font_size:1"); the action starts with a letter.
    action = ""
    for (i = 2; i <= length(binding); i++) {
        if (substr(binding, i, 1) == "=" && substr(binding, i + 1, 1) ~ /[a-z]/) {
            trigger = substr(binding, 1, i - 1)
            action = substr(binding, i + 1)
            break
        }
    }
    if (action == "") next
    keys = keys_of(trigger)
    if (keys == "" || keys in seen) next  # "super+digit_1" and "super+1" are the same keys.
    seen[keys] = 1
    section = section_of(action)
    count[section]++
    entries[section, count[section]] = (index(keys, "`") ? "- " keys "  " : "- `" keys "` ") title_of(action)
}

END {
    for (section = 1; section <= 8; section++) {
        if (!count[section]) continue
        print "## " section_titles[section]
        for (i = 1; i <= count[section]; i++) print entries[section, i]
        print ""
    }
}
'
