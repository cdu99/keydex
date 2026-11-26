import KeydexDomain

/// Shortcuts read from the menu bar of a running app.
public struct AXMenuShortcutSource: ShortcutSource {
    private let reader = AXMenuBarReader()

    public init() {}

    public func catalog(for app: AppInfo) throws(ShortcutSourceError) -> ShortcutCatalog {
        let menuBar = try reader.readMenuBar(ofProcess: app.processID)
        return ShortcutCatalog(app: app, groups: MenuShortcutMapper.groups(fromMenuBar: menuBar))
    }
}
