import KeydexDomain
import KeydexPresentation
import Observation

/// Drives the ⌘ gesture: feeds system input events to `CommandGestureRecognizer`, runs
/// its timer, and turns its decisions into panel presentations.
@MainActor
final class CommandGestureCoordinator {
    private var recognizer: CommandGestureRecognizer
    private let timing: GestureTimingPreference
    private let inputMonitor: any InputEventMonitoring
    private let permission: any AccessibilityPermissionProviding
    private let panelController: ShortcutPanelController
    private var timer: Task<Void, Never>?

    init(
        timing: GestureTimingPreference,
        inputMonitor: any InputEventMonitoring,
        permission: any AccessibilityPermissionProviding,
        panelController: ShortcutPanelController
    ) {
        recognizer = CommandGestureRecognizer(timing: timing.timing)
        self.timing = timing
        self.inputMonitor = inputMonitor
        self.permission = permission
        self.panelController = panelController
    }

    func start() {
        startMonitoring()
        restartMonitoringWhenPermissionChanges()
        followTimingChanges()
    }

    /// Delays changed in the settings apply to the next gesture, without relaunching.
    private func followTimingChanges() {
        recognizer.timing = withObservationTracking {
            timing.timing
        } onChange: { [weak self] in
            Task { @MainActor in self?.followTimingChanges() }
        }
    }

    private func startMonitoring() {
        inputMonitor.start { [weak self] event in
            guard let self else { return }
            apply(recognizer.handle(event))
        }
    }

    /// Key events only reach global monitors once the permission is granted, and monitors
    /// installed before that may stay deaf: reinstall them when the status changes.
    private func restartMonitoringWhenPermissionChanges() {
        withObservationTracking {
            _ = permission.isGranted
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.startMonitoring()
                self?.restartMonitoringWhenPermissionChanges()
            }
        }
    }

    // MARK: Effects

    private func apply(_ effects: [GestureEffect]) {
        effects.forEach(apply)
    }

    private func apply(_ effect: GestureEffect) {
        switch effect {
        case let .startTimer(delay, id):
            timer?.cancel()
            timer = Task { [weak self] in
                try? await Task.sleep(for: .seconds(delay), tolerance: .milliseconds(5))
                guard !Task.isCancelled, let self else { return }
                apply(recognizer.timerFired(id: id))
            }
        case .cancelTimer:
            timer?.cancel()
            timer = nil
        case .showGlance:
            // Never replace a sticky panel the user is reading with a transient glance.
            guard panelController.presentedMode != .sticky else { return }
            panelController.present(mode: .glance)
        case .hideGlance:
            guard panelController.presentedMode == .glance else { return }
            panelController.dismiss()
        case .showSticky:
            panelController.present(mode: .sticky)
        }
    }
}
