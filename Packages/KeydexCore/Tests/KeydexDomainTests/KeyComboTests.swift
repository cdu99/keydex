import KeydexDomain
import Testing

@Suite("Key combo display")
struct KeyComboTests {
    @Test("Modifiers are always shown in macOS order: fn ⌃ ⌥ ⇧ ⌘")
    func modifierOrder() {
        let all: ModifierSet = [.command, .shift, .option, .control, .function]
        #expect(all.symbols == ["fn", "⌃", "⌥", "⇧", "⌘"])
    }

    @Test("Only the modifiers present are shown")
    func partialModifiers() {
        let modifiers: ModifierSet = [.command, .option]
        #expect(modifiers.symbols == ["⌥", "⌘"])
    }

    @Test("A combo lists modifiers then the key, like a macOS menu")
    func displayString() {
        let combo = KeyCombo(modifiers: [.option, .command], key: .character("F"))
        #expect(combo.keycaps == ["⌥", "⌘", "F"])
        #expect(combo.displayString == "⌥⌘F")
    }

    @Test("Special keys use the standard Mac symbols", arguments: [
        (SpecialKey.returnKey, "↩"), (.delete, "⌫"), (.forwardDelete, "⌦"), (.escape, "⎋"),
        (.tab, "⇥"), (.leftArrow, "←"), (.rightArrow, "→"), (.upArrow, "↑"), (.downArrow, "↓"),
        (.pageUp, "⇞"), (.pageDown, "⇟"), (.home, "↖"), (.end, "↘"), (.function(5), "F5"),
    ])
    func specialKeySymbols(key: SpecialKey, symbol: String) {
        #expect(Key.special(key).symbol == symbol)
    }
}
