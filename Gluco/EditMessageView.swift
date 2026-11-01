import SwiftUI

struct EditMessageView: View {
    let initial: String
    let onSent: () -> Void

    @AppStorage(Keys.tgBotToken, store: AppGroup.defaults) private var botToken = ""
    @AppStorage(Keys.tgParentsChat, store: AppGroup.defaults) private var chatID = ""
    @AppStorage(Keys.tgParentsName, store: AppGroup.defaults) private var parentsName = "Батьки"
    @State private var text = ""
    @State private var saveTemplate = false
    @State private var sending = false
    @State private var status: String?
    @State private var templates: [String] = []

    private static let defaultPhrases = ["✅ Все ок", "🍝 Поїв", "🏃 Тренування", "😴 Йду спати", "🤒 Погано почуваюсь"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RecipientRow(name: parentsName, subtitle: "Кому надіслати")

                TextEditor(text: $text)
                    .font(.system(size: 17))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 130)
                    .padding(10)
                    .glass(radius: 18)

                Text("Швидко додати").font(.system(size: 13)).foregroundStyle(.white.opacity(0.55))
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(templates + Self.defaultPhrases, id: \.self) { phrase in
                            Button {
                                text += (text.hasSuffix("\n") || text.isEmpty ? "" : "\n") + phrase
                            } label: {
                                Text(phrase)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(.white.opacity(0.08)))
                                    .overlay(Capsule().strokeBorder(.white.opacity(0.14)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollIndicators(.hidden)

                Toggle(isOn: $saveTemplate) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Запам'ятати як шаблон").font(.system(size: 15, weight: .semibold))
                        Text("Твій текст з'явиться в «Швидко додати»").font(.system(size: 13)).foregroundStyle(.white.opacity(0.55))
                    }
                }
                .padding(14)
                .glass(radius: 18)

                if let status {
                    Text(status).font(.system(size: 15, weight: .semibold))
                }

                Button {
                    Task { await send() }
                } label: {
                    if sending { ProgressView().tint(.white) } else { Label("Надіслати", systemImage: "paperplane.fill") }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(sending || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(20)
        }
        .navigationTitle("Повідомлення")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if text.isEmpty { text = initial }
            templates = AppGroup.defaults.stringArray(forKey: Keys.templates) ?? []
        }
    }

    private func send() async {
        sending = true
        defer { sending = false }
        do {
            try await TelegramClient(token: botToken).send(chatID: chatID, text: text)
            if saveTemplate { storeTemplate() }
            status = "✅ Надіслано"
            try? await Task.sleep(nanoseconds: 700_000_000)
            onSent()
        } catch {
            status = "❌ \(error.localizedDescription)"
        }
    }

    /// Saves the user's own lines (everything except the glucose line) as a quick phrase.
    private func storeTemplate() {
        let custom = text
            .components(separatedBy: "\n")
            .filter { !$0.hasPrefix("🩸") }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !custom.isEmpty, !templates.contains(custom) else { return }
        let updated = [custom] + templates.prefix(9)
        AppGroup.defaults.set(Array(updated), forKey: Keys.templates)
    }
}
