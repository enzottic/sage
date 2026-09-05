import Foundation
import SwiftData

public enum SampleModelContainer {
    public static func make() throws -> ModelContainer {
        let schema = Schema([Expense.self, ExpenseTag.self])
        let configuration = ModelConfiguration("SageIntentSample", schema: schema)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

@MainActor @Observable
public final class ExpenseStore {
    public let context: ModelContext

    public init(modelContainer: ModelContainer) {
        context = modelContainer.mainContext
    }

    public func addExpense(_ expense: Expense) {
        context.insert(expense)
    }

    public func save() throws {
        try context.save()
    }

    public func fetchExpenses() throws -> [Expense] {
        try context.fetch(FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
    }

    public func fetchExpenses(with ids: [UUID]) throws -> [Expense] {
        try fetchExpenses().filter { ids.contains($0.id) }
    }

    public func fetchRecentExpenses(limit: Int = 5) throws -> [Expense] {
        Array(try fetchExpenses().prefix(limit))
    }

    public func fetchTag(id: UUID) throws -> ExpenseTag? {
        try context.fetch(FetchDescriptor<ExpenseTag>()).first { $0.id == id }
    }

    public func fetchExpenses(from start: Date, to end: Date) -> [Expense] {
        (try? fetchExpenses().filter { start <= $0.date && $0.date < end }) ?? []
    }

    public func monthlyTotal(for month: Date = .now) throws -> Double {
        try expenses(in: month).total
    }

    public func monthlyTotal(category: ExpenseCategory, month: Date = .now) throws -> Double {
        try expenses(in: month).filter { $0.category == category }.total
    }

    public func monthlyTotal(tagId: UUID, month: Date = .now) throws -> Double {
        try expenses(in: month).filter { expense in
            (expense.tags ?? []).contains { $0.id == tagId }
        }.total
    }

    public func remainingBudget(for category: ExpenseCategory) throws -> Double {
        budget(for: category) - (try monthlyTotal(category: category))
    }

    public func totalRemainingBudget() throws -> Double {
        5_000 - (try monthlyTotal())
    }

    public func seedIfNeeded() throws {
        guard try fetchExpenses().isEmpty else { return }

        let groceries = ExpenseTag(name: "Groceries", emoji: "🥗", symbolName: "basket.fill")
        let dining = ExpenseTag(name: "Dining", emoji: "🍽️", symbolName: "fork.knife")
        context.insert(groceries)
        context.insert(dining)
        context.insert(Expense(name: "Groceries", amount: 84.32, category: .needs, tags: [groceries]))
        context.insert(Expense(name: "Dinner", amount: 37.50, category: .wants, tags: [dining]))
        try context.save()
    }

    private func expenses(in month: Date) throws -> [Expense] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }
        return fetchExpenses(from: interval.start, to: interval.end)
    }

    private func budget(for category: ExpenseCategory) -> Double {
        switch category {
        case .needs: 2_500
        case .wants: 1_500
        case .savings: 1_000
        }
    }
}

