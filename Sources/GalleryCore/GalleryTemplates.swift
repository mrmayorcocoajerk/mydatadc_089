import Foundation

public enum GalleryTemplate: String, CaseIterable, Sendable {
    case home, work, studio, travel, finance
    public func makeGallery() -> Gallery {
        switch self {
        case .home: return Gallery(name: "Home", panels: [
            .init(kind: .weather, title: "Weather", origin: .init(column: 0, row: 0), size: .large, priority: 100),
            .init(kind: .nowPlaying, title: "Now Playing", origin: .init(column: 2, row: 0), size: .medium, priority: 90),
            .init(kind: .commerce, title: "Deliveries", origin: .init(column: 4, row: 0), size: .medium, priority: 80),
            .init(kind: .reading, title: "Continue Reading", origin: .init(column: 2, row: 1), size: .medium, priority: 70)])
        case .work: return Gallery(name: "Work", panels: [
            .init(kind: .career, title: "Career HQ", origin: .init(column: 0, row: 0), size: .large, priority: 100),
            .init(kind: .calendar, title: "Calendar", origin: .init(column: 2, row: 0), size: .large, priority: 95),
            .init(kind: .connections, title: "Connections", origin: .init(column: 4, row: 0), size: .medium, priority: 80),
            .init(kind: .news, title: "NewsDesk", origin: .init(column: 4, row: 1), size: .medium, priority: 60)])
        case .studio: return Gallery(name: "Studio", panels: [
            .init(kind: .nowPlaying, title: "Reference Audio", origin: .init(column: 0, row: 0), size: .large, priority: 100),
            .init(kind: .photos, title: "Visual Assets", origin: .init(column: 2, row: 0), size: .large, priority: 90),
            .init(kind: .connections, title: "Collaborators", origin: .init(column: 4, row: 0), size: .medium, priority: 70)])
        case .travel: return Gallery(name: "Travel", panels: [
            .init(kind: .weather, title: "Destination Weather", origin: .init(column: 0, row: 0), size: .large, priority: 100),
            .init(kind: .calendar, title: "Itinerary", origin: .init(column: 2, row: 0), size: .large, priority: 90),
            .init(kind: .commerce, title: "Reservations", origin: .init(column: 4, row: 0), size: .medium, priority: 80)])
        case .finance: return Gallery(name: "Finance", panels: [
            .init(kind: .finance, title: "Money HQ", origin: .init(column: 0, row: 0), size: .large, priority: 100),
            .init(kind: .commerce, title: "Orders & Receipts", origin: .init(column: 2, row: 0), size: .large, priority: 80),
            .init(kind: .calendar, title: "Upcoming Bills", origin: .init(column: 4, row: 0), size: .medium, priority: 90)])
        }
    }
}
