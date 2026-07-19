import Foundation
import Testing
@testable import FornixNubiumCore

@Test func searchMatchesNamesFoldersKindsAndTags() {
    let assets = [
        FornixAsset(name: "Launch Plan.pdf", kind: .document, byteCount: 10, fingerprint: "plan", tags: ["strategy"], folderName: "Projects"),
        FornixAsset(name: "Portrait.heic", kind: .photo, byteCount: 20, fingerprint: "portrait", tags: ["mayor"], folderName: "Photography")
    ]

    #expect(FornixNubiumIndex.search("strategy", in: assets).map(\.name) == ["Launch Plan.pdf"])
    #expect(FornixNubiumIndex.search("photo", in: assets).map(\.name) == ["Portrait.heic"])
    #expect(FornixNubiumIndex.search("projects", in: assets).map(\.name) == ["Launch Plan.pdf"])
}

@Test func duplicateIndexReportsRecoverableStorage() {
    let assets = [
        FornixAsset(name: "Original.mov", kind: .video, byteCount: 500, fingerprint: "same"),
        FornixAsset(name: "Copy.mov", kind: .video, byteCount: 500, fingerprint: "same"),
        FornixAsset(name: "Notes.txt", kind: .document, byteCount: 25, fingerprint: "notes")
    ]

    #expect(FornixNubiumIndex.duplicateGroups(in: assets).count == 1)
    #expect(FornixNubiumIndex.totalBytes(in: assets) == 1_025)
    #expect(FornixNubiumIndex.duplicateBytes(in: assets) == 500)
    #expect(FornixNubiumIndex.uniqueBytes(in: assets) == 525)
}

@Test func storeMutatesFavoriteArchiveAndAssets() async {
    let asset = FornixAsset(name: "Archive.zip", kind: .archive, byteCount: 42, fingerprint: "archive")
    let store = FornixNubiumStore(snapshot: .init(assets: [asset]))

    await store.setFavorite(true, for: asset.id)
    await store.setArchived(true, for: asset.id)
    var snapshot = await store.currentSnapshot()
    #expect(snapshot.assets.first?.isFavorite == true)
    #expect(snapshot.assets.first?.isArchived == true)

    await store.remove(id: asset.id)
    snapshot = await store.currentSnapshot()
    #expect(snapshot.assets.isEmpty)
}

@Test func storePersistsAndRestoresCatalog() async throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let catalogURL = directory.appendingPathComponent("FornixNubium.json")
    defer { try? FileManager.default.removeItem(at: directory) }

    let asset = FornixAsset(
        name: "Launch Plan.pdf",
        kind: .document,
        byteCount: 1_024,
        fingerprint: "launch-plan",
        tags: ["strategy"],
        folderName: "Projects",
        isFavorite: true,
        sourceURLString: "/tmp/Launch Plan.pdf"
    )
    let source = FornixNubiumStore(
        snapshot: .init(assets: [asset]),
        persistenceURL: catalogURL
    )

    try await source.save()

    let restored = FornixNubiumStore(persistenceURL: catalogURL)
    try await restored.load()
    let snapshot = await restored.currentSnapshot()

    #expect(snapshot.assets == [asset])
}

@Test func importingFilesBuildsCatalogAndDetectsDuplicates() async throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let catalogURL = directory
        .appendingPathComponent("Catalog", isDirectory: true)
        .appendingPathComponent("FornixNubium.json")
    let firstURL = directory.appendingPathComponent("First.txt")
    let secondURL = directory.appendingPathComponent("Second.txt")
    defer { try? FileManager.default.removeItem(at: directory) }

    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let sharedData = Data("shared contents".utf8)
    try sharedData.write(to: firstURL)
    try sharedData.write(to: secondURL)

    let store = FornixNubiumStore(persistenceURL: catalogURL)
    let imported = try await store.importFiles([firstURL, secondURL])
    let snapshot = await store.currentSnapshot()
    let duplicateGroups = FornixNubiumIndex.duplicateGroups(in: snapshot.assets)

    #expect(imported.count == 2)
    #expect(snapshot.assets.allSatisfy { $0.kind == .document })
    #expect(Set(snapshot.assets.map(\.fingerprint)).count == 1)
    #expect(duplicateGroups.count == 1)
    #expect(FileManager.default.fileExists(atPath: catalogURL.path))
}

@Test func reindexPreservesIdentityAndFavoriteState() async throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let catalogURL = directory.appendingPathComponent("FornixNubium.json")
    let fileURL = directory.appendingPathComponent("Growing.txt")
    defer { try? FileManager.default.removeItem(at: directory) }

    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try Data("small".utf8).write(to: fileURL)

    let store = FornixNubiumStore(persistenceURL: catalogURL)
    let imported = try await store.importFiles([fileURL])
    let original = try #require(imported.first)
    await store.setFavorite(true, for: original.id)

    try Data("a much larger replacement payload".utf8).write(to: fileURL)
    let reindexedCount = try await store.reindex()
    let snapshot = await store.currentSnapshot()
    let updated = try #require(snapshot.assets.first)

    #expect(reindexedCount == 1)
    #expect(snapshot.assets.count == 1)
    #expect(updated.id == original.id)
    #expect(updated.isFavorite)
    #expect(updated.byteCount > original.byteCount)
    #expect(updated.fingerprint != original.fingerprint)
}
