import Foundation
import SwiftUI

struct GlucoseReading: Identifiable, Codable, Hashable {
    var id: Date { date }
    let date: Date
    let mgdl: Double
    let direction: String?

    var mmol: Double { mgdl / 18.0182 }
}

enum Trend {
    static func symbol(_ direction: String?) -> String {
        switch direction {
        case "DoubleUp": return "chevron.up.2"
        case "SingleUp": return "arrow.up"
        case "FortyFiveUp": return "arrow.up.right"
        case "Flat": return "arrow.right"
        case "FortyFiveDown": return "arrow.down.right"
        case "SingleDown": return "arrow.down"
        case "DoubleDown": return "chevron.down.2"
        default: return "minus"
        }
    }

    static func text(_ direction: String?) -> String {
        switch direction {
        case "DoubleUp": return "⇈"
        case "SingleUp": return "↑"
        case "FortyFiveUp": return "↗"
        case "Flat": return "→"
        case "FortyFiveDown": return "↘"
        case "SingleDown": return "↓"
        case "DoubleDown": return "⇊"
        default: return ""
        }
    }
}

enum GlucoColors {
    static let green = Color(hex: 0x7FE0A9)
    static let orange = Color(hex: 0xF2A65A)
    static let yellow = Color(hex: 0xF2CF5A)
    static let red = Color(hex: 0xFF6B6B)
    static let blue = Color(hex: 0x3AA0E8)
    static let blueDark = Color(hex: 0x2283D0)
    static let background = Color(hex: 0x07090E)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

enum Zone {
    case urgentLow, low, inRange, high, urgentHigh

    static func of(_ mmol: Double, _ t: Thresholds = .current) -> Zone {
        if mmol < t.urgentLow { return .urgentLow }
        if mmol < t.low { return .low }
        if mmol > t.urgentHigh { return .urgentHigh }
        if mmol > t.high { return .high }
        return .inRange
    }

    var color: Color {
        switch self {
        case .urgentLow, .urgentHigh: return GlucoColors.red
        case .low: return GlucoColors.orange
        case .high: return GlucoColors.yellow
        case .inRange: return GlucoColors.green
        }
    }

    var title: String {
        switch self {
        case .urgentLow: return "Дуже низький"
        case .low: return "Низький"
        case .inRange: return "У діапазоні"
        case .high: return "Високий"
        case .urgentHigh: return "Дуже високий"
        }
    }

    var emoji: String {
        switch self {
        case .urgentLow, .urgentHigh: return "🔴"
        case .low: return "🟠"
        case .high: return "🟡"
        case .inRange: return "🟢"
        }
    }
}

enum Fmt {
    static func mmol(_ v: Double) -> String { String(format: "%.1f", v) }

    static func signed(_ v: Double) -> String {
        let sign = v >= 0 ? "+" : "−"
        return sign + String(format: "%.1f", abs(v))
    }

    static let time: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
}

struct GlucoseSummary {
    let current: GlucoseReading
    let delta: Double?

    init?(_ readings: [GlucoseReading]) {
        guard let last = readings.last else { return nil }
        current = last
        if readings.count > 1 {
            let prev = readings[readings.count - 2]
            delta = last.date.timeIntervalSince(prev.date) < 16 * 60 ? last.mmol - prev.mmol : nil
        } else {
            delta = nil
        }
    }

    var valueText: String { Fmt.mmol(current.mmol) }
    var deltaText: String { delta.map { Fmt.signed($0) } ?? "" }
    var arrowText: String { Trend.text(current.direction) }
    var timeText: String { Fmt.time.string(from: current.date) }
    var zone: Zone { Zone.of(current.mmol) }
    var isStale: Bool { Date().timeIntervalSince(current.date) > 15 * 60 }

    /// e.g. "🩸 6.4 ↗ (+0.3) · 14:32"
    func message() -> String {
        var s = "🩸 \(valueText)"
        if !arrowText.isEmpty { s += " \(arrowText)" }
        if delta != nil { s += " (\(deltaText))" }
        s += " · \(timeText)"
        return s
    }
}

enum GlucoseCache {
    static func save(_ readings: [GlucoseReading]) {
        let recent = Array(readings.suffix(320))
        if let data = try? JSONEncoder().encode(recent) {
            AppGroup.defaults.set(data, forKey: Keys.cache)
        }
    }

    static func load() -> [GlucoseReading] {
        guard let data = AppGroup.defaults.data(forKey: Keys.cache),
              let r = try? JSONDecoder().decode([GlucoseReading].self, from: data) else { return [] }
        return r
    }
}

struct GlucoseStats {
    let inRange: Double
    let below: Double
    let above: Double
    let average: Double
    let gmi: Double
    let count: Int

    init?(_ readings: [GlucoseReading], _ t: Thresholds = .current) {
        guard !readings.isEmpty else { return nil }
        let n = Double(readings.count)
        let belowCount = readings.filter { $0.mmol < t.low }.count
        let aboveCount = readings.filter { $0.mmol > t.high }.count
        below = Double(belowCount) / n
        above = Double(aboveCount) / n
        inRange = max(0, 1 - below - above)
        let avgMg = readings.reduce(0) { $0 + $1.mgdl } / n
        average = avgMg / 18.0182
        gmi = 3.31 + 0.02392 * avgMg
        count = readings.count
    }
}
