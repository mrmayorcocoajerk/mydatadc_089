import Foundation

public actor GalleryStore {
    private let fileURL: URL
    private var galleries: [Gallery]

    public init(fileURL: URL, seed: [Gallery] = []) {
        self.fileURL = fileURL
        self.galleries = seed
    }

    public func load() throws -> [Gallery] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return galleries }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let bits = try? container.decode(UInt64.self) {
                return Date(timeIntervalSinceReferenceDate: Double(bitPattern: bits))
            }
            let raw = try container.decode(Double.self)
            let seconds = raw > 100_000_000_000 ? raw / 1_000 : raw
            return Date(timeIntervalSince1970: seconds)
        }
        galleries = try decoder.decode([Gallery].self, from: data)
        return galleries
    }

    public func all() -> [Gallery] {
        galleries.sorted { $0.updatedAt > $1.updatedAt }
    }

    public func upsert(_ gallery: Gallery) throws {
        if let index = galleries.firstIndex(where: { $0.id == gallery.id }) {
            galleries[index] = gallery
        } else {
            galleries.append(gallery)
        }
        try persist()
    }

    public func delete(id: UUID) throws {
        galleries.removeAll { $0.id == id }
        try persist()
    }

    private func persist() throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.timeIntervalSinceReferenceDate.bitPattern)
        }
        try encoder.encode(galleries).write(to: fileURL, options: .atomic)
    }
}
