import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Draws the app icon: a dark rounded tile with a floating "window" outline
// and a play glyph, at whatever size is asked for.
func drawIcon(size S: CGFloat) -> CGImage? {
    let cs = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(data: nil, width: Int(S), height: Int(S),
                              bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high

    // macOS icons sit inside a margin rather than filling the canvas.
    let inset = S * 0.055
    let tile = CGRect(x: inset, y: inset, width: S - inset * 2, height: S - inset * 2)
    let radius = tile.width * 0.2237                      // Big Sur-ish squircle

    // Base tile, dark vertical gradient.
    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: tile, cornerWidth: radius, cornerHeight: radius, transform: nil))
    ctx.clip()
    let grad = CGGradient(colorsSpace: cs,
                          colors: [CGColor(red: 0.16, green: 0.17, blue: 0.20, alpha: 1),
                                   CGColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1)] as CFArray,
                          locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: tile.maxY), end: CGPoint(x: 0, y: tile.minY), options: [])
    ctx.restoreGState()

    // The "floating window": a rounded outline with a titlebar rule.
    let w = tile.insetBy(dx: tile.width * 0.17, dy: tile.height * 0.225)
    let wr = w.width * 0.075
    ctx.setLineWidth(max(1, S * 0.018))
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.85))
    ctx.addPath(CGPath(roundedRect: w, cornerWidth: wr, cornerHeight: wr, transform: nil))
    ctx.strokePath()

    let barY = w.maxY - w.height * 0.19
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.45))
    ctx.setLineWidth(max(1, S * 0.013))
    ctx.move(to: CGPoint(x: w.minX, y: barY))
    ctx.addLine(to: CGPoint(x: w.maxX, y: barY))
    ctx.strokePath()

    // Play triangle, centred in the area below the titlebar.
    let body = CGRect(x: w.minX, y: w.minY, width: w.width, height: barY - w.minY)
    let t = min(body.width, body.height) * 0.42
    let cx = body.midX + t * 0.12, cy = body.midY
    ctx.setFillColor(CGColor(red: 0.94, green: 0.16, blue: 0.20, alpha: 1))
    ctx.move(to: CGPoint(x: cx - t * 0.5, y: cy + t * 0.62))
    ctx.addLine(to: CGPoint(x: cx - t * 0.5, y: cy - t * 0.62))
    ctx.addLine(to: CGPoint(x: cx + t * 0.66, y: cy))
    ctx.closePath()
    ctx.fillPath()

    return ctx.makeImage()
}

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "FloatTube.iconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

// name -> pixel size, per Apple's iconset layout
let variants: [(String, CGFloat)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for (name, px) in variants {
    guard let img = drawIcon(size: px) else { continue }
    let url = URL(fileURLWithPath: "\(outDir)/\(name).png")
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { continue }
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
}
print("wrote \(variants.count) images to \(outDir)")
