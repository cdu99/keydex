@testable import KeydexInfrastructure
import KeydexDomain
import Testing

@Suite("Decoding Accessibility key equivalents")
struct AXKeyDecoderTests {
    // MARK: Modifiers

    @Test("Carbon menu modifier flags", arguments: [
        (0, ModifierSet.command),
        (1, [.shift, .command]),
        (2, [.option, .command]),
        (4, [.control, .command]),
        (7, [.control, .option, .shift, .command]),
        (8, []),
        (8 | 4, [.control]),
        (8 | 2 | 1, [.option, .shift]),
        (28, [.function, .control]), // Window › Fill: fn ⌃ F
        (16, [.function, .command]),
    ] as [(Int, ModifierSet)])
    func modifiers(raw: Int, expected: ModifierSet) {
        #expect(AXKeyDecoder.modifiers(fromMenuModifiers: raw) == expected)
    }

    // MARK: Keys

    @Test("Printable characters are shown uppercased, like on the keycap")
    func printableCharacter() {
        #expect(AXKeyDecoder.key(character: "c", glyph: nil, virtualKey: nil) == .character("C"))
        #expect(AXKeyDecoder.key(character: ",", glyph: 0, virtualKey: 43) == .character(","))
    }

    @Test("Control and AppKit function-key characters map to special keys", arguments: [
        ("\r", SpecialKey.returnKey), ("\u{7F}", .delete), ("\u{8}", .delete), ("\u{1B}", .escape),
        ("\t", .tab), (" ", .space), ("\u{F702}", .leftArrow), ("\u{F703}", .rightArrow),
        ("\u{F700}", .upArrow), ("\u{F701}", .downArrow), ("\u{F704}", .function(1)),
        ("\u{F70F}", .function(12)), ("\u{F728}", .forwardDelete), ("\u{F72C}", .pageUp),
    ])
    func specialCharacters(character: String, expected: SpecialKey) {
        #expect(AXKeyDecoder.key(character: character, glyph: nil, virtualKey: nil) == .special(expected))
    }

    @Test("Carbon menu glyphs map to special keys", arguments: [
        (0x64, SpecialKey.leftArrow), (0x65, .rightArrow), (0x68, .upArrow), (0x6A, .downArrow),
        (0x17, .delete), (0x0A, .forwardDelete), (0x0B, .returnKey), (0x1B, .escape),
        (0x02, .tab), (0x09, .space), (0x6F, .function(1)), (0x7A, .function(12)),
        (0x87, .function(13)), (0x8F, .function(16)), (0x62, .pageUp), (0x6B, .pageDown),
    ])
    func glyphs(glyph: Int, expected: SpecialKey) {
        #expect(AXKeyDecoder.key(character: nil, glyph: glyph, virtualKey: nil) == .special(expected))
    }

    @Test("The glyph wins over the character")
    func glyphPrecedence() {
        #expect(AXKeyDecoder.key(character: "\u{F702}", glyph: 0x65, virtualKey: nil) == .special(.rightArrow))
    }

    @Test("The virtual key is used only for non-printable keys")
    func virtualKeyFallback() {
        #expect(AXKeyDecoder.key(character: nil, glyph: nil, virtualKey: 0x7B) == .special(.leftArrow))
        #expect(AXKeyDecoder.key(character: nil, glyph: nil, virtualKey: 0x7A) == .special(.function(1)))
        // 0 is kVK_ANSI_A, which some apps report for items without any shortcut.
        #expect(AXKeyDecoder.key(character: nil, glyph: nil, virtualKey: 0) == nil)
    }

    @Test("Items without key equivalent have no shortcut")
    func noShortcut() {
        #expect(AXKeyDecoder.key(character: nil, glyph: nil, virtualKey: nil) == nil)
        #expect(AXKeyDecoder.key(character: "", glyph: 0, virtualKey: nil) == nil)
        #expect(AXKeyDecoder.keyCombo(of: MenuItemSnapshot(title: "À propos", commandModifiers: 0)) == nil)
    }

    @Test("A full item decodes into a combo")
    func fullItem() {
        let item = MenuItemSnapshot(title: "Rechercher", commandCharacter: "f", commandModifiers: 2)
        #expect(AXKeyDecoder.keyCombo(of: item) == KeyCombo(modifiers: [.option, .command], key: .character("F")))
    }
}
