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

public struct MoneyHQSnapshot: Codable, Equatable, Sendable {
    public var accounts: [MoneyAccount]
    public var transactions: [MoneyTransaction]

    public init(accounts: [MoneyAccount] = [], transactions: [MoneyTransaction] = []) {
        self.accounts = accounts
        self.transactions = transactions
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
}
