import KeydexDomain
import Testing

@Suite("Gesture timing")
struct GestureTimingTests {
    @Test("The standard timing is within the adjustable ranges")
    func standardIsValid() {
        #expect(GestureTiming.standard.clamped() == .standard)
    }

    @Test("Out-of-range delays are brought back within their ranges")
    func clamping() {
        let extreme = GestureTiming(glanceDelay: 0.01, doubleTapInterval: 9, stickyHoldDelay: 0.15)
        let clamped = extreme.clamped()
        #expect(clamped.glanceDelay == GestureTiming.glanceDelayRange.lowerBound)
        #expect(clamped.doubleTapInterval == GestureTiming.doubleTapIntervalRange.upperBound)
        #expect(clamped.stickyHoldDelay == 0.15)
    }
}
