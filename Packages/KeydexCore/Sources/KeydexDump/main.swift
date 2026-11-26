import AppKit
import KeydexDomain
import KeydexInfrastructure

/// Usage: keydex-dump <app name or bundle id> [--raw] [--runs N] [--pause MS]
/// Prints the shortcuts Keydex reads from a running app, and how long the read takes.

let arguments = CommandLine.arguments.dropFirst()
guard let query = arguments.first(where: { !$0.hasPrefix("--") }) else {
    print("usage: keydex-dump <app name or bundle id> [--raw] [--runs N] [--pause MS]")
    exit(2)
}
let runs = arguments.firstIndex(of: "--runs").flatMap { Int(arguments[$0 + 1]) } ?? 1
/// Pause between runs, to observe caching effects on the app's side.
let pause = arguments.firstIndex(of: "--pause").flatMap { Int(arguments[$0 + 1]) } ?? 0

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

let source = AXMenuShortcutSource()
let clock = ContinuousClock()
var catalog: ShortcutCatalog?
for run in 1...runs {
    if run > 1, pause > 0 { try await Task.sleep(for: .milliseconds(pause)) }
    let start = clock.now
    do {
        catalog = try source.catalog(for: app) // Measured synchronously, as the store reads it.
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
