import UIKit

enum StampRenderer {
    static func render(image: UIImage,
                       location: TelemetryData,
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
                let watermarkText = style.customText.isEmpty ? "GeoStamp" : style.customText
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
            
            if style.isEnabled(.address) {
                let offlineTag = location.isOffline ? " [Offline]" : ""
                lines.append("📍 " + tag + addr + offlineTag)
            }
            if style.isEnabled(.date) {
                if let gpsTime = location.gpsTimestamp {
                    let displayDate = location.isTimeSpoofed ? gpsTime : Date()
                    let dateStr = DateFormatter.localizedString(from: displayDate, dateStyle: .medium, timeStyle: .medium)
                    let tag = location.isTimeSpoofed ? " [⚠️ \(NSLocalizedString("Giờ vệ tinh", comment: ""))]" : " [\(NSLocalizedString("Giờ vệ tinh", comment: ""))]"
                    lines.append(dateStr + tag)
                } else {
                    let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
                    lines.append(dateStr + " [⚠️ \(NSLocalizedString("Giờ thiết bị", comment: ""))]")
                }
            }
            if style.isEnabled(.gps), let c = location.coordinate {
                let gpsStr = String(format: "%.6f° N   %.6f° E (±%.1fm)", c.latitude, c.longitude, location.accuracy)
                if location.isGpsSimulated {
                    lines.append(gpsStr + " [⚠️ " + NSLocalizedString("Giả lập", comment: "") + "]")
                } else {
                    lines.append(gpsStr)
                }
            }
            if style.isEnabled(.altitude) {
                lines.append(String(format: NSLocalizedString("Độ cao: %.0f m", comment: ""), location.altitude))
            }
            if style.isEnabled(.compass) {
                lines.append(String(format: NSLocalizedString("La bàn: %.0f° %@", comment: ""), location.heading, location.heading.cardinalDirection))
            }
            if style.isEnabled(.weather) {
                let offlineText = location.isOffline ? " [Offline]" : ""
                lines.append("☁️ \(location.temperature) • \(location.weatherText)\(offlineText)")
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
            
            let accentColor = UIColor(hex: style.accentHex) ?? UIColor.yellow

            if style.layoutType == "minimalist" {
                let joinedText = lines.joined(separator: "   •   ")
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.white
                ]
                let textSize = joinedText.size(withAttributes: attrs)
                let drawX = max(20, min(w - textSize.width - 20, (w - textSize.width) * style.x))
                let drawY = max(20, min(h - textSize.height - 20, (h - textSize.height) * style.y))
                let drawRect = CGRect(x: drawX, y: drawY, width: textSize.width, height: textSize.height)
                
                let shadowAttrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.black.withAlphaComponent(0.6)
                ]
                joinedText.draw(in: drawRect.offsetBy(dx: 2, dy: 2), withAttributes: shadowAttrs)
                joinedText.draw(in: drawRect, withAttributes: attrs)
                
            } else if style.layoutType == "badge" {
                let badgeSize: CGFloat = min(w * 0.35, 360)
                let bx = max(20, min(w - badgeSize - 20, (w - badgeSize) * style.x))
                let by = max(20, min(h - badgeSize - 20, (h - badgeSize) * style.y))
                let badgeBox = CGRect(x: bx, y: by, width: badgeSize, height: badgeSize)
                
                UIColor.black.withAlphaComponent(style.opacity).setFill()
                UIBezierPath(ovalIn: badgeBox).fill()
                
                accentColor.setStroke()
                let borderPath = UIBezierPath(ovalIn: badgeBox.insetBy(dx: 6, dy: 6))
                borderPath.lineWidth = 4
                borderPath.stroke()
                
                let badgeFont = UIFont(descriptor: fontDescriptor, size: fontSize * 0.72)
                let badgeLineHeight = "Test".size(withAttributes: [.font: badgeFont]).height
                let innerContentHeight = CGFloat(min(lines.count, 4)) * badgeLineHeight + CGFloat(max(0, min(lines.count, 4) - 1)) * 4
                
                var currentY = badgeBox.midY - innerContentHeight / 2
                for line in lines.prefix(4) {
                    let isAccent = line.contains(":") || line == style.customText
                    let lineAttrs: [NSAttributedString.Key: Any] = [
                        .font: badgeFont,
                        .foregroundColor: isAccent ? accentColor : .white
                    ]
                    let size = line.size(withAttributes: lineAttrs)
                    let lineX = badgeBox.midX - min(size.width, badgeSize - 24) / 2
                    let lineRect = CGRect(x: lineX, y: currentY, width: min(size.width, badgeSize - 24), height: badgeLineHeight)
                    
                    line.draw(in: lineRect, withAttributes: lineAttrs)
                    currentY += badgeLineHeight + 4
                }
                
            } else {
                let totalTextHeight = CGFloat(lines.count) * singleLineHeight + CGFloat(max(0, lines.count - 1)) * lineSpacing
                let boxPaddingY: CGFloat = 24
                let boxPaddingX: CGFloat = 28
                
                let boxW = min(w * 0.90, max(300, w * 0.85))
                let boxH = totalTextHeight + boxPaddingY * 2
                
                let minX: CGFloat = 20
                let maxX: CGFloat = max(minX, w - boxW - 20)
                let x = max(minX, min(maxX, (w - boxW) * style.x))

                let minY: CGFloat = 20
                let maxY: CGFloat = max(minY, h - boxH - 20)
                let y = max(minY, min(maxY, (h - boxH) * style.y))
                
                let box = CGRect(x: x, y: y, width: boxW, height: boxH)

                UIColor.black.withAlphaComponent(style.opacity).setFill()
                UIBezierPath(roundedRect: box, cornerRadius: CGFloat(style.cornerRadius * 1.5)).fill()

                let textInsetBox = box.insetBy(dx: boxPaddingX, dy: boxPaddingY)
                var currentY = textInsetBox.minY
                
                for line in lines {
                    let isAccent = line.contains(":") || line == style.customText
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: isAccent ? accentColor : UIColor.white
                    ]
                    let size = line.size(withAttributes: attrs)
                    line.draw(in: CGRect(x: textInsetBox.minX, y: currentY, width: textInsetBox.width - (style.isEnabled(.map) ? 150 : 0), height: size.height), withAttributes: attrs)
                    currentY += size.height + lineSpacing
                }

                // Draw map preview if active (Classic layout only)
                if style.isEnabled(.map), let map {
                    let size = min(box.width * 0.28, box.height - boxPaddingY * 2)
                    map.draw(in: CGRect(x: box.maxX - size - boxPaddingX, y: box.minY + (box.height - size) / 2,
                                        width: size, height: size))
                }

                // Draw brand logo if active (Classic layout only)
                if style.isEnabled(.logo), let logo {
                    let size = min(72, box.width * 0.12)
                    logo.draw(in: CGRect(x: box.maxX - size - boxPaddingX, y: box.minY + 12,
                                         width: size, height: size))
                }
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
