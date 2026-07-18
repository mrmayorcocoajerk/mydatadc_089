import Foundation
import Testing
@testable import MoneyHQCore

@Test func ledgerCalculatesBalancesAndMonthlySummary() {
    let calendar = Calendar(identifier: .gregorian)
    let now = Date(timeIntervalSince1970: 1_736_942_400)
    let checking = MoneyAccount(name: "Checking", kind: .checking, openingBalance: 1_000)
    let card = MoneyAccount(name: "Card", kind: .creditCard, openingBalance: -200)
    let snapshot = MoneyHQSnapshot(
        accounts: [checking, card],
        transactions: [
            MoneyTransaction(accountID: checking.id, date: now.addingTimeInterval(-60), payee: "Payroll", category: "Income", amount: 500),
            MoneyTransaction(accountID: checking.id, date: now.addingTimeInterval(-30), payee: "Market", category: "Food", amount: -75),
            MoneyTransaction(accountID: card.id, date: now.addingTimeInterval(-15), payee: "Transit", category: "Travel", amount: -25)
        ]
    )

    #expect(MoneyHQEngine.balance(for: checking, transactions: snapshot.transactions) == 1_425)
    #expect(MoneyHQEngine.balance(for: card, transactions: snapshot.transactions) == -225)
    let summary = MoneyHQEngine.summary(for: snapshot, now: now, calendar: calendar)
    #expect(summary.assets == 1_425)
    #expect(summary.liabilities == 225)
    #expect(summary.netWorth == 1_200)
    #expect(summary.income == 500)
    #expect(summary.spending == 100)
}

@Test func storeRejectsUnknownAccountsAndZeroAmounts() async {
    let store = MoneyHQStore()
    let unknown = MoneyTransaction(accountID: UUID(), payee: "Unknown", category: "Test", amount: 1)
    await #expect(throws: MoneyHQError.unknownAccount) { try await store.add(unknown) }

    let account = MoneyAccount(name: "Cash", kind: .cash)
    await store.upsert(account)
    let zero = MoneyTransaction(accountID: account.id, payee: "Zero", category: "Test", amount: 0)
    await #expect(throws: MoneyHQError.zeroAmount) { try await store.add(zero) }
}

@Test func storePersistsAndRestoresTheLedger() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let url = directory.appendingPathComponent("MoneyHQ.json")
    defer { try? FileManager.default.removeItem(at: directory) }
    let account = MoneyAccount(name: "Savings", institution: "Local Bank", kind: .savings, openingBalance: 250)
    let transaction = MoneyTransaction(accountID: account.id, payee: "Interest", category: "Income", amount: Decimal(string: "1.25")!)
    let source = MoneyHQStore(snapshot: .init(accounts: [account], transactions: [transaction]))

    try await source.save(to: url)
    let restored = MoneyHQStore()
    try await restored.load(from: url)

    let restoredSnapshot = await restored.currentSnapshot()
    let sourceSnapshot = await source.currentSnapshot()
    #expect(restoredSnapshot == sourceSnapshot)
}
