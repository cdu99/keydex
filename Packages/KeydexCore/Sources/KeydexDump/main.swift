import AppKit
import KeydexDomain
import KeydexInfrastructure

/// Usage: keydex-dump <app name or bundle id> [--raw] [--runs N]
/// Prints the shortcuts Keydex reads from a running app, and how long the read takes.

let arguments = CommandLine.arguments.dropFirst()
guard let query = arguments.first(where: { !$0.hasPrefix("--") }) else {
    print("usage: keydex-dump <app name or bundle id> [--raw] [--runs N]")
    exit(2)
}
let runs = arguments.firstIndex(of: "--runs").flatMap { Int(arguments[$0 + 1]) } ?? 1

let lowercasedQuery = query.lowercased()
guard let running = NSWorkspace.shared.runningApplications.first(where: {
    $0.bundleIdentifier?.lowercased() == lowercasedQuery || $0.localizedName?.lowercased() == lowercasedQuery
}) else {
    print("No running app matches '\(query)'.")
    exit(1)
}
let app = AppInfo(
    processID: running.processIdentifier,
    bundleIdentifier: running.bundleIdentifier,
    name: running.localizedName ?? query
)

if arguments.contains("--raw") {
    print(await MenuBarDiagnostics().report(for: app))
    exit(0)
}

let load = LoadShortcutCatalog(source: AXMenuShortcutSource())
let clock = ContinuousClock()
var catalog: ShortcutCatalog?
for run in 1...runs {
    let start = clock.now
    do {
        catalog = try await load(for: app)
    } catch {
        print("Error: \(error)")
        exit(1)
    }
    print("run \(run): \((clock.now - start).formatted(.units(allowed: [.milliseconds])))")
}
guard let catalog else { exit(1) }

print("\(app.name) — \(catalog.shortcutCount) shortcuts in \(catalog.groups.count) menus")
for group in catalog.groups {
    print("\n[\(group.title)]")
    for shortcut in group.shortcuts {
        let submenu = shortcut.menuPath.submenuTitles.joined(separator: " › ")
        let label = submenu.isEmpty ? shortcut.title : "\(submenu) › \(shortcut.title)"
        let disabled = shortcut.isEnabled ? "" : "  (grisé)"
        print("  \(shortcut.keyCombo.displayString.padding(toLength: 8, withPad: " ", startingAt: 0)) \(label)\(disabled)")
    }
}
