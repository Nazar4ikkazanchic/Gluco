import Foundation
import WidgetKit

@MainActor
final class GlucoseStore: ObservableObject {
    @Published var readings: [GlucoseReading] = GlucoseCache.load()
    @Published var error: String?
    @Published var loading = false

    private var loop: Task<Void, Never>?

    init() { start() }

    var summary: GlucoseSummary? { GlucoseSummary(readings) }

    func start() {
        loop?.cancel()
        loop = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(nanoseconds: 60 * 1_000_000_000)
            }
        }
    }

    func refresh() async {
        guard let client = NightscoutClient.current else {
            error = NightscoutError.notConfigured.localizedDescription
            return
        }
        loading = true
        defer { loading = false }
        do {
            let fresh = try await client.fetch(since: Date().addingTimeInterval(-24 * 3600))
            let changed = fresh.last?.date != readings.last?.date
            readings = fresh
            error = nil
            GlucoseCache.save(fresh)
            if changed { WidgetCenter.shared.reloadAllTimelines() }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func fetch(days: Int) async throws -> [GlucoseReading] {
        guard let client = NightscoutClient.current else { throw NightscoutError.notConfigured }
        return try await client.fetch(since: Date().addingTimeInterval(-Double(days) * 86400), count: days * 300)
    }

    var todayInRange: Double? {
        let start = Calendar.current.startOfDay(for: Date())
        return GlucoseStats(readings.filter { $0.date >= start })?.inRange
    }
}
