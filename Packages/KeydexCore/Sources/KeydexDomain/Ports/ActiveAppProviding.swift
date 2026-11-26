/// Knows which application the user is currently working in.
@MainActor
public protocol ActiveAppProviding: AnyObject {
    /// The application the user is working in. Never Keydex itself:
    /// interacting with Keydex must not change the app whose shortcuts are shown.
    var activeApp: AppInfo? { get }
}
