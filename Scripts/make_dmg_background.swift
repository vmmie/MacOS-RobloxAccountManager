import AppKit

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: make_dmg_background.swift <output.png>\n", stderr)
    exit(64)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let size = NSSize(width: 560, height: 320)
let image = NSImage(size: size)

image.lockFocus()

NSColor(red: 0.965, green: 0.968, blue: 0.972, alpha: 1).setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()

let arrowColor = NSColor(red: 0.28, green: 0.30, blue: 0.34, alpha: 0.55)
arrowColor.setStroke()
arrowColor.setFill()

let arrow = NSBezierPath()
arrow.lineWidth = 8
arrow.lineCapStyle = .round
arrow.move(to: NSPoint(x: 228, y: 166))
arrow.line(to: NSPoint(x: 342, y: 166))
arrow.stroke()

let arrowHead = NSBezierPath()
arrowHead.move(to: NSPoint(x: 354, y: 166))
arrowHead.line(to: NSPoint(x: 328, y: 184))
arrowHead.line(to: NSPoint(x: 328, y: 148))
arrowHead.close()
arrowHead.fill()

let text = "Drag to install"
let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 14, weight: .medium),
    .foregroundColor: NSColor.secondaryLabelColor
]
let textSize = text.size(withAttributes: attributes)
text.draw(
    at: NSPoint(x: (size.width - textSize.width) / 2, y: 64),
    withAttributes: attributes
)

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let data = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Could not render DMG background.\n", stderr)
    exit(1)
}

try data.write(to: outputURL, options: [.atomic])
