import Foundation
import SwiftData
import Testing
@testable import SageKit

@Suite("Recurring spending projection")
struct SpendingProjectionTests {
    @Test(arguments: [RecurrenceFrequency.daily, .weekly, .biweekly, .monthly]) @MainActor
    func ungeneratedRuleIncludesItsActualStart(frequency: RecurrenceFrequency) throws {
        let start = Date(timeIntervalSince1970: 1_786_368_000)
        let rule = RecurringExpenseRule(name: "Bill", amount: 25, note: "", category: .needs, frequency: frequency, startDate: start, recurrenceTimeZoneIdentifier: "GMT")
        let now = start.addingTimeInterval(-60)
        let projection = SpendingProjection.project(periodExpenses: [], recurringRules: [rule], interval: DateInterval(start: now, end: start.addingTimeInterval(60)), now: now, historicalVariableTotals: [])
        #expect(projection == 25)
        #expect(rule.lastGeneratedDate == nil)
    }

    @Test @MainActor
    func anchoredProjectionMatchesGenerationAcrossShortMonths() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 31, hour: 12)))
        let end = try #require(calendar.date(from: DateComponents(year: 2026, month: 5, day: 1)))
        let rule = RecurringExpenseRule(name: "Bill", amount: 25, note: "", category: .needs, frequency: .monthly, startDate: start, lastGeneratedDate: start, recurrenceTimeZoneIdentifier: "GMT")
        var foreign = Calendar(identifier: .islamicCivil)
        foreign.timeZone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        let projection = SpendingProjection.project(periodExpenses: [], recurringRules: [rule], interval: DateInterval(start: start, end: end), now: start, historicalVariableTotals: [], calendar: foreign)
        #expect(projection == 75)
        #expect(rule.lastGeneratedDate == start)
        let container = try SageModelContainer.make(for: .test)
        container.mainContext.insert(rule)
        try RecurringExpenseService(modelContext: container.mainContext).generateAllExpenses(through: end, calendar: calendar)
        #expect(try container.mainContext.fetch(FetchDescriptor<Expense>()).total == projection)
    }

    @Test @MainActor
    func periodEndIsExclusiveAndRuleEndIsInclusive() {
        let start = Date(timeIntervalSince1970: 1_786_368_000)
        let end = start.addingTimeInterval(86_400)
        let rule = RecurringExpenseRule(name: "Bill", amount: 25, note: "", category: .needs, frequency: .daily, startDate: start, endDate: end, lastGeneratedDate: start, recurrenceTimeZoneIdentifier: "GMT")
        #expect(SpendingProjection.project(periodExpenses: [], recurringRules: [rule], interval: DateInterval(start: start, end: end), now: start, historicalVariableTotals: []) == 0)
        #expect(SpendingProjection.project(periodExpenses: [], recurringRules: [rule], interval: DateInterval(start: start, end: end.addingTimeInterval(1)), now: start, historicalVariableTotals: []) == 25)
    }

    @Test @MainActor
    func conversionBoundaryAppliesToProjectionAndUpcoming() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 31, hour: 12)))
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 28, hour: 12)))
        let end = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))
        let rule = RecurringExpenseRule(name: "Bill", amount: 25, note: "", category: .needs, frequency: .monthly, startDate: start, lastGeneratedDate: start, recurrenceTimeZoneIdentifier: nil)
        rule.enableFixedSchedule(in: calendar.timeZone, after: now, existingExpenses: [])
        #expect(SpendingProjection.project(periodExpenses: [], recurringRules: [rule], interval: DateInterval(start: now, end: end), now: now, historicalVariableTotals: []) == 0)
        #expect(rule.nextOccurrence(after: now) == calendar.date(from: DateComponents(year: 2026, month: 4, day: 30, hour: 12)))
    }
}
