/// Shortcuts written down by people for an app (or for every app), because the app does not
/// list them in its menus: shell line editing, terminal keybindings, system shortcuts…
public struct ShortcutSheet: Equatable, Sendable {
    public struct Section: Equatable, Sendable {
        public let title: String?
        public let entries: [Entry]

        public init(title: String?, entries: [Entry]) {
            self.title = title
            self.entries = entries
        }
    }

    public struct Entry: Equatable, Sendable {
        public let keyCombo: KeyCombo
        public let title: String

        public init(keyCombo: KeyCombo, title: String) {
            self.keyCombo = keyCombo
            self.title = title
        }
    }

    /// Stable identifier, e.g. the file name.
    public let id: String
    public let title: String
    /// Names or bundle identifiers of the apps it applies to; empty means every app.
    public let apps: [String]
    /// A shell command whose output is a sheet, completing this one: for apps that can list
    /// their own shortcuts (`ghostty +list-keybinds`, `tmux list-keys`…), so the sheet always
    /// matches the user's configuration. Run from the sheet's folder.
    public let command: String?
    public let sections: [Section]

    public init(id: String, title: String, apps: [String], command: String? = nil, sections: [Section]) {
        self.id = id
        self.title = title
        self.apps = apps
        self.command = command
        self.sections = sections
    }

    /// The same sheet, with sections added (e.g. those produced by its command).
    public func appending(_ extraSections: [Section]) -> ShortcutSheet {
        ShortcutSheet(id: id, title: title, apps: apps, command: command, sections: extraSections + sections)
    }

    public func applies(to app: AppInfo) -> Bool {
        guard !apps.isEmpty else { return true }
        let candidates = [app.name, app.bundleIdentifier].compactMap { $0 }.map(SearchText.normalize)
        return apps.contains { candidates.contains(SearchText.normalize($0)) }
    }

    /// One group per section, titled "Sheet · Section".
    public var groups: [ShortcutGroup] {
        sections.enumerated().compactMap { sectionIndex, section in
            guard !section.entries.isEmpty else { return nil }
            let groupID = "sheet:\(id):\(sectionIndex)"
            let shortcuts = section.entries.enumerated().map { entryIndex, entry in
                Shortcut(id: "\(groupID):\(entryIndex)", title: entry.title, keyCombo: entry.keyCombo)
            }
            let groupTitle = section.title.map { "\(title) · \($0)" } ?? title
            return ShortcutGroup(
                id: groupID, title: groupTitle, kind: .sheet, appliesToEveryApp: apps.isEmpty, shortcuts: shortcuts
            )
        }
    }
}
