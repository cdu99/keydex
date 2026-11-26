import Foundation
import KeydexDomain

/// Turns the output of `ghostty +list-keybinds` (one `keybind = trigger=action` per line)
/// into a sheet with readable titles, grouped by theme. Line editing comes first: those
/// keybindings send keys to the shell, and are exactly the ones no menu lists.
enum GhosttyKeybindParser {
    static let sheetID = "ghostty-keybinds"

    static func sheet(fromListKeybinds output: String, bundleIdentifier: String) -> ShortcutSheet {
        var seen = Set<KeyCombo>()
        var entriesByTheme: [Theme: [ShortcutSheet.Entry]] = [:]
        for line in output.split(separator: "\n") {
            guard let (trigger, action) = Self.binding(in: String(line)),
                  let keyCombo = Self.keyCombo(fromTrigger: trigger),
                  seen.insert(keyCombo).inserted else { continue }
            let theme = Theme(action: action)
            entriesByTheme[theme, default: []].append(.init(keyCombo: keyCombo, title: GhosttyActionTitles.title(for: action)))
        }
        let sections = Theme.allCases.compactMap { theme in
            entriesByTheme[theme].map { ShortcutSheet.Section(title: theme.title, entries: $0) }
        }
        return ShortcutSheet(id: sheetID, title: "Ghostty", apps: [bundleIdentifier], sections: sections)
    }

    /// Splits "keybind = super+==increase_font_size:1" into ("super+=", "increase_font_size:1"):
    /// the trigger may itself end with "=", the action always starts with a letter.
    static func binding(in line: String) -> (trigger: String, action: String)? {
        let prefix = "keybind = "
        guard line.hasPrefix(prefix) else { return nil }
        let rest = line.dropFirst(prefix.count)
        var index = rest.startIndex
        while let equal = rest[index...].firstIndex(of: "=") {
            let action = rest[rest.index(after: equal)...]
            if equal > rest.startIndex, let first = action.first, first.isLetter {
                return (String(rest[..<equal]), String(action))
            }
            index = rest.index(after: equal)
        }
        return nil
    }

    /// Ghostty trigger syntax → KeyComboParser syntax. Sequences ("ctrl+a>n") and keys
    /// without a Mac keycap (copy, paste…) give nil.
    static func keyCombo(fromTrigger trigger: String) -> KeyCombo? {
        guard !trigger.contains(">") else { return nil }
        var parts = trigger.components(separatedBy: "+")
        if trigger.hasSuffix("++") { parts = Array(parts.dropLast(2)) + ["+"] } // The "+" key itself.
        let translated = parts.map { part -> String in
            switch part {
            case "super": "cmd"
            case "arrow_left": "left"
            case "arrow_right": "right"
            case "arrow_up": "up"
            case "arrow_down": "down"
            case "page_up": "pageup"
            case "page_down": "pagedown"
            default: part.hasPrefix("digit_") ? String(part.dropFirst("digit_".count)) : part
            }
        }
        // KeyComboParser treats "+" as a separator: join with spaces, keep a lone "+" key last.
        if translated.last == "+" {
            return KeyComboParser.parse(translated.dropLast().joined(separator: " ") + " +")
        }
        return KeyComboParser.parse(translated.joined(separator: " "))
    }

    enum Theme: CaseIterable {
        case lineEditing, tabs, splits, scrolling, selection, search, window, other

        init(action: String) {
            let name = action.split(separator: ":").first.map(String.init) ?? action
            switch name {
            case "text", "esc", "csi": self = .lineEditing
            case _ where name.contains("tab"): self = .tabs
            case _ where name.contains("split"): self = .splits
            case _ where name.hasPrefix("scroll") || name == "jump_to_prompt" || name == "clear_screen": self = .scrolling
            case "adjust_selection", "select_all", "copy_to_clipboard", "paste_from_clipboard", "paste_from_selection":
                self = .selection
            case _ where name.contains("search"): self = .search
            case "new_window", "close_window", "close_all_windows", "close_surface", "quit", "toggle_fullscreen":
                self = .window
            default: self = .other
            }
        }

        var title: String {
            switch self {
            case .lineEditing: "Ligne de commande"
            case .tabs: "Onglets"
            case .splits: "Splits"
            case .scrolling: "Défilement et prompts"
            case .selection: "Sélection et presse-papiers"
            case .search: "Recherche"
            case .window: "Fenêtres"
            case .other: "Autres"
            }
        }
    }
}
