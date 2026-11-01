import SwiftUI
import SwiftData

struct MainView: View {
    @EnvironmentObject var store: GlucoseStore
    @Query(sort: \LogEntry.date, order: .reverse) private var entries: [LogEntry]
    @State private var hours = 3
    @State private var showSend = false
    @State private var showAdd = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                hero
                ChartCard(readings: store.readings, entries: entries, hours: $hours)
                statsRow
                actions
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 110)
        }
        .scrollIndicators(.hidden)
        .refreshable { await store.refresh() }
        .sheet(isPresented: $showSend) {
            SendSheet(summary: store.summary)
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $showAdd) {
            AddEntryView()
                .presentationBackground(.ultraThinMaterial)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Gluco").font(.system(size: 22, weight: .bold))
                HStack(spacing: 6) {
                    Circle()
                        .fill(store.error == nil ? GlucoColors.green : GlucoColors.red)
                        .frame(width: 8, height: 8)
                    if let s = store.summary {
                        Text("Nightscout · ") + Text(s.current.date, style: .relative) + Text(" тому")
                    } else {
                        Text(store.error ?? "Nightscout")
                    }
                }
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)
            }
            Spacer()
            if store.loading { ProgressView().tint(.white) }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var hero: some View {
        if let s = store.summary {
            let color = s.isStale ? Color.gray : s.zone.color
            VStack(spacing: 6) {
                HStack(spacing: 12) {
                    Text(s.valueText)
                        .font(.system(size: 112, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Image(systemName: Trend.symbol(s.current.direction))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(color)
                        .frame(width: 54, height: 54)
                        .glass(radius: 27)
                }
                .opacity(s.isStale ? 0.5 : 1)
                Text(s.delta == nil ? "ммоль/л" : "ммоль/л · \(s.deltaText) за 5 хв")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
                HStack(spacing: 8) {
                    if s.isStale {
                        Chip(text: "Дані застаріли", color: GlucoColors.orange)
                    } else {
                        Chip(text: s.zone.title, color: s.zone.color)
                    }
                    let t = Thresholds.current
                    Chip(text: "Ціль \(Fmt.mmol(t.low))–\(Fmt.mmol(t.high))")
                }
                .padding(.top, 6)
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                Circle()
                    .fill(RadialGradient(colors: [color.opacity(0.35), .clear], center: .center, startRadius: 0, endRadius: 140))
                    .frame(width: 280, height: 280)
                    .blur(radius: 10)
            )
        } else {
            VStack(spacing: 10) {
                Text("—").font(.system(size: 96, weight: .light, design: .rounded))
                Text(store.error ?? "Завантаження…")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 30)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("У діапазоні сьогодні").font(.system(size: 12)).foregroundStyle(.white.opacity(0.55))
                Text(store.todayInRange.map { "\(Int(($0 * 100).rounded())) %" } ?? "—")
                    .font(.system(size: 20, weight: .semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .glass(radius: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text("Останній запис").font(.system(size: 12)).foregroundStyle(.white.opacity(0.55))
                if let e = entries.first {
                    Text("\(e.kind.emoji) \(e.kind == .note ? "нотатка" : "\(e.amountText) \(e.kind.unit)") · \(Fmt.time.string(from: e.date))")
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text("—").font(.system(size: 20, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .glass(radius: 20)
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button {
                showSend = true
            } label: {
                Label("Надіслати батькам", systemImage: "paperplane.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button {
                showAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .glass(radius: 18)
            }
            .buttonStyle(.plain)
        }
    }
}
