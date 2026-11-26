import AppKit
import KeydexPresentation
import SwiftUI

/// Shows and hides the shortcut panel: window sizing, placement and dismissal.
/// What the panel displays is decided by `ShortcutPanelViewModel`.
@MainActor
final class ShortcutPanelController {
    private let viewModel: ShortcutPanelViewModel
    private let panel = ShortcutPanel()
    private var presentation: Task<Void, Never>?
    private var outsideClickMonitor: Any?

    /// Share of the screen the panel may use, so it never covers it entirely.
    private static let screenFraction = CGSize(width: 0.92, height: 0.86)

    init(viewModel: ShortcutPanelViewModel) {
        self.viewModel = viewModel
        let hostingView = NSHostingView(rootView: ShortcutPanelView(viewModel: viewModel) { [weak self] in
            self?.dismiss()
        })
        hostingView.sizingOptions = [] // The controller sizes the window itself.
        panel.contentView = hostingView
    }

    /// Mode of the panel being shown (or loading), `nil` when hidden.
    private(set) var presentedMode: ShortcutPanelViewModel.Mode?

    func present(mode: ShortcutPanelViewModel.Mode) {
        presentation?.cancel()
        presentedMode = mode
        let screen = Self.screenUnderMouse()
        presentation = Task {
            await viewModel.prepare(mode: mode, availableSize: Self.availableSize(on: screen))
            guard !Task.isCancelled else { return }
            show(on: screen)
        }
    }

    func dismiss() {
        presentation?.cancel()
        presentation = nil
        presentedMode = nil
        panel.orderOut(nil)
        stopMonitoringOutsideClicks()
    }

    // MARK: Window

    private func show(on screen: NSScreen) {
        let size = viewModel.preferredSize
        let visible = screen.visibleFrame
        let origin = CGPoint(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2 + visible.height * 0.04 // Slightly above center.
        )
        panel.setFrame(CGRect(origin: origin, size: size).integral, display: true)
        panel.orderFrontRegardless()
        startMonitoringOutsideClicks()
    }

    private static func screenUnderMouse() -> NSScreen {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main ?? NSScreen.screens[0]
    }

    private static func availableSize(on screen: NSScreen) -> CGSize {
        CGSize(
            width: screen.visibleFrame.width * screenFraction.width,
            height: screen.visibleFrame.height * screenFraction.height
        )
    }

    // MARK: Dismissal

    /// A click in another app closes the panel. Clicks inside the panel are local
    /// events, which global monitors do not receive.
    private func startMonitoringOutsideClicks() {
        guard outsideClickMonitor == nil else { return }
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            MainActor.assumeIsolated { self?.dismiss() }
        }
    }

    private func stopMonitoringOutsideClicks() {
        if let outsideClickMonitor {
            NSEvent.removeMonitor(outsideClickMonitor)
        }
        outsideClickMonitor = nil
    }
}
