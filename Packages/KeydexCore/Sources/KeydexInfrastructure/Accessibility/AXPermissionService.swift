import AppKit
import ApplicationServices
import KeydexDomain
import Observation

/// Accessibility permission backed by `AXIsProcessTrusted`.
///
/// macOS sends no reliable notification when the permission changes, so the status is
/// re-checked every second while it is missing (a cheap local call), then polling stops.
@MainActor
@Observable
public final class AXPermissionService: AccessibilityPermissionProviding {
    public private(set) var isGranted: Bool

    @ObservationIgnored private var pollingTask: Task<Void, Never>?

    private static let settingsURL =
        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!

    public init() {
        isGranted = AXIsProcessTrusted()
        startPollingUntilGranted()
    }

    isolated deinit {
        pollingTask?.cancel()
    }

    public func requestAccess() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        isGranted = AXIsProcessTrustedWithOptions(options)
    }

    public func openSystemSettings() {
        NSWorkspace.shared.open(Self.settingsURL)
    }

    private func startPollingUntilGranted() {
        guard !isGranted else { return }
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                isGranted = AXIsProcessTrusted()
                if isGranted { return }
            }
        }
    }
}
