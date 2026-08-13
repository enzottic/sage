import SwiftData
import Testing
@testable import SageKit

@Suite("Expense store")
struct ExpenseStoreTests {
    @Test @MainActor
    func deleteRemovesSavedExpense() throws {
        let container = try SageModelContainer.makeInMemory()
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
