import Foundation

public enum MoneyHQEngine {
    public static func balance(for account: MoneyAccount, transactions: [MoneyTransaction]) -> Decimal {
        transactions.lazy
            .filter { $0.accountID == account.id }
            .reduce(account.openingBalance) { $0 + $1.amount }
    }

    public static func balances(in snapshot: MoneyHQSnapshot) -> [UUID: Decimal] {
        Dictionary(uniqueKeysWithValues: snapshot.accounts.map {
            ($0.id, balance(for: $0, transactions: snapshot.transactions))
        })
    }

    public static func summary(
        for snapshot: MoneyHQSnapshot,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> MoneyHQSummary {
        let active = snapshot.accounts.filter { !$0.isArchived }
        let values = active.map { ($0, balance(for: $0, transactions: snapshot.transactions)) }
        let assets = values.filter { !$0.0.kind.isLiability }.reduce(Decimal.zero) { $0 + max(0, $1.1) }
        let liabilities = values.filter { $0.0.kind.isLiability }.reduce(Decimal.zero) { $0 + max(0, -$1.1) }
        let netWorth = values.reduce(Decimal.zero) { $0 + $1.1 }
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? .distantPast
        let monthly = snapshot.transactions.filter { $0.date >= monthStart && $0.date <= now }
        let income = monthly.filter { $0.amount > 0 }.reduce(Decimal.zero) { $0 + $1.amount }
        let spending = monthly.filter { $0.amount < 0 }.reduce(Decimal.zero) { $0 + -$1.amount }
        return MoneyHQSummary(assets: assets, liabilities: liabilities, netWorth: netWorth, income: income, spending: spending)
    }

    public static func recentTransactions(in snapshot: MoneyHQSnapshot, limit: Int = 20) -> [MoneyTransaction] {
        Array(snapshot.transactions.sorted { $0.date > $1.date }.prefix(limit))
    }
}
