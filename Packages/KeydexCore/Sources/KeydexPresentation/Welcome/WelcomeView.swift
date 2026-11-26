import AppKit
import KeydexDomain
import SwiftUI

/// First-launch guide: what Keydex does, and why it needs the Accessibility permission.
/// The permission status updates live, so the user sees the moment it is granted.
public struct WelcomeView: View {
    private let permission: any AccessibilityPermissionProviding
    private let onDone: () -> Void

    public init(permission: any AccessibilityPermissionProviding, onDone: @escaping () -> Void) {
        self.permission = permission
        self.onDone = onDone
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            VStack(alignment: .leading, spacing: 14) {
                gesture(symbol: "command", title: "Maintiens ⌘", detail: "Les raccourcis de l'app que tu utilises s'affichent. Relâche pour les cacher.")
                gesture(symbol: "magnifyingglass", title: "Double appui sur ⌘, puis maintiens", detail: "Le panneau reste ouvert : tape pour chercher une action ou une touche, ↩ pour l'exécuter, Échap pour revenir.")
            }
            permissionCard
        }
        .padding(28)
        .frame(width: 500)
        .onAppear { NSApp.activate() } // No Dock icon: bring the window to the front.
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text("Bienvenue dans Keydex").font(.title2.bold())
                Text("Tes raccourcis clavier, au moment où tu en as besoin.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func gesture(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 34, height: 34)
                .glassEffect(.regular, in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if permission.isGranted {
                Label("C'est prêt ! Essaie : maintiens ⌘ dans n'importe quelle app.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
                HStack {
                    Text("Keydex vit dans la barre de menus (icône ⌘).")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Commencer", action: onDone)
                        .buttonStyle(.glassProminent)
                        .keyboardShortcut(.defaultAction)
                }
            } else {
                Label("Une autorisation est nécessaire", systemImage: "hand.raised.fill")
                    .font(.headline)
                Text("Pour lire les menus de tes apps et détecter la touche ⌘, macOS demande d'autoriser Keydex dans **Confidentialité et sécurité › Accessibilité**. Tout reste sur ton Mac : rien n'est collecté ni envoyé.")
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Text("Active Keydex dans la liste, puis reviens ici.")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Ouvrir les Réglages Système") {
                        permission.requestAccess()
                        permission.openSystemSettings()
                    }
                    .buttonStyle(.glassProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .animation(.default, value: permission.isGranted)
    }
}
