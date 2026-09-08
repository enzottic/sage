import Foundation
import SwiftData

/// Shared persisted queries for category detail and dashboard spending.
public enum ExpenseFetchDescriptors {
    public static func month(_ month: Date, calendar: Calendar = .current) -> FetchDescriptor<Expense> {
        let interval = calendar.dateInterval(of: .month, for: month)
        return range(start: interval?.start ?? month, end: interval?.end ?? month)
    }

    /// The end boundary is exclusive; inclusive as-of cutoffs are applied separately.
    public static func range(start: Date, end: Date) -> FetchDescriptor<Expense> {
        FetchDescriptor<Expense>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\Expense.date, order: .reverse)]
        )
    }
}
