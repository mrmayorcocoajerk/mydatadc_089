import Foundation

public enum VitalsEngine {
    public static func recentEntries(in snapshot: VitalsSnapshot) -> [VitalsEntry] {
        snapshot.entries.sorted {
            if $0.date == $1.date { return $0.id.uuidString < $1.id.uuidString }
            return $0.date > $1.date
        }
    }

    public static func sevenDaySummary(in snapshot: VitalsSnapshot, now: Date = Date(), calendar: Calendar = .current) -> VitalsSummary {
        let startOfToday = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
        let end = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now
        let entries = snapshot.entries.filter { $0.date >= start && $0.date < end }
        let loggedDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
        let sleepTotal = entries.reduce(0) { $0 + $1.sleepHours }
        return VitalsSummary(
            daysLogged: loggedDays.count,
            averageSleepHours: entries.isEmpty ? 0 : sleepTotal / Double(entries.count),
            totalWaterGlasses: entries.reduce(0) { $0 + $1.waterGlasses },
            totalActiveMinutes: entries.reduce(0) { $0 + $1.activeMinutes }
        )
    }
}
