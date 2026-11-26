/// All the shortcuts known for one app, grouped by menu in menu bar order.
public struct ShortcutCatalog: Hashable, Sendable {
    public let app: AppInfo
    public let groups: [ShortcutGroup]

    public init(app: AppInfo, groups: [ShortcutGroup]) {
        self.app = app
        self.groups = groups
    }

    public var shortcutCount: Int {
        groups.reduce(0) { $0 + $1.shortcuts.count }
    }

    public var isEmpty: Bool {
        shortcutCount == 0
    }
}
