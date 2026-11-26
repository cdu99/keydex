import KeydexDomain
import Testing

@Suite("Reading written key combinations")
struct KeyComboParserTests {
    @Test("Symbols, words, glued or separated", arguments: [
        ("⌃W", "⌃W"), ("ctrl+w", "⌃W"), ("Ctrl W", "⌃W"), ("cmd shift f", "⇧⌘F"), ("⇧⌘F", "⇧⌘F"),
        ("⌥⌘←", "⌥⌘←"), ("fn ctrl left", "fn⌃←"), ("alt+backspace", "⌥⌫"), ("opt d", "⌥D"),
        ("f5", "F5"), ("esc", "⎋"), ("⌘,", "⌘,"), ("cmd+-", "⌘-"), ("⌘`", "⌘`"),
    ])
    func parses(text: String, expected: String) {
        #expect(KeyComboParser.parse(text)?.displayString == expected)
    }

    @Test("The plus key itself", arguments: ["⌘+", "cmd++"])
    func plusKey(text: String) {
        #expect(KeyComboParser.parse(text) == KeyCombo(modifiers: .command, key: .character("+")))
    }

    @Test("A key alone has no modifiers")
    func keyAlone() {
        #expect(KeyComboParser.parse("tab") == KeyCombo(modifiers: [], key: .special(.tab)))
    }

    @Test("Text that is not exactly one key is rejected", arguments: ["", "cmd", "⌘AB", "ctrl x ctrl k", "hello", "⌘ potato"])
    func rejects(text: String) {
        #expect(KeyComboParser.parse(text) == nil)
    }
}
