import Foundation
import KeydexDomain

/// Gesture delays saved in the app's user defaults (local preferences file, never synced).
public struct UserDefaultsGestureTimingStore: GestureTimingStoring, @unchecked Sendable {
    // UserDefaults is documented as thread-safe.
    private let defaults: UserDefaults

    private enum Key {
        static let glanceDelay = "gesture.glanceDelay"
        static let doubleTapInterval = "gesture.doubleTapInterval"
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> GestureTiming {
        var timing = GestureTiming.standard
        if let glanceDelay = defaults.object(forKey: Key.glanceDelay) as? Double {
            timing.glanceDelay = glanceDelay
        }
        if let doubleTapInterval = defaults.object(forKey: Key.doubleTapInterval) as? Double {
            timing.doubleTapInterval = doubleTapInterval
        }
        return timing.clamped()
    }

    public func save(_ timing: GestureTiming) {
        let timing = timing.clamped()
        defaults.set(timing.glanceDelay, forKey: Key.glanceDelay)
        defaults.set(timing.doubleTapInterval, forKey: Key.doubleTapInterval)
    }
}
