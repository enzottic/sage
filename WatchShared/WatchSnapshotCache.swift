import Foundation

enum WatchSnapshotCache {
    static let widgetKind = "SylWatchMonthlySummary"
    static var defaults: UserDefaults? {
        #if DEBUG
        UserDefaults(suiteName: "group.me.enzottic.SageAppGroup.dev")
        #else
        UserDefaults(suiteName: "group.me.enzottic.SageAppGroup")
        #endif
    }

    static func load() -> WatchSnapshot? {
        guard let data = defaults?.data(forKey: "watchMonthlySnapshot") else { return nil }
        return try? JSONDecoder().decode(WatchSnapshot.self, from: data)
    }

    static func save(_ snapshot: WatchSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        defaults?.set(data, forKey: "watchMonthlySnapshot")
    }
}
