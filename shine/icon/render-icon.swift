import AppKit
import CoreGraphics

struct SeededRandom {
    var state: UInt64
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double((state >> 33) & 0x7fffffff) / Double(0x7fffffff)
    }
}

func fourPointStar(center: CGPoint, radius: CGFloat, waist: CGFloat) -> CGPath {
    let path = CGMutablePath()
    let tips = (0..<4).map { i -> CGPoint in
        let angle = CGFloat(i) * .pi / 2 + .pi / 2
        return CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }
    path.move(to: tips[0])
    for i in 0..<4 {
        let next = tips[(i + 1) % 4]
        let midAngle = CGFloat(i) * .pi / 2 + .pi / 2 + .pi / 4
        let control = CGPoint(x: center.x + cos(midAngle) * radius * waist, y: center.y + sin(midAngle) * radius * waist)
        path.addQuadCurve(to: next, control: control)
    }
    path.closeSubpath()
    return path
}

func render(size: Int, to url: URL) {
    let s = CGFloat(size)
    let k = s / 1024
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.interpolationQuality = .high
    ctx.setAllowsAntialiasing(true)

    let bodyRect = CGRect(x: 100 * k, y: 100 * k, width: 824 * k, height: 824 * k)
    let body = CGPath(roundedRect: bodyRect, cornerWidth: 185 * k, cornerHeight: 185 * k, transform: nil)
    let center = CGPoint(x: bodyRect.midX, y: bodyRect.midY)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10 * k), blur: 24 * k, color: NSColor(white: 0, alpha: 0.45).cgColor)
    ctx.addPath(body)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(body)
    ctx.clip()

    let background = CGGradient(colorsSpace: colorSpace, colors: [
        NSColor(red: 0.07, green: 0.06, blue: 0.11, alpha: 1).cgColor,
        NSColor(red: 0.01, green: 0.01, blue: 0.02, alpha: 1).cgColor
    ] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(background, startCenter: center, startRadius: 0, endCenter: center, endRadius: 600 * k, options: [.drawsAfterEndLocation])

    let glow = CGGradient(colorsSpace: colorSpace, colors: [
        NSColor(red: 0.62, green: 0.70, blue: 1.0, alpha: 0.42).cgColor,
        NSColor(red: 0.45, green: 0.40, blue: 0.95, alpha: 0.12).cgColor,
        NSColor(red: 0.2, green: 0.2, blue: 0.5, alpha: 0).cgColor
    ] as CFArray, locations: [0, 0.45, 1])!
    ctx.drawRadialGradient(glow, startCenter: center, startRadius: 0, endCenter: center, endRadius: 400 * k, options: [])

    var random = SeededRandom(state: 0x5348494e45)
    let particleCount = size >= 256 ? 90 : (size >= 64 ? 40 : 14)
    let minRadius: CGFloat = size >= 64 ? 1.6 : 0.6
    for _ in 0..<particleCount {
        let angle = random.next() * 2 * .pi
        let distance = (0.18 + pow(random.next(), 0.8) * 0.82) * 420
        let x = center.x + CGFloat(cos(angle) * distance) * k
        let y = center.y + CGFloat(sin(angle) * distance) * k
        let radius = max(minRadius, CGFloat(1.5 + random.next() * random.next() * 7) * k)
        let alpha = CGFloat(0.25 + random.next() * 0.7) * (1 - CGFloat(distance / 420) * 0.45)
        let tint = random.next()
        let color = NSColor(red: 0.80 + 0.2 * tint, green: 0.84 + 0.1 * tint, blue: 1.0, alpha: alpha)
        if radius > 4 * k && size >= 128 {
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: radius * 3, color: color.withAlphaComponent(alpha * 0.9).cgColor)
            ctx.setFillColor(color.cgColor)
            ctx.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
            ctx.restoreGState()
        } else {
            ctx.setFillColor(color.cgColor)
            ctx.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
        }
    }

    let sparkles: [(CGFloat, CGFloat, CGFloat)] = [(250, 225, 46), (-235, -240, 30), (-270, 175, 20)]
    if size >= 64 {
        for (dx, dy, r) in sparkles {
            let p = CGPoint(x: center.x + dx * k, y: center.y + dy * k)
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: 14 * k, color: NSColor(red: 0.75, green: 0.8, blue: 1, alpha: 0.9).cgColor)
            ctx.addPath(fourPointStar(center: p, radius: r * k, waist: 0.16))
            ctx.setFillColor(NSColor(red: 0.92, green: 0.94, blue: 1, alpha: 0.95).cgColor)
            ctx.fillPath()
            ctx.restoreGState()
        }
    }

    let starPath = fourPointStar(center: center, radius: 330 * k, waist: 0.17)

    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 70 * k, color: NSColor(red: 0.62, green: 0.68, blue: 1, alpha: 0.95).cgColor)
    ctx.addPath(starPath)
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(starPath)
    ctx.clip()
    let starGradient = CGGradient(colorsSpace: colorSpace, colors: [
        NSColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor,
        NSColor(red: 0.86, green: 0.88, blue: 1, alpha: 1).cgColor,
        NSColor(red: 0.66, green: 0.70, blue: 1, alpha: 1).cgColor
    ] as CFArray, locations: [0, 0.35, 1])!
    ctx.drawRadialGradient(starGradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: 330 * k, options: [.drawsAfterEndLocation])
    ctx.restoreGState()

    let core = CGGradient(colorsSpace: colorSpace, colors: [
        NSColor(white: 1, alpha: 1).cgColor,
        NSColor(white: 1, alpha: 0).cgColor
    ] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(core, startCenter: center, startRadius: 0, endCenter: center, endRadius: 70 * k, options: [])

    ctx.restoreGState()

    let image = ctx.makeImage()!
    let rep = NSBitmapImageRep(cgImage: image)
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
}

let output = URL(fileURLWithPath: CommandLine.arguments[1])
let files: [(String, Int)] = [
    ("Logo_16.png", 16), ("Logo_32.png", 32), ("Logo_32-1.png", 32), ("Logo_64.png", 64),
    ("Logo_128.png", 128), ("Logo_256.png", 256), ("Logo_256-1.png", 256),
    ("Logo_512.png", 512), ("Logo_512-1.png", 512), ("Logo_1024.png", 1024)
]
for (name, size) in files {
    render(size: size, to: output.appendingPathComponent(name))
}
print("done")
