import Foundation
import GalleryCore

public enum SceneTemplate: String, CaseIterable, Sendable {
    case morning
    case work
    case studio
    case evening
    case travel
    case sleep

    public func makeScene(now: Date = .now) -> ManorScene {
        func gallery(_ template: GalleryTemplate) -> Gallery {
            var value = template.makeGallery()
            value.updatedAt = now
            return value
        }

        switch self {
        case .morning:
            return ManorScene(
                name: "Morning",
                kind: .morning,
                gallery: gallery(.home),
                openDistricts: [.grandHall, .apple, .reading, .netSphere],
                triggers: [.timeRange(startHour: 6, endHour: 10)],
                createdAt: now,
                updatedAt: now
            )
        case .work:
            return ManorScene(
                name: "Work",
                kind: .work,
                gallery: gallery(.work),
                openDistricts: [.grandHall, .productivity, .connections, .finance],
                mutedDistricts: [.reading, .commerce],
                triggers: [.focusMode(name: "Work")],
                createdAt: now,
                updatedAt: now
            )
        case .studio:
            return ManorScene(
                name: "Studio",
                kind: .studio,
                gallery: gallery(.studio),
                openDistricts: [.grandHall, .creative, .apple, .connections],
                mutedDistricts: [.finance, .commerce],
                triggers: [.focusMode(name: "Studio")],
                createdAt: now,
                updatedAt: now
            )
        case .evening:
            return ManorScene(
                name: "Evening",
                kind: .evening,
                gallery: gallery(.home),
                openDistricts: [.grandHall, .reading, .connections, .apple],
                triggers: [.timeRange(startHour: 18, endHour: 23)],
                createdAt: now,
                updatedAt: now
            )
        case .travel:
            return ManorScene(
                name: "Travel",
                kind: .travel,
                gallery: gallery(.travel),
                openDistricts: [.grandHall, .apple, .commerce, .netSphere],
                triggers: [.location(identifier: "travel")],
                createdAt: now,
                updatedAt: now
            )
        case .sleep:
            return ManorScene(
                name: "Sleep",
                kind: .sleep,
                gallery: Gallery(name: "Sleep", panels: [
                    .init(kind: .weather, title: "Tomorrow", origin: .init(column: 0, row: 0), size: .medium, priority: 80),
                    .init(kind: .reading, title: "Sleep Timer", origin: .init(column: 2, row: 0), size: .medium, priority: 70)
                ], updatedAt: now),
                openDistricts: [.grandHall, .reading],
                mutedDistricts: Set(ManorDistrict.allCases).subtracting([.grandHall, .reading]),
                triggers: [.timeRange(startHour: 23, endHour: 6)],
                createdAt: now,
                updatedAt: now
            )
        }
    }
}
