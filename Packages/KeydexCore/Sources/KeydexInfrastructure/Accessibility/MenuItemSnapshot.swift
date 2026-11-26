/// Raw values of a menu item as exposed by the Accessibility API, before interpretation.
///
/// Keeping the raw reading separate from its interpretation lets the decoding rules be
/// unit-tested without a running app, and lets diagnostics show exactly what macOS reports.
struct MenuItemSnapshot: Equatable, Sendable {
    var title: String
    /// `AXMenuItemCmdChar`: the key equivalent character, if any.
    var commandCharacter: String?
    /// `AXMenuItemCmdVirtualKey`: the virtual key code, if any.
    var commandVirtualKey: Int?
    /// `AXMenuItemCmdGlyph`: a Carbon menu glyph code for non-printable keys, if any.
    var commandGlyph: Int?
    /// `AXMenuItemCmdModifiers`: Carbon menu modifier flags.
    var commandModifiers: Int?
    var isEnabled: Bool
    var children: [MenuItemSnapshot]

    init(
        title: String,
        commandCharacter: String? = nil,
        commandVirtualKey: Int? = nil,
        commandGlyph: Int? = nil,
        commandModifiers: Int? = nil,
        isEnabled: Bool = true,
        children: [MenuItemSnapshot] = []
    ) {
        self.title = title
        self.commandCharacter = commandCharacter
        self.commandVirtualKey = commandVirtualKey
        self.commandGlyph = commandGlyph
        self.commandModifiers = commandModifiers
        self.isEnabled = isEnabled
        self.children = children
    }
}
