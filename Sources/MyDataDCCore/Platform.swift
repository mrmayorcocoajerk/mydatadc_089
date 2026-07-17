public enum MyDataDCPlatform: String, CaseIterable, Codable, Sendable {
    case macOS, iPadOS, iOS, watchOS
}

public struct PlatformCapabilityPolicy: Equatable, Sendable {
    public let flagshipPlatforms: Set<MyDataDCPlatform> = [.macOS, .iPadOS]
    public init() {}
    public func hasFullFeatureParity(_ platform: MyDataDCPlatform) -> Bool {
        flagshipPlatforms.contains(platform)
    }
}
