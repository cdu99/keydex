import AppKit
import KeydexDomain

/// Runs the command of a sheet for an app and returns what it prints.
///
/// The command runs through `/bin/sh` from the sheet's folder (so `./script.sh` works), and
/// learns which app it is for through environment variables: `KEYDEX_APP_NAME`,
/// `KEYDEX_APP_BUNDLE_ID`, `KEYDEX_APP_PATH` (the .app bundle) and `KEYDEX_APP_PID`.
/// A command that fails, prints nothing usable or exceeds `timeout` gives `nil`.
struct SheetCommandRunner: Sendable {
    var timeout: TimeInterval

    func run(_ command: String, in directory: URL, for app: AppInfo) -> String? {
        // Output goes to a file rather than a pipe: a background process left by the command
        // would keep a pipe open, and reading it would wait for that process too.
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("keydex-sheet-\(UUID().uuidString)")
        guard FileManager.default.createFile(atPath: outputURL.path, contents: nil),
              let output = try? FileHandle(forWritingTo: outputURL) else { return nil }
        defer {
            try? output.close()
            try? FileManager.default.removeItem(at: outputURL)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]
        process.currentDirectoryURL = directory
        process.environment = ProcessInfo.processInfo.environment.merging(Self.environment(for: app)) { $1 }
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        let exited = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in exited.signal() }
        do {
            try process.run()
        } catch {
            return nil
        }
        // Never let a stuck command block the catalog read.
        guard exited.wait(timeout: .now() + timeout) == .success else {
            process.terminate()
            return nil
        }
        guard process.terminationReason == .exit, process.terminationStatus == 0,
              let data = try? Data(contentsOf: outputURL) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func environment(for app: AppInfo) -> [String: String] {
        var environment = [
            "KEYDEX_APP_NAME": app.name,
            "KEYDEX_APP_PID": String(app.processID),
        ]
        environment["KEYDEX_APP_BUNDLE_ID"] = app.bundleIdentifier
        environment["KEYDEX_APP_PATH"] = NSRunningApplication(processIdentifier: app.processID)?.bundleURL?.path
        return environment
    }
}
