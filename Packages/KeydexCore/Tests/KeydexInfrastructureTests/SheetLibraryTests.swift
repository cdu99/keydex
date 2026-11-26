import Foundation
import KeydexDomain
import KeydexInfrastructure
import Testing

@MainActor
@Suite("The sheet library")
struct SheetLibraryTests {
    private let root = FileManager.default.temporaryDirectory.appendingPathComponent("keydex-lib-\(UUID().uuidString)")

    @Test("Creates the user folder and summarizes every sheet, bundled or not")
    func summaries() throws {
        let bundled = root.appendingPathComponent("bundled")
        try FileManager.default.createDirectory(at: bundled, withIntermediateDirectories: true)
        try "# Ghostty\napps: Ghostty\ncommand: sh ./ghostty.sh\n- `⌘K` Clear\n- `⌘?!` Bad"
            .write(to: bundled.appendingPathComponent("ghostty.md"), atomically: true, encoding: .utf8)
        let user = root.appendingPathComponent("user")

        let library = SheetLibrary(bundledFolder: bundled, userFolder: user)
        #expect(FileManager.default.fileExists(atPath: user.path))
        #expect(library.summaries == [SheetSummary(
            id: "ghostty.md", title: "Ghostty", apps: ["Ghostty"], command: "sh ./ghostty.sh",
            shortcutCount: 1, issueCount: 1, isBundled: true
        )])

        try "# Mine".write(to: user.appendingPathComponent("mine.md"), atomically: true, encoding: .utf8)
        var changed = false
        library.onChange = { changed = true }
        library.reload()
        #expect(changed)
        #expect(library.summaries.map(\.isBundled) == [true, false])
    }
}
