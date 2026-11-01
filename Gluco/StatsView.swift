import SwiftUI
import SwiftData

struct StatsView: View {
    @EnvironmentObject var store: GlucoseStore
    @Query(sort: \LogEntry.date, order: .reverse) private var entries: [LogEntry]
    @State private var days = 7
    @State private var readings: [GlucoseReading] = []
    @State private var loading = false
    @State private var error: String?

    private var periodReadings: [GlucoseReading] {
        let start = days == 1 ? Calendar.current.startOfDay(for: Date()) : Date().addingTimeInterval(-Double(days) * 86400)
        return readings.filter { $0.date >= start }
    }

    private var periodEntries: [LogEntry] {
        let start = days == 1 ? Calendar.current.startOfDay(for: Date()) : Date().addingTimeInterval(-Double(days) * 86400)
        return entries.filter { $0.date >= start }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ScreenTitle(title: "Статистика")
                Picker("Період", selection: $days) {
                    Text("Сьогодні").tag(1)
                    Text("7 днів").tag(7)
                    Text("14 днів").tag(14)
                }
                .pickerStyle(.segmented)

                if let s = GlucoseStats(periodReadings) {
                    rangeCard(s)
                    HStack(spacing: 10) {
                        tile("Середній цукор", Fmt.mmol(s.average), "ммоль/л")
                        tile("Глікований (GMI)", String(format: "%.1f", s.gmi), "%")
                    }
                    HStack(spacing: 10) {
                        tile("💉 Короткий / день", perDay(.rapid), "од")
                        tile("🍞 Вуглеводи / день", perDay(.carbs), "г")
                    }
                    Text("GMI — приблизна оцінка глікованого гемоглобіну за даними сенсора. Не замінює аналіз.")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if loading {
                    ProgressView().tint(.white).padding(40)
                } else {
                    Text(error ?? "Немає даних за цей період").foregroundStyle(.white.opacity(0.6)).padding(40)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 110)
        }
        .scrollIndicators(.hidden)
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            readings = try await store.fetch(days: 14)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func perDay(_ kind: EntryKind) -> String {
        let total = periodEntries.filter { $0.kind == kind }.reduce(0) { $0 + $1.amount }
        let value = total / Double(days)
        return value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
    }

    private func rangeCard(_ s: GlucoseStats) -> some View {
        HStack(spacing: 20) {
            ZStack {
                Circle().stroke(.white.opacity(0.1), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: s.inRange)
                    .stroke(GlucoColors.green, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(Int((s.inRange * 100).rounded()))%").font(.system(size: 30, weight: .bold, design: .rounded))
                    Text("у діапазоні").font(.system(size: 11)).foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(width: 130, height: 130)

            VStack(alignment: .leading, spacing: 12) {
                legend(GlucoColors.yellow, "Вище цілі", s.above)
                legend(GlucoColors.green, "У діапазоні", s.inRange)
                legend(GlucoColors.orange, "Нижче цілі", s.below)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .glass()
    }

    private func legend(_ color: Color, _ title: String, _ value: Double) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(title).font(.system(size: 14)).foregroundStyle(.white.opacity(0.75))
            Spacer(minLength: 4)
            Text("\(Int((value * 100).rounded()))%").font(.system(size: 14, weight: .semibold))
        }
    }

    private func tile(_ title: String, _ value: String, _ unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 12)).foregroundStyle(.white.opacity(0.55)).lineLimit(1).minimumScaleFactor(0.8)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(.system(size: 24, weight: .semibold, design: .rounded))
                Text(unit).font(.system(size: 12)).foregroundStyle(.white.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glass(radius: 20)
    }
}
