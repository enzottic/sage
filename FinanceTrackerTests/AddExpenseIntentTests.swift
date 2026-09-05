import AppIntents
import Foundation
import SwiftData
import Testing
import UIKit
@testable import SageKit

@Suite("Add expense shortcut", .serialized)
struct AddExpenseIntentTests {
    @Test @MainActor
    func savesSelectedCategoryAndDate() async throws {
        let container = try SageModelContainer.make(for: .test)
        let store = ExpenseStore(modelContainer: container)
        let intent = AddExpenseAppIntent()
        intent.expenseStore = store
        intent.name = "  Groceries  "
        intent.amount = 24.50
        intent.category = .needs
        intent.date = Date(timeIntervalSince1970: 1_700_000_000)

        _ = try await intent.perform()

        let expense = try #require(store.fetchExpenses().first)
        #expect(expense.name == "Groceries")
        #expect(expense.amount == 24.50)
        #expect(expense.category == .needs)
        #expect(expense.date == intent.date)
    }

    @Test @MainActor
    func defaultsToWants() async throws {
        let container = try SageModelContainer.make(for: .test)
        let store = ExpenseStore(modelContainer: container)
        let intent = AddExpenseAppIntent()
        intent.expenseStore = store
        intent.name = "Coffee"
        intent.amount = 4

        _ = try await intent.perform()

        #expect(try store.fetchExpenses().first?.category == .wants)
    }

    @Test @MainActor
    func savesSelectedTag() async throws {
        let container = try SageModelContainer.make(for: .test)
        let store = ExpenseStore(modelContainer: container)
        let tag = ExpenseTag(name: "Dining", uiColor: .systemBlue, emoji: "")
        store.context.insert(tag)
        try store.save()
        let intent = AddExpenseAppIntent()
        intent.expenseStore = store
        intent.name = "Coffee"
        intent.amount = 4
        intent.tag = tag.entity

        _ = try await intent.perform()

        let expense = try #require(store.fetchExpenses().first)
        #expect(expense.tags?.map(\.id) == [tag.id])
    }

    @Test @MainActor
    func rejectsInvalidValuesWithoutSaving() async throws {
        let container = try SageModelContainer.make(for: .test)
        let store = ExpenseStore(modelContainer: container)
        for (name, amount) in [("  ", 5.0), ("Coffee", 0), ("Coffee", -1), ("Coffee", Double.infinity), ("Coffee", Double.nan)] {
            let intent = AddExpenseAppIntent()
            intent.expenseStore = store
            intent.name = name
            intent.amount = amount
            do {
                _ = try await intent.perform()
                Issue.record("Invalid shortcut values were accepted.")
            } catch {
                #expect(try store.fetchExpenses().isEmpty)
            }
        }
    }
}
