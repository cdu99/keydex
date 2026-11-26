import ApplicationServices
import KeydexDomain

/// Triggers a menu item of another app through the Accessibility API (`AXPress`).
public struct AXMenuActionPerformer: ShortcutActionPerforming {
    private let messagingTimeout: Float = 1.0

    public init() {}

    public func perform(_ shortcut: Shortcut, in app: AppInfo) throws(ShortcutActionError) {
        let application = AXUIElementCreateApplication(app.processID)
        AXUIElementSetMessagingTimeout(application, messagingTimeout)
        guard AXIsProcessTrusted() else { throw .accessibilityNotGranted }
        guard let menuBar = AXElement.attribute(kAXMenuBarAttribute, of: application).flatMap(AXElement.element(from:))
        else { throw .actionFailed }

        let resolver = MenuPathResolver<AXUIElement>(
            children: { Self.items(under: $0, isMenuBar: CFEqual($0, menuBar)) },
            title: { AXElement.attribute(kAXTitleAttribute, of: $0) as? String ?? "" }
        )
        guard let item = resolver.resolve(shortcut.menuPath, from: menuBar) else { throw .itemNotFound }
        guard AXUIElementPerformAction(item, kAXPressAction as CFString) == .success else { throw .actionFailed }
    }

    /// Items of the menu bar, or of the submenu (`AXMenu`) of a menu bar item or menu item.
    private static func items(under element: AXUIElement, isMenuBar: Bool) -> [AXUIElement] {
        let children = AXElement.children(of: element)
        guard !isMenuBar else { return children }
        return children.first.map(AXElement.children(of:)) ?? []
    }
}
