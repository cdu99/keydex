import AppKit
import KeydexDomain
import SwiftUI

/// Step 1 developer view: the raw list of shortcuts read from the last active app.
/// It will be replaced by the floating panel in step 2.
struct ShortcutListView: View {
    let viewModel: ShortcutListViewModel

    var body: some View {
        content
            .frame(minWidth: 420, minHeight: 300)
            .toolbar {
                ToolbarItemGroup {
                    Button("Copier le diagnostic", systemImage: "stethoscope") {
                        Task { await copyDiagnostics() }
                    }
                    Button("Recharger", systemImage: "arrow.clockwise") {
                        Task { await viewModel.reload() }
                    }
                    .keyboardShortcut("r")
                }
            }
            .task(id: viewModel.activeApp) { await viewModel.reload() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView("Aucune app active", systemImage: "app.dashed")
        case .permissionRequired:
            ContentUnavailableView(
                "Accès Accessibilité requis",
                systemImage: "lock.shield",
                description: Text("Autorise Keydex dans Réglages Système › Confidentialité et sécurité › Accessibilité.")
            )
        case let .loading(app):
            ProgressView("Lecture des menus de \(app.name)…")
        case let .failed(app, message):
            ContentUnavailableView(app.name, systemImage: "exclamationmark.triangle", description: Text(message))
        case let .loaded(catalog, duration):
            loaded(catalog, duration: duration)
        }
    }

    private func loaded(_ catalog: ShortcutCatalog, duration: Duration) -> some View {
        List {
            Section {
                ForEach(catalog.groups) { group in
                    Section(group.title) {
                        ForEach(group.shortcuts) { ShortcutRow(shortcut: $0) }
                    }
                }
            } header: {
                header(for: catalog, duration: duration)
            }
        }
    }

    private func header(for catalog: ShortcutCatalog, duration: Duration) -> some View {
        HStack(spacing: 10) {
            AppIcon(app: catalog.app)
            VStack(alignment: .leading) {
                Text(catalog.app.name).font(.headline)
                Text("\(catalog.shortcutCount) raccourcis · lus en \(duration.formatted(.units(allowed: [.milliseconds])))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func copyDiagnostics() async {
        guard let report = await viewModel.diagnostics() else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
    }
}

private struct ShortcutRow: View {
    let shortcut: Shortcut

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(shortcut.title)
                if !shortcut.menuPath.submenuTitles.isEmpty {
                    Text(shortcut.menuPath.submenuTitles.joined(separator: " › "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(shortcut.keyCombo.displayString)
                .font(.system(.body, design: .rounded).monospaced())
        }
        .foregroundStyle(shortcut.isEnabled ? .primary : .tertiary)
    }
}
