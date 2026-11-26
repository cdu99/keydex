import ApplicationServices

/// Small helpers over the C Accessibility API.
enum AXElement {
    static func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    static func element(from value: CFTypeRef) -> AXUIElement? {
        guard CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement) // Safe: type checked above.
    }

    /// Elements of an array attribute value; non-elements are skipped.
    static func elements(from value: CFTypeRef?) -> [AXUIElement] {
        guard let array = value as? [AnyObject] else { return [] }
        return array.compactMap { Self.element(from: $0) }
    }

    static func children(of element: AXUIElement) -> [AXUIElement] {
        elements(from: attribute(kAXChildrenAttribute, of: element))
    }
}
