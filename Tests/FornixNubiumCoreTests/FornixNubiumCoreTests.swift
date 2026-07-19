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
