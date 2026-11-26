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

    /// Values the user may choose. Below these, regular shortcuts would trigger the panel;
    /// above, the gestures would feel sluggish.
    public static let glanceDelayRange: ClosedRange<TimeInterval> = 0.2...1.5
    public static let doubleTapIntervalRange: ClosedRange<TimeInterval> = 0.15...0.5

    /// The same timing with user-adjustable delays brought back within their ranges
    /// (settings may come from an older version or be edited by hand).
    public func clamped() -> GestureTiming {
        GestureTiming(
            glanceDelay: glanceDelay.clamped(to: Self.glanceDelayRange),
            doubleTapInterval: doubleTapInterval.clamped(to: Self.doubleTapIntervalRange),
            stickyHoldDelay: stickyHoldDelay
        )
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
