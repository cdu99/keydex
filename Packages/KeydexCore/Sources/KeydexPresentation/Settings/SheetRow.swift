import KeydexDomain
import SwiftUI

/// One loaded sheet in the settings: what it covers, where it comes from, what it runs.
struct SheetRow: View {
    let summary: SheetSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Label(summary.title, systemImage: "doc.text")
                Spacer()
                Text(summary.isBundled ? "Intégrée" : "Perso")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(details)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let command = summary.command {
                // Commands run on the user's Mac: always show them.
                Label {
                    Text(command).font(.caption.monospaced())
                } icon: {
                    Image(systemName: "terminal")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .help("Commande exécutée pour générer une partie de la fiche, quand l'app concernée est au premier plan.")
            }
            if summary.issueCount > 0 {
                Label("\(summary.issueCount) ligne(s) illisible(s) ignorée(s)", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 2)
    }

    private var details: String {
        let apps = summary.apps.isEmpty ? "Toutes les apps (dans la recherche)" : summary.apps.joined(separator: ", ")
        guard summary.command == nil else { return apps }
        return "\(apps) · \(summary.shortcutCount) raccourci(s)"
    }
}
