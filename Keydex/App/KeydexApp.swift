import KeydexPresentation
import SwiftUI

@main
struct KeydexApp: App {
    @State private var container = AppContainer()
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some Scene {
        MenuBarExtra("Keydex", systemImage: "command") {
            StatusMenu(
                activeAppProvider: container.activeAppProvider,
                permission: container.permission,
                showPanel: { container.panelController.present(mode: .sticky) }
            )
        }

        Window("Bienvenue", id: WindowID.welcome) {
            WelcomeView(permission: container.permission) { dismissWindow(id: WindowID.welcome) }
        }
        .windowResizability(.contentSize)
        // Shown at launch while the permission is missing (first launch, or revoked).
        .defaultLaunchBehavior(container.permission.isGranted ? .suppressed : .presented)

        Window("Réglages de Keydex", id: WindowID.settings) {
            SettingsView(viewModel: container.settings)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
    }
}

enum WindowID {
    static let settings = "settings"
    static let welcome = "welcome"
}
