/// Loads the shortcuts of an app without blocking the caller's actor.
public struct LoadShortcutCatalog: Sendable {
    private let source: any ShortcutSource

    public init(source: any ShortcutSource) {
        self.source = source
    }

    @concurrent
    public func callAsFunction(for app: AppInfo) async throws(ShortcutSourceError) -> ShortcutCatalog {
        try source.catalog(for: app)
    }
}
