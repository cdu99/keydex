import KeydexDomain
import Observation

/// The gesture delays chosen by the user, shared by the settings screen (which edits them)
/// and the gesture (which follows them live). Every change is saved.
@MainActor
@Observable
public final class GestureTimingPreference {
    public var timing: GestureTiming {
        didSet {
            let clamped = timing.clamped()
            if clamped != timing { timing = clamped; return }
            store.save(timing)
        }
    }

    @ObservationIgnored private let store: any GestureTimingStoring

    public init(store: any GestureTimingStoring) {
        self.store = store
        timing = store.load()
    }

    public func resetToStandard() {
        timing = .standard
    }
}
