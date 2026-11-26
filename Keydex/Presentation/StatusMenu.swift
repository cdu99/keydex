import AppKit
import KeydexDomain
import SwiftUI

/// Content of the menu bar item.
struct StatusMenu: View {
    let activeAppProvider: any ActiveAppProviding
    let permission: any AccessibilityPermissionProviding
    let showPanel: () -> Void

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if permission.isGranted {
            Button(showShortcutsTitle, action: showPanel)
                .disabled(activeAppProvider.activeApp == nil)
        } else {
            Text("Keydex a besoin de l'accès Accessibilité")
            Button("Autoriser l'accès…") { open(WindowID.welcome) }
        }
        Divider()
        Button("Guide de démarrage…") { open(WindowID.welcome) }
        Button("Réglages…") { open(WindowID.settings) }
            .keyboardShortcut(",")
        Divider()
        Button("Quitter Keydex") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    /// Keydex has no Dock icon: bring the window to the front explicitly.
    private func open(_ windowID: String) {
        openWindow(id: windowID)
        NSApp.activate()
    }

    private var showShortcutsTitle: String {
        activeAppProvider.activeApp.map { "Afficher les raccourcis de \($0.name)" } ?? "Aucune app active"
    }
}
