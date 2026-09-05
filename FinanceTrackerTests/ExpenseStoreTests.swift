import SwiftData
import Testing
import UIKit
@testable import SageKit

@Suite("Expense store")
struct ExpenseStoreTests {
    private enum SaveFailure: Error {
        case expected
    }

    @Test @MainActor
    func isolatedWriteDoesNotSavePendingAppEdits() throws {
        let container = try SageModelContainer.make(for: .test)
        let store = ExpenseStore(modelContainer: container)
        store.context.autosaveEnabled = false
        let existing = Expense(name: "Original", amount: 18, category: .needs)
        store.addExpense(existing)
        try store.save()
        existing.name = "Pending edit"

        let entity = try store.addExpenseAndSave(
            Expense(name: "Shortcut", amount: 4, category: .wants),
            tagID: nil
        )

        let verificationContext = ModelContext(container)
        let persisted = try verificationContext.fetch(FetchDescriptor<Expense>())
        #expect(Set(persisted.map(\.name)) == ["Original", "Shortcut"])
        #expect(persisted.contains { $0.id == entity.id })
        #expect(existing.name == "Pending edit")
        #expect(store.context.hasChanges)
    }

    @Test @MainActor
    func failedIsolatedWriteRollsBackWithoutDiscardingPendingAppEdits() throws {
        let container = try SageModelContainer.make(for: .test)
        let store = ExpenseStore(modelContainer: container)
        store.context.autosaveEnabled = false
        let tag = ExpenseTag(name: "Dining", uiColor: .systemBlue, emoji: "")
        let existing = Expense(name: "Original", amount: 18, category: .needs, tags: [tag])
        store.context.insert(tag)
        store.addExpense(existing)
        try store.save()
        existing.name = "Pending edit"
        var failedContext: ModelContext?

        do {
            _ = try store.addExpenseAndSave(
                Expense(name: "Failed shortcut", amount: 4, category: .wants),
                tagID: tag.id
            ) { context in
                failedContext = context
                #expect(context.hasChanges)
                throw SaveFailure.expected
            }
            Issue.record("The save failure was suppressed.")
        } catch SaveFailure.expected {
            let context = try #require(failedContext)
            #expect(!context.hasChanges)
            // A later save must not resurrect the failed insertion or its tag relationship.
            try context.save()
            let verificationContext = ModelContext(container)
            let persisted = try verificationContext.fetch(FetchDescriptor<Expense>())
            #expect(persisted.map(\.name) == ["Original"])
            #expect(persisted.first?.tags?.map(\.id) == [tag.id])
            let persistedTag = try #require(verificationContext.fetch(FetchDescriptor<ExpenseTag>()).first)
            #expect(persistedTag.taggedExpenses?.map(\.id) == [existing.id])
            #expect(existing.name == "Pending edit")
            #expect(store.context.hasChanges)
            #expect(tag.taggedExpenses?.map(\.id) == [existing.id])
        }
    }

    @Test @MainActor
    func deleteRemovesSavedExpense() throws {
        let container = try SageModelContainer.make(for: .test)
        let store = ExpenseStore(modelContainer: container)
        let expense = Expense(name: "Delete Me", amount: 18, category: .needs)

        store.addExpense(expense)
        try store.save()
        #expect(try store.fetchExpenses().map(\.name) == ["Delete Me"])

        store.deleteExpense(expense)
        try store.save()

        #expect(try store.fetchExpenses().isEmpty)
    }
}
