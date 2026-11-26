import AppKit
import KeydexPresentation
import Observation
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
        resizeWhenContentChanges()
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

    /// Renders the active app's panel invisibly, so its first glance appears at once.
    ///
    /// Laying out and compositing a big panel takes ~100 ms the first time its content is
    /// drawn. Doing it right after the shortcuts are prefetched (fully transparent and
    /// click-through, for a fraction of a second) moves that cost out of the glance.
    func prerender() {
        guard presentedMode == nil else { return }
        let screen = Self.screenUnderMouse()
        Task {
            await viewModel.prepare(mode: .glance, availableSize: Self.availableSize(on: screen))
            guard presentedMode == nil else { return }
            place(on: screen)
            setInvisible(true)
            panel.orderFrontRegardless()
            panel.displayIfNeeded()
            try? await Task.sleep(for: Self.prerenderDuration)
            if presentedMode == nil {
                panel.orderOut(nil)
                viewModel.panelDidClose()
            }
            setInvisible(false)
        }
    }

    private static let prerenderDuration = Duration.milliseconds(250)

    private func setInvisible(_ invisible: Bool) {
        panel.alphaValue = invisible ? 0 : 1
        panel.ignoresMouseEvents = invisible
    }

    func dismiss() {
        presentation?.cancel()
        presentation = nil
        presentedMode = nil
        panel.orderOut(nil)
        stopMonitoringOutsideClicks()
        viewModel.panelDidClose()
    }

    // MARK: Window

    private func show(on screen: NSScreen) {
        place(on: screen)
        setInvisible(false) // A glance may start while the panel is being prerendered.
        panel.orderFrontRegardless()
        startMonitoringOutsideClicks()
    }

    private func place(on screen: NSScreen) {
        let size = viewModel.preferredSize
        let visible = screen.visibleFrame
        let origin = CGPoint(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2 + visible.height * 0.04 // Slightly above center.
        )
        panel.setFrame(CGRect(origin: origin, size: size).integral, display: true)
    }

    /// Cached content is shown first, then refreshed: follow size changes while visible.
    private func resizeWhenContentChanges() {
        withObservationTracking {
            _ = viewModel.preferredSize
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if panel.isVisible, let screen = panel.screen {
                    place(on: screen)
                }
                resizeWhenContentChanges()
            }
        }
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
