import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// One drawing, with a macOS silhouette for ICNS and a full-bleed web variant.
func drawIcon(size S: CGFloat, fullBleed: Bool = false) -> CGImage? {
    let cs = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(data: nil, width: Int(S), height: Int(S),
        bitsPerComponent: 8, bytesPerRow: 0, space: cs,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
    ctx.scaleBy(x: S / 1024, y: S / 1024)
    let tile = fullBleed ? CGRect(x: 0, y: 0, width: 1024, height: 1024) : CGRect(x: 54, y: 54, width: 916, height: 916)
    ctx.addPath(CGPath(roundedRect: tile, cornerWidth: fullBleed ? 0 : 205, cornerHeight: fullBleed ? 0 : 205, transform: nil))
    ctx.clip()
    let gradient = CGGradient(colorsSpace: cs, colors: [
        CGColor(red: 0.16, green: 0.36, blue: 0.85, alpha: 1),
        CGColor(red: 0.06, green: 0.13, blue: 0.39, alpha: 1)
    ] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 100, y: 1024), end: CGPoint(x: 900, y: 0), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    // A quiet rear window makes the foreground player read as floating.
    let rear = CGRect(x: 155, y: 200, width: 570, height: 405)
    ctx.setFillColor(CGColor(red: 0.45, green: 0.78, blue: 1, alpha: 0.28))
    ctx.addPath(CGPath(roundedRect: rear, cornerWidth: 48, cornerHeight: 48, transform: nil)); ctx.fillPath()
    ctx.setStrokeColor(CGColor(red: 0.65, green: 0.85, blue: 1, alpha: 0.5)); ctx.setLineWidth(8)
    ctx.addPath(CGPath(roundedRect: rear, cornerWidth: 48, cornerHeight: 48, transform: nil)); ctx.strokePath()
    let front = CGRect(x: 286, y: 375, width: 590, height: 410)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -24), blur: 40, color: CGColor(red: 0.02, green: 0.04, blue: 0.16, alpha: 0.4))
    ctx.setFillColor(CGColor(red: 1, green: 0.29, blue: 0.36, alpha: 1))
    ctx.addPath(CGPath(roundedRect: front, cornerWidth: 52, cornerHeight: 52, transform: nil)); ctx.fillPath()
    ctx.restoreGState()
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.35))
    ctx.fill(CGRect(x: 318, y: 714, width: 526, height: 4))
    for x in [330, 354, 378] { ctx.fillEllipse(in: CGRect(x: x, y: 741, width: 10, height: 10)) }
    ctx.setFillColor(CGColor(gray: 1, alpha: 1))
    ctx.move(to: CGPoint(x: 518, y: 460)); ctx.addLine(to: CGPoint(x: 518, y: 657)); ctx.addLine(to: CGPoint(x: 681, y: 558)); ctx.closePath(); ctx.fillPath()
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

// No transparent border or rounded canvas in the website artwork.
if CommandLine.arguments.count > 2, let image = drawIcon(size: 1024, fullBleed: true) {
    let url = URL(fileURLWithPath: CommandLine.arguments[2])
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { fatalError("Cannot create logo") }
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("Cannot save logo") }
}
