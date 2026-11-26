import Foundation
import KeydexDomain
import Testing

/// Replays a timeline of input events against the recognizer, running its timer on a
/// simulated clock, and records what the user would see (show / hide effects).
private struct GestureTimeline {
    private var recognizer = CommandGestureRecognizer(timing: .standard)
    private var timer: (id: Int, fireAt: TimeInterval)?
    private var now: TimeInterval = 0
    private(set) var visible: [GestureEffect] = []

    var state: CommandGestureRecognizer.State { recognizer.state }

    mutating func modifiers(_ modifiers: ModifierSet, at time: TimeInterval) {
        advance(to: time)
        apply(recognizer.handle(.modifiersChanged(modifiers, time: time)))
    }

    mutating func command(at time: TimeInterval) { modifiers(.command, at: time) }
    mutating func release(at time: TimeInterval) { modifiers([], at: time) }

    mutating func key(at time: TimeInterval) {
        advance(to: time)
        apply(recognizer.handle(.keyDown(time: time)))
    }

    mutating func click(at time: TimeInterval) {
        advance(to: time)
        apply(recognizer.handle(.pointerDown(time: time)))
    }

    /// Lets time pass, firing the timer if it is due.
    mutating func advance(to time: TimeInterval) {
        if let timer, timer.fireAt <= time {
            now = timer.fireAt
            self.timer = nil
            apply(recognizer.timerFired(id: timer.id))
        }
        now = time
    }

    private mutating func apply(_ effects: [GestureEffect]) {
        for effect in effects {
            switch effect {
            case let .startTimer(delay, id): timer = (id, now + delay)
            case .cancelTimer: timer = nil
            case .showGlance, .hideGlance, .showSticky: visible.append(effect)
            }
        }
    }
}

@Suite("⌘ gesture recognition")
struct CommandGestureRecognizerTests {
    // MARK: Glance

    @Test("Holding ⌘ alone shows the glance, releasing hides it")
    func glance() {
        var timeline = GestureTimeline()
        timeline.command(at: 0)
        timeline.advance(to: 0.49)
        #expect(timeline.visible.isEmpty, "Nothing before the delay")
        timeline.advance(to: 0.5)
        #expect(timeline.visible == [.showGlance])
        timeline.release(at: 2)
        #expect(timeline.visible == [.showGlance, .hideGlance])
        #expect(timeline.state == .idle)
    }

    @Test("Releasing ⌘ before the delay shows nothing")
    func shortPress() {
        var timeline = GestureTimeline()
        timeline.command(at: 0)
        timeline.release(at: 0.4)
        timeline.advance(to: 5)
        #expect(timeline.visible.isEmpty)
    }

    // MARK: Regular shortcuts never trigger

    @Test("⌘C never shows the panel, even if ⌘ stays held afterwards")
    func commandC() {
        var timeline = GestureTimeline()
        timeline.command(at: 0)
        timeline.key(at: 0.1)
        timeline.advance(to: 3)
        timeline.release(at: 3)
        #expect(timeline.visible.isEmpty)
    }

    @Test("⌘Tab held to switch apps never shows the panel")
    func commandTab() {
        var timeline = GestureTimeline()
        timeline.command(at: 0)
        timeline.key(at: 0.05)
        timeline.key(at: 0.6)
        timeline.advance(to: 2)
        #expect(timeline.visible.isEmpty)
        timeline.release(at: 2.5)
        #expect(timeline.state == .idle)
    }

    @Test("A key typed late, while the glance is shown, hides it and lets the shortcut through")
    func lateKey() {
        var timeline = GestureTimeline()
        timeline.command(at: 0)
        timeline.advance(to: 1)
        timeline.key(at: 1.2)
        #expect(timeline.visible == [.showGlance, .hideGlance])
        timeline.advance(to: 5)
        timeline.release(at: 5)
        #expect(timeline.visible == [.showGlance, .hideGlance], "Not shown again while ⌘ is still held")
    }

    @Test("⌘-click and ⌘-scroll never show the panel")
    func commandClick() {
        var timeline = GestureTimeline()
        timeline.command(at: 0)
        timeline.click(at: 0.2)
        timeline.advance(to: 2)
        #expect(timeline.visible.isEmpty)
    }

