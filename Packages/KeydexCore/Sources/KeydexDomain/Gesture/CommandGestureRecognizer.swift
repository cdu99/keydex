import Foundation

/// What the gesture recognizer asks its driver to do.
public enum GestureEffect: Equatable, Sendable {
    /// Call `timerFired(id:)` after `delay` seconds (replacing any running timer).
    case startTimer(delay: TimeInterval, id: Int)
    case cancelTimer
    case showGlance
    case hideGlance
    case showSticky
}

/// Recognizes the ⌘ gestures, as a pure state machine (no clock, no AppKit), so every
/// sequence can be unit-tested:
/// - hold ⌘ alone for `glanceDelay` → show the glance; release → hide it;
/// - tap ⌘, then press it again within `doubleTapInterval` and hold `stickyHoldDelay` → sticky panel.
///
/// Anything else while ⌘ is down (a key, a click, another modifier) cancels the gesture until
/// every modifier is released: a regular shortcut such as ⌘C or ⌘Tab never shows the panel.
public struct CommandGestureRecognizer: Sendable {
    public enum State: Equatable, Sendable {
        case idle
        /// ⌘ is held alone, the timer is running.
        case pressed(at: TimeInterval, isSecondTap: Bool)
        /// ⌘ was tapped quickly and released: a second press may follow.
        case tapped(releasedAt: TimeInterval)
        case showingGlance
        /// The sticky panel was opened; waiting for ⌘ to be released.
        case holdingAfterSticky
        /// The user is doing something else; ignore everything until all modifiers are released.
        case interrupted
    }

    public private(set) var state: State = .idle
    public var timing: GestureTiming
    private var timerID = 0

    public init(timing: GestureTiming = .standard) {
        self.timing = timing
    }

    public mutating func handle(_ event: InputEvent) -> [GestureEffect] {
        switch event {
        case let .modifiersChanged(modifiers, time):
            modifiersChanged(to: modifiers, at: time)
        case .keyDown, .pointerDown:
            otherInput()
        }
    }

    public mutating func timerFired(id: Int) -> [GestureEffect] {
        guard id == timerID, case let .pressed(_, isSecondTap) = state else { return [] }
        if isSecondTap {
            state = .holdingAfterSticky
            return [.showSticky]
        }
        state = .showingGlance
        return [.showGlance]
    }

    // MARK: Transitions

    private mutating func modifiersChanged(to modifiers: ModifierSet, at time: TimeInterval) -> [GestureEffect] {
        let commandAlone = modifiers == .command
        let released = modifiers.isEmpty

        switch state {
        case .idle:
            if commandAlone {
                return press(at: time, isSecondTap: false)
            }
            if !released { state = .interrupted }
            return []

        case let .pressed(pressedAt, isSecondTap):
            if released {
                let wasQuickTap = !isSecondTap && time - pressedAt <= timing.doubleTapInterval
                state = wasQuickTap ? .tapped(releasedAt: time) : .idle
                return [.cancelTimer]
            }
            if !commandAlone {
                state = .interrupted
                return [.cancelTimer]
            }
            return []

        case let .tapped(releasedAt):
            if commandAlone {
                return press(at: time, isSecondTap: time - releasedAt <= timing.doubleTapInterval)
            }
            if !released { state = .interrupted }
            return []

        case .showingGlance:
            if released {
                state = .idle
                return [.hideGlance]
            }
            if !commandAlone {
                state = .interrupted
                return [.hideGlance]
            }
            return []

        case .holdingAfterSticky, .interrupted:
            if released { state = .idle }
            return []
        }
    }

    private mutating func otherInput() -> [GestureEffect] {
        switch state {
        case .pressed:
            state = .interrupted
            return [.cancelTimer]
        case .showingGlance:
            state = .interrupted
            return [.hideGlance]
        case .tapped:
            state = .idle
            return []
        case .idle, .holdingAfterSticky, .interrupted:
            return []
        }
    }

    private mutating func press(at time: TimeInterval, isSecondTap: Bool) -> [GestureEffect] {
        state = .pressed(at: time, isSecondTap: isSecondTap)
        timerID += 1
        let delay = isSecondTap ? timing.stickyHoldDelay : timing.glanceDelay
        return [.startTimer(delay: delay, id: timerID)]
    }
}
