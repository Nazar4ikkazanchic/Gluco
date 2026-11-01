import Foundation

enum AppGroup {
    static let fallbackID = "group.com.gluco.app"

    /// SideStore/AltStore rewrite app group IDs when re-signing and expose them in `ALTAppGroups`.
    static var id: String {
        if let groups = Bundle.main.object(forInfoDictionaryKey: "ALTAppGroups") as? [String],
           let first = groups.first {
            return first
        }
        return fallbackID
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: id) ?? .standard
    }
}

enum Keys {
    static let onboarded = "onboarded"
    static let nsURL = "nsURL"
    static let nsToken = "nsToken"
    static let urgentLow = "urgentLow"
    static let low = "low"
    static let high = "high"
    static let urgentHigh = "urgentHigh"
    static let tgBotToken = "tgBotToken"
    static let tgParentsChat = "tgParentsChat"
    static let tgParentsName = "tgParentsName"
    static let templates = "templates"
    static let cache = "readingsCache"
}

struct Thresholds {
    var urgentLow: Double
    var low: Double
    var high: Double
    var urgentHigh: Double

    static var current: Thresholds {
        let d = AppGroup.defaults
        func value(_ key: String, _ fallback: Double) -> Double {
            let v = d.double(forKey: key)
            return v == 0 ? fallback : v
        }
        return Thresholds(
            urgentLow: value(Keys.urgentLow, 3.0),
            low: value(Keys.low, 3.9),
            high: value(Keys.high, 10.0),
            urgentHigh: value(Keys.urgentHigh, 13.9)
        )
    }
}
