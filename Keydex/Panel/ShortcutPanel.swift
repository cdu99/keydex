import AppKit

/// Borderless floating panel that never activates Keydex, so the app the user works in
/// keeps its focus and its menu bar.
final class ShortcutPanel: NSPanel {
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        hidesOnDeactivate = false
        isMovable = false
        animationBehavior = .none // Must appear instantly.
        isReleasedWhenClosed = false
    }

    /// The glance never takes the keyboard (the search mode will, in a later step).
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
