import ApplicationServices
import KeydexDomain

/// Reads the whole menu bar of an app through the Accessibility API.
///
/// Every value of an item is fetched in a single IPC round-trip
/// (`AXUIElementCopyMultipleAttributeValues`), which matters for apps with huge menus.
struct AXMenuBarReader: Sendable {
    /// How long to wait for an unresponsive app before giving up, in seconds.
    var messagingTimeout: Float = 1.0
    /// Guards against pathological or cyclic menus.
    var maximumDepth = 6

    func readMenuBar(ofProcess processID: Int32) throws(ShortcutSourceError) -> [MenuItemSnapshot] {
        let application = AXUIElementCreateApplication(processID)
        AXUIElementSetMessagingTimeout(application, messagingTimeout)

        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(application, kAXMenuBarAttribute as CFString, &value)
        switch error {
        case .success:
            break
        case .apiDisabled:
            throw .accessibilityNotGranted
        case .cannotComplete:
            throw .appNotResponding
        default:
            throw .noMenuBar
        }
        guard let value, let menuBar = AXElement.element(from: value) else { throw .noMenuBar }
        return AXElement.children(of: menuBar).map { snapshot(of: $0, depth: 0) }
    }

    // MARK: Tree walking

    /// Order matters: values are read back by index in `snapshot(of:depth:)`.
    private static let itemAttributes: [String] = [
        kAXTitleAttribute,
        kAXMenuItemCmdCharAttribute,
        kAXMenuItemCmdVirtualKeyAttribute,
        kAXMenuItemCmdGlyphAttribute,
        kAXMenuItemCmdModifiersAttribute,
        kAXEnabledAttribute,
        kAXChildrenAttribute,
    ]

    private func snapshot(of item: AXUIElement, depth: Int) -> MenuItemSnapshot {
        let values = Self.attributeValues(of: item)
        let submenus = AXElement.elements(from: values[safe: 6])
        let children = depth < maximumDepth
            ? submenus.flatMap(AXElement.children(of:)).map { snapshot(of: $0, depth: depth + 1) }
            : []
        return MenuItemSnapshot(
            title: values[safe: 0] as? String ?? "",
            commandCharacter: values[safe: 1] as? String,
            commandVirtualKey: values[safe: 2] as? Int,
            commandGlyph: values[safe: 3] as? Int,
            commandModifiers: values[safe: 4] as? Int,
            isEnabled: values[safe: 5] as? Bool ?? true,
            children: children
        )
    }

    // MARK: Low-level helpers

    /// Missing attributes come back as `AXValue` error placeholders, which fail the casts above.
    private static func attributeValues(of element: AXUIElement) -> [AnyObject] {
        var values: CFArray?
        let error = AXUIElementCopyMultipleAttributeValues(
            element, itemAttributes as CFArray, AXCopyMultipleAttributeOptions(rawValue: 0), &values
        )
        guard error == .success, let values = values as? [AnyObject] else { return [] }
        return values
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
