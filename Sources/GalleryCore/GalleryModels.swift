import Foundation

public struct GridPoint: Codable, Hashable, Sendable {
    public var column: Int
    public var row: Int
    public init(column: Int, row: Int) { self.column = column; self.row = row }
}

public struct GridSize: Codable, Hashable, Sendable {
    public var columns: Int
    public var rows: Int
    public init(columns: Int, rows: Int) { self.columns = columns; self.rows = rows }
    public static let small = GridSize(columns: 1, rows: 1)
    public static let medium = GridSize(columns: 2, rows: 1)
    public static let large = GridSize(columns: 2, rows: 2)
}

public enum PanelKind: String, Codable, CaseIterable, Sendable {
    case weather, nowPlaying, calendar, career, finance, commerce, reading, connections, photos, news, custom
}

public struct GalleryPanel: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var kind: PanelKind
    public var title: String
    public var origin: GridPoint
    public var size: GridSize
    public var priority: Int
    public var isLocked: Bool
    public init(id: UUID = UUID(), kind: PanelKind, title: String, origin: GridPoint, size: GridSize, priority: Int = 0, isLocked: Bool = false) {
        self.id = id; self.kind = kind; self.title = title; self.origin = origin; self.size = size; self.priority = priority; self.isLocked = isLocked
    }
}

public struct Gallery: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var columns: Int
    public var panels: [GalleryPanel]
    public var updatedAt: Date
    public init(id: UUID = UUID(), name: String, columns: Int = 6, panels: [GalleryPanel] = [], updatedAt: Date = .now) {
        self.id = id; self.name = name; self.columns = max(1, columns); self.panels = panels; self.updatedAt = updatedAt
    }
}
