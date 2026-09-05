import SwiftData
import Testing
import UIKit
@testable import SageKit

@Suite("Schema migration", .serialized)
struct SchemaMigrationTests {
    @Test @MainActor
    func v1StoreMigratesToCurrentSchema() throws {
        UIColorValueTransformer.register()
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "SageMigration-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appending(path: "Migration.sqlite")

        try createV1Store(at: storeURL)

        let schema = Schema(versionedSchema: SageSchemaV6.self)
        let configuration = ModelConfiguration(
            "Migration",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: schema,
            migrationPlan: SageSchemaMigrationPlan.self,
            configurations: [configuration]
        )
        let expenses = try container.mainContext.fetch(FetchDescriptor<Expense>())

        #expect(expenses.count == 1)
        let expense = try #require(expenses.first)
        #expect(expense.name == "Legacy Rent")
        #expect(expense.amount == 900)
        #expect(expense.category == .needs)
        #expect(expense.note == "V1 record")
        #expect(expense.account == nil)
        #expect(expense.recurringOccurrenceKey == nil)
        let rule = try #require(container.mainContext.fetch(FetchDescriptor<RecurringExpenseRule>()).first)
        #expect(rule.name == "Legacy Rule")
        #expect(rule.recurrenceTimeZoneIdentifier == nil)
        #expect(rule.recurrenceEffectiveDate == nil)
    }

    @Test @MainActor
    func v5RecurringStoreMigratesWithoutChangingScheduleOrKeys() throws {
        UIColorValueTransformer.register()
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "SageMigration-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "Migration.sqlite")
        let ruleID = UUID()
        let expenseID = UUID()
        let start = Date(timeIntervalSince1970: 1_769_860_800)
        let cursor = start.addingTimeInterval(28 * 86_400)
        let key = RecurringExpenseOccurrence.key(ruleID: ruleID, scheduledDate: cursor)
        try createV5Store(at: url, ruleID: ruleID, expenseID: expenseID, start: start, cursor: cursor, key: key)

        // Reopen both the migrated legacy rule and its explicitly converted schedule.
        for opening in 0..<3 {
            let schema = Schema(versionedSchema: SageSchemaV6.self)
            let configuration = ModelConfiguration("Migration", schema: schema, url: url, cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, migrationPlan: SageSchemaMigrationPlan.self, configurations: [configuration])
            let rule = try #require(container.mainContext.fetch(FetchDescriptor<RecurringExpenseRule>()).first)
            let expense = try #require(container.mainContext.fetch(FetchDescriptor<Expense>()).first)
            #expect(rule.id == ruleID)
            #expect(rule.startDate == start)
            #expect(rule.lastGeneratedDate == cursor)
            #expect(rule.endDate == cursor.addingTimeInterval(365 * 86_400))
            #expect(rule.frequency == .monthly)
            if opening < 2 {
                #expect(rule.recurrenceTimeZoneIdentifier == nil)
                #expect(rule.recurrenceEffectiveDate == nil)
            } else {
                #expect(rule.recurrenceTimeZoneIdentifier == TimeZone(secondsFromGMT: 0)!.identifier)
                #expect(rule.recurrenceEffectiveDate == cursor)
            }
            #expect(rule.tags?.first?.name == "Bills")
            #expect(rule.account?.name == "Bank")
            #expect(expense.id == expenseID)
            #expect(expense.recurringExpenseId == ruleID)
            #expect(expense.recurringOccurrenceKey == key)
            #expect(expense.date == cursor.addingTimeInterval(60))
            #expect(expense.tags?.first?.id == rule.tags?.first?.id)
            #expect(expense.account?.id == rule.account?.id)
            if opening == 1 {
                rule.enableFixedSchedule(in: TimeZone(secondsFromGMT: 0)!, after: cursor, existingExpenses: [expense])
                try container.mainContext.save()
            }
        }
    }

    private func createV5Store(at url: URL, ruleID: UUID, expenseID: UUID, start: Date, cursor: Date, key: String) throws {
        let schema = Schema(versionedSchema: SageSchemaV5.self)
        let configuration = ModelConfiguration("Migration", schema: schema, url: url, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let tag = SageSchemaV5.ExpenseTag(name: "Bills", uiColor: .blue, emoji: "B")
        let account = SageSchemaV5.ExpenseAccount(id: UUID(), name: "Bank", type: .bankAccount)
        let rule = SageSchemaV5.RecurringExpenseRule(name: "Rent", amount: 900, note: "Legacy", category: .needs, tags: [tag], frequency: .monthly, startDate: start, endDate: cursor.addingTimeInterval(365 * 86_400), lastGeneratedDate: cursor)
        rule.id = ruleID
        rule.account = account
        let expense = SageSchemaV5.Expense(name: "Rent", amount: 900, date: cursor.addingTimeInterval(60), tags: [tag], recurringExpenseId: ruleID, recurringOccurrenceKey: key, account: account)
        expense.id = expenseID
        context.insert(tag)
        context.insert(account)
        context.insert(rule)
        context.insert(expense)
        try context.save()
    }

    private func createV1Store(at url: URL) throws {
        let schema = Schema(versionedSchema: SageSchemaV1.self)
        let configuration = ModelConfiguration(
            "Migration",
            schema: schema,
            url: url,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        context.insert(
            SageSchemaV1.Expense(
                name: "Legacy Rent",
                amount: 900,
                category: .needs,
                note: "V1 record"
            )
        )
        let tag = SageSchemaV1.ExpenseTag(name: "Bills", uiColor: .blue, emoji: "B")
        context.insert(tag)
        context.insert(SageSchemaV1.RecurringExpenseRule(name: "Legacy Rule", amount: 900, note: "", category: .needs, tag: tag, frequency: .monthly, startDate: Date(timeIntervalSince1970: 1_769_860_800)))
        try context.save()
    }
}
