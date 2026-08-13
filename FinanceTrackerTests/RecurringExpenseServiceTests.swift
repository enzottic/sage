import Foundation
import SwiftData
import Testing
@testable import SageKit

@Suite("Recurring expense service")
struct RecurringExpenseServiceTests {
    @Test @MainActor
    func dailyRuleGeneratesEachOccurrenceOnlyOnce() throws {
        let container = try SageModelContainer.makeInMemory()
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
        service.generateAllExpenses(through: end)
        service.generateAllExpenses(through: end)

        let expenses = try context.fetch(FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.date)]))
        let secondOccurrence = try #require(calendar.date(byAdding: .day, value: 1, to: start))
        #expect(expenses.count == 3)
        #expect(expenses.map(\.date) == [start, secondOccurrence, end])
        #expect(rule.lastGeneratedDate == end)
        #expect(expenses.allSatisfy { $0.recurringExpenseId == rule.id })
    }

    @Test @MainActor
    func ruleStopsAtEndDate() throws {
        let container = try SageModelContainer.makeInMemory()
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

        RecurringExpenseService(modelContext: context).generateAllExpenses(through: target)

        let expenses = try context.fetch(FetchDescriptor<Expense>())
        #expect(expenses.map(\.date).sorted() == [start, end])
        #expect(rule.lastGeneratedDate == end)
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
