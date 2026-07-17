import Foundation
import GalleryCore

public protocol PanelSnapshotProvider: Sendable {
    var supportedKind: PanelKind { get }
    func snapshot(for panel: GalleryPanel, at date: Date) async throws -> PanelSnapshot
}

public struct ClosurePanelProvider: PanelSnapshotProvider {
    public let supportedKind: PanelKind
    private let producer: @Sendable (GalleryPanel, Date) async throws -> PanelSnapshot

    public init(
        supportedKind: PanelKind,
        producer: @escaping @Sendable (GalleryPanel, Date) async throws -> PanelSnapshot
    ) {
        self.supportedKind = supportedKind
        self.producer = producer
    }

    public func snapshot(for panel: GalleryPanel, at date: Date) async throws -> PanelSnapshot {
        try await producer(panel, date)
    }
}
