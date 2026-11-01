import SwiftUI
import SwiftData

@main
struct GlucoApp: App {
    @StateObject private var store = GlucoseStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: LogEntry.self)
    }
}
