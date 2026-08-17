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
            let boxW = w * 0.90
            let boxH = min(h * 0.32, 380)
            let x = (w - boxW) / 2
            let y = max(20, h * style.y - boxH / 2)
            let box = CGRect(x: x, y: y, width: boxW, height: boxH)

            UIColor.black.withAlphaComponent(style.opacity).setFill()
            UIBezierPath(roundedRect: box, cornerRadius: style.cornerRadius).fill()

            var lines: [String] = []
            if style.isEnabled(.address) { lines.append("📍 " + location.address) }
            if style.isEnabled(.date) {
                lines.append(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))
            }
            if style.isEnabled(.gps), let c = location.coordinate {
                lines.append(String(format: "%.6f° N   %.6f° E", c.latitude, c.longitude))
            }
            if style.isEnabled(.altitude) {
                lines.append(String(format: NSLocalizedString("Độ cao: %.0f m", comment: ""), location.altitude))
            }
            if style.isEnabled(.compass) {
                lines.append(String(format: NSLocalizedString("La bàn: %.0f°", comment: ""), location.heading))
            }
            if style.isEnabled(.weather) {
                lines.append("☁️ \(location.temperature) • \(location.weatherText)")
            }
            if style.isEnabled(.custom) { lines.append(style.customText) }

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: style.fontSize, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            lines.joined(separator: "\n").draw(in: box.insetBy(dx: 20, dy: 18), withAttributes: attrs)

            if style.isEnabled(.map), let map {
                let size = min(box.width * 0.28, 120)
                map.draw(in: CGRect(x: box.maxX - size - 16, y: box.maxY - size - 16,
                                    width: size, height: size))
            }

            if style.isEnabled(.logo), let logo {
                let size = min(72, box.width * 0.18)
                logo.draw(in: CGRect(x: box.maxX - size - 18, y: box.minY + 12,
                                     width: size, height: size))
            }
        }
    }
}
