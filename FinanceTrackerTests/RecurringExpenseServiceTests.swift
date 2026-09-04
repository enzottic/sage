import Foundation
import SwiftData
import Testing
@testable import SageKit

@Suite("Recurring expense service")
struct RecurringExpenseServiceTests {
    @Test @MainActor
    func dailyRuleGeneratesEachOccurrenceOnlyOnce() throws {
        let container = try SageModelContainer.make(for: .test)
        let context = container.mainContext
        let calendar = utcCalendar()
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 10, hour: 12)))
        let end = try #require(calendar.date(byAdding: .day, value: 2, to: start))
        let rule = RecurringExpenseRule(
            name: "Daily Coffee",
            amount: 5,
            note: "",
            category: .wants,
            frequency: .daily,
            startDate: start
        )
        context.insert(rule)
        try context.save()

        let service = RecurringExpenseService(modelContext: context)
        try service.generateAllExpenses(through: end)
        try service.generateAllExpenses(through: end)

        let expenses = try context.fetch(FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.date)]))
        let secondOccurrence = try #require(calendar.date(byAdding: .day, value: 1, to: start))
        #expect(expenses.count == 3)
        #expect(expenses.map(\.date) == [start, secondOccurrence, end])
        #expect(rule.lastGeneratedDate == end)
        #expect(expenses.allSatisfy { $0.recurringExpenseId == rule.id })
    }

    @Test @MainActor
    func ruleStopsAtEndDate() throws {
        let container = try SageModelContainer.make(for: .test)
        let context = container.mainContext
        let calendar = utcCalendar()
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 1, hour: 12)))
        let end = try #require(calendar.date(byAdding: .weekOfYear, value: 1, to: start))
        let target = try #require(calendar.date(byAdding: .month, value: 1, to: start))
        let rule = RecurringExpenseRule(
            name: "Weekly Bill",
            amount: 25,
            note: "",
            category: .needs,
            frequency: .weekly,
            startDate: start,
            endDate: end
        )
        context.insert(rule)

        try RecurringExpenseService(modelContext: context).generateAllExpenses(through: target)

        let expenses = try context.fetch(FetchDescriptor<Expense>())
        #expect(expenses.map(\.date).sorted() == [start, end])
        #expect(rule.lastGeneratedDate == end)
    }

    @Test @MainActor
    func existingOccurrenceIsSkippedWhenRuleCursorIsStale() throws {
        let container = try SageModelContainer.make(for: .test)
        let context = container.mainContext
        let calendar = utcCalendar()
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 10, hour: 12)))
        let end = try #require(calendar.date(byAdding: .day, value: 1, to: start))
        let rule = RecurringExpenseRule(
            name: "Daily Coffee",
            amount: 5,
            note: "",
            category: .wants,
            frequency: .daily,
            startDate: start
        )
        context.insert(rule)
        context.insert(
            Expense(
                name: rule.name,
                amount: rule.amount,
                category: rule.category,
                date: start,
                recurringExpenseId: rule.id
            )
        )
        try context.save()

        let result = try RecurringExpenseService(modelContext: context)
            .generateAllExpenses(through: end)
        let expenses = try context.fetch(FetchDescriptor<Expense>())

        #expect(result.generatedCount == 1)
        #expect(result.skippedCount == 1)
        #expect(result.repair.backfilledCount == 1)
        #expect(expenses.count == 2)
        #expect(Set(expenses.compactMap(\.recurringOccurrenceKey)).count == 2)
        #expect(rule.lastGeneratedDate == end)
    }

    @Test @MainActor
    func exactImportedDuplicateIsRemoved() throws {
        let container = try SageModelContainer.make(for: .test)
        let context = container.mainContext
        let date = Date(timeIntervalSince1970: 1_786_368_000)
        let rule = RecurringExpenseRule(
            name: "Subscription",
            amount: 12,
            note: "Monthly plan",
            category: .wants,
            frequency: .monthly,
            startDate: date,
            lastGeneratedDate: date
        )
        context.insert(rule)
        for _ in 0..<2 {
            context.insert(
                Expense(
                    name: rule.name,
                    amount: rule.amount,
                    category: rule.category,
                    date: date,
                    note: rule.note,
                    recurringExpenseId: rule.id
                )
            )
        }
        try context.save()

        let result = try RecurringExpenseService(modelContext: context)
            .generateAllExpenses(through: date)
        let expenses = try context.fetch(FetchDescriptor<Expense>())

        #expect(result.generatedCount == 0)
        #expect(result.repair.backfilledCount == 2)
        #expect(result.repair.removedCount == 1)
        #expect(result.repair.conflictingGroupCount == 0)
        #expect(expenses.count == 1)
    }

    @Test @MainActor
    func conflictingImportedCopiesAreNotDeleted() throws {
        let container = try SageModelContainer.make(for: .test)
        let context = container.mainContext
        let date = Date(timeIntervalSince1970: 1_786_368_000)
        let ruleID = UUID()
        let key = RecurringExpenseOccurrence.key(ruleID: ruleID, scheduledDate: date)
        context.insert(
            Expense(
                name: "Subscription",
                amount: 12,
                date: date,
                recurringExpenseId: ruleID,
                recurringOccurrenceKey: key
            )
        )
        context.insert(
            Expense(
                name: "Subscription",
                amount: 15,
                date: date,
                recurringExpenseId: ruleID,
                recurringOccurrenceKey: key
            )
        )
        try context.save()

        let firstResult = try RecurringExpenseRepairService(modelContext: context).repair()
        try context.save()
        let secondResult = try RecurringExpenseRepairService(modelContext: context).repair()
        let expenses = try context.fetch(FetchDescriptor<Expense>())

        #expect(firstResult.removedCount == 0)
        #expect(firstResult.conflictingGroupCount == 1)
        #expect(secondResult.removedCount == 0)
        #expect(expenses.count == 2)
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
