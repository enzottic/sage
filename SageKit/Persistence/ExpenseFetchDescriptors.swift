import Foundation
import SwiftData

/// Shared persisted queries for expense lists and spending.
public enum ExpenseFetchDescriptors {
    /// Fetches the visible search window plus one match to detect another page.
    /// Growing the window keeps SwiftData updates live without stale offset pages.
    public static func search(_ query: String, visibleLimit: Int) -> FetchDescriptor<Expense> {
        precondition(visibleLimit > 0 && visibleLimit < Int.max)
        var descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { expense in
                expense.name.localizedStandardContains(query)
                || expense.note.localizedStandardContains(query)
                || (expense.tags?.contains { tag in
                    tag.name.localizedStandardContains(query)
                } == true)
            },
            sortBy: [SortDescriptor(\Expense.date, order: .reverse)]
        )
        descriptor.fetchLimit = visibleLimit + 1
        return descriptor
    }

    public static func month(_ month: Date, calendar: Calendar = .current) -> FetchDescriptor<Expense> {
        let interval = calendar.dateInterval(of: .month, for: month)
        return range(start: interval?.start ?? month, end: interval?.end ?? month)
    }

    public static func recurringScheduled(in month: Date, calendar: Calendar = .current) -> FetchDescriptor<Expense> {
        let interval = calendar.dateInterval(of: .month, for: month)
        let start = interval?.start ?? month
        let end = interval?.end ?? month
        return FetchDescriptor<Expense>(predicate: #Predicate { expense in
            expense.recurringExpenseId != nil
                && expense.recurringScheduledDate != nil
                && expense.recurringScheduledDate! >= start
                && expense.recurringScheduledDate! < end
        })
    }

    /// The end boundary is exclusive; inclusive as-of cutoffs are applied separately.
    public static func range(start: Date, end: Date) -> FetchDescriptor<Expense> {
        FetchDescriptor<Expense>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\Expense.date, order: .reverse)]
        )
    }
}
