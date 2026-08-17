import SwiftUI
import UIKit

enum StampField: String, CaseIterable, Identifiable, Codable {
    case address, date, gps, altitude, compass, weather, map, custom, logo
    var id: String { rawValue }

    var title: String {
        switch self {
        case .address: return NSLocalizedString("Địa chỉ", comment: "")
        case .date: return NSLocalizedString("Ngày & giờ", comment: "")
        case .gps: return NSLocalizedString("Tọa độ GPS", comment: "")
        case .altitude: return NSLocalizedString("Độ cao", comment: "")
        case .compass: return NSLocalizedString("La bàn", comment: "")
        case .weather: return NSLocalizedString("Thời tiết", comment: "")
        case .map: return NSLocalizedString("Bản đồ", comment: "")
        case .custom: return NSLocalizedString("Chữ tùy chỉnh", comment: "")
        case .logo: return NSLocalizedString("Logo", comment: "")
        }
    }

    var icon: String {
        switch self {
        case .address: return "location.fill"
        case .date: return "calendar"
        case .gps: return "mappin.and.ellipse"
        case .altitude: return "mountain.2.fill"
        case .compass: return "safari.fill"
        case .weather: return "cloud.sun.fill"
        case .map: return "map.fill"
        case .custom: return "textformat"
        case .logo: return "photo"
        }
    }
}

struct StampStyle: Codable, Equatable {
    var enabled: [StampField: Bool] = Dictionary(uniqueKeysWithValues:
        StampField.allCases.map { ($0, [.address, .date, .gps, .weather, .map].contains($0)) }
    )
    var customText = "GeoStamp"
    var fontSize: Double = 22
    var opacity: Double = 0.72
    var cornerRadius: Double = 18
    var x: Double = 0.5
    var y: Double = 0.80
    var accentHex = "#FFD400"
    var useCustomAddress = false
    var customAddress = ""
    var fontDesign = "default"
    var isTiled = false
    var customFields: [String] = []
    var layoutType = "classic"

    func isEnabled(_ field: StampField) -> Bool { enabled[field] ?? false }
}

struct SavedTemplate: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var style: StampStyle
}

final class StampStore: ObservableObject {
    @Published var style = StampStyle()
    @Published var templates: [SavedTemplate] = []
    @Published var logo: UIImage?

    private let key = "timemark.templates.v5"

    init() {
        loadFromLocalAndCloud()
        
        // Listen for iCloud external changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ubiquitousKeyValueStoreDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    @objc private func ubiquitousKeyValueStoreDidChange(notification: Notification) {
        DispatchQueue.main.async {
            self.loadFromLocalAndCloud()
        }
    }
    
    private func loadFromLocalAndCloud() {
        // Try cloud first
        if let cloudData = NSUbiquitousKeyValueStore.default.data(forKey: key),
           let cloudValues = try? JSONDecoder().decode([SavedTemplate].self, from: cloudData) {
            self.templates = cloudValues
            // Keep local cached in sync
            UserDefaults.standard.set(cloudData, forKey: key)
            return
        }
        
        // Fallback to local user defaults
        if let localData = UserDefaults.standard.data(forKey: key),
           let localValues = try? JSONDecoder().decode([SavedTemplate].self, from: localData) {
            self.templates = localValues
        }
    }

    func saveTemplate(name: String) {
        templates.append(SavedTemplate(name: name, style: style))
        persist()
    }

    func deleteTemplate(_ template: SavedTemplate) {
        templates.removeAll { $0.id == template.id }
        persist()
    }

    func load(_ template: SavedTemplate) {
        style = template.style
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(templates) {
            // Save locally
            UserDefaults.standard.set(data, forKey: key)
            // Save to iCloud
            NSUbiquitousKeyValueStore.default.set(data, forKey: key)
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }

    func loadLogo(_ image: UIImage?) {
        logo = image
        style.enabled[.logo] = image != nil
    }
}

import SwiftUI

extension Font {
    static func customFont(size: CGFloat, weight: Font.Weight = .semibold, designName: String) -> Font {
        let design: Font.Design
        switch designName {
        case "monospaced": design = .monospaced
        case "rounded": design = .rounded
        case "serif": design = .serif
        default: design = .default
        }
        return Font.system(size: size, weight: weight, design: design)
    }
}

extension Double {
    var cardinalDirection: String {
        let directions = [
            NSLocalizedString("Bắc", comment: ""),
            NSLocalizedString("Đông Bắc", comment: ""),
            NSLocalizedString("Đông", comment: ""),
            NSLocalizedString("Đông Nam", comment: ""),
            NSLocalizedString("Nam", comment: ""),
            NSLocalizedString("Tây Nam", comment: ""),
            NSLocalizedString("Tây", comment: ""),
            NSLocalizedString("Tây Bắc", comment: "")
        ]
        let index = Int((self + 22.5) / 45.0) & 7
        return directions[index]
    }
}
