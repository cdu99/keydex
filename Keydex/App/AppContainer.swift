import KeydexDomain
import KeydexInfrastructure

/// Composition root: the only place where concrete implementations are chosen
/// and wired together. The rest of the app depends on Domain abstractions.
@MainActor
final class AppContainer {
    let activeAppProvider: any ActiveAppProviding

    init() {
        activeAppProvider = WorkspaceActiveAppTracker()
    }
}
