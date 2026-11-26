import AppKit
import KeydexDomain
import SwiftUI

/// Content of the menu bar item.
struct StatusMenu: View {
    let activeAppProvider: any ActiveAppProviding

    var body: some View {
        Text(activeAppTitle)
        Divider()
        Button("Quitter Keydex") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    private var activeAppTitle: String {
        activeAppProvider.activeApp.map { "App active : \($0.name)" } ?? "Aucune app active"
    }
}
