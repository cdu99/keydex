/// Keeps the user's gesture delays between launches.
public protocol GestureTimingStoring: Sendable {
    /// The saved timing, or `.standard` if none was saved.
    func load() -> GestureTiming
    func save(_ timing: GestureTiming)
}
