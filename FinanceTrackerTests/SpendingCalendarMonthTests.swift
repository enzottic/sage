import Foundation
import Testing
@testable import SageKit

@Suite("Spending calendar month")
struct SpendingCalendarMonthTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        calendar.firstWeekday = 2
        return calendar
    }

    @Test(arguments: [(2026, 8, 31, 6), (2026, 2, 28, 0), (2024, 2, 29, 4), (2026, 4, 30, 3)])
    func laysOutSundayFirstMonths(year: Int, month: Int, count: Int, padding: Int) throws {
        let date = try #require(calendar.date(from: DateComponents(year: year, month: month, day: 15)))
        let result = SpendingCalendarMonth(month: date, expenses: [], calendar: calendar)
        #expect(result.leadingEmptyDays == padding)
        #expect(result.days.count == count)
        #expect(result.days.allSatisfy { $0.amount == 0 })
        #expect(result.days.map { calendar.component(.day, from: $0.date) } == Array(1...count))
    }

    @Test @MainActor
    func sumsRecordedExpensesAndRefundsWithExclusiveMonthEnd() throws {
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 1)))
        let end = try #require(calendar.date(byAdding: .month, value: 1, to: start))
        let nextDay = try #require(calendar.date(byAdding: .day, value: 1, to: start))
        let expenses = [
            Expense(name: "Before month", amount: 999, date: start.addingTimeInterval(-1)),
            Expense(name: "Needs", amount: 20.25, category: .needs, date: start),
            Expense(name: "Wants", amount: 15.50, category: .wants, date: start.addingTimeInterval(3600)),
            Expense(name: "Savings", amount: 10, category: .savings, date: start.addingTimeInterval(7200)),
            Expense(name: "Refund", amount: -5.25, date: start.addingTimeInterval(10800)),
            Expense(name: "Refund only", amount: -12.50, date: nextDay),
            Expense(name: "Last second", amount: 8, date: end.addingTimeInterval(-1)),
            Expense(name: "Next month", amount: 999, date: end)
        ]
        let result = SpendingCalendarMonth(month: start, expenses: expenses, calendar: calendar)
        #expect(result.days[0].amount == 40.50)
        #expect(result.days[1].amount == -12.50)
        #expect(result.days[2].amount == 0)
        #expect(result.days[30].amount == 8)
        #expect(result.days.reduce(0) { $0 + $1.amount } == 36)
    }

    @Test(arguments: [(3, 8, 23), (11, 1, 25)]) @MainActor
    func groupsLocalDaysAcrossDaylightSaving(month: Int, day: Int, hours: Int) throws {
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: month, day: day)))
        let nextDay = try #require(calendar.date(byAdding: .day, value: 1, to: start))
        #expect(nextDay.timeIntervalSince(start) == Double(hours * 3600))
        let expenses = [
            Expense(name: "Start", amount: 10, date: start),
            Expense(name: "End", amount: 20, date: nextDay.addingTimeInterval(-1)),
            Expense(name: "Next day", amount: 50, date: nextDay)
        ]
        let result = SpendingCalendarMonth(month: start, expenses: expenses, calendar: calendar)
        #expect(result.days[day - 1].amount == 30)
        #expect(result.days[day].amount == 50)
        #expect(result.days.allSatisfy { calendar.startOfDay(for: $0.date) == $0.date })
    }
}
