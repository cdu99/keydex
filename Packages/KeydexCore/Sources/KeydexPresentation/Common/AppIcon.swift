import AppKit
import KeydexDomain
import SwiftUI

/// The Dock icon of a running app.
struct AppIcon: View {
    let app: AppInfo
    var size: CGFloat = 32

    var body: some View {
        if let icon = NSRunningApplication(processIdentifier: app.processID)?.icon {
            Image(nsImage: icon)
                .resizable()
                .frame(width: size, height: size)
        } else {
            Image(systemName: "app.dashed")
                .font(.system(size: size * 0.8))
                .frame(width: size, height: size)
        }
    }
}
