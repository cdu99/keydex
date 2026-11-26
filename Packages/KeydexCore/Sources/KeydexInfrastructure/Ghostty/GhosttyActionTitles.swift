import KeydexDomain

/// Readable titles for Ghostty actions ("new_split:right" → "Nouveau split à droite").
/// Unknown actions are humanized ("toggle_secure_input" → "Toggle secure input").
enum GhosttyActionTitles {
    static func title(for action: String) -> String {
        let parts = action.split(separator: ":", maxSplits: 1).map(String.init)
        let name = parts[0]
        let parameter = parts.count > 1 ? parts[1] : nil
        if let title = title(name: name, parameter: parameter) { return title }
        return humanize(name) + (parameter.map { " (\($0))" } ?? "")
    }

    private static let directions = ["left": "à gauche", "right": "à droite", "up": "en haut", "down": "en bas"]

    private static func title(name: String, parameter: String?) -> String? {
        switch (name, parameter) {
        case ("text", let text?): sentKeysTitle(forText: text)
        case ("esc", let key?): escapeTitle(key)
        case ("new_window", _): "Nouvelle fenêtre"
        case ("new_tab", _): "Nouvel onglet"
        case ("close_surface", _): "Fermer le terminal"
        case ("close_tab", _): "Fermer l'onglet"
        case ("close_window", _): "Fermer la fenêtre"
        case ("close_all_windows", _): "Fermer toutes les fenêtres"
        case ("quit", _): "Quitter Ghostty"
        case ("toggle_fullscreen", _): "Plein écran"
        case ("previous_tab", _): "Onglet précédent"
        case ("next_tab", _): "Onglet suivant"
        case ("last_tab", _): "Dernier onglet"
        case ("goto_tab", let number?): "Aller à l'onglet \(number)"
        case ("new_split", let direction?): "Nouveau split \(directions[direction] ?? direction)"
        case ("goto_split", "previous"): "Split précédent"
        case ("goto_split", "next"): "Split suivant"
        case ("goto_split", let direction?): "Aller au split \(directions[direction] ?? direction)"
        case ("resize_split", let value?):
            "Redimensionner le split \(directions[String(value.split(separator: ",")[0])] ?? value)"
        case ("equalize_splits", _): "Égaliser les splits"
        case ("toggle_split_zoom", _): "Agrandir ou rétablir le split"
        case ("scroll_to_top", _): "Défiler tout en haut"
        case ("scroll_to_bottom", _): "Défiler tout en bas"
        case ("scroll_page_up", _): "Page précédente"
        case ("scroll_page_down", _): "Page suivante"
        case ("scroll_to_selection", _): "Défiler jusqu'à la sélection"
        case ("jump_to_prompt", let delta?): delta.hasPrefix("-") ? "Prompt précédent" : "Prompt suivant"
        case ("clear_screen", _): "Effacer l'écran"
        case ("select_all", _): "Tout sélectionner"
        case ("adjust_selection", let direction?):
            "Étendre la sélection \(directions[direction] ?? direction.replacingOccurrences(of: "_", with: " "))"
        case ("copy_to_clipboard", _): "Copier"
        case ("paste_from_clipboard", _): "Coller"
        case ("paste_from_selection", _): "Coller la sélection"
        case ("start_search", _): "Rechercher"
        case ("search_selection", _): "Rechercher la sélection"
        case ("end_search", _): "Fermer la recherche"
        case ("navigate_search", "next"): "Résultat suivant"
        case ("navigate_search", "previous"): "Résultat précédent"
        case ("increase_font_size", _): "Agrandir le texte"
        case ("decrease_font_size", _): "Réduire le texte"
        case ("reset_font_size", _): "Taille du texte par défaut"
        case ("reload_config", _): "Recharger la configuration"
        case ("open_config", _): "Ouvrir la configuration"
        case ("toggle_command_palette", _): "Palette de commandes"
        case ("inspector", _): "Inspecteur du terminal"
        case ("undo", _): "Annuler"
        case ("redo", _): "Rétablir"
        case ("write_screen_file", let mode?) where mode.hasPrefix("copy"): "Copier le contenu de l'écran (fichier)"
        case ("write_screen_file", let mode?) where mode.hasPrefix("paste"): "Coller le contenu de l'écran (fichier)"
        case ("write_screen_file", let mode?) where mode.hasPrefix("open"): "Ouvrir le contenu de l'écran"
        default: nil
        }
    }

    /// `text:\x01` sends a control character to the shell; zsh gives it its meaning.
    private static func sentKeysTitle(forText text: String) -> String {
        let meanings: [String: String] = [
            "\\x01": "Début de ligne (envoie ⌃A)",
            "\\x05": "Fin de ligne (envoie ⌃E)",
            "\\x15": "Effacer jusqu'au début de la ligne (envoie ⌃U)",
            "\\x0b": "Effacer jusqu'à la fin de la ligne (envoie ⌃K)",
            "\\x17": "Effacer le mot précédent (envoie ⌃W)",
        ]
        if let meaning = meanings[text.lowercased()] { return meaning }
        if text.hasPrefix("\\x"), let code = UInt8(text.dropFirst(2), radix: 16), (1...26).contains(code) {
            return "Envoie ⌃\(Character(UnicodeScalar(code + 64)))"
        }
        return "Envoie « \(text) »"
    }

    /// `esc:b` sends Escape then a key, i.e. Meta+key for the shell.
    private static func escapeTitle(_ key: String) -> String {
        switch key {
        case "b": "Mot précédent (envoie ⌥B)"
        case "f": "Mot suivant (envoie ⌥F)"
        case "d": "Effacer le mot suivant (envoie ⌥D)"
        default: "Envoie ⎋ \(key)"
        }
    }

    private static func humanize(_ name: String) -> String {
        let words = name.replacingOccurrences(of: "_", with: " ")
        return words.prefix(1).uppercased() + words.dropFirst()
    }
}
