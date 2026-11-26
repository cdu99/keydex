import AppKit
import KeydexDomain

extension AppInfo {
    init(_ runningApplication: NSRunningApplication) {
        self.init(
            processID: runningApplication.processIdentifier,
            bundleIdentifier: runningApplication.bundleIdentifier,
            name: runningApplication.localizedName ?? runningApplication.bundleIdentifier ?? "App"
        )
    }
}
