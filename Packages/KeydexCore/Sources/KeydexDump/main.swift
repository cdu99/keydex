import AppKit
import KeydexDomain
import KeydexInfrastructure

/// Usage: keydex-dump <app name or bundle id> [--raw] [--runs N] [--pause MS] [--perform TITLE]
///        keydex-dump --check-sheet <file.md>...
/// Prints the shortcuts Keydex reads from a running app, and how long the read takes;
/// or checks shortcut sheets and prints what Keydex understands of them.

let arguments = CommandLine.arguments.dropFirst()

if arguments.first == "--check-sheet" {
    var hasIssues = false
    for path in arguments.dropFirst() {
        let url = URL(fileURLWithPath: path)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            print("\(path): cannot read the file")
            hasIssues = true
            continue
        }
        let result = ShortcutSheetParser.parse(text, id: url.deletingPathExtension().lastPathComponent)
        let sheet = result.sheet
        let apps = sheet.apps.isEmpty ? "every app" : sheet.apps.joined(separator: ", ")
        print("\(path): \(sheet.title) — for \(apps)")
        for section in sheet.sections {
            print("  [\(section.title ?? sheet.title)]")
            for entry in section.entries {
                print("    \(entry.keyCombo.displayString.padding(toLength: 8, withPad: " ", startingAt: 0)) \(entry.title)")
            }
        }
        for issue in result.issues {
            print("  ⚠️ line \(issue.line): \(issue.message)")
        }
        hasIssues = hasIssues || !result.issues.isEmpty
    }
    exit(hasIssues ? 1 : 0)
}
guard let query = arguments.first(where: { !$0.hasPrefix("--") }) else {
    print("usage: keydex-dump <app name or bundle id> [--raw] [--runs N] [--pause MS] [--perform TITLE]\n       keydex-dump --check-sheet <file.md>...")
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

/// Triggers the first shortcut with this exact title, to check AXPress on a real app.
if let index = arguments.firstIndex(of: "--perform") {
    let title = arguments[arguments.index(after: index)]
    guard let shortcut = catalog.groups.flatMap(\.shortcuts).first(where: { $0.title == title }) else {
        print("No shortcut titled '\(title)'.")
        exit(1)
    }
    do {
        try AXMenuActionPerformer().perform(shortcut, in: app)
        print("Performed '\(title)' (\(shortcut.keyCombo.displayString)).")
    } catch {
        print("Error: \(error)")
        exit(1)
    }
    exit(0)
}

print("\(app.name) — \(catalog.shortcutCount) shortcuts in \(catalog.groups.count) menus")
for group in catalog.groups {
    print("\n[\(group.title)]")
    for shortcut in group.shortcuts {
        let submenu = shortcut.context.joined(separator: " › ")
        let label = submenu.isEmpty ? shortcut.title : "\(submenu) › \(shortcut.title)"
        let disabled = shortcut.isEnabled ? "" : "  (grisé)"
        print("  \(shortcut.keyCombo.displayString.padding(toLength: 8, withPad: " ", startingAt: 0)) \(label)\(disabled)")
    }
}
