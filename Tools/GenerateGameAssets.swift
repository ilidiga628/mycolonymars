import AppKit
import Foundation

struct RGB {
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat

    init(_ hex: Int) {
        r = CGFloat((hex >> 16) & 0xFF) / 255
        g = CGFloat((hex >> 8) & 0xFF) / 255
        b = CGFloat(hex & 0xFF) / 255
    }

    var color: NSColor {
        NSColor(red: r, green: g, blue: b, alpha: 1)
    }
}

enum TileShape {
    case apple
    case banana
    case berry
    case capsule
    case heart
    case pentagon
}

struct TileSpec {
    let name: String
    let file: String
    let shape: TileShape
    let top: RGB
    let mid: RGB
    let bottom: RGB
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assetRoot = root.appendingPathComponent("MyColony/Assets.xcassets")
let soundsRoot = root.appendingPathComponent("MyColony/Sounds")
let size = CGSize(width: 512, height: 512)

let tiles: [TileSpec] = [
    TileSpec(name: "TileApple", file: "tile-apple.png", shape: .apple, top: RGB(0xFF8AA4), mid: RGB(0xFF244A), bottom: RGB(0x9D0628)),
    TileSpec(name: "TileBanana", file: "tile-banana.png", shape: .banana, top: RGB(0xFFF7A0), mid: RGB(0xFFD92E), bottom: RGB(0xD18A05)),
    TileSpec(name: "TileBerry", file: "tile-berry.png", shape: .berry, top: RGB(0xFF86F4), mid: RGB(0xC32DFF), bottom: RGB(0x6512AA)),
    TileSpec(name: "TileBlueCandy", file: "tile-blue-candy.png", shape: .capsule, top: RGB(0x99F2FF), mid: RGB(0x1EBEFF), bottom: RGB(0x0050C8)),
    TileSpec(name: "TileHeart", file: "tile-heart.png", shape: .heart, top: RGB(0xFF91A8), mid: RGB(0xFF225E), bottom: RGB(0xA20030)),
    TileSpec(name: "TileGreenJelly", file: "tile-green-jelly.png", shape: .pentagon, top: RGB(0xA6FF74), mid: RGB(0x2DF048), bottom: RGB(0x087D26))
]

for tile in tiles {
    drawTile(tile)
    writeImageSet(name: tile.name, file: tile.file)
}

drawParticle(name: "SparkleParticle", file: "sparkle-particle.png", color: RGB(0xFFF6A0).color, kind: "sparkle")
writeImageSet(name: "SparkleParticle", file: "sparkle-particle.png")
drawParticle(name: "JellyDrop", file: "jelly-drop.png", color: RGB(0xFF4AA2).color, kind: "drop")
writeImageSet(name: "JellyDrop", file: "jelly-drop.png")

try? FileManager.default.createDirectory(at: soundsRoot, withIntermediateDirectories: true)
writeWav(name: "jelly_pop_1.wav", frequency: 520, glide: 1.8, duration: 0.16)
writeWav(name: "jelly_pop_2.wav", frequency: 680, glide: 1.45, duration: 0.14)
writeWav(name: "syrup_squish.wav", frequency: 210, glide: 0.68, duration: 0.22)
writeWav(name: "storm_burst.wav", frequency: 360, glide: 2.2, duration: 0.42)
writeWav(name: "coin_collect.wav", frequency: 940, glide: 1.2, duration: 0.18)

func drawTile(_ spec: TileSpec) {
    let image = NSImage(size: size)
    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    NSColor.clear.setFill()
    NSRect(origin: .zero, size: size).fill()

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    shadow.shadowBlurRadius = 26
    shadow.shadowOffset = CGSize(width: 0, height: -18)
    shadow.set()

    let bodyRect = CGRect(x: 72, y: 64, width: 368, height: 368)
    let body = path(for: spec.shape, in: bodyRect)
    gradient(colors: [spec.top.color, spec.mid.color, spec.bottom.color], rect: bodyRect).draw(in: body, angle: -55)

    NSShadow().set()
    spec.bottom.color.withAlphaComponent(0.42).setStroke()
    body.lineWidth = 14
    body.stroke()

    spec.top.color.withAlphaComponent(0.42).setStroke()
    let inner = path(for: spec.shape, in: bodyRect.insetBy(dx: 24, dy: 24))
    inner.lineWidth = 10
    inner.stroke()

    NSColor.white.withAlphaComponent(0.58).setFill()
    let shine = NSBezierPath(roundedRect: CGRect(x: 144, y: 312, width: 155, height: 42), xRadius: 21, yRadius: 21)
    var transform = AffineTransform()
    transform.translate(x: 220, y: 333)
    transform.rotate(byDegrees: 23)
    transform.translate(x: -220, y: -333)
    shine.transform(using: transform)
    shine.fill()

    NSColor.white.withAlphaComponent(0.22).setFill()
    NSBezierPath(ovalIn: CGRect(x: 122, y: 110, width: 260, height: 260)).fill()

    if spec.shape == .apple {
        RGB(0x47E858).color.setFill()
        let leaf = NSBezierPath(roundedRect: CGRect(x: 292, y: 390, width: 86, height: 42), xRadius: 21, yRadius: 21)
        var leafTransform = AffineTransform()
        leafTransform.translate(x: 335, y: 411)
        leafTransform.rotate(byDegrees: -28)
        leafTransform.translate(x: -335, y: -411)
        leaf.transform(using: leafTransform)
        leaf.fill()
    }

    image.unlockFocus()
    savePNG(image, to: assetRoot.appendingPathComponent("\(spec.name).imageset/\(spec.file)"))
}

func path(for shape: TileShape, in rect: CGRect) -> NSBezierPath {
    switch shape {
    case .apple, .berry:
        return NSBezierPath(ovalIn: rect)
    case .banana:
        let path = NSBezierPath()
        path.move(to: CGPoint(x: rect.minX + 64, y: rect.midY + 34))
        path.curve(to: CGPoint(x: rect.maxX - 42, y: rect.midY + 68), controlPoint1: CGPoint(x: rect.midX - 24, y: rect.maxY + 92), controlPoint2: CGPoint(x: rect.maxX - 10, y: rect.maxY - 20))
        path.curve(to: CGPoint(x: rect.minX + 70, y: rect.midY - 82), controlPoint1: CGPoint(x: rect.maxX - 88, y: rect.midY - 92), controlPoint2: CGPoint(x: rect.midX - 18, y: rect.minY - 8))
        path.curve(to: CGPoint(x: rect.minX + 64, y: rect.midY + 34), controlPoint1: CGPoint(x: rect.minX + 20, y: rect.midY - 48), controlPoint2: CGPoint(x: rect.minX + 26, y: rect.midY + 4))
        return path
    case .capsule:
        let rect = CGRect(x: rect.minX + 24, y: rect.minY + 92, width: rect.width - 48, height: rect.height - 184)
        let path = NSBezierPath(roundedRect: rect, xRadius: rect.height / 2, yRadius: rect.height / 2)
        var transform = AffineTransform()
        transform.translate(x: rect.midX, y: rect.midY)
        transform.rotate(byDegrees: -24)
        transform.translate(x: -rect.midX, y: -rect.midY)
        path.transform(using: transform)
        return path
    case .heart:
        let path = NSBezierPath()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + 30))
        path.curve(to: CGPoint(x: rect.minX + 16, y: rect.midY + 58), controlPoint1: CGPoint(x: rect.midX - 150, y: rect.minY + 128), controlPoint2: CGPoint(x: rect.minX - 10, y: rect.midY - 10))
        path.curve(to: CGPoint(x: rect.midX, y: rect.midY + 74), controlPoint1: CGPoint(x: rect.minX + 28, y: rect.maxY + 78), controlPoint2: CGPoint(x: rect.midX - 112, y: rect.maxY + 40))
        path.curve(to: CGPoint(x: rect.maxX - 16, y: rect.midY + 58), controlPoint1: CGPoint(x: rect.midX + 112, y: rect.maxY + 40), controlPoint2: CGPoint(x: rect.maxX - 28, y: rect.maxY + 78))
        path.curve(to: CGPoint(x: rect.midX, y: rect.minY + 30), controlPoint1: CGPoint(x: rect.maxX + 10, y: rect.midY - 10), controlPoint2: CGPoint(x: rect.midX + 150, y: rect.minY + 128))
        return path
    case .pentagon:
        let path = NSBezierPath()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.line(to: CGPoint(x: rect.maxX, y: rect.midY + 62))
        path.line(to: CGPoint(x: rect.maxX - 58, y: rect.minY + 10))
        path.line(to: CGPoint(x: rect.minX + 58, y: rect.minY + 10))
        path.line(to: CGPoint(x: rect.minX, y: rect.midY + 62))
        path.close()
        return path
    }
}

