import SwiftUI
import SwiftData
import SageKit

struct ExpenseCalendarWidget: View {
    private let selectedMonth: Date
    @Query private var expenses: [Expense]
    @ScaledMetric(relativeTo: .caption2) private var minimumDayWidth = 40.0

    private let calendar = Calendar.current

    init(selectedMonth: Date) {
        self.selectedMonth = selectedMonth
        _expenses = expenseQuery(for: selectedMonth)
    }

    var body: some View {
        let month = SpendingCalendarMonth(month: selectedMonth, expenses: expenses, calendar: calendar)

        Section {
            ViewThatFits(in: .horizontal) {
                calendarGrid(month)
                    .frame(minWidth: minimumDayWidth * 7 + 24)
                ScrollView(.horizontal) {
                    calendarGrid(month)
                        .frame(minWidth: minimumDayWidth * 7 + 24)
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .listRowSeparator(.hidden)
        } header: {
            Text("Expense Calendar")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    private func calendarGrid(_ month: SpendingCalendarMonth) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<7) { weekday in
                    Text(calendar.shortWeekdaySymbols[weekday].uppercased())
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(calendar.weekdaySymbols[weekday])
                }
            }
            .padding(.bottom, 4)

            ForEach(0..<((month.leadingEmptyDays + month.days.count + 6) / 7), id: \.self) { week in
                HStack(spacing: 4) {
                    ForEach(0..<7) { weekday in
                        let index = week * 7 + weekday - month.leadingEmptyDays
                        if month.days.indices.contains(index) {
                            dayCell(month.days[index])
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .accessibilityHidden(true)
                        }
                    }
                }
            }
        }
        // Keep the requested Sunday-to-Saturday column order in every locale.
        .environment(\.layoutDirection, .leftToRight)
    }

    private func dayCell(_ day: SpendingCalendarMonth.Day) -> some View {
        let isToday = calendar.isDateInToday(day.date)
        let isFuture = day.date > calendar.startOfDay(for: .now)
        let dayNumber = calendar.component(.day, from: day.date)

        return VStack(spacing: 4) {
            Text(dayNumber.formatted())
                .font(.caption)
                .fontWeight(isToday ? .bold : .medium)
                .foregroundStyle(isToday ? Color.sage : Color.primary)
            Text(calendarAmount(day.amount))
                .font(.caption2)
                .foregroundStyle(day.amount == 0 ? .secondary : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .monospacedDigit()
        .padding(.horizontal, 2)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 48)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? Color.sage.opacity(0.12) : isFuture ? Color.clear : Color(.tertiarySystemGroupedBackground))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isToday ? Color.sage : Color(.separator), lineWidth: isToday ? 1.5 : 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(day.date.formatted(date: .complete, time: .omitted))
        .accessibilityValue("\(day.amount.currencyString) spent\(isToday ? ", Today" : "")")
        .accessibilityIdentifier("expense-calendar-day-\(dayNumber)")
    }

    private func calendarAmount(_ amount: Double) -> String {
        let rounded = amount.rounded(.up)
        guard let code = LedgerCurrency.currentCode else {
            return rounded.currencyStringRounded
        }
        if abs(rounded) >= 1_000 {
            return rounded.formatted(
                .currency(code: code)
                    .notation(.compactName)
                    .precision(.fractionLength(0...1))
            )
        }
        return rounded.formatted(.currency(code: code).precision(.fractionLength(0)))
    }
}

#Preview {
    @Previewable @State var container: ModelContainer = {
        let container = try! SageModelContainer.make(for: .previewEmpty)
        let monthStart = Calendar.current.dateInterval(of: .month, for: .now)!.start
        container.mainContext.insert(Expense(name: "Rent", amount: 1400, category: .needs, date: monthStart))
        container.mainContext.insert(Expense(name: "Groceries", amount: 88.75, category: .needs))
        try! container.mainContext.save()
        return container
    }()

    List {
        ExpenseCalendarWidget(selectedMonth: .now)
    }
    .environmentInjection(container: container)
}
