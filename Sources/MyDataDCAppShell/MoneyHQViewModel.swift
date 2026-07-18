import Foundation
import MoneyHQCore

#if canImport(SwiftUI)
import SwiftUI

@MainActor
public final class MoneyHQViewModel: ObservableObject {
    @Published public private(set) var snapshot = MoneyHQSnapshot()
    @Published public private(set) var errorMessage: String?

    public let store: MoneyHQStore
    private let persistenceURL: URL?

    public init(store: MoneyHQStore = MoneyHQStore(), persistenceURL: URL? = MoneyHQViewModel.defaultPersistenceURL) {
        self.store = store
        self.persistenceURL = persistenceURL
    }

    public static var defaultPersistenceURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MyDataDC", isDirectory: true)
            .appendingPathComponent("MoneyHQ.json")
    }

    public var summary: MoneyHQSummary { MoneyHQEngine.summary(for: snapshot) }
    public var balances: [UUID: Decimal] { MoneyHQEngine.balances(in: snapshot) }
    public var recentTransactions: [MoneyTransaction] { MoneyHQEngine.recentTransactions(in: snapshot) }

    public func load() async {
        do {
            if let persistenceURL { try await store.load(from: persistenceURL) }
            snapshot = await store.currentSnapshot()
            errorMessage = nil
        } catch {
            errorMessage = "Money HQ could not load its local ledger."
        }
    }

    public func addAccount(name: String, institution: String, kind: MoneyAccountKind, openingBalance: Decimal) async throws {
        var signedBalance = openingBalance
        if kind.isLiability && openingBalance > 0 { signedBalance = -openingBalance }
        await store.upsert(MoneyAccount(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            institution: institution.trimmingCharacters(in: .whitespacesAndNewlines),
            kind: kind,
            openingBalance: signedBalance
        ))
        try await synchronizeAndSave()
    }

    public func addTransaction(
        accountID: UUID,
        payee: String,
        category: String,
        amount: Decimal,
        isIncome: Bool,
        date: Date,
        isPending: Bool
    ) async throws {
        let signedAmount = isIncome ? abs(amount) : -abs(amount)
        try await store.add(MoneyTransaction(
            accountID: accountID,
            date: date,
            payee: payee.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: signedAmount,
            isPending: isPending
        ))
        try await synchronizeAndSave()
    }

    private func synchronizeAndSave() async throws {
        if let persistenceURL { try await store.save(to: persistenceURL) }
        snapshot = await store.currentSnapshot()
        errorMessage = nil
    }
}
#endif
