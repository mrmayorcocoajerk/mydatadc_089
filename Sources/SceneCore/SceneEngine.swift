import Foundation

public enum SceneEngineError: Error, Equatable {
    case duplicateScene
    case sceneNotFound
}

public struct SceneMatch: Equatable, Sendable {
    public let scene: ManorScene
    public let score: Int
    public let reason: String
}

public struct SceneEngine: Sendable {
    public init() {}

    public func bestMatch(in scenes: [ManorScene], context: SceneContext, calendar: Calendar = .current) -> SceneMatch? {
        scenes.compactMap { match(scene: $0, context: context, calendar: calendar) }
            .max { lhs, rhs in
                if lhs.score == rhs.score { return lhs.scene.updatedAt < rhs.scene.updatedAt }
                return lhs.score < rhs.score
            }
    }

    public func match(scene: ManorScene, context: SceneContext, calendar: Calendar = .current) -> SceneMatch? {
        var score = 0
        var reasons: [String] = []

        for trigger in scene.triggers {
            switch trigger {
            case .manual:
                continue
            case let .timeRange(startHour, endHour):
                guard (0...23).contains(startHour), (0...23).contains(endHour) else { continue }
                let hour = calendar.component(.hour, from: context.date)
                let matches = startHour <= endHour
                    ? (startHour..<endHour).contains(hour)
                    : hour >= startHour || hour < endHour
                if matches {
                    score += 20
                    reasons.append("time")
                }
            case let .focusMode(name):
                if context.focusModeName?.localizedCaseInsensitiveCompare(name) == .orderedSame {
                    score += 100
                    reasons.append("focus")
                }
            case let .location(identifier):
                if context.locationIdentifier?.localizedCaseInsensitiveCompare(identifier) == .orderedSame {
                    score += 80
                    reasons.append("location")
                }
            }
        }

        guard score > 0 else { return nil }
        return SceneMatch(scene: scene, score: score, reason: reasons.joined(separator: "+"))
    }
}
