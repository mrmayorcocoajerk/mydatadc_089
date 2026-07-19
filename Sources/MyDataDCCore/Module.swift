import Foundation

public enum MyDataDCModuleID: String, CaseIterable, Codable, Sendable {
    case manor
    case ongakuStudio
    case chosenMeiga
    case shashinTeki
    case fornixNubium
    case careerHQ
    case moneyHQ
    case vitalsStudio
    case timeStudio
    case newsDesk
    case parcelDeliveryDropZone
    case electronicMailDigitalDoormat
    case chrysanthemum
}

public struct MyDataDCModule: Identifiable, Equatable, Codable, Sendable {
    public let id: MyDataDCModuleID
    public var displayName: String
    public var subtitle: String
    public var systemImage: String
    public var isEnabled: Bool

    public init(
        id: MyDataDCModuleID,
        displayName: String,
        subtitle: String,
        systemImage: String,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.displayName = displayName
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.isEnabled = isEnabled
    }
}
