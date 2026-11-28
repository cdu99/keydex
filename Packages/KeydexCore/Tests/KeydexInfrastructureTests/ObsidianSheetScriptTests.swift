import Foundation
import KeydexDomain
import Testing

/// Tests the bundled sheets/obsidian.sh against the real output of Obsidian's command line
/// (Obsidian 1.12, a vault with a few custom hotkeys), through a fake Obsidian.app whose
/// `obsidian-cli` prints the fixtures.
@Suite("The Obsidian sheet script")
struct ObsidianSheetScriptTests {
    private static let testsFolder = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    private static let repository = testsFolder.deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()

    /// Runs the script with a fake CLI; `namesAvailable: false` makes `eval` fail.
    private static func sheet(namesAvailable: Bool) -> ShortcutSheet {
        let fakeApp = FileManager.default.temporaryDirectory.appendingPathComponent("Obsidian-\(UUID().uuidString).app")
        let executable = fakeApp.appendingPathComponent("Contents/MacOS/obsidian-cli")
        try! FileManager.default.createDirectory(at: executable.deletingLastPathComponent(), withIntermediateDirectories: true)
        let fixtures = testsFolder.appendingPathComponent("Fixtures").path
        let eval = namesAvailable ? "cat '\(fixtures)/obsidian-eval-names.txt'" : "echo 'Error: not enabled' >&2; exit 1"
        let cli = """
            #!/bin/sh
            case "$1" in
                eval) \(eval) ;;
                hotkeys) cat '\(fixtures)/obsidian-hotkeys.tsv' ;;
                *) exit 1 ;;
            esac
            """
        try! cli.write(to: executable, atomically: true, encoding: .utf8)
        try! FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [repository.appendingPathComponent("sheets/obsidian.sh").path]
        process.environment = ["KEYDEX_APP_PATH": fakeApp.path, "PATH": "/usr/bin:/bin"]
        let output = Pipe()
        process.standardOutput = output
        try! process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0)
        let result = ShortcutSheetParser.parse(String(data: data, encoding: .utf8)!, id: "obsidian")
        #expect(result.issues.isEmpty, "The script prints a valid sheet: \(result.issues)")
        return result.sheet
    }

    private let sheet = Self.sheet(namesAvailable: true)

    private func title(of keys: String, in sheet: ShortcutSheet) -> String? {
        let combo = KeyComboParser.parse(keys)
        return sheet.sections.flatMap(\.entries).first { $0.keyCombo == combo }?.title
    }

    @Test("Hotkeys get Obsidian's own names, without the plugin prefix")
    func titles() {
        #expect(title(of: "⌘B", in: sheet) == "Toggle bold")
        #expect(title(of: "⌘P", in: sheet) == "Open command palette")
        #expect(title(of: "⌥⌘G", in: sheet) == "Open graph view")
        #expect(title(of: "⌥T", in: sheet) == "Insert template", "Custom hotkey")
    }

    @Test("A command with several hotkeys gets one entry per hotkey; Mac-less keys are skipped")
    func keys() {
        #expect(title(of: "⌃⇥", in: sheet) == "Go to next tab")
        #expect(title(of: "⇧⌘]", in: sheet) == "Go to next tab")
        #expect(title(of: "⌥⌘↩", in: sheet) == "Open link under cursor to the right")
        #expect(title(of: "F2", in: sheet) == "Rename file")
        let entries = sheet.sections.flatMap(\.entries)
        #expect(!entries.contains { $0.title == "Show context menu under cursor" }, "⌥ Insert has no Mac key")
        #expect(Set(entries.map(\.keyCombo)).count == entries.count)
    }

    @Test("Sections group commands by theme, editing first")
    func sections() {
        #expect(sheet.sections.map(\.title) == [
            "Édition", "Onglets et fenêtres", "Navigation et recherche", "Fichiers", "Panneaux",
        ])
    }

    @Test("Without command names (eval unavailable), titles come from the command ids")
    func withoutNames() {
        let sheet = Self.sheet(namesAvailable: false)
        #expect(title(of: "⌘B", in: sheet) == "Toggle bold")
        #expect(title(of: "⌘O", in: sheet) == "Open")
        #expect(sheet.sections.flatMap(\.entries).count > 40)
    }
}
