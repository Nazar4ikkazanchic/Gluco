import SwiftUI

struct SendSheet: View {
    let summary: GlucoseSummary?
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Keys.tgBotToken, store: AppGroup.defaults) private var botToken = ""
    @AppStorage(Keys.tgParentsChat, store: AppGroup.defaults) private var chatID = ""
    @AppStorage(Keys.tgParentsName, store: AppGroup.defaults) private var parentsName = "Батьки"
    @State private var sending = false
    @State private var status: String?
    @State private var goEdit = false

    private var message: String { summary?.message() ?? "🩸 немає даних" }
    private var configured: Bool { !botToken.isEmpty && !chatID.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("Надіслати батькам").font(.system(size: 20, weight: .bold))
                        Text("Через Telegram-бота Gluco").font(.system(size: 14)).foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.top, 20)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(message).font(.system(size: 17))
                        Text("попередній перегляд").font(.system(size: 11)).foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(hex: 0x2B5278), in: UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 18, bottomTrailingRadius: 4, topTrailingRadius: 18))

                    RecipientRow(name: parentsName, subtitle: configured ? "Telegram" : "Не налаштовано: Профіль → Telegram")

                    if configured {
                        Button {
                            Task { await sendNow() }
                        } label: {
                            OptionLabel(icon: "bolt.fill", title: "Надіслати одразу", subtitle: "Бот сам напише це повідомлення", primary: true, loading: sending)
                        }
                        .buttonStyle(.plain)
                        .disabled(sending)

                        Button {
                            goEdit = true
                        } label: {
                            OptionLabel(icon: "pencil", title: "Відредагувати", subtitle: "Змінити текст перед відправкою", primary: false, loading: false)
                        }
                        .buttonStyle(.plain)
                    }

                    if let status {
                        Text(status).font(.system(size: 15, weight: .semibold)).multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationDestination(isPresented: $goEdit) {
                EditMessageView(initial: message, onSent: { dismiss() })
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func sendNow() async {
        sending = true
        defer { sending = false }
        do {
            try await TelegramClient(token: botToken).send(chatID: chatID, text: message)
            status = "✅ Надіслано"
            try? await Task.sleep(nanoseconds: 700_000_000)
            dismiss()
        } catch {
            status = "❌ \(error.localizedDescription)"
        }
    }
}

struct RecipientRow: View {
    let name: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: 15, weight: .bold))
                .frame(width: 38, height: 38)
                .background(Circle().fill(LinearGradient(colors: [Color(hex: 0xF2A65A), Color(hex: 0xE56458)], startPoint: .topLeading, endPoint: .bottomTrailing)))
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(size: 15, weight: .semibold))
                Text(subtitle).font(.system(size: 13)).foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
        }
        .padding(14)
        .glass(radius: 18)
    }
}

struct OptionLabel: View {
    let icon: String
    let title: String
    let subtitle: String
    let primary: Bool
    let loading: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(.white.opacity(primary ? 0.18 : 0.1))
                if loading { ProgressView().tint(.white) } else { Image(systemName: icon).font(.system(size: 18, weight: .semibold)) }
            }
            .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .semibold))
                Text(subtitle).font(.system(size: 13)).foregroundStyle(.white.opacity(primary ? 0.8 : 0.6))
            }
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(14)
        .background {
            if primary {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(colors: [GlucoColors.blue, GlucoColors.blueDark], startPoint: .top, endPoint: .bottom))
            }
        }
        .modifier(OptionalGlass(enabled: !primary))
    }
}

private struct OptionalGlass: ViewModifier {
    let enabled: Bool
    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled { content.glass(radius: 18) } else { content }
    }
}
