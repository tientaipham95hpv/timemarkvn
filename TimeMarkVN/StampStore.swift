import SwiftUI
import UIKit

enum StampField: String, CaseIterable, Identifiable, Codable {
    case address, date, gps, altitude, compass, weather, map, custom, logo
    var id: String { rawValue }

    var title: String {
        switch self {
        case .address: return "Địa chỉ"
        case .date: return "Ngày & giờ"
        case .gps: return "Tọa độ GPS"
        case .altitude: return "Độ cao"
        case .compass: return "La bàn"
        case .weather: return "Thời tiết"
        case .map: return "Bản đồ"
        case .custom: return "Chữ tùy chỉnh"
        case .logo: return "Logo"
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
    var customText = "TimeMark VN"
    var fontSize: Double = 22
    var opacity: Double = 0.72
    var cornerRadius: Double = 18
    var x: Double = 0.5
    var y: Double = 0.80
    var accentHex = "#FFD400"

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
        if let data = UserDefaults.standard.data(forKey: key),
           let value = try? JSONDecoder().decode([SavedTemplate].self, from: data) {
            templates = value
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
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func loadLogo(_ image: UIImage?) {
        logo = image
        style.enabled[.logo] = image != nil
    }
}
