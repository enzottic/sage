import SwiftUI
import Charts

public struct SpendingChartSeries: Identifiable {
    public let category: ExpenseCategory?
    public let points: [SpendingMonthSummary.Point]
    public let color: Color
    public var id: String { category?.rawValue ?? "Total" }

    public init(category: ExpenseCategory?, points: [SpendingMonthSummary.Point], color: Color) {
        self.category = category
        self.points = points
        self.color = color
    }
}

/// Renders snapshot values without querying storage or owning app interaction state.
/// Supply one series per category/total, unique ascending days, and a valid month length.
public struct DailySpendingChart: View {
    private let series: [SpendingChartSeries]
    private let averageDays: [SpendingMonthSummary.Point]
    private let daysInMonth: Int
    private let selectedDay: Int?
    private let currencyCode: String?

    public init(series: [SpendingChartSeries], averageDays: [SpendingMonthSummary.Point] = [],
                daysInMonth: Int, currencyCode: String?, selectedDay: Int? = nil) {
        self.series = series
        self.averageDays = averageDays
        self.daysInMonth = daysInMonth
        self.selectedDay = selectedDay
        self.currencyCode = currencyCode
    }

    public var body: some View {
        Chart {
            ForEach(stableLinePoints(averageDays), id: \.id) { item in
                let point = item.point
                LineMark(x: .value("Day", point.day), y: .value("Spent", point.total), series: .value("Series", "Average"))
                    .foregroundStyle(Color.secondary.opacity(0.65))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    .accessibilityHidden(item.id >= averageDays.count)
            }
            ForEach(series) { line in
                spendingLine(line)
            }
            if let selectedDay {
                RuleMark(x: .value("Day", selectedDay))
                    .foregroundStyle(.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .chartXScale(domain: 1...daysInMonth)
        .chartXAxis {
            AxisMarks(values: [1, 5, 10, 15, 20, 25, daysInMonth]) { _ in AxisValueLabel() }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(currencyLabel(amount, rounded: true)).font(.caption2)
                    }
                }
            }
        }
        .accessibilityLabel("Cumulative spending by day of the month")
    }

    @ChartContentBuilder
    private func spendingLine(_ line: SpendingChartSeries) -> some ChartContent {
        ForEach(stableLinePoints(line.points), id: \.id) { item in
            let point = item.point
            LineMark(x: .value("Day", point.day), y: .value("Spent", point.total), series: .value("Series", line.id))
                .foregroundStyle(line.color)
                .lineStyle(StrokeStyle(lineWidth: line.category == nil ? 3 : 2))
                .accessibilityLabel("\(line.id), day \(point.day)")
                .accessibilityValue(currencyLabel(point.total))
                .accessibilityHidden(item.id >= line.points.count)
        }
        if let point = line.points.first(where: { $0.day == selectedDay }) ?? line.points.last {
            PointMark(x: .value("Day", point.day), y: .value("Spent", point.total))
                .foregroundStyle(line.color)
                .symbolSize(selectedDay == nil ? 25 : 65)
        }
    }

    private func stableLinePoints(_ points: [SpendingMonthSummary.Point]) -> [(id: Int, point: SpendingMonthSummary.Point)] {
        guard let last = points.last else { return [] }
        // Keep all 31 marks alive across months; unused marks collapse onto the endpoint.
        // Removing marks instead leaves the old line visible during Charts' removal transition.
        return (0..<31).map { index in
            (id: index, point: index < points.count ? points[index] : last)
        }
    }

    private func currencyLabel(_ amount: Double, rounded: Bool = false) -> String {
        guard let currencyCode else {
            let number = rounded ? amount.formatted(.number.precision(.fractionLength(0))) : amount.formatted()
            return "\(number) (currency not confirmed)"
        }
        let format = FloatingPointFormatStyle<Double>.Currency(code: currencyCode)
        return amount.formatted(rounded ? format.precision(.fractionLength(0)) : format)
    }
}

#Preview {
    DailySpendingChart(
        series: [SpendingChartSeries(category: nil, points: [
            .init(day: 1, total: 100), .init(day: 5, total: 180),
            .init(day: 10, total: 350), .init(day: 15, total: 420),
        ], color: .primary)],
        daysInMonth: 30, currencyCode: "USD"
    )
    .frame(height: 200)
    .padding()
}
