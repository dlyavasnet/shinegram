import AppKit
struct R { var s: UInt64; mutating func n() -> CGFloat { s = s &* 6364136223846793005 &+ 1442695040888963407; return CGFloat(Double((s >> 33) & 0x7fffffff) / Double(0x7fffffff)) } }
func star(_ c: CGPoint, _ r: CGFloat, _ w: CGFloat = 0.17) -> CGPath {
    let p = CGMutablePath()
    let t = (0..<4).map { i -> CGPoint in let a = CGFloat(i) * .pi/2 + .pi/2; return CGPoint(x: c.x + cos(a)*r, y: c.y + sin(a)*r) }
    p.move(to: t[0])
    for i in 0..<4 { let a = CGFloat(i) * .pi/2 + .pi/2 + .pi/4; p.addQuadCurve(to: t[(i+1)%4], control: CGPoint(x: c.x + cos(a)*r*w, y: c.y + sin(a)*r*w)) }
    p.closeSubpath(); return p
}
func render(scale: CGFloat, out: String) {
    let W: CGFloat = 640, H: CGFloat = 420
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(data: nil, width: Int(W*scale), height: Int(H*scale), bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.scaleBy(x: scale, y: scale)
    let bg = CGGradient(colorsSpace: cs, colors: [NSColor(red: 0.08, green: 0.07, blue: 0.14, alpha: 1).cgColor, NSColor(red: 0.01, green: 0.01, blue: 0.03, alpha: 1).cgColor] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(bg, startCenter: CGPoint(x: W/2, y: H*0.55), startRadius: 0, endCenter: CGPoint(x: W/2, y: H*0.55), endRadius: 460, options: [.drawsAfterEndLocation])
    for (x, col) in [(170.0, NSColor(red: 0.55, green: 0.6, blue: 1, alpha: 0.22)), (470.0, NSColor(red: 0.7, green: 0.45, blue: 1, alpha: 0.14))] {
        let g = CGGradient(colorsSpace: cs, colors: [col.cgColor, col.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 1])!
        ctx.drawRadialGradient(g, startCenter: CGPoint(x: x, y: 200), startRadius: 0, endCenter: CGPoint(x: x, y: 200), endRadius: 170, options: [])
    }
    var r = R(s: 0x53484e)
    for _ in 0..<220 {
        let x = r.n()*W, y = r.n()*H, rad = 0.4 + r.n()*r.n()*1.9, a = 0.15 + r.n()*0.6
        ctx.setFillColor(NSColor(red: 0.85, green: 0.88, blue: 1, alpha: a).cgColor)
        ctx.fillEllipse(in: CGRect(x: x-rad, y: y-rad, width: rad*2, height: rad*2))
    }
    for (x, y, s) in [(60.0, 360.0, 9.0), (590.0, 70.0, 11.0), (560.0, 365.0, 6.0), (95.0, 60.0, 6.0), (330.0, 385.0, 5.0)] {
        ctx.saveGState(); ctx.setShadow(offset: .zero, blur: 8, color: NSColor(red: 0.7, green: 0.75, blue: 1, alpha: 0.9).cgColor)
        ctx.addPath(star(CGPoint(x: x, y: y), s)); ctx.setFillColor(NSColor(white: 1, alpha: 0.9).cgColor); ctx.fillPath(); ctx.restoreGState()
    }
    let arrow = CGMutablePath()
    arrow.move(to: CGPoint(x: 262, y: 200)); arrow.addQuadCurve(to: CGPoint(x: 372, y: 200), control: CGPoint(x: 317, y: 228))
    ctx.saveGState(); ctx.setShadow(offset: .zero, blur: 10, color: NSColor(red: 0.6, green: 0.65, blue: 1, alpha: 0.9).cgColor)
    ctx.setStrokeColor(NSColor(white: 1, alpha: 0.85).cgColor); ctx.setLineWidth(3); ctx.setLineCap(.round); ctx.setLineDash(phase: 0, lengths: [2, 9])
    ctx.addPath(arrow); ctx.strokePath(); ctx.setLineDash(phase: 0, lengths: [])
    let head = CGMutablePath(); head.move(to: CGPoint(x: 360, y: 213)); head.addLine(to: CGPoint(x: 376, y: 199)); head.addLine(to: CGPoint(x: 358, y: 190))
    ctx.addPath(head); ctx.strokePath(); ctx.restoreGState()
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    let p = NSMutableParagraphStyle(); p.alignment = .center
    let titleShadow = NSShadow(); titleShadow.shadowBlurRadius = 14; titleShadow.shadowColor = NSColor(red: 0.6, green: 0.65, blue: 1, alpha: 0.9)
    NSAttributedString(string: "ShineGram", attributes: [.font: NSFont.systemFont(ofSize: 34, weight: .bold), .foregroundColor: NSColor.white, .paragraphStyle: p, .shadow: titleShadow]).draw(in: CGRect(x: 0, y: 330, width: W, height: 46))
    NSAttributedString(string: "Перетащи ShineGram в папку «Программы»", attributes: [.font: NSFont.systemFont(ofSize: 14, weight: .medium), .foregroundColor: NSColor(white: 1, alpha: 0.7), .paragraphStyle: p]).draw(in: CGRect(x: 0, y: 302, width: W, height: 22))
    NSAttributedString(string: "t.me/dlyavasnet", attributes: [.font: NSFont.systemFont(ofSize: 12, weight: .regular), .foregroundColor: NSColor(red: 0.75, green: 0.78, blue: 1, alpha: 0.65), .paragraphStyle: p]).draw(in: CGRect(x: 0, y: 22, width: W, height: 18))
    NSGraphicsContext.restoreGraphicsState()
    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!); rep.size = NSSize(width: W, height: H)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
}
render(scale: 1, out: CommandLine.arguments[1])
render(scale: 2, out: CommandLine.arguments[2])
