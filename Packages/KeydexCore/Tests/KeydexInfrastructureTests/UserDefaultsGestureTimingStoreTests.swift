import Foundation
import KeydexDomain
import KeydexInfrastructure
import Testing

@Suite("Saving gesture delays")
struct UserDefaultsGestureTimingStoreTests {
    /// A throwaway defaults domain, so tests never touch the real preferences.
    private let defaults: UserDefaults = {
        let suite = "keydex.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }()

    @Test("Nothing saved yet gives the standard timing")
    func defaultsToStandard() {
        #expect(UserDefaultsGestureTimingStore(defaults: defaults).load() == .standard)
    }

    @Test("Saved delays are loaded back")
    func roundTrip() {
        let store = UserDefaultsGestureTimingStore(defaults: defaults)
        var timing = GestureTiming.standard
        timing.glanceDelay = 0.8
        timing.doubleTapInterval = 0.25
        store.save(timing)
        #expect(store.load() == timing)
    }

    @Test("Out-of-range saved values are clamped when loaded")
    func clampsOnLoad() {
        defaults.set(42.0, forKey: "gesture.glanceDelay")
        #expect(UserDefaultsGestureTimingStore(defaults: defaults).load().glanceDelay == GestureTiming.glanceDelayRange.upperBound)
    }
}
