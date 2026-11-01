import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: GlucoseStore
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(Keys.onboarded, store: AppGroup.defaults) private var onboarded = false
    @State private var tab: AppTab = .home

    var body: some View {
        ZStack {
            GlucoBackground()
            if onboarded {
                Group {
                    switch tab {
                    case .home: MainView()
                    case .entries: EntriesView()
                    case .stats: StatsView()
                    case .profile: SettingsView()
                    }
                }
                VStack {
                    Spacer()
                    GlassTabBar(tab: $tab)
                }
                .ignoresSafeArea(.keyboard)
            } else {
                OnboardingView()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await store.refresh() } }
        }
    }
}
