import Foundation
import SwiftUI

struct WeatherData {
    let temperature: String
    let description: String
    let iconName: String
    let highTemp: String
    let lowTemp: String
    let humidity: String
    let cityName: String

    var iconColor: Color {
        switch iconName {
        case "sun.max.fill": return .orange
        case "cloud.sun.fill": return .orange
        case "cloud.drizzle.fill", "cloud.rain.fill": return .blue
        case "cloud.bolt.rain.fill": return .purple
        case "cloud.snow.fill": return .cyan
        default: return .gray
        }
    }
}

class WeatherService {
    static let shared = WeatherService()
    private var cache: [String: (data: WeatherData, timestamp: Date)] = [:]
    private let cacheInterval: TimeInterval = 1800

    func fetchWeather(for city: String, completion: @escaping (WeatherData?) -> Void) {
        let trimmed = city.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            completion(nil)
            return
        }

        if let cached = cache[trimmed], Date().timeIntervalSince(cached.timestamp) < cacheInterval {
            completion(cached.data)
            return
        }

        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://wttr.in/\(encoded)?format=j1&lang=zh") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            self?.parseResponse(data, city: trimmed, completion: completion)
        }.resume()
    }

    private func parseResponse(_ data: Data, city: String, completion: @escaping (WeatherData?) -> Void) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let conditions = (json["current_condition"] as? [[String: Any]])?.first,
              let todayWeather = (json["weather"] as? [[String: Any]])?.first else {
            DispatchQueue.main.async { completion(nil) }
            return
        }

        let temp = conditions["temp_C"] as? String ?? "--"
        let humidity = conditions["humidity"] as? String ?? "--"
        let weatherCode = conditions["weatherCode"] as? String ?? ""

        let desc: String
        if let langZh = (conditions["lang_zh"] as? [[String: String]])?.first?["value"], !langZh.isEmpty {
            desc = langZh
        } else if let weatherDesc = (conditions["weatherDesc"] as? [[String: String]])?.first?["value"] {
            desc = weatherDesc
        } else {
            desc = "未知"
        }

        let high = todayWeather["maxtempC"] as? String ?? "--"
        let low = todayWeather["mintempC"] as? String ?? "--"
        let iconName = mapWeatherIcon(code: weatherCode)

        let weatherData = WeatherData(
            temperature: temp,
            description: desc,
            iconName: iconName,
            highTemp: high,
            lowTemp: low,
            humidity: humidity,
            cityName: city
        )

        DispatchQueue.main.async { [weak self] in
            self?.cache[city] = (weatherData, Date())
            completion(weatherData)
        }
    }

    private func mapWeatherIcon(code: String) -> String {
        switch code {
        case "113": return "sun.max.fill"
        case "116": return "cloud.sun.fill"
        case "119", "122": return "cloud.fill"
        case "143", "248", "260": return "cloud.fog.fill"
        case "176", "263", "266", "293", "296": return "cloud.drizzle.fill"
        case "299", "302", "305", "308", "311", "314", "356", "359": return "cloud.rain.fill"
        case "200", "386", "389", "392", "395": return "cloud.bolt.rain.fill"
        case "179", "182", "185", "227", "230", "320", "323", "326",
             "329", "332", "335", "338", "350", "353", "362", "365",
             "368", "371", "374", "377": return "cloud.snow.fill"
        default: return "cloud.fill"
        }
    }
}
