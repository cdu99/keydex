import Foundation

/// Delays of the ⌘ gesture, in seconds.
public struct GestureTiming: Equatable, Sendable {
    /// How long ⌘ must be held alone before the glance panel appears.
    public var glanceDelay: TimeInterval
    /// Maximum length of the first tap of a double tap, and maximum gap before the second press.
    public var doubleTapInterval: TimeInterval
    /// How long the second press of a double tap must be held to open the sticky panel.
    public var stickyHoldDelay: TimeInterval

    public init(glanceDelay: TimeInterval, doubleTapInterval: TimeInterval, stickyHoldDelay: TimeInterval) {
        self.glanceDelay = glanceDelay
        self.doubleTapInterval = doubleTapInterval
        self.stickyHoldDelay = stickyHoldDelay
    }

    public static let standard = GestureTiming(glanceDelay: 0.5, doubleTapInterval: 0.3, stickyHoldDelay: 0.15)
}
