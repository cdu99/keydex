import KeydexPresentation
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

        Window("Réglages de Keydex", id: WindowID.settings) {
            SettingsView(viewModel: container.settings)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
    }
}

enum WindowID {
    static let settings = "settings"
}
