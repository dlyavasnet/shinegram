import AppKit
import CoreGraphics
import TelegramCore
import Localization
import TelegramContext

public struct ShineAppIconVariant: Equatable {
    public let id: String
    let englishName: String
    let russianName: String
    let backgroundTop: NSColor
    let backgroundBottom: NSColor
    let glow: NSColor
    let starCenter: NSColor
    let starMiddle: NSColor
    let starEdge: NSColor
    let particle: NSColor

    public var name: String {
        return shineLocalized(englishName, russianName)
    }

    public static let classic = ShineAppIconVariant(id: "classic", englishName: "Starlight", russianName: "Звёздный свет", backgroundTop: NSColor(red: 0.07, green: 0.06, blue: 0.11, alpha: 1), backgroundBottom: NSColor(red: 0.01, green: 0.01, blue: 0.02, alpha: 1), glow: NSColor(red: 0.62, green: 0.70, blue: 1.0, alpha: 1), starCenter: .white, starMiddle: NSColor(red: 0.86, green: 0.88, blue: 1, alpha: 1), starEdge: NSColor(red: 0.66, green: 0.70, blue: 1, alpha: 1), particle: NSColor(red: 0.85, green: 0.88, blue: 1, alpha: 1))

    public static let gold = ShineAppIconVariant(id: "gold", englishName: "Gold", russianName: "Золото", backgroundTop: NSColor(red: 0.11, green: 0.08, blue: 0.03, alpha: 1), backgroundBottom: NSColor(red: 0.02, green: 0.015, blue: 0.0, alpha: 1), glow: NSColor(red: 1.0, green: 0.78, blue: 0.32, alpha: 1), starCenter: .white, starMiddle: NSColor(red: 1.0, green: 0.92, blue: 0.68, alpha: 1), starEdge: NSColor(red: 1.0, green: 0.72, blue: 0.22, alpha: 1), particle: NSColor(red: 1.0, green: 0.88, blue: 0.6, alpha: 1))

    public static let ruby = ShineAppIconVariant(id: "ruby", englishName: "Ruby", russianName: "Рубин", backgroundTop: NSColor(red: 0.12, green: 0.03, blue: 0.06, alpha: 1), backgroundBottom: NSColor(red: 0.02, green: 0.0, blue: 0.01, alpha: 1), glow: NSColor(red: 1.0, green: 0.32, blue: 0.45, alpha: 1), starCenter: .white, starMiddle: NSColor(red: 1.0, green: 0.78, blue: 0.82, alpha: 1), starEdge: NSColor(red: 1.0, green: 0.36, blue: 0.48, alpha: 1), particle: NSColor(red: 1.0, green: 0.7, blue: 0.76, alpha: 1))

    public static let emerald = ShineAppIconVariant(id: "emerald", englishName: "Emerald", russianName: "Изумруд", backgroundTop: NSColor(red: 0.02, green: 0.10, blue: 0.07, alpha: 1), backgroundBottom: NSColor(red: 0.0, green: 0.02, blue: 0.01, alpha: 1), glow: NSColor(red: 0.30, green: 1.0, blue: 0.68, alpha: 1), starCenter: .white, starMiddle: NSColor(red: 0.78, green: 1.0, blue: 0.88, alpha: 1), starEdge: NSColor(red: 0.30, green: 0.92, blue: 0.62, alpha: 1), particle: NSColor(red: 0.7, green: 1.0, blue: 0.85, alpha: 1))

    public static let ocean = ShineAppIconVariant(id: "ocean", englishName: "Ocean", russianName: "Океан", backgroundTop: NSColor(red: 0.02, green: 0.07, blue: 0.13, alpha: 1), backgroundBottom: NSColor(red: 0.0, green: 0.01, blue: 0.03, alpha: 1), glow: NSColor(red: 0.25, green: 0.78, blue: 1.0, alpha: 1), starCenter: .white, starMiddle: NSColor(red: 0.76, green: 0.94, blue: 1.0, alpha: 1), starEdge: NSColor(red: 0.28, green: 0.72, blue: 1.0, alpha: 1), particle: NSColor(red: 0.7, green: 0.92, blue: 1.0, alpha: 1))

    public static let violet = ShineAppIconVariant(id: "violet", englishName: "Nebula", russianName: "Туманность", backgroundTop: NSColor(red: 0.09, green: 0.03, blue: 0.13, alpha: 1), backgroundBottom: NSColor(red: 0.015, green: 0.0, blue: 0.03, alpha: 1), glow: NSColor(red: 0.78, green: 0.38, blue: 1.0, alpha: 1), starCenter: .white, starMiddle: NSColor(red: 0.92, green: 0.80, blue: 1.0, alpha: 1), starEdge: NSColor(red: 0.74, green: 0.42, blue: 1.0, alpha: 1), particle: NSColor(red: 0.9, green: 0.78, blue: 1.0, alpha: 1))

