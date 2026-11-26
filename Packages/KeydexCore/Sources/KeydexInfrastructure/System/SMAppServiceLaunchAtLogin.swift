import KeydexDomain
import Observation
import ServiceManagement

/// Launch at login through `SMAppService.mainApp` (no helper app needed on macOS 13+).
/// macOS registers the app where it currently is: install it in /Applications first.
@MainActor
@Observable
public final class SMAppServiceLaunchAtLogin: LaunchAtLoginControlling {
    public private(set) var status: LaunchAtLoginStatus

    private let service = SMAppService.mainApp

    public init() {
        status = Self.status(of: service)
    }

    public func setEnabled(_ enabled: Bool) throws {
        defer { status = Self.status(of: service) }
        if enabled {
            try service.register()
        } else {
            try service.unregister()
        }
    }

    public func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    private static func status(of service: SMAppService) -> LaunchAtLoginStatus {
        switch service.status {
        case .enabled: .enabled
        case .requiresApproval: .requiresApproval
        case .notRegistered, .notFound: .disabled
        @unknown default: .disabled
        }
    }
}
