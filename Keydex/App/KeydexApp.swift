import SwiftUI

@main
struct KeydexApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        MenuBarExtra("Keydex", systemImage: "command") {
            StatusMenu(activeAppProvider: container.activeAppProvider, permission: container.permission)
        }

        Window("Raccourcis", id: WindowID.shortcutList) {
            ShortcutListView(viewModel: container.shortcutList)
        }
        .defaultLaunchBehavior(.suppressed)
        .defaultSize(width: 520, height: 640)
    }
}

enum WindowID {
    static let shortcutList = "shortcut-list"
}
