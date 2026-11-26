import SwiftUI

/// Search field of the sticky panel. Arrow keys, Return and Escape drive the results
/// while the text keeps the focus, so the user never leaves the keyboard.
struct SearchField: View {
    @Bindable var viewModel: ShortcutPanelViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Action ou touches (ex. copier, ⌘⇧F)", text: $viewModel.query)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isFocused)
                .onKeyPress(.upArrow) { viewModel.moveSelection(.previous); return .handled }
                .onKeyPress(.downArrow) { viewModel.moveSelection(.next); return .handled }
                .onKeyPress(.return) { viewModel.performSelection(); return .handled }
                .onKeyPress(.escape) { viewModel.close(); return .handled }
                .onExitCommand { viewModel.close() }
        }
        .padding(.horizontal, 10)
        .frame(width: 300, height: 30)
        .glassEffect(.regular, in: .capsule)
        .onChange(of: viewModel.searchSession, initial: true) { isFocused = true }
    }
}
