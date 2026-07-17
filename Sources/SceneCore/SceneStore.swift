import Foundation

public actor SceneStore {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL) {
        self.fileURL = fileURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .millisecondsSince1970
        decoder.dateDecodingStrategy = .millisecondsSince1970
    }

    public func load() throws -> [ManorScene] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        return try decoder.decode([ManorScene].self, from: Data(contentsOf: fileURL))
    }

    public func upsert(_ scene: ManorScene) throws {
        var scenes = try load()
        if let index = scenes.firstIndex(where: { $0.id == scene.id }) {
            scenes[index] = scene
        } else {
            guard !scenes.contains(where: { $0.name.localizedCaseInsensitiveCompare(scene.name) == .orderedSame }) else {
                throw SceneEngineError.duplicateScene
            }
            scenes.append(scene)
        }
        try save(scenes)
    }

    public func remove(id: UUID) throws {
        var scenes = try load()
        guard scenes.contains(where: { $0.id == id }) else { throw SceneEngineError.sceneNotFound }
        scenes.removeAll { $0.id == id }
        try save(scenes)
    }

    private func save(_ scenes: [ManorScene]) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(scenes).write(to: fileURL, options: .atomic)
    }
}

public actor SceneActivationHistory {
    private var values: [SceneActivation] = []
    public init() {}

    public func record(sceneID: UUID, reason: String, at date: Date = .now) {
        values.append(SceneActivation(sceneID: sceneID, activatedAt: date, reason: reason))
    }

    public func all() -> [SceneActivation] { values }
}
