import CoreGraphics
import KeydexDomain

enum Fixtures {
    static let app = AppInfo(processID: 42, bundleIdentifier: "com.example.app", name: "Example")

    static func group(_ title: String, index: Int, rows: Int) -> ShortcutGroup {
        let shortcuts = (0..<rows).map { row in
            Shortcut(
                title: "\(title) \(row)",
                keyCombo: KeyCombo(modifiers: .command, key: .character("\(row % 10)")),
                isEnabled: true,
                menuPath: MenuPath([.init(index: index, title: title), .init(index: row, title: "\(title) \(row)")])
            )
        }
        return ShortcutGroup(title: title, menuIndex: index, shortcuts: shortcuts)
    }

    static let screen = CGSize(width: 1400, height: 800)
}

struct StubShortcutSource: ShortcutSource {
    let result: Result<[ShortcutGroup], ShortcutSourceError>

    func catalog(for app: AppInfo) throws(ShortcutSourceError) -> ShortcutCatalog {
        try ShortcutCatalog(app: app, groups: result.get())
    }
}

@MainActor
final class StubActiveApp: ActiveAppProviding {
    var activeApp: AppInfo?
    init(_ app: AppInfo?) { activeApp = app }
}

@MainActor
final class StubPermission: AccessibilityPermissionProviding {
    var isGranted: Bool
    private(set) var requestCount = 0
    private(set) var openedSettings = false

    init(granted: Bool) { isGranted = granted }
    func requestAccess() { requestCount += 1 }
    func openSystemSettings() { openedSettings = true }
}
