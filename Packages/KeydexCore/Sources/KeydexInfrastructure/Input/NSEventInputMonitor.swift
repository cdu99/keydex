import AppKit
import KeydexDomain

/// Listens to system-wide keyboard and pointer events with `NSEvent` monitors.
///
/// Monitors only observe: events still reach their app untouched, so Keydex can never
/// swallow a shortcut. Global monitors need the Accessibility permission for key events,
/// and receive nothing while Secure Input is on (password fields), by design of macOS.
@MainActor
public final class NSEventInputMonitor: InputEventMonitoring {
    private var monitors: [Any] = []

    private static let mask: NSEvent.EventTypeMask = [
        .flagsChanged, .keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel,
    ]

    public init() {}

    isolated deinit {
        stop()
    }

    public func start(_ handler: @escaping @MainActor (InputEvent) -> Void) {
        stop()
        // Global: events sent to other apps. Local: events sent to Keydex itself (its panel).
        if let global = NSEvent.addGlobalMonitorForEvents(matching: Self.mask, handler: { event in
            let input = InputEvent(event)
            MainActor.assumeIsolated { input.map(handler) }
        }) {
            monitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: Self.mask, handler: { event in
            let input = InputEvent(event)
            MainActor.assumeIsolated { input.map(handler) }
            return event
        }) {
            monitors.append(local)
        }
    }

    public func stop() {
        monitors.forEach(NSEvent.removeMonitor)
        monitors.removeAll()
    }
}

extension InputEvent {
    init?(_ event: NSEvent) {
        switch event.type {
        case .flagsChanged:
            self = .modifiersChanged(ModifierSet(event.modifierFlags), time: event.timestamp)
        case .keyDown:
            self = .keyDown(time: event.timestamp)
        case .leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel:
            self = .pointerDown(time: event.timestamp)
        default:
            return nil
        }
    }
}

extension ModifierSet {
    /// Caps Lock and device-dependent bits are ignored.
    init(_ flags: NSEvent.ModifierFlags) {
        let flags = flags.intersection(.deviceIndependentFlagsMask)
        var modifiers: ModifierSet = []
        if flags.contains(.function) { modifiers.insert(.function) }
        if flags.contains(.control) { modifiers.insert(.control) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.shift) { modifiers.insert(.shift) }
        if flags.contains(.command) { modifiers.insert(.command) }
        self = modifiers
    }
}
