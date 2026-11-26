import AppKit
import KeydexDomain
import Observation

/// Tracks the frontmost application through `NSWorkspace` activation notifications,
/// ignoring Keydex itself so that the last "real" app is remembered.
@MainActor
@Observable
public final class WorkspaceActiveAppTracker: ActiveAppProviding {
    public private(set) var activeApp: AppInfo?

    @ObservationIgnored private let ownBundleIdentifier: String?
    @ObservationIgnored private let notificationCenter: NotificationCenter
    @ObservationIgnored private var activationObserver: NSObjectProtocol?

    public init(
        workspace: NSWorkspace = .shared,
        ownBundleIdentifier: String? = Bundle.main.bundleIdentifier
    ) {
        self.ownBundleIdentifier = ownBundleIdentifier
        self.notificationCenter = workspace.notificationCenter
        record(workspace.frontmostApplication.map(AppInfo.init))
        activationObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: workspace,
            queue: .main
        ) { [weak self] notification in
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            let appInfo = app.map(AppInfo.init)
            MainActor.assumeIsolated { self?.record(appInfo) }
        }
    }

    isolated deinit {
        if let activationObserver {
            notificationCenter.removeObserver(activationObserver)
        }
    }

    private func record(_ app: AppInfo?) {
        guard let app, app.bundleIdentifier != ownBundleIdentifier else { return }
        activeApp = app
    }
}
