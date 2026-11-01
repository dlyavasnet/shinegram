import Cocoa
import Security

public struct ShineBadge: Equatable {
    public enum Icon: Equatable {
        case emoji(String)
        case symbol(String)
        case image(Data)
    }

    public let id: Int
    public let name: String
    public let color: NSColor
    public let shape: String
    public let icon: Icon

    public static func ==(lhs: ShineBadge, rhs: ShineBadge) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name && lhs.shape == rhs.shape && lhs.icon == rhs.icon && lhs.color.hexString == rhs.color.hexString
    }
}

private extension NSColor {
    var hexString: String {
        guard let rgb = usingColorSpace(.sRGB) else {
            return ""
        }
        return String(format: "%02x%02x%02x", Int(rgb.redComponent * 255), Int(rgb.greenComponent * 255), Int(rgb.blueComponent * 255))
    }
}

public final class ShineBadges {
    public static let shared = ShineBadges()

    private static let feedURL = URL(string: "https://unt1tled.online/shinegram/badges.json")!
    private static let publicKeyX963 = Data(base64Encoded: "BFHXT296yMjfdXs7YIIFAWWqWe6TmclE/gG/wsejxeLzAYmmCabIdgl9p3f30okJZYc7Y74yojwnwYcLJwIhHFc=")
    private static let maxFeedBytes = 2 * 1024 * 1024
    private static let maxImageBytes = 64 * 1024
    private static let refreshInterval: TimeInterval = 30 * 60

    private let queue = DispatchQueue(label: "app.shinegram.badges")
    private var users: [Int64: [ShineBadge]] = [:]
    private var issuedAt: Int64 = 0
    private var lastAttempt: Date?
    private var loading = false
    private let lock = NSLock()

    private var cacheURL: URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return base.appendingPathComponent("ShineGram/badges-feed.json")
    }

    private init() {
        if let url = cacheURL, let data = try? Data(contentsOf: url), data.count <= ShineBadges.maxFeedBytes {
            _ = apply(envelope: data, fromCache: true)
        }
    }

    public func badges(for userId: Int64) -> [ShineBadge] {
        refreshIfNeeded()
        lock.lock()
        defer { lock.unlock() }
        return users[userId] ?? []
    }

    public func refreshIfNeeded() {
        queue.async { [weak self] in
            guard let self, !self.loading else {
                return
            }
            if let lastAttempt = self.lastAttempt, Date().timeIntervalSince(lastAttempt) < ShineBadges.refreshInterval {
                return
            }
            self.lastAttempt = Date()
            self.loading = true
            self.fetch()
        }
    }

    private func fetch() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 30
        configuration.httpCookieAcceptPolicy = .never
        configuration.httpShouldSetCookies = false
        configuration.urlCache = nil
        let session = URLSession(configuration: configuration)
        var request = URLRequest(url: ShineBadges.feedURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let task = session.dataTask(with: request) { [weak self] data, response, _ in
            guard let self else {
                return
            }
            self.queue.async {
                self.loading = false
                guard let http = response as? HTTPURLResponse, http.statusCode == 200, http.url?.host == ShineBadges.feedURL.host, let data, data.count <= ShineBadges.maxFeedBytes else {
                    return
                }
                if self.apply(envelope: data, fromCache: false), let url = self.cacheURL {
                    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                    try? data.write(to: url, options: .atomic)
                }
            }
        }
        task.resume()
        session.finishTasksAndInvalidate()
    }

    private func verify(payload: Data, signature: Data) -> Bool {
        guard let keyData = ShineBadges.publicKeyX963, keyData.count == 65 else {
            return false
        }
        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits: 256,
        ]
        guard let key = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, nil) else {
            return false
        }
        return SecKeyVerifySignature(key, .ecdsaSignatureMessageX962SHA256, payload as CFData, signature as CFData, nil)
    }

    private func apply(envelope data: Data, fromCache: Bool) -> Bool {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let payloadString = object["payload"] as? String, let signatureString = object["sig"] as? String,
              let payload = Data(base64Encoded: payloadString), let signature = Data(base64Encoded: signatureString),
              verify(payload: payload, signature: signature),
              let feed = try? JSONSerialization.jsonObject(with: payload) as? [String: Any],
              (feed["v"] as? NSNumber)?.intValue == 1,
              let issued = (feed["iat"] as? NSNumber)?.int64Value,
              let expires = (feed["exp"] as? NSNumber)?.int64Value else {
            return false
        }
        let now = Int64(Date().timeIntervalSince1970)
        if expires < now {
            if fromCache {
                lock.lock()
                users = [:]
                lock.unlock()
            }
            return false
        }
        lock.lock()
        let currentIssued = issuedAt
        lock.unlock()
        if issued < currentIssued {
            return false
        }

        var definitions: [Int: ShineBadge] = [:]
        for raw in (feed["badges"] as? [[String: Any]] ?? []).prefix(500) {
            guard let id = (raw["id"] as? NSNumber)?.intValue else {
                continue
            }
            let name = String((raw["name"] as? String ?? "").prefix(64))
            let color = shineColor(raw["color"] as? String)
            let shape = String((raw["shape"] as? String ?? "circle").prefix(16))
            var icon: ShineBadge.Icon = .symbol("star.fill")
            if let rawIcon = raw["icon"] as? [String: Any], let kind = rawIcon["t"] as? String, let value = rawIcon["v"] as? String {
                switch kind {
                case "emoji":
                    if !value.isEmpty {
                        icon = .emoji(String(value.prefix(8)))
                    }
                case "symbol":
                    icon = .symbol(shineSymbol(value))
                case "image":
                    if let image = Data(base64Encoded: value), image.count <= ShineBadges.maxImageBytes, shineIsSafeImage(image) {
                        icon = .image(image)
                    }
                default:
                    break
                }
            }
            definitions[id] = ShineBadge(id: id, name: name, color: color, shape: shape, icon: icon)
        }

        var result: [Int64: [ShineBadge]] = [:]
        for (key, value) in (feed["users"] as? [String: Any] ?? [:]) {
            guard let userId = Int64(key), userId > 0, let ids = value as? [NSNumber] else {
                continue
            }
            let badges = ids.prefix(16).compactMap { definitions[$0.intValue] }
            if !badges.isEmpty {
                result[userId] = badges
            }
        }

        lock.lock()
        users = result
        issuedAt = issued
        lock.unlock()
        return true
    }
}

