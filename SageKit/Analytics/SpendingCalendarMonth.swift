import Foundation

/// A Sunday-first month of recorded spending, including zero-spend days and refunds.
public struct SpendingCalendarMonth {
    public struct Day: Identifiable {
        public let date: Date
        public let amount: Double
        public var id: Date { date }
    }

    public let leadingEmptyDays: Int
    public let days: [Day]

    public init(month: Date, expenses: [Expense], calendar: Calendar = .current) {
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let dayRange = calendar.range(of: .day, in: .month, for: month) else {
            leadingEmptyDays = 0
            days = []
            return
        }

        // Weekday components are Sunday = 1, regardless of the locale's first weekday.
        leadingEmptyDays = calendar.component(.weekday, from: interval.start) - 1
        var totals: [Date: Double] = [:]
        for expense in expenses where expense.date >= interval.start && expense.date < interval.end {
            totals[calendar.startOfDay(for: expense.date), default: 0] += expense.amount
        }

        days = dayRange.compactMap { day in
            guard let date = calendar.date(byAdding: .day, value: day - dayRange.lowerBound, to: interval.start) else {
                return nil
            }
            return Day(date: date, amount: totals[calendar.startOfDay(for: date), default: 0])
        }
    }
}
