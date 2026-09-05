import AppIntents
import Foundation

public struct AddExpenseAppIntent: AppIntent {
    public static var title: LocalizedStringResource = "Add New Expense"

    @Parameter(title: "Name") var name: String
    @Parameter(title: "Amount") var amount: Double
    @Parameter(title: "Date") var date: Date?
    @Parameter(title: "Category") var category: ExpenseCategory?
    @Parameter(title: "Tag") var tag: ExpenseTagEntity?
    @Dependency var expenseStore: ExpenseStore

    public static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$name) for \(\.$amount)") {
            \.$category
            \.$date
            \.$tag
        }
    }

    public init() {}

    @MainActor
    public func perform() async throws -> some ReturnsValue<ExpenseEntity> {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw $name.needsValueError("Enter an expense name.")
        }
        guard amount.isFinite, amount > 0 else {
            throw $amount.needsValueError("Enter an amount greater than zero.")
        }

        let expense = Expense(
            name: trimmedName,
            amount: amount,
            category: category ?? .wants,
            date: date ?? .now
        )
        if let tag, let resolved = try? expenseStore.fetchTag(id: tag.id) {
            expense.tags = [resolved]
        }
        expenseStore.addExpense(expense)
        try expenseStore.save()
        return .result(value: ExpenseEntity(expense))
    }
}

public struct GetMonthlySpendingIntent: AppIntent {
    public static var title: LocalizedStringResource = "Get Monthly Spending"

    @Parameter(title: "Category") public var category: ExpenseCategory?
    @Parameter(title: "Tag") public var tag: ExpenseTagEntity?
    @Dependency var expenseStore: ExpenseStore

    public static var parameterSummary: some ParameterSummary {
        Summary("How much have I spent this month?") {
            \.$category
            \.$tag
        }
    }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        if let tag, let total = try? expenseStore.monthlyTotal(tagId: tag.id) {
            return .result(dialog: "You've spent \(total.currencyString) on \(tag.name.lowercased()) this month.")
        } else if let category, let total = try? expenseStore.monthlyTotal(category: category) {
            return .result(dialog: "You've spent \(total.currencyString) on \(category.rawValue.lowercased()) this month.")
        }
        if let total = try? expenseStore.monthlyTotal() {
            return .result(dialog: "You've spent \(total.currencyString) this month.")
        }
        return .result(dialog: "Unable to get monthly spending from Sage.")
    }
}

public struct GetBudgetRemainingIntent: AppIntent {
    public static var title: LocalizedStringResource = "Check Budget Remaining"

    @Parameter(title: "Category") public var category: ExpenseCategory?
    @Dependency var expenseStore: ExpenseStore

    public static var parameterSummary: some ParameterSummary {
        Summary("How much budget do I have left?") { \.$category }
    }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let remaining = try category.map { try expenseStore.remainingBudget(for: $0) }
            ?? expenseStore.totalRemainingBudget()
        if remaining >= 0 {
            return .result(dialog: "You have \(remaining.currencyString) remaining this month.")
        }
        return .result(dialog: "You're \((-remaining).currencyString) over budget this month.")
    }
}

public enum ExpenseTimePeriod: String, AppEnum {
    case today, yesterday, thisWeek, lastWeek, thisMonth, lastMonth

    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Time Period"
    public static var caseDisplayRepresentations: [ExpenseTimePeriod: DisplayRepresentation] = [
        .today: "Today", .yesterday: "Yesterday", .thisWeek: "This Week",
        .lastWeek: "Last Week", .thisMonth: "This Month", .lastMonth: "Last Month",
    ]

    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date.now
        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            return (start, calendar.date(byAdding: .day, value: 1, to: start) ?? now)
        case .yesterday:
            let end = calendar.startOfDay(for: now)
            return (calendar.date(byAdding: .day, value: -1, to: end) ?? end, end)
        case .thisWeek:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return (start, calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? now)
        case .lastWeek:
            let end = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return (calendar.date(byAdding: .weekOfYear, value: -1, to: end) ?? end, end)
        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return (start, calendar.date(byAdding: .month, value: 1, to: start) ?? now)
        case .lastMonth:
            let end = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return (calendar.date(byAdding: .month, value: -1, to: end) ?? end, end)
        }
    }
}

public struct FindExpensesIntent: AppIntent {
    public static var title: LocalizedStringResource = "Find Expenses"
    public static var openAppWhenRun = false

    @Parameter(title: "Time Period", default: .thisMonth) public var timePeriod: ExpenseTimePeriod
    @Parameter(title: "Tag") public var tag: ExpenseTagEntity?
    @Parameter(title: "Category") public var category: ExpenseCategory?
    @Parameter(title: "Name Contains") public var nameFilter: String?
    @Dependency var expenseStore: ExpenseStore

    public static var parameterSummary: some ParameterSummary {
        Summary("How much did I spend \(\.$timePeriod)?") {
            \.$tag
            \.$category
            \.$nameFilter
        }
    }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<Double> {
        let range = timePeriod.dateRange
        var expenses = expenseStore.fetchExpenses(from: range.start, to: range.end)
        if let tag { expenses = expenses.filter { ($0.tags ?? []).contains { $0.id == tag.id } } }
        if let category { expenses = expenses.filter { $0.category == category } }
        if let nameFilter, !nameFilter.isEmpty {
            expenses = expenses.filter { $0.name.localizedCaseInsensitiveContains(nameFilter) }
        }
        let total = expenses.total
        return .result(value: total, dialog: "You spent \(total.currencyString) in that period.")
    }
}

