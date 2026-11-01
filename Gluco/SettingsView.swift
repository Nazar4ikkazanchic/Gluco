import SwiftUI
import WidgetKit

struct SettingsView: View {
    @EnvironmentObject var store: GlucoseStore
    @AppStorage(Keys.nsURL, store: AppGroup.defaults) private var nsURL = ""
    @AppStorage(Keys.nsToken, store: AppGroup.defaults) private var nsToken = ""
    @AppStorage(Keys.urgentLow, store: AppGroup.defaults) private var urgentLow = 3.0
    @AppStorage(Keys.low, store: AppGroup.defaults) private var low = 3.9
    @AppStorage(Keys.high, store: AppGroup.defaults) private var high = 10.0
    @AppStorage(Keys.urgentHigh, store: AppGroup.defaults) private var urgentHigh = 13.9
    @AppStorage(Keys.tgBotToken, store: AppGroup.defaults) private var botToken = ""
    @AppStorage(Keys.tgParentsChat, store: AppGroup.defaults) private var chatID = ""
    @AppStorage(Keys.tgParentsName, store: AppGroup.defaults) private var parentsName = "Батьки"

    @State private var nsStatus: String?
    @State private var chats: [TelegramChat] = []
    @State private var tgStatus: String?

    var body: some View {
        Form {
            Section {
                ScreenTitle(title: "Профіль").listRowBackground(Color.clear)
            }

            Section {
                TextField("https://мій-nightscout.herokuapp.com", text: $nsURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Токен (тільки для читання)", text: $nsToken)
                Button("Перевірити підключення") { Task { await testNightscout() } }
                if let nsStatus { Text(nsStatus).font(.footnote) }
            } header: { Text("Nightscout") }
            .listRowBackground(Color.white.opacity(0.06))

            Section {
                valueStepper("🔴 Дуже низький", $urgentLow, 2.0...4.0)
                valueStepper("🟠 Низький", $low, 3.0...6.0)
                valueStepper("🟡 Високий", $high, 7.0...14.0)
                valueStepper("🔴 Дуже високий", $urgentHigh, 10.0...22.0)
            } header: { Text("Діапазон і пороги, ммоль/л") }
            .listRowBackground(Color.white.opacity(0.06))

            Section {
                SecureField("Токен бота від @BotFather", text: $botToken)
                TextField("Ім'я (напр. Мама і Тато)", text: $parentsName)
                TextField("Chat ID батьків", text: $chatID)
                    .keyboardType(.numbersAndPunctuation)
                Button("Знайти чати") { Task { await findChats() } }
                ForEach(chats) { chat in
                    Button {
                        chatID = chat.id
                        if parentsName == "Батьки" || parentsName.isEmpty { parentsName = chat.title }
                        tgStatus = "✅ Обрано: \(chat.title)"
                    } label: {
                        HStack {
                            Text(chat.title)
                            Spacer()
                            if chat.id == chatID { Image(systemName: "checkmark") }
                        }
                    }
                }
                if let tgStatus { Text(tgStatus).font(.footnote) }
            } header: {
                Text("Telegram")
            } footer: {
                Text("Попроси батьків написати твоєму боту /start (або додай бота в сімейну групу), потім натисни «Знайти чати» і вибери потрібний.")
            }
            .listRowBackground(Color.white.opacity(0.06))

            Section {
                Text("Gluco не є медичним виробом. Рішення щодо інсуліну приймай за глюкометром/сенсором і порадами лікаря.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                Text("Версія \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            } header: { Text("Про програму") }
            .listRowBackground(Color.white.opacity(0.06))

            Color.clear.frame(height: 70).listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
        .onChange(of: low) { _, _ in WidgetCenter.shared.reloadAllTimelines() }
        .onChange(of: high) { _, _ in WidgetCenter.shared.reloadAllTimelines() }
    }

    private func valueStepper(_ title: String, _ value: Binding<Double>, _ range: ClosedRange<Double>) -> some View {
        Stepper(value: value, in: range, step: 0.1) {
            HStack {
                Text(title)
                Spacer()
                Text(Fmt.mmol(value.wrappedValue)).monospacedDigit().foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private func testNightscout() async {
        nsStatus = "Перевіряю…"
        do {
            let r = try await NightscoutClient(baseURL: nsURL, token: nsToken).fetch(since: Date().addingTimeInterval(-3600))
            if let last = r.last {
                nsStatus = "✅ Працює! Останнє значення: \(Fmt.mmol(last.mmol)) о \(Fmt.time.string(from: last.date))"
            } else {
                nsStatus = "⚠️ Підключився, але за останню годину немає даних"
            }
            await store.refresh()
        } catch {
            nsStatus = "❌ \(error.localizedDescription)"
        }
    }

    private func findChats() async {
        tgStatus = "Шукаю…"
        do {
            chats = try await TelegramClient(token: botToken).recentChats()
            tgStatus = chats.isEmpty ? "Чатів не знайдено. Спершу напишіть боту /start." : "Вибери чат зі списку"
        } catch {
            tgStatus = "❌ \(error.localizedDescription)"
        }
    }
}
