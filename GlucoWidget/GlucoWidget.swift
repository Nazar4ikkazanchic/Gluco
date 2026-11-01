import WidgetKit
import SwiftUI
import Charts

struct GlucoEntry: TimelineEntry {
    let date: Date
    let readings: [GlucoseReading]

    var summary: GlucoseSummary? { GlucoseSummary(readings) }

    static var sample: GlucoEntry {
        let now = Date()
        let values: [Double] = [140, 150, 160, 150, 130, 115, 108, 104, 106, 110, 112, 115]
        let r = values.enumerated().map { i, v in
            GlucoseReading(date: now.addingTimeInterval(Double(i - values.count + 1) * 300), mgdl: v, direction: "FortyFiveUp")
        }
        return GlucoEntry(date: now, readings: r)
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> GlucoEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (GlucoEntry) -> Void) {
        if context.isPreview {
            completion(.sample)
            return
        }
        Task { completion(await load()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GlucoEntry>) -> Void) {
        Task {
            let entry = await load()
            completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(10 * 60))))
        }
    }

    private func load() async -> GlucoEntry {
        let since = Date().addingTimeInterval(-3 * 3600)
        if let client = NightscoutClient.current,
           let fresh = try? await client.fetch(since: since, count: 60),
           !fresh.isEmpty {
            return GlucoEntry(date: Date(), readings: fresh)
        }
        return GlucoEntry(date: Date(), readings: GlucoseCache.load().filter { $0.date >= since })
    }
}

struct GlucoWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: GlucoEntry

    var body: some View {
        if let s = entry.summary {
            switch family {
            case .accessoryCircular: circular(s)
            case .accessoryRectangular: rectangular(s)
            case .accessoryInline: Text("\(s.valueText) \(s.arrowText) \(s.deltaText)")
            case .systemMedium: medium(s)
            default: small(s)
            }
        } else {
            VStack(spacing: 4) {
                Image(systemName: "drop")
                Text("Немає даних").font(.caption2)
            }
        }
    }

    private func color(_ s: GlucoseSummary) -> Color { s.isStale ? .gray : s.zone.color }

    private func circular(_ s: GlucoseSummary) -> some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text(s.valueText).font(.system(size: 20, weight: .bold, design: .rounded)).minimumScaleFactor(0.6)
                Image(systemName: Trend.symbol(s.current.direction)).font(.system(size: 11, weight: .bold))
            }
            .strikethrough(s.isStale)
        }
    }

    private func rectangular(_ s: GlucoseSummary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(s.valueText).font(.system(size: 22, weight: .bold, design: .rounded))
                Image(systemName: Trend.symbol(s.current.direction)).font(.system(size: 13, weight: .bold))
                Text(s.deltaText).font(.system(size: 13))
                Spacer(minLength: 0)
                Text(s.current.date, style: .relative).font(.system(size: 10)).lineLimit(1)
            }
            Sparkline(readings: entry.readings, color: .primary)
                .frame(height: 22)
        }
    }

    private func small(_ s: GlucoseSummary) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Gluco").font(.system(size: 12, weight: .semibold)).foregroundStyle(.white.opacity(0.6))
                Spacer()
                Text(s.current.date, style: .relative).font(.system(size: 11)).foregroundStyle(.white.opacity(0.5)).lineLimit(1)
            }
            Spacer()
            Text(s.valueText)
                .font(.system(size: 50, weight: .light, design: .rounded))
                .foregroundStyle(.white)
                .opacity(s.isStale ? 0.5 : 1)
                .minimumScaleFactor(0.6)
            HStack(spacing: 4) {
                Image(systemName: Trend.symbol(s.current.direction))
                Text(s.deltaText.isEmpty ? "ммоль/л" : "\(s.deltaText) ммоль/л")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(color(s))
        }
    }

    private func medium(_ s: GlucoseSummary) -> some View {
        HStack(spacing: 14) {
            small(s).frame(width: 120)
            VStack(alignment: .leading, spacing: 6) {
                Text("3 год").font(.system(size: 12)).foregroundStyle(.white.opacity(0.55))
                Sparkline(readings: entry.readings, color: color(s), showRange: true)
                if let stats = GlucoseStats(entry.readings) {
                    Text("\(Int((stats.inRange * 100).rounded()))% у діапазоні")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }
}

struct Sparkline: View {
    let readings: [GlucoseReading]
    var color: Color
    var showRange = false

    var body: some View {
        let t = Thresholds.current
        let maxY = max(12, (readings.map(\.mmol).max() ?? 0) + 1)
        return Chart {
            if showRange, let first = readings.first?.date, let last = readings.last?.date {
                RectangleMark(
                    xStart: .value("s", first), xEnd: .value("e", last),
                    yStart: .value("lo", t.low), yEnd: .value("hi", t.high)
                )
                .foregroundStyle(GlucoColors.green.opacity(0.12))
            }
            ForEach(readings) { r in
                LineMark(x: .value("t", r.date), y: .value("v", r.mmol))
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
            }
        }
        .chartYScale(domain: 2...maxY)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}

struct GlucoWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GlucoWidget", provider: Provider()) { entry in
            GlucoWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(colors: [Color(hex: 0x14243A), Color(hex: 0x0A1A16)], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
        }
        .configurationDisplayName("Цукор")
        .description("Поточний цукор із Nightscout")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct GlucoWidgetBundle: WidgetBundle {
    var body: some Widget {
        GlucoWidget()
    }
}
