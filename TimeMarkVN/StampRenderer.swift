import UIKit

enum StampRenderer {
    static func render(image: UIImage,
                       location: LocationManager,
                       style: StampStyle,
                       logo: UIImage?,
                       map: UIImage?) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))

            let w = image.size.width
            let h = image.size.height

            // Draw tiled/grid watermark (diagonal copyright overlay)
            if style.isTiled {
                let watermarkText = style.customText.isEmpty ? "TimeMark VN" : style.customText
                let tiledFont = UIFont.systemFont(ofSize: w * 0.024, weight: .bold)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: tiledFont,
                    .foregroundColor: UIColor.white.withAlphaComponent(0.12)
                ]
                let textRect = watermarkText.size(withAttributes: attrs)
                let spacingX = textRect.width + w * 0.15
                let spacingY = textRect.height + h * 0.15
                
                var currentX: CGFloat = 0
                while currentX < w {
                    var currentY: CGFloat = 0
                    while currentY < h {
                        if let context = UIGraphicsGetCurrentContext() {
                            context.saveGState()
                            context.translateBy(x: currentX, y: currentY)
                            context.rotate(by: -CGFloat.pi / 6)
                            watermarkText.draw(at: .zero, withAttributes: attrs)
                            context.restoreGState()
                        }
                        currentY += spacingY
                    }
                    currentX += spacingX
                }
            }
            
            // Calculate dynamic box height based on number of active fields
            var lines: [String] = []
            let addr = style.useCustomAddress ? (style.customAddress.isEmpty ? location.address : style.customAddress) : location.address
            let tag = style.useCustomAddress ? "[\(NSLocalizedString("Thủ công", comment: ""))] " : "[\(NSLocalizedString("Tự động", comment: ""))] "
            
            if style.isEnabled(.address) { lines.append("📍 " + tag + addr) }
            if style.isEnabled(.date) {
                lines.append(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))
            }
            if style.isEnabled(.gps), let c = location.coordinate {
                lines.append(String(format: "%.6f° N   %.6f° E (±%.1fm)", c.latitude, c.longitude, location.accuracy))
            }
            if style.isEnabled(.altitude) {
                lines.append(String(format: NSLocalizedString("Độ cao: %.0f m", comment: ""), location.altitude))
            }
            if style.isEnabled(.compass) {
                lines.append(String(format: NSLocalizedString("La bàn: %.0f° %@", comment: ""), location.heading, location.heading.cardinalDirection))
            }
            if style.isEnabled(.weather) {
                lines.append("☁️ \(location.temperature) • \(location.weatherText)")
            }
            if style.isEnabled(.custom) {
                lines.append(style.customText)
                for field in style.customFields {
                    if !field.isEmpty {
                        lines.append(field)
                    }
                }
            }

            let lineSpacing: CGFloat = 8
            let fontSize = style.fontSize * 1.5 // Scaling font size for output resolution
            
            var fontDescriptor = UIFont.systemFont(ofSize: fontSize, weight: .semibold).fontDescriptor
            switch style.fontDesign {
            case "monospaced":
                fontDescriptor = fontDescriptor.withDesign(.monospaced) ?? fontDescriptor
            case "rounded":
                fontDescriptor = fontDescriptor.withDesign(.rounded) ?? fontDescriptor
            case "serif":
                fontDescriptor = fontDescriptor.withDesign(.serif) ?? fontDescriptor
            default:
                fontDescriptor = fontDescriptor.withDesign(.default) ?? fontDescriptor
            }
            let font = UIFont(descriptor: fontDescriptor, size: fontSize)
            
            let singleLineHeight = "Test".size(withAttributes: [.font: font]).height
            
            let totalTextHeight = CGFloat(lines.count) * singleLineHeight + CGFloat(max(0, lines.count - 1)) * lineSpacing
            let boxPaddingY: CGFloat = 24
            let boxPaddingX: CGFloat = 28
            
            let boxW = w * 0.90
            let boxH = totalTextHeight + boxPaddingY * 2
            let x = (w - boxW) / 2
            let y = max(20, h * style.y - boxH / 2)
            let box = CGRect(x: x, y: y, width: boxW, height: boxH)

            // Draw stamp background card
            UIColor.black.withAlphaComponent(style.opacity).setFill()
            UIBezierPath(roundedRect: box, cornerRadius: CGFloat(style.cornerRadius * 1.5)).fill()

            // Draw lines sequentially
            let textInsetBox = box.insetBy(dx: boxPaddingX, dy: boxPaddingY)
            var currentY = textInsetBox.minY
            let accentColor = UIColor(hex: style.accentHex) ?? UIColor.yellow
            
            for line in lines {
                let isAccent = line.contains(":") || line == style.customText
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: isAccent ? accentColor : UIColor.white
                ]
                let size = line.size(withAttributes: attrs)
                line.draw(in: CGRect(x: textInsetBox.minX, y: currentY, width: textInsetBox.width - 150, height: size.height), withAttributes: attrs)
                currentY += size.height + lineSpacing
            }

            // Draw map preview if active
            if style.isEnabled(.map), let map {
                let size = min(box.width * 0.28, box.height - boxPaddingY * 2)
                map.draw(in: CGRect(x: box.maxX - size - boxPaddingX, y: box.minY + (box.height - size) / 2,
                                    width: size, height: size))
            }

            // Draw brand logo if active
            if style.isEnabled(.logo), let logo {
                let size = min(72, box.width * 0.12)
                logo.draw(in: CGRect(x: box.maxX - size - boxPaddingX, y: box.minY + 12,
                                     width: size, height: size))
            }
        }
    }
}

// UIColor Hex extension
extension UIColor {
    convenience init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
