import KeydexDomain
import SwiftUI

/// Content of the floating shortcut panel.
public struct ShortcutPanelView: View {
    private let viewModel: ShortcutPanelViewModel
    private let onClose: () -> Void

    public init(viewModel: ShortcutPanelViewModel, onClose: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onClose = onClose
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: PanelMetrics.headerSpacing) {
            header
                .frame(height: PanelMetrics.headerHeight)
            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(PanelMetrics.padding)
        .frame(width: viewModel.preferredSize.width, height: viewModel.preferredSize.height)
        .panelBackground()
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            if let app = headerApp {
                AppIcon(app: app, size: PanelMetrics.headerHeight)
                VStack(alignment: .leading, spacing: 1) {
                    Text(app.name)
                        .font(.system(size: 15, weight: .semibold))
                    if case let .loaded(catalog, _) = viewModel.content {
                        Text("\(catalog.shortcutCount) raccourcis")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("Keydex").font(.system(size: 15, weight: .semibold))
            }
            Spacer()
            if viewModel.mode == .sticky {
                closeButton
            }
        }
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 26, height: 26)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .help("Fermer (Échap)")
        .accessibilityLabel("Fermer")
    }

    private var headerApp: AppInfo? {
        switch viewModel.content {
        case let .loaded(catalog, _): catalog.app
        case let .loading(app), let .noShortcuts(app), let .failed(app, _): app
        case .noActiveApp, .permissionRequired: nil
        }
    }

    // MARK: Content

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.content {
        case let .loaded(_, layout):
            if layout.needsScrolling {
                ScrollView { columns(layout) }
                    .scrollIndicators(.automatic)
            } else {
                columns(layout)
            }
        case .loading:
            ProgressView().controlSize(.small)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .noActiveApp:
            message("Aucune app active", systemImage: "app.dashed")
        case let .noShortcuts(app):
            message("Aucun raccourci dans les menus de \(app.name)", systemImage: "keyboard")
        case let .failed(_, text):
            message(text, systemImage: "exclamationmark.triangle")
        case .permissionRequired:
            permissionMessage
        }
    }

    private func columns(_ layout: PanelLayout) -> some View {
        HStack(alignment: .top, spacing: PanelMetrics.columnSpacing) {
            ForEach(layout.columns.indices, id: \.self) { index in
                VStack(alignment: .leading, spacing: PanelMetrics.groupSpacing) {
                    ForEach(layout.columns[index]) { ShortcutBlockView(block: $0, width: layout.columnWidth) }
                }
            }
        }
    }

    private func message(_ text: String, systemImage: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 26))
                .foregroundStyle(.secondary)
            Text(text)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var permissionMessage: some View {
        VStack(spacing: 10) {
            Text("Keydex a besoin de l'accès Accessibilité pour lire les menus de tes apps.")
                .multilineTextAlignment(.center)
            Button("Ouvrir les Réglages") { viewModel.requestPermission() }
                .buttonStyle(.glassProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
