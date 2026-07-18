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

    public func deleteTransaction(id: UUID) {
        snapshot.transactions.removeAll { $0.id == id }
    }

    public func save(to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(snapshot).write(to: url, options: .atomic)
    }

    public func load(from url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        snapshot = try decoder.decode(MoneyHQSnapshot.self, from: Data(contentsOf: url))
    }
}
