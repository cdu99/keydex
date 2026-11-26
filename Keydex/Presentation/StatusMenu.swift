import AppKit
import KeydexDomain
import SwiftUI

/// Content of the menu bar item.
struct StatusMenu: View {
    let activeAppProvider: any ActiveAppProviding
    let permission: any AccessibilityPermissionProviding
    let showPanel: () -> Void

    var body: some View {
        if permission.isGranted {
            Button(showShortcutsTitle, action: showPanel)
                .disabled(activeAppProvider.activeApp == nil)
        } else {
            Text("Keydex a besoin de l'accès Accessibilité")
            Button("Autoriser l'accès…") {
                permission.requestAccess()
                permission.openSystemSettings()
            }
        }
        Divider()
        Button("Quitter Keydex") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    private var showShortcutsTitle: String {
        activeAppProvider.activeApp.map { "Afficher les raccourcis de \($0.name)" } ?? "Aucune app active"
    }
}
