import Foundation

public actor MoneyHQStore {
    private var snapshot: MoneyHQSnapshot

    public init(snapshot: MoneyHQSnapshot = MoneyHQSnapshot()) {
        self.snapshot = snapshot
    }

    public func currentSnapshot() -> MoneyHQSnapshot { snapshot }

    public func upsert(_ account: MoneyAccount) {
        if let index = snapshot.accounts.firstIndex(where: { $0.id == account.id }) {
            snapshot.accounts[index] = account
        } else {
            snapshot.accounts.append(account)
        }
    }

    public func add(_ transaction: MoneyTransaction) throws {
        guard snapshot.accounts.contains(where: { $0.id == transaction.accountID }) else {
            throw MoneyHQError.unknownAccount
        }
        guard transaction.amount != 0 else { throw MoneyHQError.zeroAmount }
        snapshot.transactions.append(transaction)
    }

    public func upsert(_ budget: MoneyBudget) throws {
        guard budget.monthlyLimit > 0 else { throw MoneyHQError.invalidBudgetLimit }
        if let index = snapshot.budgets.firstIndex(where: { $0.id == budget.id }) {
            snapshot.budgets[index] = budget
        } else {
            snapshot.budgets.append(budget)
        }
    }

    public func deleteBudget(id: UUID) {
        snapshot.budgets.removeAll { $0.id == id }
    }

    public func setPending(transactionID: UUID, isPending: Bool) throws {
        guard let index = snapshot.transactions.firstIndex(where: { $0.id == transactionID }) else {
            throw MoneyHQError.unknownTransaction
        }
        snapshot.transactions[index].isPending = isPending
    }

    public func deleteTransaction(id: UUID) throws {
        guard snapshot.transactions.contains(where: { $0.id == id }) else {
            throw MoneyHQError.unknownTransaction
        }
        snapshot.transactions.removeAll { $0.id == id }
    }

    public func save(to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.timeIntervalSinceReferenceDate)
        }
        try encoder.encode(snapshot).write(to: url, options: .atomic)
    }

    public func load(from url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            return Date(timeIntervalSinceReferenceDate: try container.decode(Double.self))
        }
        do {
            snapshot = try decoder.decode(MoneyHQSnapshot.self, from: data)
        } catch {
            let legacyDecoder = JSONDecoder()
            legacyDecoder.dateDecodingStrategy = .iso8601
            snapshot = try legacyDecoder.decode(MoneyHQSnapshot.self, from: data)
        }
    }
}
