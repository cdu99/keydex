// Draws Keydex's app icon (a ⌘ keycap on a blue squircle) at every size macOS needs,
// into Keydex/Resources/Assets.xcassets/AppIcon.appiconset.
// Usage: swift scripts/make-app-icon.swift
import AppKit

let output = URL(fileURLWithPath: "Keydex/Resources/Assets.xcassets/AppIcon.appiconset")

/// Draws the icon on a 1024-point canvas, following the macOS icon grid
/// (824-point body centered, with room for the shadow).
func drawIcon(in context: CGContext) {
    let canvas: CGFloat = 1024
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let bodyPath = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)

    // Drop shadow and blue gradient body.
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: NSColor.black.withAlphaComponent(0.35).cgColor)
    context.addPath(bodyPath)
    context.setFillColor(NSColor.black.cgColor)
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(bodyPath)
    context.clip()
    let blue = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
        NSColor(red: 0.30, green: 0.55, blue: 1.00, alpha: 1).cgColor,
        NSColor(red: 0.20, green: 0.22, blue: 0.75, alpha: 1).cgColor,
    ] as CFArray, locations: [0, 1])!
    context.drawLinearGradient(blue, start: CGPoint(x: 0, y: canvas - 100), end: CGPoint(x: 0, y: 100), options: [])
    context.restoreGState()

    // Keycap: a light rounded square with a darker base, like a key seen from the top.
    let cap = CGRect(x: 262, y: 262, width: 500, height: 500)
    let capBase = CGPath(roundedRect: cap.offsetBy(dx: 0, dy: -22), cornerWidth: 110, cornerHeight: 110, transform: nil)
    let capTop = CGPath(roundedRect: cap, cornerWidth: 110, cornerHeight: 110, transform: nil)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -18), blur: 40, color: NSColor.black.withAlphaComponent(0.30).cgColor)
    context.addPath(capBase)
    context.setFillColor(NSColor(white: 0.80, alpha: 1).cgColor)
    context.fillPath()
    context.restoreGState()
    context.saveGState()
    context.addPath(capTop)
    context.clip()
    let white = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
        NSColor(white: 1.0, alpha: 1).cgColor, NSColor(white: 0.92, alpha: 1).cgColor,
    ] as CFArray, locations: [0, 1])!
    context.drawLinearGradient(white, start: CGPoint(x: 0, y: cap.maxY), end: CGPoint(x: 0, y: cap.minY), options: [])
    context.restoreGState()

    // The ⌘ symbol, in the body's blue.
    let configuration = NSImage.SymbolConfiguration(pointSize: 270, weight: .semibold)
    guard let symbol = NSImage(systemSymbolName: "command", accessibilityDescription: nil)?
        .withSymbolConfiguration(configuration) else { fatalError("SF Symbol 'command' not found") }
    let tinted = NSImage(size: symbol.size, flipped: false) { rect in
        symbol.draw(in: rect)
        NSColor(red: 0.22, green: 0.33, blue: 0.85, alpha: 1).set()
        rect.fill(using: .sourceAtop)
        return true
    }
    let symbolRect = CGRect(
        x: cap.midX - symbol.size.width / 2, y: cap.midY - symbol.size.height / 2,
        width: symbol.size.width, height: symbol.size.height
    )
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    tinted.draw(in: symbolRect)
}

func png(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!
    let context = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
    context.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
    drawIcon(in: context)
    return rep.representation(using: .png, properties: [:])!
}

// macOS icon sizes: (points, scale).
let sizes = [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2), (256, 1), (256, 2), (512, 1), (512, 2)]
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
var images: [[String: String]] = []
for (points, scale) in sizes {
    let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
    try png(pixels: points * scale).write(to: output.appendingPathComponent(name))
    images.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": name])
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: output.appendingPathComponent("Contents.json"))
try #"{ "info" : { "author" : "xcode", "version" : 1 } }"#.data(using: .utf8)!
    .write(to: output.deletingLastPathComponent().appendingPathComponent("Contents.json"))
print("Wrote \(sizes.count) icons to \(output.path)")
