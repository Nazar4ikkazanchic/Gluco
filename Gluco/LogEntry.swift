import Foundation
import SwiftData
import SwiftUI

enum EntryKind: String, CaseIterable, Identifiable {
    case rapid, long, carbs, note

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rapid: return "Короткий"
        case .long: return "Довгий"
        case .carbs: return "Вуглеводи"
        case .note: return "Нотатка"
        }
    }

    var emoji: String {
        switch self {
        case .rapid: return "💉"
        case .long: return "🌙"
        case .carbs: return "🍞"
        case .note: return "📝"
        }
    }

    var unit: String {
        switch self {
        case .rapid, .long: return "од"
        case .carbs: return "г"
        case .note: return ""
        }
    }

    var color: Color {
        switch self {
        case .rapid: return Color(hex: 0x5EA8F0)
        case .long: return Color(hex: 0xA98CF0)
        case .carbs: return GlucoColors.orange
        case .note: return Color.white.opacity(0.7)
        }
    }

    var defaultAmount: Double {
        switch self {
        case .rapid: return 4
        case .long: return 12
        case .carbs: return 30
        case .note: return 0
        }
    }

    var step: Double {
        switch self {
        case .rapid, .long: return 0.5
        case .carbs: return 5
        case .note: return 0
        }
    }
}

@Model
final class LogEntry {
    var date: Date
    var kindRaw: String
    var amount: Double
    var note: String

    init(date: Date = .now, kind: EntryKind, amount: Double, note: String = "") {
        self.date = date
        self.kindRaw = kind.rawValue
        self.amount = amount
        self.note = note
    }

    var kind: EntryKind {
        get { EntryKind(rawValue: kindRaw) ?? .note }
        set { kindRaw = newValue.rawValue }
    }

    var amountText: String {
        amount.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(amount)) : String(format: "%.1f", amount)
    }

    var chartLabel: String { kind == .note ? "✎" : amountText }

    var title: String {
        switch kind {
        case .note: return note.isEmpty ? "Нотатка" : note
        default: return "\(kind.title): \(amountText) \(kind.unit)"
        }
    }
}
