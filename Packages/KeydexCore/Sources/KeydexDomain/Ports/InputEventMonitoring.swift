/// Delivers the keyboard and pointer events of the whole system (not only Keydex's).
@MainActor
public protocol InputEventMonitoring: AnyObject {
    func start(_ handler: @escaping @MainActor (InputEvent) -> Void)
    func stop()
}
