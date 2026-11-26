import Foundation
import KeydexDomain
import Testing

/// Tests the bundled sheets/ghostty.sh against the real output of `ghostty +list-keybinds`
/// (Ghostty 1.4 defaults), through a fake Ghostty.app whose executable prints the fixture.
@Suite("The Ghostty sheet script")
struct GhosttySheetScriptTests {
    private static let testsFolder = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    private static let repository = testsFolder.deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()

    private let sheet: ShortcutSheet = {
        let fakeApp = FileManager.default.temporaryDirectory.appendingPathComponent("Ghostty-\(UUID().uuidString).app")
        let executable = fakeApp.appendingPathComponent("Contents/MacOS/ghostty")
        try! FileManager.default.createDirectory(at: executable.deletingLastPathComponent(), withIntermediateDirectories: true)
        let fixture = testsFolder.appendingPathComponent("Fixtures/ghostty-list-keybinds.txt").path
        try! "#!/bin/sh\ncat '\(fixture)'\n".write(to: executable, atomically: true, encoding: .utf8)
        try! FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [repository.appendingPathComponent("sheets/ghostty.sh").path]
        process.environment = ["KEYDEX_APP_PATH": fakeApp.path, "PATH": "/usr/bin:/bin"]
        let output = Pipe()
        process.standardOutput = output
        try! process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let result = ShortcutSheetParser.parse(String(data: data, encoding: .utf8)!, id: "ghostty")
        #expect(result.issues.isEmpty, "The script prints a valid sheet: \(result.issues)")
        return result.sheet
    }()

    private func title(of keys: String) -> String? {
        let combo = KeyComboParser.parse(keys)
        return sheet.sections.flatMap(\.entries).first { $0.keyCombo == combo }?.title
    }

    @Test("Line editing comes first, with what each key sends to the shell")
    func lineEditing() {
        #expect(sheet.sections.first?.title == "Ligne de commande")
        #expect(title(of: "⌥←") == "Mot précédent (envoie ⌥B)")
        #expect(title(of: "⌥→") == "Mot suivant (envoie ⌥F)")
        #expect(title(of: "⌘←") == "Début de ligne (envoie ⌃A)")
        #expect(title(of: "⌘⌫") == "Effacer jusqu’au début de la ligne (envoie ⌃U)")
    }

    @Test("Actions get readable titles, grouped by theme")
    func titles() {
        #expect(title(of: "⌘K") == "Effacer l’écran")
        #expect(title(of: "⇧⌘↑") == "Prompt précédent")
        #expect(title(of: "⌘D") == "Nouveau split à droite")
        #expect(title(of: "⌘3") == "Aller à l’onglet 3")
        #expect(title(of: "⌘=") == "Agrandir le texte", "Trigger ending with '='")
        #expect(title(of: "⌘+") == "Agrandir le texte", "The '+' key")
        #expect(sheet.sections.map(\.title).contains("Splits"))
    }

    @Test("Each key combination appears once; keys without a Mac keycap are skipped")
    func uniqueAndComplete() {
        let combos = sheet.sections.flatMap(\.entries).map(\.keyCombo)
        #expect(Set(combos).count == combos.count)
        #expect(combos.count > 70)
    }
}
