import Foundation
import SageKit
import SwiftData

extension SageModelContainer {
    @MainActor
    static func makePreview() throws -> ModelContainer {
        let container = try make(for: .preview)
        #if DEBUG
        let context = ModelContext(container)
        MockDataSeeder.seed(into: context, seedsAppConfiguration: false)
        try context.save()
        #endif
        return container
    }

    @MainActor
    static let preview: ModelContainer = {
        do {
            return try makePreview()
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()

    @MainActor
    static let previewEmpty: ModelContainer = {
        do {
            return try make(for: .previewEmpty)
        } catch {
            fatalError("Failed to create empty preview container: \(error)")
        }
    }()

    /// Fresh, context-owned rules without invoking the debug app's sample-data seeder.
    @MainActor
    static func makeRecurringPreview() throws -> ModelContainer {
        let container = try make(for: .previewEmpty)
        let calendar = Calendar.current
        let now = Date.now
        let bills = ExpenseTag.billsAndUtils
        let subscriptions = ExpenseTag.subscriptions
        container.mainContext.insert(bills)
        container.mainContext.insert(subscriptions)

        let rules = [
            RecurringExpenseRule(
                name: "Internet", amount: 55, note: "", category: .needs, tag: bills,
                frequency: .monthly, startDate: calendar.date(byAdding: .day, value: 1, to: now)!
            ),
            RecurringExpenseRule(
                name: "Music", amount: 10.99, note: "", category: .wants, tag: subscriptions,
                frequency: .monthly, startDate: calendar.date(byAdding: .day, value: 3, to: now)!
            ),
            RecurringExpenseRule(
                name: "Meal Delivery", amount: 65, note: "", category: .needs, tag: bills,
                frequency: .weekly, startDate: calendar.date(byAdding: .day, value: 7, to: now)!
            ),
        ]
        rules.forEach { container.mainContext.insert($0) }
        try container.mainContext.save()
        return container
    }
}
