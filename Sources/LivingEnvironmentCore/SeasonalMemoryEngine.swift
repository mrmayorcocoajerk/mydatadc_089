import Foundation

public enum SeasonalMemoryEngine {
    public static func recall(
        from memories: [EnvironmentMemory],
        near date: Date,
        matchingTags tags: Set<String> = [],
        calendar: Calendar = .current
    ) -> EnvironmentMemory? {
        memories.max { lhs, rhs in
            score(lhs, date: date, tags: tags, calendar: calendar) < score(rhs, date: date, tags: tags, calendar: calendar)
        }
    }

    public static func blend(
        current: AtmosphereProfile,
        recalled memory: EnvironmentMemory,
        strength: Double
    ) -> AtmosphereProfile {
        let weight = min(max(strength, 0), 0.45)
        let inverse = 1 - weight
        return AtmosphereProfile(
            lightingTone: weight >= 0.3 ? memory.profile.lightingTone : current.lightingTone,
            lightIntensity: current.lightIntensity * inverse + memory.profile.lightIntensity * weight,
            reflectionIntensity: current.reflectionIntensity * inverse + memory.profile.reflectionIntensity * weight,
            motionScale: current.motionScale * inverse + memory.profile.motionScale * weight,
            ambientSound: current.ambientSound,
            showsSeasonalAccents: current.showsSeasonalAccents || memory.profile.showsSeasonalAccents,
            celebrationAccent: current.celebrationAccent,
            reducesDistractions: current.reducesDistractions
        )
    }

    private static func score(_ memory: EnvironmentMemory, date: Date, tags: Set<String>, calendar: Calendar) -> Double {
        let target = calendar.dateComponents([.month, .day], from: date)
        let candidate = calendar.dateComponents([.month, .day], from: memory.capturedAt)
        let seasonalMatch = target.month == candidate.month ? 0.55 : 0
        let dayMatch = target.day == candidate.day ? 0.15 : 0
        let overlap = tags.isEmpty ? 0 : Double(memory.dominantTags.intersection(tags).count) / Double(tags.count)
        return seasonalMatch + dayMatch + overlap * 0.2 + memory.importance * 0.1
    }
}