    public static let all: [ShineAppIconVariant] = [.classic, .gold, .ruby, .emerald, .ocean, .violet]

    public static func ==(lhs: ShineAppIconVariant, rhs: ShineAppIconVariant) -> Bool {
        return lhs.id == rhs.id
    }
}

private struct ShineSeededRandom {
    var state: UInt64
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double((state >> 33) & 0x7fffffff) / Double(0x7fffffff)
    }
}

private func fourPointStar(center: CGPoint, radius: CGFloat, waist: CGFloat) -> CGPath {
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

public func shineRenderAppIcon(_ variant: ShineAppIconVariant, size: Int) -> CGImage? {
    let s = CGFloat(size)
    let k = s / 1024
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB), let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        return nil
    }
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

    if let background = CGGradient(colorsSpace: colorSpace, colors: [variant.backgroundTop.cgColor, variant.backgroundBottom.cgColor] as CFArray, locations: [0, 1]) {
        ctx.drawRadialGradient(background, startCenter: center, startRadius: 0, endCenter: center, endRadius: 600 * k, options: [.drawsAfterEndLocation])
    }

    if let glow = CGGradient(colorsSpace: colorSpace, colors: [variant.glow.withAlphaComponent(0.42).cgColor, variant.glow.withAlphaComponent(0.12).cgColor, variant.glow.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 0.45, 1]) {
        ctx.drawRadialGradient(glow, startCenter: center, startRadius: 0, endCenter: center, endRadius: 400 * k, options: [])
    }

    var random = ShineSeededRandom(state: 0x5348494e45)
    let particleCount = size >= 256 ? 90 : (size >= 64 ? 40 : 14)
    let minRadius: CGFloat = size >= 64 ? 1.6 : 0.6
    for _ in 0..<particleCount {
        let angle = random.next() * 2 * .pi
        let distance = (0.18 + pow(random.next(), 0.8) * 0.82) * 420
        let x = center.x + CGFloat(cos(angle) * distance) * k
        let y = center.y + CGFloat(sin(angle) * distance) * k
        let radius = max(minRadius, CGFloat(1.5 + random.next() * random.next() * 7) * k)
        let alpha = CGFloat(0.25 + random.next() * 0.7) * (1 - CGFloat(distance / 420) * 0.45)
        _ = random.next()
        let color = variant.particle.withAlphaComponent(alpha)
        if radius > 4 * k && size >= 128 {
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: radius * 3, color: variant.particle.withAlphaComponent(alpha * 0.9).cgColor)
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
            ctx.setShadow(offset: .zero, blur: 14 * k, color: variant.glow.withAlphaComponent(0.9).cgColor)
            ctx.addPath(fourPointStar(center: p, radius: r * k, waist: 0.16))
            ctx.setFillColor(variant.starMiddle.withAlphaComponent(0.95).cgColor)
            ctx.fillPath()
            ctx.restoreGState()
        }
    }

    let starPath = fourPointStar(center: center, radius: 330 * k, waist: 0.17)

    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 70 * k, color: variant.glow.withAlphaComponent(0.95).cgColor)
    ctx.addPath(starPath)
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(starPath)
    ctx.clip()
    if let starGradient = CGGradient(colorsSpace: colorSpace, colors: [variant.starCenter.cgColor, variant.starMiddle.cgColor, variant.starEdge.cgColor] as CFArray, locations: [0, 0.35, 1]) {
        ctx.drawRadialGradient(starGradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: 330 * k, options: [.drawsAfterEndLocation])
    }
    ctx.restoreGState()

    if let core = CGGradient(colorsSpace: colorSpace, colors: [NSColor(white: 1, alpha: 1).cgColor, NSColor(white: 1, alpha: 0).cgColor] as CFArray, locations: [0, 1]) {
        ctx.drawRadialGradient(core, startCenter: center, startRadius: 0, endCenter: center, endRadius: 70 * k, options: [])
    }

    ctx.restoreGState()

    return ctx.makeImage()
}

public enum ShineAppIcons {
    public static var selected: ShineAppIconVariant {
        let id = ShineSettings.appIcon
        return ShineAppIconVariant.all.first(where: { $0.id == id }) ?? .classic
    }