func drawParticle(name: String, file: String, color: NSColor, kind: String) {
    let image = NSImage(size: CGSize(width: 256, height: 256))
    image.lockFocus()
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: 256, height: 256).fill()
    color.setFill()
    if kind == "sparkle" {
        let path = NSBezierPath()
        path.move(to: CGPoint(x: 128, y: 238))
        path.line(to: CGPoint(x: 154, y: 154))
        path.line(to: CGPoint(x: 238, y: 128))
        path.line(to: CGPoint(x: 154, y: 102))
        path.line(to: CGPoint(x: 128, y: 18))
        path.line(to: CGPoint(x: 102, y: 102))
        path.line(to: CGPoint(x: 18, y: 128))
        path.line(to: CGPoint(x: 102, y: 154))
        path.close()
        path.fill()
    } else {
        let path = NSBezierPath()
        path.move(to: CGPoint(x: 128, y: 236))
        path.curve(to: CGPoint(x: 48, y: 94), controlPoint1: CGPoint(x: 82, y: 170), controlPoint2: CGPoint(x: 48, y: 145))
        path.curve(to: CGPoint(x: 128, y: 22), controlPoint1: CGPoint(x: 48, y: 45), controlPoint2: CGPoint(x: 86, y: 22))
        path.curve(to: CGPoint(x: 208, y: 94), controlPoint1: CGPoint(x: 170, y: 22), controlPoint2: CGPoint(x: 208, y: 45))
        path.curve(to: CGPoint(x: 128, y: 236), controlPoint1: CGPoint(x: 208, y: 145), controlPoint2: CGPoint(x: 174, y: 170))
        path.fill()
        NSColor.white.withAlphaComponent(0.48).setFill()
        NSBezierPath(ovalIn: CGRect(x: 88, y: 132, width: 42, height: 62)).fill()
    }
    image.unlockFocus()
    savePNG(image, to: assetRoot.appendingPathComponent("\(name).imageset/\(file)"))
}

