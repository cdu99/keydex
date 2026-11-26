import KeydexDomain

/// Developer tool: dumps the raw Accessibility values of an app's menus, to check how
/// macOS reports a given shortcut (e.g. whether fn is exposed) against what the menu shows.
public struct MenuBarDiagnostics: Sendable {
    private let reader = AXMenuBarReader()

    public init() {}

    @concurrent
    public func report(for app: AppInfo) async -> String {
        let header = "Keydex — diagnostic Accessibilité de \(app.name) (\(app.bundleIdentifier ?? "?"))\n"
        do {
            let menuBar = try reader.readMenuBar(ofProcess: app.processID)
            return header + menuBar.map { describe($0, depth: 0) }.joined()
        } catch {
            return header + "Erreur : \(error)\n"
        }
    }

    private func describe(_ item: MenuItemSnapshot, depth: Int) -> String {
        let indent = String(repeating: "  ", count: depth)
        var fields: [String] = []
        if let character = item.commandCharacter {
            let codes = character.unicodeScalars.map { String(format: "U+%04X", $0.value) }
            fields.append("char=\(codes.joined(separator: ","))")
        }
        if let key = item.commandVirtualKey { fields.append("vkey=\(key)") }
        if let glyph = item.commandGlyph, glyph != 0 { fields.append("glyph=\(glyph)") }
        let hasKey = item.commandCharacter != nil || item.commandVirtualKey != nil || item.commandGlyph ?? 0 != 0
        if let modifiers = item.commandModifiers, hasKey {
            fields.append("mods=\(modifiers)")
        }
        if !item.isEnabled { fields.append("disabled") }
        if let combo = AXKeyDecoder.keyCombo(of: item) { fields.append("→ \(combo.displayString)") }
        let line = "\(indent)\(item.title.isEmpty ? "—" : item.title)  \(fields.joined(separator: " "))\n"
        return line + item.children.map { describe($0, depth: depth + 1) }.joined()
    }
}
