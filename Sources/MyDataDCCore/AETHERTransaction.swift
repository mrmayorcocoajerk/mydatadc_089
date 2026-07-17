import Foundation

public struct AETHERTransaction: Sendable, Equatable {
    public enum Operation: Sendable, Equatable {
        case upsert(AETHERObject)
        case remove(AETHERObjectID)
    }

    public let id: UUID
    public let operations: [Operation]

    public init(id: UUID = UUID(), operations: [Operation]) {
        self.id = id
        self.operations = operations
    }
}

public struct AETHERTransactionResult: Sendable, Equatable {
    public let transactionID: UUID
    public let insertedOrUpdated: [AETHERObject]
    public let removed: [AETHERObject]

    public init(
        transactionID: UUID,
        insertedOrUpdated: [AETHERObject],
        removed: [AETHERObject]
    ) {
        self.transactionID = transactionID
        self.insertedOrUpdated = insertedOrUpdated
        self.removed = removed
    }
}
