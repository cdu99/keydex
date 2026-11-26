/// Status of the macOS Accessibility permission, which Keydex needs to read other apps' menus.
@MainActor
public protocol AccessibilityPermissionProviding: AnyObject {
    var isGranted: Bool { get }
    /// Asks macOS to register Keydex in the Accessibility list and show its permission prompt.
    func requestAccess()
    /// Opens System Settings at Privacy & Security › Accessibility.
    func openSystemSettings()
}
