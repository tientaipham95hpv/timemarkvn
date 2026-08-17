import Foundation

enum WeatherService {
    static func load(latitude: Double, longitude: Double,
                     completion: @escaping (String, String) -> Void) {
        let url = URL(string:
            "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,weather_code"
        )!

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let current = json["current"] as? [String: Any],
                  let temp = current["temperature_2m"] as? Double,
                  let code = current["weather_code"] as? Int else {
                completion("--°C", NSLocalizedString("Chưa có dữ liệu", comment: ""))
                return
            }

            let text: String
            switch code {
            case 0: text = NSLocalizedString("Trời quang", comment: "")
            case 1...3: text = NSLocalizedString("Có mây", comment: "")
            case 45...48: text = NSLocalizedString("Sương mù", comment: "")
            case 51...67: text = NSLocalizedString("Mưa", comment: "")
            case 71...77: text = NSLocalizedString("Tuyết", comment: "")
            case 80...82: text = NSLocalizedString("Mưa rào", comment: "")
            case 95...99: text = NSLocalizedString("Dông", comment: "")
            default: text = NSLocalizedString("Thời tiết", comment: "")
            }

            DispatchQueue.main.async {
                completion(String(format: "%.0f°C", temp), text)
            }
        }.resume()
    }
}
