#if canImport(SwiftUI)
import Foundation
import SwiftUI
import UniformTypeIdentifiers
import FornixNubiumCore

public struct FornixNubiumView: View {
    private enum Collection: String, CaseIterable, Identifiable {
        case all = "All Files"
        case favorites = "Favorites"
        case duplicates = "Duplicates"
        case archive = "Archive"

        var id: Self { self }
    }

    private let onReturnToManor: () -> Void
    private let store: FornixNubiumStore
    @State private var query = ""
    @State private var collection: Collection = .all
    @State private var assets: [FornixAsset] = []
    @State private var isImporting = false
    @State private var isWorking = false
    @State private var statusMessage: String?

    public init(onReturnToManor: @escaping () -> Void = {}) {
        self.onReturnToManor = onReturnToManor
        self.store = FornixNubiumStore(
            persistenceURL: FornixNubiumStore.defaultPersistenceURL
        )
    }

    private var duplicateIDs: Set<UUID> {
        Set(FornixNubiumIndex.duplicateGroups(in: assets).flatMap { $0.map(\.id) })
    }

    private var displayedAssets: [FornixAsset] {
        let scoped = switch collection {
        case .all: assets.filter { !$0.isArchived }
        case .favorites: assets.filter(\.isFavorite)
        case .duplicates: assets.filter { duplicateIDs.contains($0.id) }
        case .archive: assets.filter(\.isArchived)
        }
        return FornixNubiumIndex.search(query, in: scoped)
            .sorted { $0.modifiedAt > $1.modifiedAt }
    }

    public var body: some View {
        ZStack {
            LivingGradient().ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: MyDataDCSpacing.large) {
                    header
                    metrics
                    browser
                }
                .padding(MyDataDCSpacing.xLarge)
            }
        }
        .navigationTitle("Fornix Nūbium")
        .task { await loadLibrary() }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            Task { await handleImport(result) }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: MyDataDCSpacing.small) {
                Label("FORNIX NŪBIUM", systemImage: "externaldrive.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Text("Your private cloud, awake to every detail.")
                    .font(.largeTitle.bold())
                Text("Search, organize, protect, and recover your digital life without leaving The Manor.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Reindex", systemImage: "arrow.triangle.2.circlepath") {
                Task { await reindexLibrary() }
            }
            .buttonStyle(.bordered)
            .disabled(isWorking || assets.isEmpty)
            Button("Import Files", systemImage: "plus") {
                isImporting = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(isWorking)
            Button("The Manor", systemImage: "building.columns.fill", action: onReturnToManor)
                .buttonStyle(.bordered)
        }
    }

    private var metrics: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: MyDataDCSpacing.medium)], spacing: MyDataDCSpacing.medium) {
            metric("Stored", ByteCountFormatter.string(fromByteCount: FornixNubiumIndex.totalBytes(in: assets), countStyle: .file), "externaldrive.fill")
            metric("Unique data", ByteCountFormatter.string(fromByteCount: FornixNubiumIndex.uniqueBytes(in: assets), countStyle: .file), "checkmark.seal.fill")
            metric("Assets", assets.count.formatted(), "square.stack.3d.up.fill")
            metric("Recoverable", ByteCountFormatter.string(fromByteCount: FornixNubiumIndex.duplicateBytes(in: assets), countStyle: .file), "square.on.square")
        }
    }

    private func metric(_ title: String, _ value: String, _ symbol: String) -> some View {
        FrostedPanel {
            VStack(alignment: .leading, spacing: MyDataDCSpacing.small) {
                Label(title, systemImage: symbol).foregroundStyle(.secondary)
                Text(value).font(.title.bold()).monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var browser: some View {
        FrostedPanel {
            VStack(alignment: .leading, spacing: MyDataDCSpacing.medium) {
                HStack {
                    Text("Smart Library").font(.title2.bold())
                    Spacer()
                    Picker("Collection", selection: $collection) {
                        ForEach(Collection.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 520)
                }

                TextField("Search names, folders, formats, and tags", text: $query)
                    .textFieldStyle(.roundedBorder)

                if let statusMessage {
                    Label(statusMessage, systemImage: isWorking ? "hourglass" : "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if displayedAssets.isEmpty {
                    if assets.isEmpty && query.isEmpty {
                        ContentUnavailableView {
                            Label("Your library is ready", systemImage: "externaldrive.badge.plus")
                        } description: {
                            Text("Import files to create a private, searchable catalog. Your original files stay where they are.")
                        } actions: {
                            Button("Import Files") { isImporting = true }
                                .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity, minHeight: 240)
                    } else {
                        ContentUnavailableView.search(text: query)
                            .frame(maxWidth: .infinity, minHeight: 220)
                    }
                } else {
                    VStack(spacing: 0) {
                        ForEach(displayedAssets) { asset in
                            assetRow(asset)
                            if asset.id != displayedAssets.last?.id { Divider() }
                        }
                    }
                }
            }
        }
    }

    private func assetRow(_ asset: FornixAsset) -> some View {
        HStack(spacing: MyDataDCSpacing.medium) {
            Image(systemName: asset.kind.systemImage)
                .font(.title2)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(asset.name).font(.headline)
                Text(metadata(for: asset))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if duplicateIDs.contains(asset.id) {
                Label("Duplicate", systemImage: "square.on.square")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }
            Text(ByteCountFormatter.string(fromByteCount: asset.byteCount, countStyle: .file))
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
            Button {
                Task { await toggleFavorite(asset) }
            } label: {
                Image(systemName: asset.isFavorite ? "star.fill" : "star")
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, MyDataDCSpacing.small)
        .contextMenu {
            Button(asset.isArchived ? "Return to Library" : "Move to Archive") {
                Task { await toggleArchived(asset) }
            }
        }
    }

    private func metadata(for asset: FornixAsset) -> String {
        let tags = asset.tags.prefix(2).joined(separator: " · ")
        guard let folderName = asset.folderName else { return tags }
        return tags.isEmpty ? folderName : "\(folderName)  •  \(tags)"
    }

    @MainActor
    private func loadLibrary() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await store.load()
            await refreshSnapshot()
            statusMessage = assets.isEmpty
                ? "No files imported yet."
                : "Loaded \(assets.count.formatted()) files."
        } catch {
            statusMessage = "Could not load the library: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func handleImport(_ result: Result<[URL], any Error>) async {
        do {
            let urls = try result.get()
            let scopedURLs = urls.map { ($0, $0.startAccessingSecurityScopedResource()) }
            defer {
                for (url, didAccess) in scopedURLs where didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            isWorking = true
            let imported = try await store.importFiles(urls)
            await refreshSnapshot()
            statusMessage = "Imported \(imported.count.formatted()) files."
            isWorking = false
        } catch {
            isWorking = false
            statusMessage = "Import failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func reindexLibrary() async {
        isWorking = true
        defer { isWorking = false }
        do {
            let refreshed = try await store.reindex()
            await refreshSnapshot()
            statusMessage = "Reindexed \(refreshed.formatted()) files."
        } catch {
            statusMessage = "Reindex failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func toggleFavorite(_ asset: FornixAsset) async {
        await store.setFavorite(!asset.isFavorite, for: asset.id)
        await refreshSnapshot()
    }

    @MainActor
    private func toggleArchived(_ asset: FornixAsset) async {
        await store.setArchived(!asset.isArchived, for: asset.id)
        await refreshSnapshot()
    }

    @MainActor
    private func refreshSnapshot() async {
        assets = await store.currentSnapshot().assets
    }
}
#endif
