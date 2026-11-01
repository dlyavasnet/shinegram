import Cocoa
import TGUIKit
import TelegramCore
import Localization
import TelegramTheme

private func ghostGlyph(color: NSColor, enabled: Bool, scale: CGFloat) -> CGImage? {
    let size: CGFloat = 22
    let pixels = Int(size * scale)
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB), let ctx = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        return nil
    }
    ctx.scaleBy(x: scale, y: scale)
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

    let left: CGFloat = 4.5
    let right: CGFloat = 17.5
    let bottom: CGFloat = 3.5
    let width = right - left
    let headCenter = CGPoint(x: size / 2, y: 12.5)
    let radius = width / 2

    let body = CGMutablePath()
    body.move(to: CGPoint(x: left, y: bottom))
    body.addLine(to: CGPoint(x: left, y: headCenter.y))
    body.addArc(center: headCenter, radius: radius, startAngle: .pi, endAngle: 0, clockwise: true)
    body.addLine(to: CGPoint(x: right, y: bottom))
    let waves = 3
    let step = width / CGFloat(waves)
    for i in 0..<waves {
        let x1 = right - CGFloat(i) * step
        let x2 = x1 - step
        body.addQuadCurve(to: CGPoint(x: x2, y: bottom), control: CGPoint(x: (x1 + x2) / 2, y: bottom + 2.6))
    }
    body.closeSubpath()

    let eyeLeft = CGRect(x: headCenter.x - 3.6, y: headCenter.y - 1.6, width: 2.4, height: 3.2)
    let eyeRight = CGRect(x: headCenter.x + 1.2, y: headCenter.y - 1.6, width: 2.4, height: 3.2)

    if enabled {
        ctx.addPath(body)
        ctx.setFillColor(color.cgColor)
        ctx.fillPath()
        ctx.setBlendMode(.clear)
        ctx.fillEllipse(in: eyeLeft)
        ctx.fillEllipse(in: eyeRight)
        ctx.setBlendMode(.normal)
    } else {
        ctx.addPath(body)
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(1.5)
        ctx.setLineJoin(.round)
        ctx.strokePath()
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: eyeLeft)
        ctx.fillEllipse(in: eyeRight)
    }
    return ctx.makeImage()
}

final class ShineGhostButton : Control {
    private let imageView = ImageView()
    private var observer: NSObjectProtocol?
    private var currentEnabled: Bool?

    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(imageView)
        imageView.isEventLess = true
        self.scaleOnClick = true
        self.set(handler: { _ in
            ShineSettings.setGhostMode(!ShineSettings.isGhostModeEnabled)
        }, for: .Click)
        observer = NotificationCenter.default.addObserver(forName: ShineSettings.didChangeNotification, object: nil, queue: .main, using: { [weak self] _ in
            self?.update(animated: true)
        })
        update(animated: false)
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        currentEnabled = nil
        update(animated: false)
    }

    override func updateLocalizationAndTheme(theme: PresentationTheme) {
        super.updateLocalizationAndTheme(theme: theme)
        currentEnabled = nil
        update(animated: false)
    }

    func update(animated: Bool) {
        let enabled = ShineSettings.isGhostModeEnabled
        let changed = currentEnabled != nil && currentEnabled != enabled
        if currentEnabled == enabled {
            return
        }
        currentEnabled = enabled
        let color = enabled ? theme.colors.accentIcon : theme.colors.grayIcon
        let scale = max(1, window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2)
        if let image = ghostGlyph(color: color, enabled: enabled, scale: scale) {
            imageView.image = image
            imageView.setFrameSize(NSMakeSize(CGFloat(image.width) / scale, CGFloat(image.height) / scale))
        }
        self.toolTip = enabled ? shineLocalized("Ghost Mode: On", "Режим призрака: включён") : shineLocalized("Ghost Mode: Off", "Режим призрака: выключен")
        self.setAccessibilityLabel(self.toolTip)
        if animated && changed {
            imageView.layer?.animateScaleSpring(from: 0.6, to: 1, duration: 0.3)
        }
        needsLayout = true
    }

    override func layout() {
        super.layout()
        imageView.center()
    }
}
