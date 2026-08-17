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
                completion("--°C", "Không có dữ liệu")
                return
            }

            let text: String
            switch code {
            case 0: text = "Trời quang"
            case 1...3: text = "Có mây"
            case 45...48: text = "Sương mù"
            case 51...67: text = "Mưa"
            case 71...77: text = "Tuyết"
            case 80...82: text = "Mưa rào"
            case 95...99: text = "Dông"
            default: text = "Thời tiết"
            }

            DispatchQueue.main.async {
                completion(String(format: "%.0f°C", temp), text)
            }
        }.resume()
    }
}
