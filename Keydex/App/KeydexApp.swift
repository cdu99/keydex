import SwiftUI

@main
struct KeydexApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        MenuBarExtra("Keydex", systemImage: "command") {
            StatusMenu(
                activeAppProvider: container.activeAppProvider,
                permission: container.permission,
                showPanel: { container.panelController.present(mode: .sticky) }
            )
        }
    }
}
