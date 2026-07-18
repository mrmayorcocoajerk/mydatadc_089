#if canImport(SwiftUI)
import SwiftUI
import MoneyHQCore

public struct MoneyHQView: View {
    @StateObject private var viewModel: MoneyHQViewModel
    @State private var sheet: MoneyHQSheet?
    @State private var transactionToDelete: MoneyTransaction?
    private let onReturnToManor: () -> Void

    public init(
        viewModel: MoneyHQViewModel = MoneyHQViewModel(),
        onReturnToManor: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onReturnToManor = onReturnToManor
    }

    public var body: some View {
        ZStack {
            LivingGradient().ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: MyDataDCSpacing.large) {
                    header
                    summaryGrid
                    budgetsPanel
                    accountsPanel
                    ledgerPanel
                }
                .padding(MyDataDCSpacing.xLarge)
            }
        }
        .navigationTitle("Money HQ")
        .task { await viewModel.load() }
        .sheet(item: $sheet) { destination in
            switch destination {
            case .account:
                AddMoneyAccountView(viewModel: viewModel)
            case .transaction:
                AddMoneyTransactionView(viewModel: viewModel)
            case .budget:
                AddMoneyBudgetView(viewModel: viewModel)
            }
        }
        .alert(
            "Delete transaction?",
            isPresented: Binding(
                get: { transactionToDelete != nil },
                set: { if !$0 { transactionToDelete = nil } }
            ),
            presenting: transactionToDelete
        ) { transaction in
            Button("Cancel", role: .cancel) { transactionToDelete = nil }
            Button("Delete", role: .destructive) {
                transactionToDelete = nil
                Task { try? await viewModel.deleteTransaction(id: transaction.id) }
            }
        } message: { transaction in
            Text("This removes \(transaction.payee.isEmpty ? transaction.category : transaction.payee) from the local ledger.")
        }
    }

    private var header: some View {
        FrostedPanel {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: MyDataDCSpacing.small) {
                    Text("Money HQ").font(.largeTitle.bold())
                    Text("A private, on-device view of your balances and activity.")
                        .font(.headline).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Back to The Manor", systemImage: "house", action: onReturnToManor)
            }
        }
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 16)], spacing: 16) {
            metric("Net Worth", value: viewModel.summary.netWorth, icon: "chart.line.uptrend.xyaxis")
            metric("Assets", value: viewModel.summary.assets, icon: "banknote")
            metric("Liabilities", value: viewModel.summary.liabilities, icon: "creditcard")
            metric("This Month In", value: viewModel.summary.income, icon: "arrow.down.circle")
            metric("This Month Out", value: viewModel.summary.spending, icon: "arrow.up.circle")
        }
    }

    private func metric(_ title: String, value: Decimal, icon: String) -> some View {
        FrostedPanel {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: icon).foregroundStyle(.secondary)
                Text(currency(value)).font(.title2.bold()).monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var accountsPanel: some View {
        FrostedPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Accounts").font(.title2.bold())
                    Spacer()
                    Button("Add Account", systemImage: "plus") { sheet = .account }
                }
                if viewModel.snapshot.accounts.isEmpty {
                    ContentUnavailableView("No accounts yet", systemImage: "building.columns", description: Text("Add an account to begin your local ledger."))
                } else {
                    ForEach(viewModel.snapshot.accounts.filter { !$0.isArchived }) { account in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(account.name).font(.headline)
                                Text([account.institution, account.kind.displayName].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(currency(viewModel.balances[account.id] ?? 0)).bold().monospacedDigit()
                        }
                        Divider()
                    }
                }
            }
        }
    }

    private var budgetsPanel: some View {
        FrostedPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Monthly Budgets").font(.title2.bold())
                    Spacer()
                    Button("Add Budget", systemImage: "plus") { sheet = .budget }
                }
                if viewModel.budgetProgress.isEmpty {
                    ContentUnavailableView(
                        "No budgets yet",
                        systemImage: "target",
                        description: Text("Set a category limit to track this month's spending.")
                    )
                } else {
                    ForEach(viewModel.budgetProgress) { progress in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(progress.budget.category).font(.headline)
                                Spacer()
                                Text("\(currency(progress.spent)) of \(currency(progress.budget.monthlyLimit))")
                                    .font(.subheadline).monospacedDigit()
                            }
                            ProgressView(value: progress.fractionUsed)
                                .tint(progress.isOverBudget ? Color.red : Color.cyan)
                            Text(progress.isOverBudget
                                 ? "Over by \(currency(progress.spent - progress.budget.monthlyLimit))"
                                 : "\(currency(progress.remaining)) remaining")
                                .font(.caption)
                                .foregroundStyle(progress.isOverBudget ? Color.red : Color.secondary)
                        }
                        Divider()
                    }
                }
            }
        }
    }

    private var ledgerPanel: some View {
        FrostedPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Recent Activity").font(.title2.bold())
                    Spacer()
                    Button("Add Transaction", systemImage: "plus") { sheet = .transaction }
                        .disabled(viewModel.snapshot.accounts.isEmpty)
                }
                if viewModel.recentTransactions.isEmpty {
                    ContentUnavailableView("No transactions yet", systemImage: "list.bullet.rectangle")
                } else {
                    ForEach(viewModel.recentTransactions, id: \.id) { (transaction: MoneyTransaction) in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(transaction.payee.isEmpty ? transaction.category : transaction.payee).font(.headline)
                                Text(transaction.date.formatted(date: .abbreviated, time: .omitted) + " · " + transaction.category)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            if transaction.isPending { Text("Pending").font(.caption).foregroundStyle(.orange) }
                            Spacer()
                            Text(currency(transaction.amount))
                                .foregroundStyle(transaction.amount < 0 ? Color.primary : Color.green)
                                .monospacedDigit()
                            Menu {
                                Button(
                                    transaction.isPending ? "Mark Cleared" : "Mark Pending",
                                    systemImage: transaction.isPending ? "checkmark.circle" : "clock"
                                ) {
                                    Task {
                                        try? await viewModel.setPending(
                                            transactionID: transaction.id,
                                            isPending: !transaction.isPending
                                        )
                                    }
                                }
                                Divider()
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    transactionToDelete = transaction
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                        Divider()
                    }
                }
            }
        }
    }

    private func currency(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).doubleValue.formatted(.currency(code: "USD"))
    }
}

