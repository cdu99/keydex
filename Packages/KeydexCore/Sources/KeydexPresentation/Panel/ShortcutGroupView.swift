import KeydexDomain
import SwiftUI

/// How rows react to the user, in the sticky panel only (the glance is not interactive).
struct RowInteraction {
    let selection: Shortcut.ID?
    let select: (Shortcut) -> Void
    let perform: (Shortcut) -> Void
}

/// One menu of the app (title + its shortcuts), or the part of it shown in one column.
struct ShortcutBlockView: View {
    let block: PanelLayout.Block
    let width: CGFloat
    let interaction: RowInteraction?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .font(.system(size: 11, weight: .semibold))
                .frame(height: PanelMetrics.groupTitleHeight, alignment: .topLeading)
            ForEach(block.shortcuts) { shortcut in
                row(for: shortcut)
                    .frame(height: PanelMetrics.rowHeight)
                    .id(shortcut.id)
            }
        }
        .frame(width: width, alignment: .leading)
    }

    @ViewBuilder
    private func row(for shortcut: Shortcut) -> some View {
        if let interaction {
            ShortcutRowView(shortcut: shortcut, isSelected: interaction.selection == shortcut.id)
                .contentShape(Rectangle())
                .onTapGesture { interaction.perform(shortcut) }
                .help(shortcut.isPerformable ? "" : "Raccourci documenté : à faire au clavier, Keydex ne peut pas l'exécuter.")
                .onHover { hovering in if hovering { interaction.select(shortcut) } }
        } else {
            ShortcutRowView(shortcut: shortcut, isSelected: false)
        }
    }

    /// Sheet groups are marked (icon, tint): their shortcuts are in no menu.
    @ViewBuilder
    private var header: some View {
        switch block.kind {
        case .menu:
            title.foregroundStyle(.secondary)
        case .sheet:
            HStack(spacing: 4) {
                Image(systemName: "doc.text")
                title
            }
            .foregroundStyle(.tint)
            .help("Raccourcis documentés dans une fiche : ils ne figurent dans aucun menu.")
        }
    }

    private var title: Text {
        let menu = Text(block.title.uppercased())
        guard block.isContinuation else { return menu }
        return Text("\(menu) \(Text("(suite)").foregroundStyle(.tertiary))")
    }
}

/// An action and its keys, aligned like in a macOS menu. Selected like a menu item.
struct ShortcutRowView: View {
    let shortcut: Shortcut
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            title
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 4)
            KeyComboView(keyCombo: shortcut.keyCombo)
        }
        .font(.system(size: 12.5))
        .opacity(shortcut.isEnabled || isSelected ? 1 : 0.4)
        .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
        .background {
            if isSelected {
                // Grey for documented shortcuts: they can be read, not run.
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(shortcut.isPerformable ? Color.accentColor : Color.gray)
                    .padding(.horizontal, -5)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var title: Text {
        let submenus = shortcut.context
        guard !submenus.isEmpty else { return Text(shortcut.title) }
        let prefix = Text((submenus + [""]).joined(separator: " › ")).foregroundStyle(isSelected ? .white.opacity(0.75) : .secondary)
        return Text("\(prefix)\(shortcut.title)")
    }
}

/// Modifiers right-aligned, then the key in its own column, as macOS menus do.
struct KeyComboView: View {
    let keyCombo: KeyCombo

    var body: some View {
        HStack(spacing: 1) {
            Text(keyCombo.modifiers.symbols.joined())
                .opacity(0.65)
            Text(keyCombo.key.symbol)
                .frame(minWidth: 14, alignment: .leading)
        }
        .font(.system(size: 12.5, weight: .medium))
        .fixedSize()
    }
}
