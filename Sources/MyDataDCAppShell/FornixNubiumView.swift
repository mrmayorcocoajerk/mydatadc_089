#if canImport(SwiftUI)
import Foundation
import SwiftUI
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
    @State private var query = ""
    @State private var collection: Collection = .all
    @State private var assets: [FornixAsset]

    public init(onReturnToManor: @escaping () -> Void = {}) {
        self.onReturnToManor = onReturnToManor
        _assets = State(initialValue: Self.previewAssets)
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
            Button("The Manor", systemImage: "building.columns.fill", action: onReturnToManor)
                .buttonStyle(.borderedProminent)
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

                if displayedAssets.isEmpty {
                    ContentUnavailableView.search(text: query)
                        .frame(maxWidth: .infinity, minHeight: 220)
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
                guard let index = assets.firstIndex(where: { $0.id == asset.id }) else { return }
                assets[index].isFavorite.toggle()
            } label: {
                Image(systemName: asset.isFavorite ? "star.fill" : "star")
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, MyDataDCSpacing.small)
    }

    private func metadata(for asset: FornixAsset) -> String {
        let tags = asset.tags.prefix(2).joined(separator: " · ")
        guard let folderName = asset.folderName else { return tags }
        return tags.isEmpty ? folderName : "\(folderName)  •  \(tags)"
    }

    private static let previewAssets: [FornixAsset] = [
        .init(name: "Mayor Portrait.heic", kind: .photo, byteCount: 8_400_000, fingerprint: "portrait-master", tags: ["portrait", "manor"], folderName: "Photography", isFavorite: true),
        .init(name: "Mayor Portrait Copy.heic", kind: .photo, byteCount: 8_400_000, fingerprint: "portrait-master", tags: ["duplicate", "portrait"], folderName: "Imports"),
        .init(name: "Fornix Nūbium Brief.pdf", kind: .document, byteCount: 2_650_000, fingerprint: "brief-v3", tags: ["strategy", "cloud"], folderName: "Projects", isFavorite: true),
        .init(name: "Studio Session 07.wav", kind: .audio, byteCount: 184_000_000, fingerprint: "studio-session-07", tags: ["music", "master"], folderName: "ongaku(studio)"),
        .init(name: "Legacy Export.zip", kind: .archive, byteCount: 92_000_000, fingerprint: "legacy-export", tags: ["cold storage"], folderName: "Archive", isArchived: true)
    ]
}
#endif
