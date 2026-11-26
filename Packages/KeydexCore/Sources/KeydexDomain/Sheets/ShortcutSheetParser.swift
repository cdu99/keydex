import Foundation

/// Reads a sheet written in Markdown, so shared sheets also read well on GitHub:
///
///     # zsh
///     apps: Ghostty, Terminal, iTerm2
///     command: ./zsh.sh        (optional: its output is a sheet completing this one)
///
///     Free text is allowed and ignored.
///
///     ## Words
///     - `⌃W` Delete the previous word
///     - `⌥D` Delete the next word
///
/// Entries are list items (keys in backticks, or separated from the title by two spaces)
/// or table rows (`| ⌃W | Delete the previous word |`). Entries whose keys cannot be read
/// are reported as issues, with their line number.
public enum ShortcutSheetParser {
    public struct Issue: Equatable, Sendable {
        public let line: Int
        public let message: String
    }

    public struct Result: Equatable, Sendable {
        public let sheet: ShortcutSheet
        public let issues: [Issue]
    }

    public static func parse(_ text: String, id: String) -> Result {
        var builder = SheetBuilder(id: id)
        for (index, rawLine) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            builder.read(String(rawLine).trimmingCharacters(in: .whitespaces), lineNumber: index + 1)
        }
        return builder.result
    }
}

private struct SheetBuilder {
    let id: String
    private var title: String?
    private var apps: [String] = []
    private var command: String?
    private var sections: [ShortcutSheet.Section] = []
    private var currentTitle: String?
    private var currentEntries: [ShortcutSheet.Entry] = []
    private var issues: [ShortcutSheetParser.Issue] = []

    init(id: String) {
        self.id = id
    }

    var result: ShortcutSheetParser.Result {
        var builder = self
        builder.closeSection()
        let sheet = ShortcutSheet(id: id, title: title ?? id, apps: apps, command: command, sections: builder.sections)
        return ShortcutSheetParser.Result(sheet: sheet, issues: issues)
    }

    mutating func read(_ line: String, lineNumber: Int) {
        if line.hasPrefix("## ") {
            closeSection()
            currentTitle = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        } else if line.hasPrefix("# ") {
            if title == nil { title = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces) }
        } else if let value = Self.value(of: "apps", in: line), isInHeader {
            apps = value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        } else if let value = Self.value(of: "command", in: line), isInHeader {
            command = value.trimmingCharacters(in: CharacterSet(charactersIn: "`")).nilIfEmpty
        } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
            readEntry(Self.listEntry(String(line.dropFirst(2))), line: line, lineNumber: lineNumber)
        } else if line.hasPrefix("|") {
            guard let cells = Self.tableEntry(line) else { return } // Header or separator row.
            readEntry(cells, line: line, lineNumber: lineNumber)
        }
        // Anything else is free text.
    }

    /// Metadata (apps, command) is only read before the first section and entry.
    private var isInHeader: Bool {
        sections.isEmpty && currentTitle == nil && currentEntries.isEmpty
    }

    private mutating func readEntry(_ parts: (keys: String, title: String)?, line: String, lineNumber: Int) {
        guard let parts, !parts.title.isEmpty else {
            issues.append(.init(line: lineNumber, message: "Entrée illisible : « \(line) »"))
            return
        }
        guard let keyCombo = KeyComboParser.parse(parts.keys) else {
            issues.append(.init(line: lineNumber, message: "Touches non reconnues : « \(parts.keys) »"))
            return
        }
        currentEntries.append(.init(keyCombo: keyCombo, title: parts.title))
    }

    private mutating func closeSection() {
        if !currentEntries.isEmpty || currentTitle != nil {
            sections.append(.init(title: currentTitle, entries: currentEntries))
        }
        currentEntries = []
        currentTitle = nil
    }

    // MARK: Line formats

    /// `apps: A, B` (case-insensitive key).
    private static func value(of key: String, in line: String) -> String? {
        guard let colon = line.firstIndex(of: ":"),
              line[..<colon].trimmingCharacters(in: .whitespaces).lowercased() == key else { return nil }
        return String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
    }

    /// "`⌃W` Title", "`⌃W` — Title", or "⌃W  Title" (two spaces or a tab).
    private static func listEntry(_ text: String) -> (keys: String, title: String)? {
        if text.hasPrefix("`"), let closing = text.dropFirst().firstIndex(of: "`") {
            let keys = String(text[text.index(after: text.startIndex)..<closing])
            let rest = text[text.index(after: closing)...]
            return (keys, Self.trimSeparators(String(rest)))
        }
        for separator in ["\t", "  "] {
            if let range = text.range(of: separator) {
                return (String(text[..<range.lowerBound]), Self.trimSeparators(String(text[range.upperBound...])))
            }
        }
        return nil
    }

    /// `| keys | title |`; header ("Keys", "Touches") and separator (`|---|`) rows give nil.
    private static func tableEntry(_ line: String) -> (keys: String, title: String)? {
        let cells = line.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        guard cells.count >= 2 else { return nil }
        let keys = cells[0].replacingOccurrences(of: "`", with: "")
        let isSeparator = keys.allSatisfy { "-: ".contains($0) }
        let isHeader = ["keys", "touches", "raccourci", "shortcut"].contains(keys.lowercased())
        guard !isSeparator, !isHeader else { return nil }
        return (keys, cells[1])
    }

    private static func trimSeparators(_ text: String) -> String {
        text.trimmingCharacters(in: CharacterSet(charactersIn: " \t—–-:"))
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
