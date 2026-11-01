import Foundation

enum NightscoutError: LocalizedError {
    case notConfigured
    case badURL
    case http(Int)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Nightscout не налаштовано"
        case .badURL: return "Неправильна адреса Nightscout"
        case .http(401): return "Немає доступу (перевір токен)"
        case .http(let code): return "Помилка Nightscout (код \(code))"
        }
    }
}

struct NightscoutClient {
    let baseURL: String
    let token: String

    static var current: NightscoutClient? {
        let d = AppGroup.defaults
        let url = (d.string(forKey: Keys.nsURL) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty else { return nil }
        return NightscoutClient(baseURL: url, token: d.string(forKey: Keys.nsToken) ?? "")
    }

    private struct Entry: Decodable {
        let sgv: Double?
        let date: Double?
        let direction: String?
    }

    func fetch(since: Date, count: Int = 400) async throws -> [GlucoseReading] {
        var base = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !base.lowercased().hasPrefix("http") { base = "https://" + base }
        while base.hasSuffix("/") { base.removeLast() }
        guard var comps = URLComponents(string: base + "/api/v1/entries/sgv.json") else {
            throw NightscoutError.badURL
        }
        var items = [
            URLQueryItem(name: "count", value: String(count)),
            URLQueryItem(name: "find[date][$gte]", value: String(Int64(since.timeIntervalSince1970 * 1000)))
        ]
        let tok = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tok.isEmpty { items.append(URLQueryItem(name: "token", value: tok)) }
        comps.queryItems = items
        guard let url = comps.url else { throw NightscoutError.badURL }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw NightscoutError.http(http.statusCode)
        }
        let entries = try JSONDecoder().decode([Entry].self, from: data)
        return entries.compactMap { e -> GlucoseReading? in
            guard let sgv = e.sgv, let ms = e.date, sgv > 0 else { return nil }
            return GlucoseReading(date: Date(timeIntervalSince1970: ms / 1000), mgdl: sgv, direction: e.direction)
        }
        .sorted { $0.date < $1.date }
    }
}
