import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: GlucoseStore
    @AppStorage(Keys.onboarded, store: AppGroup.defaults) private var onboarded = false
    @AppStorage(Keys.nsURL, store: AppGroup.defaults) private var nsURL = ""
    @AppStorage(Keys.nsToken, store: AppGroup.defaults) private var nsToken = ""
    @State private var checking = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(GlucoColors.green)
                    .shadow(color: GlucoColors.green.opacity(0.6), radius: 30)
                    .padding(.top, 70)
                VStack(spacing: 8) {
                    Text("Привіт! Це Gluco").font(.system(size: 30, weight: .bold))
                    Text("Підключи свій Nightscout, і цукор завжди буде під рукою: в програмі, на віджетах і в Telegram.")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    TextField("Адреса Nightscout", text: $nsURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(16)
                        .glass(radius: 18)
                    SecureField("Токен (тільки для читання)", text: $nsToken)
                        .padding(16)
                        .glass(radius: 18)
                    Text("Токен: Nightscout → Admin Tools → Subjects → додай нового з роллю «readable».")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let error {
                    Text("❌ \(error)").font(.system(size: 14, weight: .semibold)).foregroundStyle(GlucoColors.red)
                }

                Button {
                    Task { await connect() }
                } label: {
                    if checking { ProgressView().tint(.white) } else { Text("Підключити") }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(nsURL.trimmingCharacters(in: .whitespaces).isEmpty || checking)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func connect() async {
        checking = true
        defer { checking = false }
        do {
            _ = try await NightscoutClient(baseURL: nsURL, token: nsToken).fetch(since: Date().addingTimeInterval(-3600))
            error = nil
            onboarded = true
            await store.refresh()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
