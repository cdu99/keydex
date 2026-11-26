import CoreServices
import Foundation

/// Calls `onChange` (on the main queue) shortly after anything changes in a folder, using
/// FSEvents: it also catches editors that save by replacing the file.
public final class DirectoryWatcher: @unchecked Sendable {
    // The stream is only touched in init/deinit; FSEvents calls back on `queue`.
    private var stream: FSEventStreamRef?
    private let onChange: @MainActor () -> Void
    private let queue = DispatchQueue(label: "keydex.directory-watcher")

    /// - Parameter latency: seconds to wait to coalesce bursts of events (an editor saving).
    public init(directory: URL, latency: TimeInterval = 0.3, onChange: @escaping @MainActor () -> Void) {
        self.onChange = onChange
        var context = FSEventStreamContext(
            version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil
        )
        let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            let watcher = Unmanaged<DirectoryWatcher>.fromOpaque(info).takeUnretainedValue()
            DispatchQueue.main.async { MainActor.assumeIsolated { watcher.onChange() } }
        }
        stream = FSEventStreamCreate(
            nil, callback, &context, [directory.path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow), latency,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer)
        )
        if let stream {
            FSEventStreamSetDispatchQueue(stream, queue)
            FSEventStreamStart(stream)
        }
    }

    deinit {
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
    }
}