func writeImageSet(name: String, file: String) {
    let contents = """
    {
      "images" : [
        {
          "filename" : "\(file)",
          "idiom" : "universal",
          "scale" : "1x"
        }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    """
    try? contents.write(to: assetRoot.appendingPathComponent("\(name).imageset/Contents.json"), atomically: true, encoding: .utf8)
}

func gradient(colors: [NSColor], rect: CGRect) -> NSGradient {
    NSGradient(colors: colors) ?? NSGradient(starting: colors[0], ending: colors.last ?? colors[0])!
}

func savePNG(_ image: NSImage, to url: URL) {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let data = bitmap.representation(using: .png, properties: [:]) else {
        return
    }
    try? data.write(to: url)
}

func writeWav(name: String, frequency: Double, glide: Double, duration: Double) {
    let sampleRate = 44_100
    let sampleCount = Int(duration * Double(sampleRate))
    var data = Data()
    for sample in 0..<sampleCount {
        let t = Double(sample) / Double(sampleRate)
        let env = pow(max(0, 1 - t / duration), 1.8)
        let f = frequency * pow(glide, t / duration)
        let tone = sin(2 * Double.pi * f * t)
        let click = sin(2 * Double.pi * f * 2.7 * t) * 0.26
        let value = Int16(max(-1, min(1, (tone + click) * env * 0.34)) * Double(Int16.max))
        data.append(UInt8(value & 0xff))
        data.append(UInt8((value >> 8) & 0xff))
    }

    var wav = Data()
    wav.append("RIFF".data(using: .ascii)!)
    wav.appendLE(UInt32(36 + data.count))
    wav.append("WAVEfmt ".data(using: .ascii)!)
    wav.appendLE(UInt32(16))
    wav.appendLE(UInt16(1))
    wav.appendLE(UInt16(1))
    wav.appendLE(UInt32(sampleRate))
    wav.appendLE(UInt32(sampleRate * 2))
    wav.appendLE(UInt16(2))
    wav.appendLE(UInt16(16))
    wav.append("data".data(using: .ascii)!)
    wav.appendLE(UInt32(data.count))
    wav.append(data)
    try? wav.write(to: soundsRoot.appendingPathComponent(name))
}

extension Data {
    mutating func appendLE(_ value: UInt16) {
        append(UInt8(value & 0xff))
        append(UInt8((value >> 8) & 0xff))
    }

    mutating func appendLE(_ value: UInt32) {
        append(UInt8(value & 0xff))
        append(UInt8((value >> 8) & 0xff))
        append(UInt8((value >> 16) & 0xff))
        append(UInt8((value >> 24) & 0xff))
    }
}
