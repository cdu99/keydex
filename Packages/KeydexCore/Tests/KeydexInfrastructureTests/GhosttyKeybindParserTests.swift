import Foundation
@testable import KeydexInfrastructure
import KeydexDomain
import Testing

@Suite("Reading Ghostty's keybindings")
struct GhosttyKeybindParserTests {
    /// Real output of `ghostty +list-keybinds --default` (Ghostty 1.4).
    private let output = try! String(
        contentsOf: URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Fixtures/ghostty-list-keybinds.txt"),
        encoding: .utf8
    )
    private var sheet: ShortcutSheet {
        GhosttyKeybindParser.sheet(fromListKeybinds: output, bundleIdentifier: "com.mitchellh.ghostty")
    }

    private func entry(_ keys: String) -> ShortcutSheet.Entry? {
        let combo = KeyComboParser.parse(keys)
        return sheet.sections.flatMap(\.entries).first { $0.keyCombo == combo }
    }

    @Test("Triggers that end with '=' are split correctly")
    func triggerWithEqualSign() {
        #expect(GhosttyKeybindParser.binding(in: "keybind = super+==increase_font_size:1")! == ("super+=", "increase_font_size:1"))
        #expect(GhosttyKeybindParser.binding(in: "keybind = super+ctrl+==equalize_splits")! == ("super+ctrl+=", "equalize_splits"))
    }

    @Test("Ghostty trigger names become Mac keys", arguments: [
        ("super+shift+arrow_up", "⇧⌘↑"), ("alt+arrow_left", "⌥←"), ("super+digit_1", "⌘1"),
        ("super+page_down", "⌘⇟"), ("super+backspace", "⌘⌫"), ("super++", "⌘+"), ("shift+home", "⇧↖"),
    ])
    func triggers(trigger: String, expected: String) {
        #expect(GhosttyKeybindParser.keyCombo(fromTrigger: trigger)?.displayString == expected)
    }

    @Test("Sequences and keys without a Mac keycap are skipped")
    func skipped() {
        #expect(GhosttyKeybindParser.keyCombo(fromTrigger: "ctrl+a>n") == nil)
        #expect(GhosttyKeybindParser.keyCombo(fromTrigger: "copy") == nil)
    }

    @Test("The line editing keys come first, with what they send to the shell")
    func lineEditing() {
        #expect(sheet.sections.first?.title == "Ligne de commande")
        #expect(entry("⌥←")?.title == "Mot précédent (envoie ⌥B)")
        #expect(entry("⌥→")?.title == "Mot suivant (envoie ⌥F)")
        #expect(entry("⌘←")?.title == "Début de ligne (envoie ⌃A)")
        #expect(entry("⌘⌫")?.title == "Effacer jusqu'au début de la ligne (envoie ⌃U)")
    }

    @Test("Actions get readable titles and themes")
    func titles() {
        #expect(entry("⌘K")?.title == "Effacer l'écran")
        #expect(entry("⇧⌘↑")?.title == "Prompt précédent")
        #expect(entry("⌘D")?.title == "Nouveau split à droite")
        #expect(entry("⌘3")?.title == "Aller à l'onglet 3")
        let titles = sheet.sections.map(\.title)
        #expect(titles.contains("Splits") && titles.contains("Onglets"))
    }

    @Test("Each key combination appears once (super+digit_1 and super+1 are the same)")
    func noDuplicates() {
        let combos = sheet.sections.flatMap(\.entries).map(\.keyCombo)
        #expect(Set(combos).count == combos.count)
        #expect(combos.count > 70)
    }

    @Test("Unknown actions are humanized")
    func unknownAction() {
        #expect(GhosttyActionTitles.title(for: "toggle_secure_input") == "Toggle secure input")
    }
}
