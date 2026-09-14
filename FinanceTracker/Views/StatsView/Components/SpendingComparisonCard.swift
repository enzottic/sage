import SwiftUI
import SageKit

/// Observations about recorded spending, with equal visual weight and no forecasts.
struct SpendingComparisonCard: View {
    @Environment(AppConfiguration.self) private var config
    let summary: SpendingMonthSummary
    let isCurrentMonth: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights").font(.headline)
            if summary.previousExpenseCount == 0 {
                insight(icon: "calendar", text: "No expenses recorded for the previous comparison period.")
            } else if summary.expenses.isEmpty {
                insight(icon: "receipt", text: "No expenses recorded for the selected month. Add an expense to compare periods.")
            } else if summary.previousTotal > 0 {
                let change = (summary.total - summary.previousTotal) / summary.previousTotal
                let percent = abs(change).formatted(.percent.precision(.fractionLength(0)))
                let comparison = isCurrentMonth ? "at this point last month" : "the previous month"
                insight(icon: change == 0 ? "equal" : "arrow.left.arrow.right",
                        text: change == 0 ? "You spent the same amount as \(comparison)." : "You spent \(percent) \(change > 0 ? "more" : "less") than \(comparison).")
            } else {
                let previous = summary.previousTotal.currencyString(code: config.ledgerCurrencyCode)
                insight(icon: "arrow.left.arrow.right",
                        text: "Net spending for the previous comparison period was \(previous). A percentage comparison isn’t available when the previous total is zero or negative.")
            }
            if !summary.expenses.isEmpty {
                let average = summary.total / Double(max(1, summary.days.count))
                insight(icon: "chart.bar", text: "You spent \(average.currencyString(code: config.ledgerCurrencyCode)) per day on average\(isCurrentMonth ? " so far" : "").")
                if let largest = summary.expenses.max(by: { $0.amount < $1.amount }), largest.amount > 0 {
                    insight(icon: "receipt", text: "Your largest expense was \(largest.name), at \(largest.amount.currencyString(code: config.ledgerCurrencyCode)).")
                }
            } else {
                insight(icon: "receipt", text: "Add expenses to see patterns in your spending.")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.cardBackground, in: .rect(cornerRadius: 15))
    }

    private func insight(icon: String, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon).foregroundStyle(.secondary).frame(width: 20)
                .accessibilityHidden(true)
            Text(text).fixedSize(horizontal: false, vertical: true)
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }
}
