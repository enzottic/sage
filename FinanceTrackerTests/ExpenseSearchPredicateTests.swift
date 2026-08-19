import SwiftData
import Testing
import UIKit
@testable import SageKit

@Suite("Expense search predicate")
struct ExpenseSearchPredicateTests {
    @Test @MainActor
    func findsExpenseByTagName() throws {
        let container = try SageModelContainer.make(for: .test)
        let context = container.mainContext
        let tag = ExpenseTag(name: "Groceries", uiColor: .blue, emoji: "🛒")
        let expense = Expense(name: "Market", amount: 20, tags: [tag])
        context.insert(tag)
        context.insert(expense)
        try context.save()

        let query = "Grocer"
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { expense in
                expense.name.localizedStandardContains(query)
                || expense.note.localizedStandardContains(query)
                || (expense.tags?.contains { tag in
                    tag.name.localizedStandardContains(query)
                } == true)
            }
        )

        let matches = try context.fetch(descriptor)
        #expect(matches.map(\.id) == [expense.id])
    }
}
