import Foundation
import KeydexInfrastructure
import Testing

@MainActor
@Suite("Watching the sheets folder")
struct DirectoryWatcherTests {
    @Test("Saving a file in the folder is noticed")
    func noticesChanges() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("keydex-watch-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var changes = 0
        let watcher = DirectoryWatcher(directory: folder, latency: 0.05) { changes += 1 }
        try await Task.sleep(for: .milliseconds(200)) // Let the stream start.

        try "# App".write(to: folder.appendingPathComponent("app.md"), atomically: true, encoding: .utf8)
        for _ in 0..<60 where changes == 0 {
            try await Task.sleep(for: .milliseconds(50))
        }
        #expect(changes > 0)
        withExtendedLifetime(watcher) {}
    }
}
