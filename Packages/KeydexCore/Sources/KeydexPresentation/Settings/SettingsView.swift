import KeydexDomain
import SwiftUI

/// The settings window.
public struct SettingsView: View {
    @Bindable private var viewModel: SettingsViewModel

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Form {
            gestureSection
            launchSection
            sheetsSection
            permissionSection
            privacySection
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Sections

    private var gestureSection: some View {
        Section {
            delaySlider(
                "Coup d'œil (⌘ maintenu)",
                value: $viewModel.glanceDelay,
                range: GestureTiming.glanceDelayRange,
                help: "Temps pendant lequel ⌘ doit être maintenu seul avant l'affichage. Plus court, c'est plus réactif, mais le panneau risque d'apparaître quand tu hésites sur un raccourci."
            )
            delaySlider(
                "Double appui (recherche)",
                value: $viewModel.doubleTapInterval,
                range: GestureTiming.doubleTapIntervalRange,
                help: "Temps maximal entre les deux appuis sur ⌘ pour ouvrir la recherche."
            )
        } header: {
            Text("Délais")
        } footer: {
            HStack {
                Spacer()
                Button("Valeurs par défaut", action: viewModel.resetTiming)
                    .disabled(viewModel.isStandardTiming)
            }
        }
    }

    private var launchSection: some View {
        Section("Général") {
            Toggle("Ouvrir Keydex à l'ouverture de session", isOn: $viewModel.launchesAtLogin)
            if viewModel.launchAtLoginStatus == .requiresApproval {
                HStack {
                    Text("macOS attend ton accord dans Éléments de connexion.")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Ouvrir", action: viewModel.openLoginItemsSettings)
                }
            }
            if let error = viewModel.launchAtLoginError {
                Text(error).foregroundStyle(.red)
            }
        }
    }

    private var sheetsSection: some View {
        Section {
            ForEach(viewModel.sheets.summaries) { SheetRow(summary: $0) }
            HStack {
                Text(viewModel.sheets.userFolder.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Spacer()
                Button("Ouvrir le dossier", action: viewModel.sheets.openUserFolder)
            }
        } header: {
            Text("Fiches de raccourcis")
        } footer: {
            Text("Les fiches ajoutent les raccourcis qui ne sont dans aucun menu. Dépose un fichier Markdown dans ce dossier : il est pris en compte dès l'enregistrement. Un fichier du même nom qu'une fiche intégrée la remplace.")
                .foregroundStyle(.secondary)
        }
    }

    private var permissionSection: some View {
        Section {
            HStack {
                Label("Accès Accessibilité", systemImage: "hand.raised")
                Spacer()
                if viewModel.isAccessibilityGranted {
                    Label("Autorisé", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button("Autoriser…", action: viewModel.requestAccessibility)
                }
            }
        } header: {
            Text("Autorisation")
        } footer: {
            Text("Nécessaire pour lire les menus de tes apps, détecter la touche ⌘ et déclencher une action depuis le panneau.")
                .foregroundStyle(.secondary)
        }
    }

    private var privacySection: some View {
        Section("Confidentialité") {
            Label {
                Text("Keydex lit les menus de tes apps uniquement sur ce Mac. Aucune donnée n'est collectée, enregistrée ni envoyée : l'app ne se connecte jamais à Internet.")
            } icon: {
                Image(systemName: "lock.shield")
            }
        }
    }

    // MARK: Components

    private func delaySlider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        help: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(Self.seconds(value.wrappedValue))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: 0.05) {
                Text(title)
            } minimumValueLabel: {
                Text(Self.seconds(range.lowerBound)).font(.caption)
            } maximumValueLabel: {
                Text(Self.seconds(range.upperBound)).font(.caption)
            }
            .labelsHidden()
            Text(help)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }

    private static func seconds(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(2)))) s"
    }
}