private func shineColor(_ string: String?) -> NSColor {
    let fallback = NSColor(srgbRed: 0.42, green: 0.42, blue: 0.45, alpha: 1)
    guard var hex = string?.trimmingCharacters(in: .whitespaces), hex.hasPrefix("#") else {
        return fallback
    }
    hex.removeFirst()
    guard hex.count == 6, let value = UInt32(hex, radix: 16) else {
        return fallback
    }
    return NSColor(srgbRed: CGFloat((value >> 16) & 0xff) / 255, green: CGFloat((value >> 8) & 0xff) / 255, blue: CGFloat(value & 0xff) / 255, alpha: 1)
}

private func shineIsSafeImage(_ data: Data) -> Bool {
    let bytes = [UInt8](data.prefix(12))
    if bytes.count >= 8 && bytes[0..<8] == [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a] {
        return true
    }
    if bytes.count >= 3 && bytes[0..<3] == [0xff, 0xd8, 0xff] {
        return true
    }
    if bytes.count >= 12 && bytes[0..<4] == [0x52, 0x49, 0x46, 0x46] && bytes[8..<12] == [0x57, 0x45, 0x42, 0x50] {
        return true
    }
    if bytes.count >= 6 && (bytes[0..<6] == [0x47, 0x49, 0x46, 0x38, 0x39, 0x61] || bytes[0..<6] == [0x47, 0x49, 0x46, 0x38, 0x37, 0x61]) {
        return true
    }
    return false
}

private let shineSymbolMap: [String: String] = [
    "verified": "checkmark.seal.fill",
    "workspace_premium": "rosette",
    "star": "star.fill",
    "grade": "star.fill",
    "favorite": "heart.fill",
    "bolt": "bolt.fill",
    "diamond": "suit.diamond.fill",
    "shield": "shield.fill",
    "security": "shield.fill",
    "code": "chevron.left.forwardslash.chevron.right",
    "terminal": "terminal.fill",
    "brush": "paintbrush.fill",
    "palette": "paintpalette.fill",
    "music_note": "music.note",
    "mic": "mic.fill",
    "sports_esports": "gamecontroller.fill",
    "rocket_launch": "airplane",
    "local_fire_department": "flame.fill",
    "whatshot": "flame.fill",
    "emoji_events": "trophy.fill",
    "military_tech": "medal.fill",
    "crown": "crown.fill",
    "pets": "pawprint.fill",
    "support_agent": "headphones",
    "build": "wrench.and.screwdriver.fill",
    "handyman": "hammer.fill",
    "auto_awesome": "sparkles",
    "celebration": "party.popper.fill",
    "school": "graduationcap.fill",
    "public": "globe",
    "camera": "camera.fill",
    "photo_camera": "camera.fill",
    "videocam": "video.fill",
    "key": "key.fill",
    "lock": "lock.fill",
    "visibility": "eye.fill",
    "science": "flask.fill",
    "bug_report": "ant.fill",
    "admin_panel_settings": "person.badge.shield.checkmark.fill",
    "person": "person.fill",
    "group": "person.2.fill",
    "smart_toy": "cpu",
    "cube": "cube.fill",
    "spinner": "circle.dashed",
    "spinner4": "circle.dashed",
]

private func shineSymbol(_ name: String) -> String {
    return shineSymbolMap[name] ?? "star.fill"
}

