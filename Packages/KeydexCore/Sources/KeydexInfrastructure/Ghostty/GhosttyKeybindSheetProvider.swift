import AppKit
import KeydexDomain
import Synchronization

/// Ghostty's keybindings, read from Ghostty itself (`ghostty +list-keybinds`), so the sheet
/// always matches the user's configuration. Most of them are in no menu: line editing keys
/// sent to the shell, prompt jumps, scrolling, selection…
///
/// Only runs for Ghostty, with the executable of the running instance (~10 ms), and keeps the
/// result briefly so the prefetch and the glance do not both run it.
public final class GhosttyKeybindSheetProvider: ShortcutSheetProviding {
    public static let bundleIdentifier = "com.mitchellh.ghostty"

    private let cache = Mutex<(date: Date, sheet: ShortcutSheet)?>(nil)
    private let maxAge: TimeInterval
    private let timeout: TimeInterval

    public init(maxAge: TimeInterval = 2, timeout: TimeInterval = 2) {
        self.maxAge = maxAge
        self.timeout = timeout
    }

    public func sheets(for app: AppInfo) -> [ShortcutSheet] {
        guard app.bundleIdentifier == Self.bundleIdentifier else { return [] }
        if let cached = cache.withLock({ $0 }), Date().timeIntervalSince(cached.date) < maxAge {
            return [cached.sheet]
        }
        guard let output = listKeybinds(of: app) else { return [] }
        let sheet = GhosttyKeybindParser.sheet(fromListKeybinds: output, bundleIdentifier: Self.bundleIdentifier)
        cache.withLock { $0 = (Date(), sheet) }
        return [sheet]
    }

    private func listKeybinds(of app: AppInfo) -> String? {
        guard let bundle = NSRunningApplication(processIdentifier: app.processID)?.bundleURL else { return nil }
        let process = Process()
        process.executableURL = bundle.appendingPathComponent("Contents/MacOS/ghostty")
        process.arguments = ["+list-keybinds"]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return nil
        }
        // Never let a stuck process block the catalog read.
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [process] in
            if process.isRunning { process.terminate() }
        }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
