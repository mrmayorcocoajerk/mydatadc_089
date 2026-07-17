import Foundation

public enum GalleryLayoutError: Error, Equatable, Sendable { case panelNotFound, lockedPanel, invalidSize, outsideGrid, occupied }

public struct GalleryLayoutEngine: Sendable {
    public init() {}
    public func adding(_ panel: GalleryPanel, to gallery: Gallery) throws -> Gallery {
        try validate(panel, in: gallery, ignoring: nil)
        var result = gallery; result.panels.append(panel); result.updatedAt = .now; return result
    }
    public func moving(panelID: UUID, to origin: GridPoint, in gallery: Gallery) throws -> Gallery {
        guard let index = gallery.panels.firstIndex(where: { $0.id == panelID }) else { throw GalleryLayoutError.panelNotFound }
        guard !gallery.panels[index].isLocked else { throw GalleryLayoutError.lockedPanel }
        var result = gallery; result.panels[index].origin = origin
        try validate(result.panels[index], in: result, ignoring: panelID)
        result.updatedAt = .now; return result
    }
    public func resizing(panelID: UUID, to size: GridSize, in gallery: Gallery) throws -> Gallery {
        guard let index = gallery.panels.firstIndex(where: { $0.id == panelID }) else { throw GalleryLayoutError.panelNotFound }
        guard !gallery.panels[index].isLocked else { throw GalleryLayoutError.lockedPanel }
        var result = gallery; result.panels[index].size = size
        try validate(result.panels[index], in: result, ignoring: panelID)
        result.updatedAt = .now; return result
    }
    public func removing(panelID: UUID, from gallery: Gallery) throws -> Gallery {
        guard let panel = gallery.panels.first(where: { $0.id == panelID }) else { throw GalleryLayoutError.panelNotFound }
        guard !panel.isLocked else { throw GalleryLayoutError.lockedPanel }
        var result = gallery; result.panels.removeAll { $0.id == panelID }; result.updatedAt = .now; return result
    }
    public func firstAvailableOrigin(for size: GridSize, in gallery: Gallery, maxRows: Int = 100) -> GridPoint? {
        guard size.columns > 0, size.rows > 0, size.columns <= gallery.columns else { return nil }
        for row in 0..<maxRows {
            for column in 0...(gallery.columns - size.columns) {
                let candidate = GalleryPanel(kind: .custom, title: "Candidate", origin: .init(column: column, row: row), size: size)
                if (try? validate(candidate, in: gallery, ignoring: nil)) != nil { return candidate.origin }
            }
        }
        return nil
    }
    public func compacting(_ gallery: Gallery) -> Gallery {
        var result = Gallery(id: gallery.id, name: gallery.name, columns: gallery.columns, updatedAt: gallery.updatedAt)
        let ordered = gallery.panels.sorted {
            if $0.isLocked != $1.isLocked { return $0.isLocked && !$1.isLocked }
            if $0.priority != $1.priority { return $0.priority > $1.priority }
            if $0.origin.row != $1.origin.row { return $0.origin.row < $1.origin.row }
            return $0.origin.column < $1.origin.column
        }
        for panel in ordered {
            if panel.isLocked { result.panels.append(panel); continue }
            guard let origin = firstAvailableOrigin(for: panel.size, in: result) else { continue }
            var moved = panel; moved.origin = origin; result.panels.append(moved)
        }
        result.updatedAt = .now; return result
    }
    private func validate(_ panel: GalleryPanel, in gallery: Gallery, ignoring ignoredID: UUID?) throws {
        guard panel.size.columns > 0, panel.size.rows > 0 else { throw GalleryLayoutError.invalidSize }
        guard panel.origin.column >= 0, panel.origin.row >= 0, panel.origin.column + panel.size.columns <= gallery.columns else { throw GalleryLayoutError.outsideGrid }
        let proposed = footprint(of: panel)
        for existing in gallery.panels where existing.id != ignoredID {
            if !proposed.isDisjoint(with: footprint(of: existing)) { throw GalleryLayoutError.occupied }
        }
    }
    private func footprint(of panel: GalleryPanel) -> Set<GridPoint> {
        var points: Set<GridPoint> = []
        for row in panel.origin.row..<(panel.origin.row + panel.size.rows) {
            for column in panel.origin.column..<(panel.origin.column + panel.size.columns) { points.insert(.init(column: column, row: row)) }
        }
        return points
    }
}
