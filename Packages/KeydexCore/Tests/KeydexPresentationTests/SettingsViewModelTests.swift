import Foundation
import KeydexDomain
import KeydexPresentation
import Synchronization
import Testing

private final class InMemoryTimingStore: GestureTimingStoring {
    private let saved = Mutex<GestureTiming?>(nil)
    var lastSaved: GestureTiming? { saved.withLock { $0 } }
    func load() -> GestureTiming { lastSaved ?? .standard }
    func save(_ timing: GestureTiming) { saved.withLock { $0 = timing } }
}

private struct RegistrationRefused: Error {}

@MainActor
private final class StubLaunchAtLogin: LaunchAtLoginControlling {
    var status: LaunchAtLoginStatus = .disabled
    var refuses = false
    func setEnabled(_ enabled: Bool) throws {
        if refuses { throw RegistrationRefused() }
        status = enabled ? .enabled : .disabled
    }
    func openLoginItemsSettings() {}
}

@MainActor
private final class StubSheetLibrary: SheetLibraryProviding {
    var summaries: [SheetSummary] = []
    let userFolder = URL(fileURLWithPath: "/tmp/keydex")
    func openUserFolder() {}
}

@MainActor
@Suite("Settings")
struct SettingsViewModelTests {
    private let store = InMemoryTimingStore()
    private let launchAtLogin = StubLaunchAtLogin()

    private func makeViewModel() -> SettingsViewModel {
        SettingsViewModel(
            gestureTiming: GestureTimingPreference(store: store),
            launchAtLogin: launchAtLogin,
            permission: StubPermission(granted: true),
            sheets: StubSheetLibrary()
        )
    }

    @Test("Changing a delay updates the shared preference and saves it")
    func changeDelay() {
        let viewModel = makeViewModel()
        viewModel.glanceDelay = 0.8
        #expect(viewModel.gestureTiming.timing.glanceDelay == 0.8)
        #expect(store.lastSaved?.glanceDelay == 0.8)
        #expect(!viewModel.isStandardTiming)
    }

    @Test("Delays outside their range are clamped")
    func clampDelay() {
        let viewModel = makeViewModel()
        viewModel.doubleTapInterval = 5
        #expect(viewModel.doubleTapInterval == GestureTiming.doubleTapIntervalRange.upperBound)
    }

    @Test("Reset restores the standard delays")
    func reset() {
        let viewModel = makeViewModel()
        viewModel.glanceDelay = 1.2
        viewModel.resetTiming()
        #expect(viewModel.isStandardTiming)
        #expect(store.lastSaved == .standard)
    }

    @Test("The launch at login switch registers Keydex")
    func launchAtLoginSwitch() {
        let viewModel = makeViewModel()
        viewModel.launchesAtLogin = true
        #expect(launchAtLogin.status == .enabled)
        #expect(viewModel.launchesAtLogin)
        #expect(viewModel.launchAtLoginError == nil)
    }

    @Test("A refused registration is explained")
    func launchAtLoginRefused() {
        launchAtLogin.refuses = true
        let viewModel = makeViewModel()
        viewModel.launchesAtLogin = true
        #expect(!viewModel.launchesAtLogin)
        #expect(viewModel.launchAtLoginError?.contains("Applications") == true)
    }
}
