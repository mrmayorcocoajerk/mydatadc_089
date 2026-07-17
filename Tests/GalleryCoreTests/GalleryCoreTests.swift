import Foundation
import Testing
@testable import GalleryCore

@Test func addsPanelWhenSpaceIsFree() throws {
    let engine = GalleryLayoutEngine()
    let panel = GalleryPanel(kind: .weather, title: "Weather", origin: .init(column: 0, row: 0), size: .large)
    let gallery = try engine.adding(panel, to: Gallery(name: "Home"))
    #expect(gallery.panels == [panel])
}

@Test func rejectsOverlappingPanel() throws {
    let engine = GalleryLayoutEngine()
    let first = GalleryPanel(kind: .weather, title: "Weather", origin: .init(column: 0, row: 0), size: .large)
    let second = GalleryPanel(kind: .calendar, title: "Calendar", origin: .init(column: 1, row: 1), size: .large)
    let gallery = try engine.adding(first, to: Gallery(name: "Home"))
    #expect(throws: GalleryLayoutError.occupied) { _ = try engine.adding(second, to: gallery) }
}

@Test func lockedPanelsCannotMoveOrDelete() {
    let engine = GalleryLayoutEngine()
    let locked = GalleryPanel(kind: .weather, title: "Weather", origin: .init(column: 0, row: 0), size: .small, isLocked: true)
    let gallery = Gallery(name: "Home", panels: [locked])
    #expect(throws: GalleryLayoutError.lockedPanel) { _ = try engine.moving(panelID: locked.id, to: .init(column: 1, row: 0), in: gallery) }
    #expect(throws: GalleryLayoutError.lockedPanel) { _ = try engine.removing(panelID: locked.id, from: gallery) }
}

@Test func findsFirstAvailableOrigin() {
    let engine = GalleryLayoutEngine()
    let panel = GalleryPanel(kind: .weather, title: "Weather", origin: .init(column: 0, row: 0), size: .large)
    let gallery = Gallery(name: "Home", columns: 4, panels: [panel])
    #expect(engine.firstAvailableOrigin(for: .medium, in: gallery) == GridPoint(column: 2, row: 0))
}

@Test func templatesContainNoOverlaps() throws {
    let engine = GalleryLayoutEngine()
    for template in GalleryTemplate.allCases {
        let gallery = template.makeGallery()
        var rebuilt = Gallery(name: gallery.name, columns: gallery.columns)
        for panel in gallery.panels { rebuilt = try engine.adding(panel, to: rebuilt) }
        #expect(rebuilt.panels.count == gallery.panels.count)
    }
}

@Test func storeRoundTripsGallery() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let url = directory.appendingPathComponent("galleries.json")
    let gallery = GalleryTemplate.home.makeGallery()
    let store = GalleryStore(fileURL: url)
    try await store.upsert(gallery)
    let reloaded = GalleryStore(fileURL: url)
    let values = try await reloaded.load()
    #expect(values == [gallery])
}
