import Foundation

public enum MoneyAccountKind: String, CaseIterable, Codable, Hashable, Sendable {
    case checking
    case savings
    case cash
    case investment
    case creditCard
    case loan

    public var displayName: String {
        switch self {
        case .checking: "Checking"
        case .savings: "Savings"
        case .cash: "Cash"
        case .investment: "Investment"
        case .creditCard: "Credit Card"
        case .loan: "Loan"
        }
    }

    public var isLiability: Bool { self == .creditCard || self == .loan }
}

public struct MoneyAccount: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var institution: String
    public var kind: MoneyAccountKind
    /// Signed ledger value. Asset balances are positive; amounts owed are negative.
    public var openingBalance: Decimal
    public var currencyCode: String
    public var isArchived: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        institution: String = "",
        kind: MoneyAccountKind,
        openingBalance: Decimal = 0,
        currencyCode: String = "USD",
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.institution = institution
        self.kind = kind
        self.openingBalance = openingBalance
        self.currencyCode = currencyCode
        self.isArchived = isArchived
    }
}

public struct MoneyTransaction: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let accountID: UUID
    public var date: Date
    public var payee: String
    public var category: String
    /// A signed change to the account: positive is money in, negative is money out.
    public var amount: Decimal
    public var note: String
    public var isPending: Bool

    public init(
        id: UUID = UUID(),
        accountID: UUID,
        date: Date = Date(),
        payee: String,
        category: String,
        amount: Decimal,
        note: String = "",
        isPending: Bool = false
    ) {
        self.id = id
        self.accountID = accountID
        self.date = date
        self.payee = payee
        self.category = category
        self.amount = amount
        self.note = note
        self.isPending = isPending
    }
}

public struct MoneyBudget: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var category: String
    public var monthlyLimit: Decimal
    public var isActive: Bool

    public init(id: UUID = UUID(), category: String, monthlyLimit: Decimal, isActive: Bool = true) {
        self.id = id
        self.category = category
        self.monthlyLimit = monthlyLimit
        self.isActive = isActive
    }
}

public struct MoneyHQSnapshot: Codable, Equatable, Sendable {
    public var accounts: [MoneyAccount]
    public var transactions: [MoneyTransaction]
    public var budgets: [MoneyBudget]

    public init(
        accounts: [MoneyAccount] = [],
        transactions: [MoneyTransaction] = [],
        budgets: [MoneyBudget] = []
    ) {
        self.accounts = accounts
        self.transactions = transactions
        self.budgets = budgets
    }

    private enum CodingKeys: String, CodingKey { case accounts, transactions, budgets }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accounts = try container.decodeIfPresent([MoneyAccount].self, forKey: .accounts) ?? []
        transactions = try container.decodeIfPresent([MoneyTransaction].self, forKey: .transactions) ?? []
        budgets = try container.decodeIfPresent([MoneyBudget].self, forKey: .budgets) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accounts, forKey: .accounts)
        try container.encode(transactions, forKey: .transactions)
        try container.encode(budgets, forKey: .budgets)
    }
}

public struct MoneyBudgetProgress: Identifiable, Equatable, Sendable {
    public let budget: MoneyBudget
    public let spent: Decimal

    public var id: UUID { budget.id }
    public var remaining: Decimal { max(0, budget.monthlyLimit - spent) }
    public var isOverBudget: Bool { spent > budget.monthlyLimit }
    public var fractionUsed: Double {
        guard budget.monthlyLimit > 0 else { return 0 }
        return min(1, max(0, NSDecimalNumber(decimal: spent / budget.monthlyLimit).doubleValue))
    }
}

public struct MoneyHQSummary: Equatable, Sendable {
    public let assets: Decimal
    public let liabilities: Decimal
    public let netWorth: Decimal
    public let income: Decimal
    public let spending: Decimal

    public init(assets: Decimal, liabilities: Decimal, netWorth: Decimal, income: Decimal, spending: Decimal) {
        self.assets = assets
        self.liabilities = liabilities
        self.netWorth = netWorth
        self.income = income
        self.spending = spending
    }
}

public enum MoneyHQError: Error, Equatable, Sendable {
    case unknownAccount
    case zeroAmount
    case invalidBudgetLimit
    case unknownTransaction
}
