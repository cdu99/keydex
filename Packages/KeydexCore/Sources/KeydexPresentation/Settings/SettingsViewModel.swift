import KeydexDomain
import Observation

/// State and actions of the settings window.
@MainActor
@Observable
public final class SettingsViewModel {
    public let gestureTiming: GestureTimingPreference
    public let sheets: any SheetLibraryProviding
    public private(set) var launchAtLoginError: String?

    @ObservationIgnored private let launchAtLogin: any LaunchAtLoginControlling
    @ObservationIgnored private let permission: any AccessibilityPermissionProviding

    public init(
        gestureTiming: GestureTimingPreference,
        launchAtLogin: any LaunchAtLoginControlling,
        permission: any AccessibilityPermissionProviding,
        sheets: any SheetLibraryProviding
    ) {
        self.gestureTiming = gestureTiming
        self.sheets = sheets
        self.launchAtLogin = launchAtLogin
        self.permission = permission
    }

    // MARK: Gesture delays

    public var glanceDelay: Double {
        get { gestureTiming.timing.glanceDelay }
        set { gestureTiming.timing.glanceDelay = newValue }
    }

    public var doubleTapInterval: Double {
        get { gestureTiming.timing.doubleTapInterval }
        set { gestureTiming.timing.doubleTapInterval = newValue }
    }

    public var isStandardTiming: Bool {
        gestureTiming.timing == .standard
    }

    public func resetTiming() {
        gestureTiming.resetToStandard()
    }

    // MARK: Launch at login

    public var launchAtLoginStatus: LaunchAtLoginStatus {
        launchAtLogin.status
    }

    /// On as soon as it is registered, even while waiting for the user's approval.
    public var launchesAtLogin: Bool {
        get { launchAtLogin.status != .disabled }
        set { setLaunchAtLogin(newValue) }
    }

    public func openLoginItemsSettings() {
        launchAtLogin.openLoginItemsSettings()
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try launchAtLogin.setEnabled(enabled)
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = enabled
                ? "macOS a refusé le lancement automatique. Installe Keydex dans le dossier Applications, puis réessaie."
                : "Impossible de retirer Keydex des éléments d'ouverture. Fais-le depuis les Réglages Système."
        }
    }

    // MARK: Accessibility

    public var isAccessibilityGranted: Bool {
        permission.isGranted
    }

    public func requestAccessibility() {
        permission.requestAccess()
        permission.openSystemSettings()
    }
}
