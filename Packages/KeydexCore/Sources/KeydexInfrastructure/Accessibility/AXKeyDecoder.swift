import Carbon.HIToolbox
import KeydexDomain

/// Turns the raw key-equivalent attributes of an Accessibility menu item into a `KeyCombo`.
enum AXKeyDecoder {
    /// Returns the shortcut of a menu item, or `nil` if the item has none.
    static func keyCombo(of item: MenuItemSnapshot) -> KeyCombo? {
        guard let key = key(character: item.commandCharacter,
                            glyph: item.commandGlyph,
                            virtualKey: item.commandVirtualKey) else { return nil }
        return KeyCombo(modifiers: modifiers(fromMenuModifiers: item.commandModifiers ?? 0), key: key)
    }

    /// The glyph wins when present (it is how macOS labels non-printable keys), then the
    /// character, and the virtual key only as a fallback for non-printable keys.
    static func key(character: String?, glyph: Int?, virtualKey: Int?) -> Key? {
        if let glyph, let special = specialKey(forGlyph: glyph) {
            return .special(special)
        }
        if let character, !character.isEmpty {
            return key(forCharacter: character)
        }
        if let virtualKey, let special = specialKey(forVirtualKey: virtualKey) {
            return .special(special)
        }
        return nil
    }

    // MARK: Modifiers

    /// Carbon menu modifier flags (`kAXMenuItemModifier*`). ⌘ is implied unless
    /// `kAXMenuItemModifierNoCommand` is set. Bit 4 (fn / 🌐) is undocumented but reported by
    /// macOS, e.g. for Window › Fill (fn ⌃ F): observed value 28 = fn + no ⌘ + ⌃.
    static func modifiers(fromMenuModifiers raw: Int) -> ModifierSet {
        var modifiers: ModifierSet = raw & kAXMenuItemModifierNoCommand == 0 ? .command : []
        if raw & kAXMenuItemModifierShift != 0 { modifiers.insert(.shift) }
        if raw & kAXMenuItemModifierOption != 0 { modifiers.insert(.option) }
        if raw & kAXMenuItemModifierControl != 0 { modifiers.insert(.control) }
        if raw & menuModifierFunction != 0 { modifiers.insert(.function) }
        return modifiers
    }

    private static let kAXMenuItemModifierShift = 1 << 0
    private static let kAXMenuItemModifierOption = 1 << 1
    private static let kAXMenuItemModifierControl = 1 << 2
    private static let kAXMenuItemModifierNoCommand = 1 << 3
    private static let menuModifierFunction = 1 << 4

    // MARK: Characters

    private static func key(forCharacter character: String) -> Key? {
        guard let scalar = character.unicodeScalars.first else { return nil }
        if let special = specialKey(forScalar: scalar.value) {
            return .special(special)
        }
        let isControlCharacter = scalar.value < 0x20 || scalar.value == 0x7F
        let isPrivateUse = (0xF700...0xF8FF).contains(scalar.value)
        guard !isControlCharacter, !isPrivateUse else { return nil }
        return .character(character.uppercased())
    }

    /// Control characters and AppKit function-key characters (`NSUpArrowFunctionKey`…).
    private static func specialKey(forScalar value: UInt32) -> SpecialKey? {
        switch value {
        case 0x03: .enter
        case 0x08, 0x7F: .delete
        case 0x09: .tab
        case 0x0D: .returnKey
        case 0x19: .backTab
        case 0x1B: .escape
        case 0x20: .space
        case 0xF700: .upArrow
        case 0xF701: .downArrow
        case 0xF702: .leftArrow
        case 0xF703: .rightArrow
        case 0xF704...0xF726: .function(Int(value - 0xF704) + 1)
        case 0xF728: .forwardDelete
        case 0xF729: .home
        case 0xF72B: .end
        case 0xF72C: .pageUp
        case 0xF72D: .pageDown
        case 0xF739: .clear
        case 0xF746: .help
        default: nil
        }
    }

    // MARK: Glyphs

    /// Carbon menu glyphs (`kMenu*Glyph` in HIToolbox/Menus.h).
    private static func specialKey(forGlyph glyph: Int) -> SpecialKey? {
        switch glyph {
        case 0x02: .tab
        case 0x03: .backTab
        case 0x04: .enter
        case 0x09: .space
        case 0x0A: .forwardDelete
        case 0x0B, 0x0C, 0x0D: .returnKey
        case 0x10, 0x6A: .downArrow
        case 0x17: .delete
        case 0x18, 0x64: .leftArrow
        case 0x19, 0x68: .upArrow
        case 0x1A, 0x65: .rightArrow
        case 0x1B: .escape
        case 0x1C: .clear
        case 0x62: .pageUp
        case 0x63: .capsLock
        case 0x66: .home
        case 0x67: .help
        case 0x69: .end
        case 0x6B: .pageDown
        case 0x6F...0x7A: .function(glyph - 0x6F + 1)
        case 0x87...0x89: .function(glyph - 0x87 + 13)
        case 0x8C: .eject
        case 0x8F...0x92: .function(glyph - 0x8F + 16)
        default: nil
        }
    }

    // MARK: Virtual keys

    /// Only non-printable keys: printable ones are always reported through the character,
    /// and some apps report virtual key 0 (`kVK_ANSI_A`) for items without a shortcut.
    private static let specialKeysByVirtualKey: [Int: SpecialKey] = [
        kVK_Return: .returnKey, kVK_ANSI_KeypadEnter: .enter, kVK_Tab: .tab, kVK_Space: .space,
        kVK_Delete: .delete, kVK_ForwardDelete: .forwardDelete, kVK_Escape: .escape,
        kVK_ANSI_KeypadClear: .clear,
        kVK_LeftArrow: .leftArrow, kVK_RightArrow: .rightArrow,
        kVK_UpArrow: .upArrow, kVK_DownArrow: .downArrow,
        kVK_Home: .home, kVK_End: .end, kVK_PageUp: .pageUp, kVK_PageDown: .pageDown,
        kVK_Help: .help,
        kVK_F1: .function(1), kVK_F2: .function(2), kVK_F3: .function(3), kVK_F4: .function(4),
        kVK_F5: .function(5), kVK_F6: .function(6), kVK_F7: .function(7), kVK_F8: .function(8),
        kVK_F9: .function(9), kVK_F10: .function(10), kVK_F11: .function(11), kVK_F12: .function(12),
        kVK_F13: .function(13), kVK_F14: .function(14), kVK_F15: .function(15), kVK_F16: .function(16),
        kVK_F17: .function(17), kVK_F18: .function(18), kVK_F19: .function(19), kVK_F20: .function(20),
    ]

    private static func specialKey(forVirtualKey virtualKey: Int) -> SpecialKey? {
        specialKeysByVirtualKey[virtualKey]
    }
}
