import Foundation

/// A keyboard or pointer event, reduced to what the ⌘ gesture needs.
/// `time` is in seconds on a monotonic clock (e.g. `NSEvent.timestamp`).
public enum InputEvent: Equatable, Sendable {
    /// The set of held modifier keys changed.
    case modifiersChanged(ModifierSet, time: TimeInterval)
    /// A non-modifier key was pressed.
    case keyDown(time: TimeInterval)
    /// A click or a scroll.
    case pointerDown(time: TimeInterval)
}
