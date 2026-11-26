import SwiftUI

/// Liquid Glass background, with an opaque fallback when the user enabled
/// Settings › Accessibility › Display › Reduce transparency.
struct PanelBackground: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let shape = RoundedRectangle(cornerRadius: PanelMetrics.cornerRadius, style: .continuous)

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background(Color(nsColor: .windowBackgroundColor), in: shape)
                .overlay(shape.strokeBorder(Color(nsColor: .separatorColor)))
        } else {
            content.glassEffect(.regular, in: shape)
        }
    }
}

extension View {
    func panelBackground() -> some View {
        modifier(PanelBackground())
    }
}
