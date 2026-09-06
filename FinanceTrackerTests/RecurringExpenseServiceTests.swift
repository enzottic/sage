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
            startDate: start,
            recurrenceTimeZoneIdentifier: "GMT"
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
            endDate: end,
            recurrenceTimeZoneIdentifier: "GMT"
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
            startDate: start,
            recurrenceTimeZoneIdentifier: "GMT"
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

    @Test(arguments: [2026, 2028]) @MainActor
    func monthlyAnchorSurvivesShortMonths(year: Int) throws {
        let calendar = utcCalendar()
        for day in [29, 30, 31] {
            let start = try #require(calendar.date(from: DateComponents(year: year, month: 1, day: day, hour: 12)))
            let expected = try [1, 2, 3, 4].map { month in
                let lastDay = month == 2 ? (year == 2028 ? 29 : 28) : (month == 4 ? 30 : 31)
                return try #require(calendar.date(from: DateComponents(year: year, month: month, day: min(day, lastDay), hour: 12)))
            }
            for incremental in [false, true] {
                let container = try SageModelContainer.make(for: .test)
                let context = container.mainContext
                let rule = RecurringExpenseRule(name: "Monthly", amount: 10, note: "", category: .needs, frequency: .monthly, startDate: start, recurrenceTimeZoneIdentifier: "GMT")
                context.insert(rule)
                let service = RecurringExpenseService(modelContext: context)
                for date in incremental ? expected : [expected[3]] {
                    try service.generateAllExpenses(through: date)
                }
                #expect(try context.fetch(FetchDescriptor<Expense>()).map(\.date).sorted() == expected)
                #expect(rule.nextOccurrence(after: start) == calendar.date(from: DateComponents(year: year, month: 5, day: day, hour: 12)))
            }
        }
    }

    @Test @MainActor
    func legacyScheduleRemainsUnchangedUntilConfirmed() throws {
        let calendar = utcCalendar()
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 31, hour: 12)))
        let march = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 28, hour: 12)))
        let container = try SageModelContainer.make(for: .test)
        let context = container.mainContext
        let rule = RecurringExpenseRule(name: "Legacy", amount: 10, note: "", category: .needs, frequency: .monthly, startDate: start, recurrenceTimeZoneIdentifier: nil)
        context.insert(rule)
        try RecurringExpenseService(modelContext: context).generateAllExpenses(through: march, calendar: calendar)
        #expect(rule.lastGeneratedDate == march)
        #expect(rule.recurrenceTimeZoneIdentifier == nil)
        #expect(rule.recurrenceEffectiveDate == nil)
        #expect(rule.nextOccurrence(calendar: calendar) == calendar.date(from: DateComponents(year: 2026, month: 4, day: 28, hour: 12)))
    }

    @Test @MainActor
    func confirmedConversionPreservesKeysAndSkipsCompletedMonthWithStaleCursor() throws {
        let calendar = utcCalendar()
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 31, hour: 12)))
        let march = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 28, hour: 12)))
        let april = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 30, hour: 12)))
        let container = try SageModelContainer.make(for: .test)
        let context = container.mainContext
        let rule = RecurringExpenseRule(name: "Legacy", amount: 10, note: "", category: .needs, frequency: .monthly, startDate: start, lastGeneratedDate: start, recurrenceTimeZoneIdentifier: nil)
        let key = RecurringExpenseOccurrence.key(ruleID: rule.id, scheduledDate: march)
        let editedDate = start.addingTimeInterval(60)
        let expense = Expense(name: "Edited", amount: 15, date: editedDate, recurringExpenseId: rule.id, recurringOccurrenceKey: key)
        context.insert(rule)
        context.insert(expense)
        rule.enableFixedSchedule(in: calendar.timeZone, after: start, existingExpenses: [expense])
        #expect(rule.recurrenceEffectiveDate == march)
        #expect(rule.lastGeneratedDate == start)
        #expect(rule.startDate == start)
        #expect(rule.nextOccurrence(calendar: calendar) == april)
        try context.save()

        // A stale CloudKit cursor must not remove the separately persisted boundary.
        rule.lastGeneratedDate = nil
        let service = RecurringExpenseService(modelContext: context)
        try service.generateAllExpenses(through: april)
        rule.lastGeneratedDate = start
        try service.generateAllExpenses(through: april)
        let expenses = try context.fetch(FetchDescriptor<Expense>())
        #expect(expenses.count == 2)
        #expect(expense.recurringOccurrenceKey == key)
        #expect(expense.date == editedDate)
        #expect(expense.amount == 15)
        #expect(rule.lastGeneratedDate == april)
    }

    @Test(arguments: [RecurrenceFrequency.daily, .weekly, .biweekly, .monthly]) @MainActor
    func fixedScheduleIgnoresDeviceCalendarAndTimeZone(frequency: RecurrenceFrequency) throws {
        var home = utcCalendar()
        home.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let start = try #require(home.date(from: DateComponents(year: 2026, month: 2, day: 28, hour: 12)))
        let end = try #require(home.date(from: DateComponents(year: 2026, month: 4, day: 30, hour: 12)))
        var foreign = Calendar(identifier: .buddhist)
        foreign.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let container = try SageModelContainer.make(for: .test)
        let context = container.mainContext
        let rule = RecurringExpenseRule(name: "Fixed", amount: 10, note: "", category: .needs, frequency: frequency, startDate: start, recurrenceTimeZoneIdentifier: home.timeZone.identifier)
        context.insert(rule)
        let service = RecurringExpenseService(modelContext: context)
        try service.generateAllExpenses(through: end, calendar: home)
        let before = try context.fetch(FetchDescriptor<Expense>()).compactMap(\.recurringOccurrenceKey).sorted()
        rule.lastGeneratedDate = nil
        let result = try service.generateAllExpenses(through: end, calendar: foreign)
        #expect(result.generatedCount == 0)
        #expect(result.skippedCount == before.count)
        #expect(try context.fetch(FetchDescriptor<Expense>()).compactMap(\.recurringOccurrenceKey).sorted() == before)
        #expect(rule.nextOccurrence(calendar: home) == rule.nextOccurrence(calendar: foreign))
    }

    @Test @MainActor
    func dstGapDoesNotPermanentlyShiftAnchorTime() throws {
        var calendar = utcCalendar()
        calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 2, minute: 30)))
        let rule = RecurringExpenseRule(name: "DST", amount: 1, note: "", category: .needs, frequency: .daily, startDate: start, recurrenceTimeZoneIdentifier: calendar.timeZone.identifier)
        let schedule = RecurringExpenseSchedule(rule: rule)
        let gap = try #require(schedule.nextOccurrence(after: start))
        let following = try #require(schedule.nextOccurrence(after: gap))
        #expect(calendar.component(.hour, from: gap) == 3)
        #expect(calendar.component(.minute, from: gap) == 30)
        #expect(calendar.component(.hour, from: following) == 2)
        #expect(calendar.component(.minute, from: following) == 30)
    }

    @Test(arguments: [RecurrenceFrequency.daily, .weekly, .biweekly, .monthly]) @MainActor
    func lordHoweHalfHourGapStaysOnScheduledDay(frequency: RecurrenceFrequency) throws {
        var calendar = utcCalendar()
        calendar.timeZone = try #require(TimeZone(identifier: "Australia/Lord_Howe"))
        let startComponents: DateComponents
        let followingComponents: DateComponents
        switch frequency {
        case .daily:
            startComponents = DateComponents(year: 2026, month: 10, day: 3, hour: 2, minute: 15)
            followingComponents = DateComponents(year: 2026, month: 10, day: 5, hour: 2, minute: 15)
        case .weekly:
            startComponents = DateComponents(year: 2026, month: 9, day: 27, hour: 2, minute: 15)
            followingComponents = DateComponents(year: 2026, month: 10, day: 11, hour: 2, minute: 15)
        case .biweekly:
            startComponents = DateComponents(year: 2026, month: 9, day: 20, hour: 2, minute: 15)
            followingComponents = DateComponents(year: 2026, month: 10, day: 18, hour: 2, minute: 15)
        case .monthly:
            startComponents = DateComponents(year: 2026, month: 9, day: 4, hour: 2, minute: 15)
            followingComponents = DateComponents(year: 2026, month: 11, day: 4, hour: 2, minute: 15)
        }
        let start = try #require(calendar.date(from: startComponents)).addingTimeInterval(0.125)
        let gap = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 4, hour: 2, minute: 30))).addingTimeInterval(0.125)
        let following = try #require(calendar.date(from: followingComponents)).addingTimeInterval(0.125)
        let container = try SageModelContainer.make(for: .test)
        let context = container.mainContext
        let rule = RecurringExpenseRule(name: "Lord Howe", amount: 1, note: "", category: .needs, frequency: frequency, startDate: start, recurrenceTimeZoneIdentifier: calendar.timeZone.identifier)
        context.insert(rule)
        let schedule = RecurringExpenseSchedule(rule: rule)
        #expect(schedule.nextOccurrence(after: start) == gap)
        #expect(schedule.nextOccurrence(after: gap) == following)

        let service = RecurringExpenseService(modelContext: context)
        try service.generateAllExpenses(through: gap)
        #expect(rule.lastGeneratedDate == gap)
        try service.generateAllExpenses(through: following)
        rule.lastGeneratedDate = start
        let retry = try service.generateAllExpenses(through: following)
        #expect(retry.generatedCount == 0)
        #expect(retry.skippedCount == 2)
        #expect(try context.fetch(FetchDescriptor<Expense>()).map(\.date).sorted() == [start, gap, following])
    }

    @Test @MainActor
    func newRulesCaptureTimeZoneWithoutConversionBoundary() {
        let rule = RecurringExpenseRule(name: "New", amount: 1, note: "", category: .needs, frequency: .monthly, startDate: .now)
        #expect(rule.recurrenceTimeZoneIdentifier == TimeZone.current.identifier)
        #expect(rule.recurrenceEffectiveDate == nil)
    }

    @Test @MainActor
    func conversionWithNoCursorSkipsPastCatchUpButKeepsFutureStart() throws {
        let calendar = utcCalendar()
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 15, hour: 12)))
        let future = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 20, hour: 12)))
        let rule = RecurringExpenseRule(name: "Future", amount: 10, note: "", category: .needs, frequency: .monthly, startDate: future, recurrenceTimeZoneIdentifier: nil)
        rule.enableFixedSchedule(in: calendar.timeZone, after: now, existingExpenses: [])
        #expect(RecurringExpenseSchedule(rule: rule).firstPendingOccurrence() == future)
        rule.startDate = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 20, hour: 12)))
        #expect(RecurringExpenseSchedule(rule: rule).firstPendingOccurrence() == future)
        rule.endDate = now
        #expect(RecurringExpenseSchedule(rule: rule).firstPendingOccurrence() == nil)
    }

    @Test @MainActor
    func dailyConversionHonorsBoundaryWithoutChangingCadenceOrKeys() throws {
        let start = Date(timeIntervalSince1970: 1_786_368_000)
        let boundary = start.addingTimeInterval(2 * 86_400 + 60)
        let rule = RecurringExpenseRule(name: "Daily", amount: 1, note: "", category: .needs, frequency: .daily, startDate: start, recurrenceTimeZoneIdentifier: nil)
        rule.enableFixedSchedule(in: utcCalendar().timeZone, after: boundary, existingExpenses: [])
        let expected = start.addingTimeInterval(3 * 86_400)
        #expect(RecurringExpenseSchedule(rule: rule).firstPendingOccurrence() == expected)
        rule.lastGeneratedDate = start
        #expect(RecurringExpenseSchedule(rule: rule).firstPendingOccurrence() == expected)
    }

    @Test @MainActor
    func dstOverlapUsesFirstOccurrenceAndRetainsFractionalSeconds() throws {
        var calendar = utcCalendar()
        calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 31, hour: 1, minute: 30))).addingTimeInterval(0.125)
        let rule = RecurringExpenseRule(name: "DST", amount: 1, note: "", category: .needs, frequency: .daily, startDate: start, recurrenceTimeZoneIdentifier: calendar.timeZone.identifier)
        let next = try #require(RecurringExpenseSchedule(rule: rule).nextOccurrence(after: start))
        #expect(next.timeIntervalSince(start) == 86_400)
        #expect(calendar.timeZone.secondsFromGMT(for: next) == -4 * 3_600)
        #expect(next.timeIntervalSince1970 - floor(next.timeIntervalSince1970) == 0.125)
    }

    @Test @MainActor
    func cancelledConversionRollsBackOnlyUnsavedScheduleChanges() throws {
        let container = try SageModelContainer.make(for: .test)
        let context = container.mainContext
        context.autosaveEnabled = false
        let start = Date(timeIntervalSince1970: 1_786_368_000)
        let rule = RecurringExpenseRule(name: "Legacy", amount: 1, note: "", category: .needs, frequency: .monthly, startDate: start, lastGeneratedDate: start, recurrenceTimeZoneIdentifier: nil)
        let expense = Expense(name: "Legacy", amount: 1, date: start, recurringExpenseId: rule.id)
        context.insert(rule)
        context.insert(expense)
        try context.save()
        #expect(!context.hasChanges)
        rule.enableFixedSchedule(in: utcCalendar().timeZone, after: start, existingExpenses: [expense])
        #expect(context.hasChanges)
        #expect(rule.recurrenceTimeZoneIdentifier == "GMT")
        #expect(rule.recurrenceEffectiveDate == start)
        context.rollback()
        #expect(!context.hasChanges)

        // SwiftData refreshes cached model values on fetch after rollback.
        let fetched = try #require(context.fetch(FetchDescriptor<RecurringExpenseRule>()).first)
        #expect(fetched === rule)
        #expect(rule.recurrenceTimeZoneIdentifier == nil)
        #expect(rule.recurrenceEffectiveDate == nil)
        #expect(rule.lastGeneratedDate == start)
        #expect(expense.recurringOccurrenceKey == nil)
        #expect(try context.fetch(FetchDescriptor<Expense>()).count == 1)

        try context.save()
        let verificationContext = ModelContext(container)
        let persisted = try #require(verificationContext.fetch(FetchDescriptor<RecurringExpenseRule>()).first)
        #expect(persisted.recurrenceTimeZoneIdentifier == nil)
        #expect(persisted.recurrenceEffectiveDate == nil)
        #expect(persisted.lastGeneratedDate == start)
    }

    @Test @MainActor
    func frequencyEditContinuesFromCursorAndMonthlyCrossesYearBoundary() throws {
        let calendar = utcCalendar()
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 31, hour: 12)))
        let cursor = try #require(calendar.date(from: DateComponents(year: 2026, month: 12, day: 31, hour: 12)))
        let rule = RecurringExpenseRule(name: "Fixed", amount: 1, note: "", category: .needs, frequency: .monthly, startDate: start, lastGeneratedDate: cursor, recurrenceTimeZoneIdentifier: "GMT")
        #expect(rule.nextOccurrence() == calendar.date(from: DateComponents(year: 2027, month: 1, day: 31, hour: 12)))
        rule.frequency = .weekly
        #expect(rule.nextOccurrence() == calendar.date(byAdding: .day, value: 7, to: cursor))
        rule.frequency = .biweekly
        #expect(rule.nextOccurrence() == calendar.date(byAdding: .day, value: 14, to: cursor))
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
