import KeydexDomain
import SwiftUI

/// One menu of the app (title + its shortcuts), as a block of a panel column.
struct ShortcutGroupView: View {
    let group: ShortcutGroup
    let width: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(group.title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(height: PanelMetrics.groupTitleHeight, alignment: .topLeading)
            ForEach(group.shortcuts) { shortcut in
                ShortcutRowView(shortcut: shortcut)
                    .frame(height: PanelMetrics.rowHeight)
            }
        }
        .frame(width: width, alignment: .leading)
    }
}

/// An action and its keys, aligned like in a macOS menu.
struct ShortcutRowView: View {
    let shortcut: Shortcut

    var body: some View {
        HStack(spacing: 8) {
            title
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 4)
            KeyComboView(keyCombo: shortcut.keyCombo)
        }
        .font(.system(size: 12.5))
        .opacity(shortcut.isEnabled ? 1 : 0.4)
        .accessibilityElement(children: .combine)
    }

    private var title: Text {
        let submenus = shortcut.menuPath.submenuTitles
        guard !submenus.isEmpty else { return Text(shortcut.title) }
        let prefix = Text((submenus + [""]).joined(separator: " › ")).foregroundStyle(.secondary)
        return Text("\(prefix)\(shortcut.title)")
    }
}

/// Modifiers right-aligned, then the key in its own column, as macOS menus do.
struct KeyComboView: View {
    let keyCombo: KeyCombo

    var body: some View {
        HStack(spacing: 1) {
            Text(keyCombo.modifiers.symbols.joined())
                .foregroundStyle(.secondary)
            Text(keyCombo.key.symbol)
                .frame(minWidth: 14, alignment: .leading)
        }
        .font(.system(size: 12.5, weight: .medium))
        .fixedSize()
    }
}
