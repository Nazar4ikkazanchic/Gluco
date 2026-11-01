import SwiftUI
import SwiftData

struct AddEntryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let editing: LogEntry?
    @State private var kind: EntryKind
    @State private var amount: Double
    @State private var note: String
    @State private var date: Date

    init(editing: LogEntry? = nil) {
        self.editing = editing
        _kind = State(initialValue: editing?.kind ?? .rapid)
        _amount = State(initialValue: editing?.amount ?? EntryKind.rapid.defaultAmount)
        _note = State(initialValue: editing?.note ?? "")
        _date = State(initialValue: editing?.date ?? .now)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    kindPicker
                    if kind != .note { amountEditor }
                    TextField(kind == .note ? "Що сталося? (спорт, хвороба, стрес…)" : "Коментар (необов'язково)", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                        .padding(14)
                        .glass(radius: 18)
                    DatePicker("Час", selection: $date, in: ...Date.now)
                        .padding(14)
                        .glass(radius: 18)
                    Button(editing == nil ? "Зберегти" : "Оновити") { save() }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(kind == .note && note.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(20)
            }
            .navigationTitle(editing == nil ? "Новий запис" : "Змінити запис")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Скасувати") { dismiss() } }
            }
        }
        .onChange(of: kind) { _, newKind in
            if editing == nil { amount = newKind.defaultAmount }
        }
    }

    private var kindPicker: some View {
        HStack(spacing: 8) {
            ForEach(EntryKind.allCases) { k in
                Button {
                    kind = k
                } label: {
                    VStack(spacing: 6) {
                        Text(k.emoji).font(.system(size: 24))
                        Text(k.title).font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 74)
                    .background(RoundedRectangle(cornerRadius: 18).fill(kind == k ? k.color.opacity(0.3) : .clear))
                    .glass(radius: 18)
                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(kind == k ? k.color : .clear, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var amountEditor: some View {
        HStack {
            stepButton("minus") { amount = max(0, amount - kind.step) }
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField("0", value: $amount, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .frame(width: 140)
                Text(kind.unit).font(.system(size: 20)).foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            stepButton("plus") { amount += kind.step }
        }
        .padding(16)
        .glass()
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Circle().fill(.white.opacity(0.1)))
        }
        .buttonStyle(.plain)
    }

    private func save() {
        if let e = editing {
            e.kind = kind
            e.amount = kind == .note ? 0 : amount
            e.note = note
            e.date = date
        } else {
            context.insert(LogEntry(date: date, kind: kind, amount: kind == .note ? 0 : amount, note: note))
        }
        try? context.save()
        dismiss()
    }
}
