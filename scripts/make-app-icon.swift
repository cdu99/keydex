// Builds Keydex's app icon as an Icon Composer document (Keydex/Resources/AppIcon.icon),
// so macOS renders it with Liquid Glass (specular highlights, dark and tinted variants).
//
// Two layers on a blue-violet fill:
// - back: a frosted panel listing shortcuts (what Keydex shows);
// - front: a ⌘ keycap.
// Usage: swift scripts/make-app-icon.swift  (then open AppIcon.icon in Icon Composer to tweak)
import AppKit

let canvas: CGFloat = 1024
let iconURL = URL(fileURLWithPath: "Keydex/Resources/AppIcon.icon")
let assetsURL = iconURL.appendingPathComponent("Assets")

// MARK: Drawing helpers

func renderLayer(_ draw: (CGContext) -> Void) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(canvas), pixelsHigh: Int(canvas), bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!
    let graphics = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = graphics
    draw(graphics.cgContext)
    NSGraphicsContext.current = nil
    return rep.representation(using: .png, properties: [:])!
}

func fill(_ rect: CGRect, radius: CGFloat, color: NSColor, in context: CGContext) {
    context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.setFillColor(color.cgColor)
    context.fillPath()
}

// MARK: Layers

/// A panel of four shortcut rows: an action name (bar) and its keys (small keycaps).
let panelRect = CGRect(x: 168, y: 330, width: 560, height: 480)
let panel = renderLayer { context in
    fill(panelRect, radius: 72, color: NSColor(white: 1, alpha: 0.55), in: context)
}

/// Rows drawn flat on top of the glass panel: small shapes look noisy when refracted.
let rows = renderLayer { context in
    let rowWidths: [CGFloat] = [250, 190, 280, 210]
    for (index, width) in rowWidths.enumerated() {
        let y = panelRect.maxY - 120 - CGFloat(index) * 92
        let ink = NSColor(white: 1, alpha: 0.92)
        fill(CGRect(x: panelRect.minX + 60, y: y, width: width, height: 34), radius: 17, color: ink, in: context)
        fill(CGRect(x: panelRect.maxX - 160, y: y - 6, width: 46, height: 46), radius: 12, color: ink, in: context)
        fill(CGRect(x: panelRect.maxX - 104, y: y - 6, width: 46, height: 46), radius: 12, color: ink, in: context)
    }
}

/// The ⌘ keycap, overlapping the panel's lower right corner.
let keycapRect = CGRect(x: 470, y: 168, width: 390, height: 390)
let keycap = renderLayer { context in
    fill(keycapRect, radius: 96, color: .white, in: context)
}

let symbol = renderLayer { context in
    let configuration = NSImage.SymbolConfiguration(pointSize: 215, weight: .semibold)
    guard let image = NSImage(systemSymbolName: "command", accessibilityDescription: nil)?
        .withSymbolConfiguration(configuration) else { fatalError("SF Symbol 'command' not found") }
    let tinted = NSImage(size: image.size, flipped: false) { rect in
        image.draw(in: rect)
        NSColor(red: 0.30, green: 0.30, blue: 0.92, alpha: 1).set()
        rect.fill(using: .sourceAtop)
        return true
    }
    tinted.draw(in: CGRect(
        x: keycapRect.midX - image.size.width / 2, y: keycapRect.midY - image.size.height / 2,
        width: image.size.width, height: image.size.height
    ))
}

// MARK: Document

let document: [String: Any] = [
    "fill": ["automatic-gradient": "extended-srgb:0.34000,0.36000,0.98000,1.00000"],
    "groups": [
        [
            "name": "Keycap",
            "layers": [
                ["name": "Symbol", "image-name": "symbol.png", "glass": false],
                ["name": "Keycap", "image-name": "keycap.png", "glass": true],
            ],
            "shadow": ["kind": "neutral", "opacity": 0.5],
            "translucency": ["enabled": false, "value": 0],
            "specular": true,
        ],
        [
            "name": "Panel",
            "layers": [
                ["name": "Rows", "image-name": "rows.png", "glass": false],
                ["name": "Panel", "image-name": "panel.png", "glass": true],
            ],
            "shadow": ["kind": "neutral", "opacity": 0.3],
            "translucency": ["enabled": true, "value": 0.4],
            "blur-material": 0.5,
            "specular": true,
        ],
    ],
    "supported-platforms": ["squares": ["macOS"]],
]

try? FileManager.default.removeItem(at: iconURL)
try FileManager.default.createDirectory(at: assetsURL, withIntermediateDirectories: true)
try panel.write(to: assetsURL.appendingPathComponent("panel.png"))
try rows.write(to: assetsURL.appendingPathComponent("rows.png"))
try keycap.write(to: assetsURL.appendingPathComponent("keycap.png"))
try symbol.write(to: assetsURL.appendingPathComponent("symbol.png"))
try JSONSerialization.data(withJSONObject: document, options: [.prettyPrinted, .sortedKeys])
    .write(to: iconURL.appendingPathComponent("icon.json"))
print("Wrote \(iconURL.path)")