private enum MoneyHQSheet: String, Identifiable {
    case account, transaction, budget
    var id: String { rawValue }
}

private struct AddMoneyBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MoneyHQViewModel
    @State private var category = ""
    @State private var limit = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Category, such as Food", text: $category)
                TextField("Monthly limit", text: $limit)
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .navigationTitle("Add Budget")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 420, minHeight: 240)
    }

    private func save() {
        guard let value = Decimal(string: limit.replacingOccurrences(of: ",", with: "")), value > 0 else {
            errorMessage = "Enter a monthly limit greater than zero."
            return
        }
        Task {
            do {
                try await viewModel.addBudget(category: category, monthlyLimit: value)
                dismiss()
            } catch { errorMessage = "The budget could not be saved." }
        }
    }
}

private struct AddMoneyAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MoneyHQViewModel
    @State private var name = ""
    @State private var institution = ""
    @State private var kind = MoneyAccountKind.checking
    @State private var balance = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Account name", text: $name)
                TextField("Institution (optional)", text: $institution)
                Picker("Type", selection: $kind) {
                    ForEach(MoneyAccountKind.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                TextField(kind.isLiability ? "Amount owed" : "Opening balance", text: $balance)
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .navigationTitle("Add Account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .frame(minWidth: 420, minHeight: 300)
    }

    private func save() {
        guard let amount = Decimal(string: balance.replacingOccurrences(of: ",", with: "")) else {
            errorMessage = "Enter a valid opening balance."
            return
        }
        Task {
            do {
                try await viewModel.addAccount(name: name, institution: institution, kind: kind, openingBalance: amount)
                dismiss()
            } catch { errorMessage = "The account could not be saved." }
        }
    }
}

private struct AddMoneyTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MoneyHQViewModel
    @State private var accountID: UUID?
    @State private var payee = ""
    @State private var category = "General"
    @State private var amount = ""
    @State private var isIncome = false
    @State private var date = Date()
    @State private var isPending = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Picker("Account", selection: $accountID) {
                    ForEach(viewModel.snapshot.accounts.filter { !$0.isArchived }) { account in
                        Text(account.name).tag(Optional(account.id))
                    }
                }
                Picker("Direction", selection: $isIncome) {
                    Text("Money Out").tag(false)
                    Text("Money In").tag(true)
                }.pickerStyle(.segmented)
                TextField("Payee or source", text: $payee)
                TextField("Category", text: $category)
                TextField("Amount", text: $amount)
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Toggle("Pending", isOn: $isPending)
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .navigationTitle("Add Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
        }
        .frame(minWidth: 440, minHeight: 400)
        .onAppear { accountID = accountID ?? viewModel.snapshot.accounts.first(where: { !$0.isArchived })?.id }
    }

    private func save() {
        guard let accountID, let value = Decimal(string: amount.replacingOccurrences(of: ",", with: "")), value != 0 else {
            errorMessage = "Choose an account and enter a non-zero amount."
            return
        }
        Task {
            do {
                try await viewModel.addTransaction(accountID: accountID, payee: payee, category: category, amount: value, isIncome: isIncome, date: date, isPending: isPending)
                dismiss()
            } catch { errorMessage = "The transaction could not be saved." }
        }
    }
}
#endif
