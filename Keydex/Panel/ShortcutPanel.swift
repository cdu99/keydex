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

    /// Only the sticky panel takes the keyboard (to type a search); the glance never does.
    /// Even then Keydex is not activated: the user's app stays active, with its menu bar.
    var acceptsKeyboard = false

    override var canBecomeKey: Bool { acceptsKeyboard }
    override var canBecomeMain: Bool { false }
}
