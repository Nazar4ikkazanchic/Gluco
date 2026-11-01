import SwiftUI
import SwiftData

struct EntriesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \LogEntry.date, order: .reverse) private var entries: [LogEntry]
    @State private var editing: LogEntry?
    @State private var showAdd = false

    private struct DayGroup: Identifiable {
        let day: Date
        let items: [LogEntry]
        var id: Date { day }
    }

    private var grouped: [DayGroup] {
        let groups = Dictionary(grouping: entries) { Calendar.current.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { DayGroup(day: $0, items: groups[$0] ?? []) }
    }

    var body: some View {
        List {
            HStack {
                ScreenTitle(title: "Записи")
                Button { showAdd = true } label: {
                    Image(systemName: "plus").font(.system(size: 18, weight: .semibold)).foregroundStyle(.white)
                        .frame(width: 44, height: 44).glass(radius: 22)
                }
                .buttonStyle(.plain)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if entries.isEmpty {
                Text("Поки що немає записів. Натисни «+», щоб додати інсулін, вуглеводи чи нотатку.")
                    .foregroundStyle(.white.opacity(0.6))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            ForEach(grouped) { group in
                Section {
                    ForEach(group.items) { e in
                        Button { editing = e } label: { row(e) }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.white.opacity(0.06))
                            .swipeActions {
                                Button(role: .destructive) { context.delete(e) } label: { Label("Видалити", systemImage: "trash") }
                            }
                    }
                } header: {
                    Text(group.day.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Color.clear.frame(height: 90).listRowBackground(Color.clear).listRowSeparator(.hidden)
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .sheet(item: $editing) { e in AddEntryView(editing: e).presentationBackground(.ultraThinMaterial) }
        .sheet(isPresented: $showAdd) { AddEntryView().presentationBackground(.ultraThinMaterial) }
    }

    private func row(_ e: LogEntry) -> some View {
        HStack(spacing: 12) {
            Text(e.kind.emoji)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(Circle().fill(e.kind.color.opacity(0.2)))
            VStack(alignment: .leading, spacing: 2) {
                Text(e.title).font(.system(size: 16, weight: .semibold)).lineLimit(2)
                if e.kind != .note && !e.note.isEmpty {
                    Text(e.note).font(.system(size: 13)).foregroundStyle(.white.opacity(0.6)).lineLimit(1)
                }
            }
            Spacer()
            Text(Fmt.time.string(from: e.date)).font(.system(size: 14)).foregroundStyle(.white.opacity(0.6))
        }
        .contentShape(Rectangle())
    }
}
