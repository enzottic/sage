import Foundation
import SwiftData
import Testing
import UIKit
@testable import SageKit

@Suite("Data deletion")
struct DataDeletionServiceTests {
    @Test @MainActor
    func expensesOnlyKeepsRecurringRules() throws {
        let container = try SageModelContainer.make(for: .test)
        let context = container.mainContext
        let rule = RecurringExpenseRule(
            name: "Rent",
            amount: 1_000,
            note: "",
            category: .needs,
            frequency: .monthly,
            startDate: .now
        )
        context.insert(Expense(name: "Rent", amount: 1_000, category: .needs))
        context.insert(rule)
        try context.save()

        try DataDeletionService(modelContext: context).deleteExpenses(includeRecurringRules: false)

        #expect(try context.fetch(FetchDescriptor<Expense>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<RecurringExpenseRule>()).map(\.id) == [rule.id])
    }

    @Test @MainActor
    func expensesAndRulesCannotGenerateNewExpenses() throws {
        let container = try SageModelContainer.make(for: .test)
        let context = container.mainContext
        context.insert(Expense(name: "Rent", amount: 1_000, category: .needs))
        context.insert(
            RecurringExpenseRule(
                name: "Rent",
                amount: 1_000,
                note: "",
                category: .needs,
                frequency: .monthly,
                startDate: .now
            )
        )
        try context.save()

        try DataDeletionService(modelContext: context).deleteExpenses(includeRecurringRules: true)
        RecurringExpenseService(modelContext: context).generateAllExpenses(through: .now)

        #expect(try context.fetch(FetchDescriptor<Expense>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<RecurringExpenseRule>()).isEmpty)
    }

    @Test @MainActor
    func fullResetDeletesEveryUserModel() throws {
        let container = try SageModelContainer.make(for: .test)
        let context = container.mainContext
        let tag = ExpenseTag(name: "Custom", uiColor: .systemBlue, emoji: "💵")
        let account = ExpenseAccount(id: UUID(), name: "Checking", type: .bankAccount)
        context.insert(tag)
        context.insert(account)
        context.insert(Expense(name: "Purchase", amount: 20, category: .wants, tags: [tag], account: account))
        context.insert(
            RecurringExpenseRule(
                name: "Subscription",
                amount: 10,
                note: "",
                category: .wants,
                tags: [tag],
                frequency: .monthly,
                startDate: .now
            )
        )
        try context.save()

        try DataDeletionService(modelContext: context).deleteAllUserData()

        #expect(try context.fetch(FetchDescriptor<Expense>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<RecurringExpenseRule>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<ExpenseTag>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<ExpenseAccount>()).isEmpty)
    }
}
