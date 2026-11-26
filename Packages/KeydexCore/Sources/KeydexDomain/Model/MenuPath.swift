/// Location of an item in an app's menu bar, from the top-level menu down to the item.
///
/// Each component keeps both its position and its title, so the item can be found again
/// to trigger it, and a moved or renamed item is detected instead of pressing the wrong one.
public struct MenuPath: Hashable, Sendable {
    public struct Component: Hashable, Sendable {
        public let index: Int
        public let title: String

        public init(index: Int, title: String) {
            self.index = index
            self.title = title
        }
    }

    public let components: [Component]

    public init(_ components: [Component]) {
        self.components = components
    }

    public func appending(index: Int, title: String) -> MenuPath {
        MenuPath(components + [Component(index: index, title: title)])
    }

    /// Titles of the submenus between the top-level menu and the item itself.
    public var submenuTitles: [String] {
        guard components.count > 2 else { return [] }
        return components.dropFirst().dropLast().map(\.title)
    }
}
