import SwiftUI
import Charts

struct ChartCard: View {
    let readings: [GlucoseReading]
    let entries: [LogEntry]
    @Binding var hours: Int

    private var start: Date { Date().addingTimeInterval(-Double(hours) * 3600) }
    private var points: [GlucoseReading] { readings.filter { $0.date >= start } }
    private var marks: [LogEntry] { entries.filter { $0.date >= start } }
    private var maxY: Double { max(14, (points.map(\.mmol).max() ?? 0) + 1) }

    var body: some View {
        VStack(spacing: 10) {
            Picker("Період", selection: $hours) {
                ForEach([3, 6, 12, 24], id: \.self) { h in
                    Text("\(h) год").tag(h)
                }
            }
            .pickerStyle(.segmented)

            chart
                .frame(height: 190)
        }
        .padding(14)
        .glass()
    }

    private var chart: some View {
        let t = Thresholds.current
        let symbolSize: CGFloat = hours <= 6 ? 24 : 10
        return Chart {
            RectangleMark(
                xStart: .value("Початок", start),
                xEnd: .value("Кінець", Date()),
                yStart: .value("Низ", t.low),
                yEnd: .value("Верх", t.high)
            )
            .foregroundStyle(GlucoColors.green.opacity(0.10))

            ForEach(points) { r in
                PointMark(
                    x: .value("Час", r.date),
                    y: .value("ммоль/л", r.mmol)
                )
                .foregroundStyle(Zone.of(r.mmol, t).color)
                .symbolSize(symbolSize)
            }

            ForEach(marks) { e in
                RuleMark(x: .value("Запис", e.date))
                    .foregroundStyle(e.kind.color.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 3]))
                    .annotation(position: .bottom, spacing: 2) {
                        Text(e.chartLabel)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(Circle().fill(e.kind.color.opacity(0.35)))
                    }
            }
        }
        .chartYScale(domain: 2...maxY)
        .chartXScale(domain: start...Date())
        .chartYAxis {
            AxisMarks(position: .leading, values: [t.low, t.high]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                    .foregroundStyle(.white.opacity(0.2))
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(Fmt.mmol(v)).font(.system(size: 11)).foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisValueLabel(format: .dateTime.hour().minute())
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
}