    @Test("Another modifier with ⌘ (⇧⌘, ⌥⌘…) never shows the panel", arguments: [
        ModifierSet([.command, .shift]), [.command, .option], [.command, .control], [.command, .function],
    ])
    func otherModifierAdded(combo: ModifierSet) {
        var timeline = GestureTimeline()
        timeline.command(at: 0)
        timeline.modifiers(combo, at: 0.2)
        timeline.modifiers(.command, at: 0.3) // releasing the other modifier first
        timeline.advance(to: 3)
        #expect(timeline.visible.isEmpty)
    }

    @Test("⌘ pressed after another modifier (⇧ then ⌘) never shows the panel")
    func commandAfterOtherModifier() {
        var timeline = GestureTimeline()
        timeline.modifiers(.shift, at: 0)
        timeline.modifiers([.shift, .command], at: 0.1)
        timeline.modifiers(.command, at: 0.2)
        timeline.advance(to: 3)
        #expect(timeline.visible.isEmpty)
    }

    @Test("Adding a modifier while the glance is shown hides it")
    func modifierAddedDuringGlance() {
        var timeline = GestureTimeline()
        timeline.command(at: 0)
        timeline.advance(to: 1)
        timeline.modifiers([.command, .shift], at: 1.1)
        #expect(timeline.visible == [.showGlance, .hideGlance])
    }

    // MARK: Double tap

    @Test("Double tap then hold opens the sticky panel, which stays after release")
    func doubleTap() {
        var timeline = GestureTimeline()
        timeline.command(at: 0)
        timeline.release(at: 0.1)
        timeline.command(at: 0.25)
        timeline.advance(to: 0.45)
        #expect(timeline.visible == [.showSticky])
        timeline.release(at: 0.6)
        #expect(timeline.visible == [.showSticky], "Releasing does not hide the sticky panel")
        #expect(timeline.state == .idle)
    }

    @Test("Double tap released too early opens nothing")
    func doubleTapWithoutHold() {
        var timeline = GestureTimeline()
        timeline.command(at: 0)
        timeline.release(at: 0.1)
        timeline.command(at: 0.25)
        timeline.release(at: 0.3)
        timeline.advance(to: 3)
        #expect(timeline.visible.isEmpty)
    }

    @Test("A second press after the double-tap interval is a plain hold")
    func secondPressTooLate() {
        var timeline = GestureTimeline()
        timeline.command(at: 0)
        timeline.release(at: 0.1)
        timeline.command(at: 0.5)
        timeline.advance(to: 0.8)
        #expect(timeline.visible.isEmpty)
        timeline.advance(to: 1.0)
        #expect(timeline.visible == [.showGlance])
    }

    @Test("A first press held too long is not a tap")
    func firstPressTooLong() {
        var timeline = GestureTimeline()
        timeline.command(at: 0)
        timeline.release(at: 0.4)
        timeline.command(at: 0.5)
        timeline.advance(to: 0.7)
        #expect(timeline.visible.isEmpty)
    }

    @Test("Two ⌘ shortcuts in a row (⌘C, ⌘V) are not a double tap")
    func twoShortcutsInARow() {
        var timeline = GestureTimeline()
        timeline.command(at: 0)
        timeline.key(at: 0.05)
        timeline.release(at: 0.1)
        timeline.command(at: 0.2)
        timeline.key(at: 0.25)
        timeline.advance(to: 2)
        #expect(timeline.visible.isEmpty)
    }

    @Test("A key typed between the two taps cancels the double tap")
    func keyBetweenTaps() {
        var timeline = GestureTimeline()
        timeline.command(at: 0)
        timeline.release(at: 0.1)
        timeline.key(at: 0.15)
        timeline.command(at: 0.2)
        timeline.advance(to: 0.5)
        #expect(timeline.visible.isEmpty)
        timeline.advance(to: 0.7)
        #expect(timeline.visible == [.showGlance], "Treated as a fresh hold")
    }

    // MARK: Timers

    @Test("A stale timer is ignored")
    func staleTimer() {
        var recognizer = CommandGestureRecognizer()
        let first = recognizer.handle(.modifiersChanged(.command, time: 0))
        guard case let .startTimer(_, staleID) = first.first else {
            Issue.record("Expected a timer")
            return
        }
        _ = recognizer.handle(.modifiersChanged([], time: 0.4))
        _ = recognizer.handle(.modifiersChanged(.command, time: 1))
        #expect(recognizer.timerFired(id: staleID).isEmpty)
    }
}
