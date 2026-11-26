import Foundation
import KeydexDomain
import KeydexInfrastructure
import Testing

@Suite("Loading sheets from folders")
struct DirectorySheetProviderTests {
    private let root: URL = {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("keydex-tests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    private func folder(_ name: String, files: [String: String]) throws -> URL {
        let url = root.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        for (file, text) in files {
            try text.write(to: url.appendingPathComponent(file), atomically: true, encoding: .utf8)
        }
        return url
    }

    @Test("Markdown files are loaded in name order; other files are ignored")
    func loadsMarkdown() throws {
        let user = try folder("user", files: [
            "zsh.md": "# zsh\n- `⌃W` Word", "macos.md": "# macOS\n- `⌃←` Space", "notes.txt": "ignored",
        ])
        let provider = DirectorySheetProvider(directories: [user])
        #expect(provider.sheets().map(\.title) == ["macOS", "zsh"])
    }

    @Test("A user file replaces the bundled file with the same name")
    func override() throws {
        let bundled = try folder("bundled", files: ["zsh.md": "# zsh (bundled)", "macos.md": "# macOS"])
        let user = try folder("user", files: ["ZSH.md": "# zsh (mine)"])
        let provider = DirectorySheetProvider(directories: [bundled, user])
        #expect(Set(provider.sheets().map(\.title)) == ["macOS", "zsh (mine)"])
    }

    @Test("Reload picks up changes, and parsing issues are reported per file")
    func reloadAndIssues() throws {
        let user = try folder("user", files: [:])
        let provider = DirectorySheetProvider(directories: [user])
        #expect(provider.sheets().isEmpty)

        try "# App\n- `⌘?!` Bad".write(to: user.appendingPathComponent("app.md"), atomically: true, encoding: .utf8)
        provider.reload()
        #expect(provider.sheets().map(\.title) == ["App"])
        #expect(provider.files.first?.issues.count == 1)
    }

    @Test("A missing folder is simply empty")
    func missingFolder() {
        #expect(DirectorySheetProvider(directories: [root.appendingPathComponent("nope")]).sheets().isEmpty)
    }
}