private func shineShapePath(_ shape: String, in rect: CGRect) -> CGPath {
    let path = CGMutablePath()
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let r = min(rect.width, rect.height) / 2
    func polygon(_ count: Int, rotation: CGFloat, radius: CGFloat) {
        for i in 0..<count {
            let angle = rotation + CGFloat(i) * 2 * .pi / CGFloat(count)
            let point = CGPoint(x: c.x + cos(angle) * radius, y: c.y + sin(angle) * radius)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
    }
    switch shape {
    case "square":
        path.addRoundedRect(in: rect.insetBy(dx: r * 0.08, dy: r * 0.08), cornerWidth: r * 0.35, cornerHeight: r * 0.35)
    case "hexagon":
        polygon(6, rotation: .pi / 6, radius: r)
    case "octagon":
        polygon(8, rotation: .pi / 8, radius: r)
    case "diamond":
        polygon(4, rotation: .pi / 2, radius: r)
    case "shield":
        path.move(to: CGPoint(x: c.x, y: rect.minY))
        path.addCurve(to: CGPoint(x: rect.minX + r * 0.1, y: rect.maxY - r * 0.35), control1: CGPoint(x: c.x - r * 0.55, y: rect.minY + r * 0.25), control2: CGPoint(x: rect.minX + r * 0.1, y: c.y))
        path.addLine(to: CGPoint(x: c.x, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - r * 0.1, y: rect.maxY - r * 0.35))
        path.addCurve(to: CGPoint(x: c.x, y: rect.minY), control1: CGPoint(x: rect.maxX - r * 0.1, y: c.y), control2: CGPoint(x: c.x + r * 0.55, y: rect.minY + r * 0.25))
        path.closeSubpath()
    case "seal":
        let points = 24
        for i in 0..<points {
            let angle = CGFloat(i) * 2 * .pi / CGFloat(points)
            let radius = i % 2 == 0 ? r : r * 0.86
            let point = CGPoint(x: c.x + cos(angle) * radius, y: c.y + sin(angle) * radius)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
    case "star":
        for i in 0..<10 {
            let angle = -CGFloat.pi / 2 + CGFloat(i) * .pi / 5
            let radius = i % 2 == 0 ? r : r * 0.5
            let point = CGPoint(x: c.x + cos(angle) * radius, y: c.y - sin(angle) * radius)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
    default:
        path.addEllipse(in: rect)
    }
    return path
}

private func shineInk(for color: NSColor) -> NSColor {
    guard let rgb = color.usingColorSpace(.sRGB) else {
        return .white
    }
    func lin(_ v: CGFloat) -> CGFloat {
        return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
    }
    let luminance = 0.2126 * lin(rgb.redComponent) + 0.7152 * lin(rgb.greenComponent) + 0.0722 * lin(rgb.blueComponent)
    return luminance > 0.42 ? NSColor(srgbRed: 0.04, green: 0.04, blue: 0.05, alpha: 1) : .white
}

public func shineBadgeImage(_ badge: ShineBadge, size: CGFloat, scale: CGFloat) -> CGImage? {
    let pixels = Int(size * scale)
    guard pixels > 0, let colorSpace = CGColorSpace(name: CGColorSpace.sRGB), let ctx = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        return nil
    }
    ctx.scaleBy(x: scale, y: scale)
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let shape = shineShapePath(badge.shape, in: rect.insetBy(dx: 0.5, dy: 0.5))
    ctx.addPath(shape)
    ctx.setFillColor(badge.color.cgColor)
    ctx.fillPath()

    let ink = shineInk(for: badge.color)
    let inner = rect.insetBy(dx: size * 0.24, dy: size * 0.24)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    switch badge.icon {
    case let .emoji(text):
        let font = NSFont.systemFont(ofSize: size * 0.5)
        let attributed = NSAttributedString(string: text, attributes: [.font: font])
        let bounds = attributed.size()
        attributed.draw(at: NSPoint(x: rect.midX - bounds.width / 2, y: rect.midY - bounds.height / 2))
    case let .symbol(name):
        if #available(macOS 11.0, *), let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil) {
            let configured = symbol.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: size * 0.5, weight: .semibold)) ?? symbol
            let tinted = NSImage(size: configured.size, flipped: false) { drawRect in
                configured.draw(in: drawRect)
                ink.set()
                drawRect.fill(using: .sourceAtop)
                return true
            }
            let aspect = tinted.size.width / max(1, tinted.size.height)
            var target = inner
            if aspect > 1 {
                target.size.height = inner.width / aspect
            } else {
                target.size.width = inner.height * aspect
            }
            target.origin = CGPoint(x: rect.midX - target.width / 2, y: rect.midY - target.height / 2)
            tinted.draw(in: target)
        } else {
            ctx.addPath(shineShapePath("star", in: inner))
            ctx.setFillColor(ink.cgColor)
            ctx.fillPath()
        }
    case let .image(data):
        if let image = NSImage(data: data) {
            ctx.saveGState()
            ctx.addPath(shape)
            ctx.clip()
            image.draw(in: rect)
            ctx.restoreGState()
        }
    }
    NSGraphicsContext.restoreGraphicsState()
    return ctx.makeImage()
}
