/// Whether Keydex starts when the user logs in.
@MainActor
public protocol LaunchAtLoginControlling: AnyObject {
    var status: LaunchAtLoginStatus { get }
    func setEnabled(_ enabled: Bool) throws
    /// Opens System Settings › General › Login Items, where the user approves or removes it.
    func openLoginItemsSettings()
}

public enum LaunchAtLoginStatus: Equatable, Sendable {
    case enabled
    case disabled
    /// Registered, but the user must allow it in System Settings › Login Items.
    case requiresApproval
}
