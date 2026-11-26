/// A running application whose shortcuts Keydex can show.
public struct AppInfo: Hashable, Sendable {
    public let processID: Int32
    public let bundleIdentifier: String?
    public let name: String

    public init(processID: Int32, bundleIdentifier: String?, name: String) {
        self.processID = processID
        self.bundleIdentifier = bundleIdentifier
        self.name = name
    }
}