    private static var folder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base.appendingPathComponent("ShineGram/AppIcons", isDirectory: true)
    }

    private static func path(for variant: ShineAppIconVariant) -> String? {
        let url = folder.appendingPathComponent("\(variant.id)-v1.png")
        if FileManager.default.fileExists(atPath: url.path) {
            return url.path
        }
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
        guard let image = shineRenderAppIcon(variant, size: 1024) else {
            return nil
        }
        let rep = NSBitmapImageRep(cgImage: image)
        guard let data = rep.representation(using: .png, properties: [:]) else {
            return nil
        }
        do {
            try data.write(to: url)
            return url.path
        } catch {
            return nil
        }
    }

    public static func applySelected() {
        let variant = selected
        if variant == .classic {
            Dock.setCustomAppIcon(path: nil)
        } else {
            Dock.setCustomAppIcon(path: path(for: variant))
        }
    }

    public static func select(_ variant: ShineAppIconVariant) {
        ShineSettings.appIcon = variant.id
        applySelected()
    }
}

public enum ShineRuntime {
    private static var observers: [NSObjectProtocol] = []

    public static func start() {
        guard observers.isEmpty else {
            return
        }
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: ShineSettings.didChangeNotification, object: nil, queue: .main, using: { _ in
            applyStreamerMode()
        }))
        observers.append(center.addObserver(forName: NSApplication.didFinishLaunchingNotification, object: nil, queue: .main, using: { _ in
            applyStreamerMode()
        }))
        observers.append(center.addObserver(forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main, using: { notification in
            if let window = notification.object as? NSWindow {
                apply(to: window)
            }
        }))
        observers.append(center.addObserver(forName: NSWindow.didBecomeMainNotification, object: nil, queue: .main, using: { notification in
            if let window = notification.object as? NSWindow {
                apply(to: window)
            }
        }))
    }

    private static func apply(to window: NSWindow) {
        let sharingType: NSWindow.SharingType = ShineSettings.streamerMode ? .none : .readOnly
        if window.sharingType != sharingType {
            window.sharingType = sharingType
        }
    }

    private static func applyStreamerMode() {
        guard let app = NSApp else {
            return
        }
        for window in app.windows {
            apply(to: window)
        }
    }
}

public enum ShineHooks {
    public static var openLink: ((String, any AccountContextProtocol) -> Void)?
    public static let creatorChannelUrl = "https://t.me/dlyavasnet"
}

private func shineIconPixelSize(_ reference: CGImage) -> Int {
    return max(16, reference.width)
}

public func shineSettingsIcon(_ variant: ShineAppIconVariant, reference: CGImage) -> CGImage {
    let pixels = shineIconPixelSize(reference)
    let renderSize = Int((CGFloat(pixels) * 1024 / 824).rounded())
    guard let full = shineRenderAppIcon(variant, size: renderSize) else {
        return reference
    }
    let inset = CGFloat(renderSize) * 100 / 1024
    let rect = CGRect(x: inset, y: inset, width: CGFloat(pixels), height: CGFloat(pixels)).integral
    return full.cropping(to: rect) ?? reference
}

public func shineChannelIcon(reference: CGImage) -> CGImage {
    let pixels = shineIconPixelSize(reference)
    let s = CGFloat(pixels)
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB), let ctx = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        return reference
    }
    let rect = CGRect(x: 0, y: 0, width: s, height: s)
    let body = CGPath(roundedRect: rect, cornerWidth: s * 0.225, cornerHeight: s * 0.225, transform: nil)
    ctx.addPath(body)
    ctx.clip()
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: [NSColor(red: 0.62, green: 0.42, blue: 1.0, alpha: 1).cgColor, NSColor(red: 0.36, green: 0.30, blue: 0.92, alpha: 1).cgColor] as CFArray, locations: [0, 1]) {
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0), options: [])
    }
    ctx.setFillColor(NSColor.white.cgColor)
    let horn = CGMutablePath()
    horn.move(to: CGPoint(x: s * 0.24, y: s * 0.42))
    horn.addLine(to: CGPoint(x: s * 0.40, y: s * 0.42))
    horn.addLine(to: CGPoint(x: s * 0.70, y: s * 0.26))
    horn.addLine(to: CGPoint(x: s * 0.70, y: s * 0.74))
    horn.addLine(to: CGPoint(x: s * 0.40, y: s * 0.58))
    horn.addLine(to: CGPoint(x: s * 0.24, y: s * 0.58))
    horn.closeSubpath()
    ctx.addPath(horn)
    ctx.fillPath()
    ctx.fill(CGRect(x: s * 0.31, y: s * 0.26, width: s * 0.09, height: s * 0.17))
    ctx.addPath(fourPointStar(center: CGPoint(x: s * 0.80, y: s * 0.72), radius: s * 0.10, waist: 0.2))
    ctx.fillPath()
    return ctx.makeImage() ?? reference
}
