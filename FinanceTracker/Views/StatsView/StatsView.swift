import SwiftUI
import SwiftData
import Charts
import SageKit

enum StatsTimeframe: String, CaseIterable, Identifiable {
    case monthly = "Monthly"
    case weekly = "Weekly"
    var id: String { rawValue }
}

private struct SpendingPeriodData: Identifiable {
    let periodStart: Date
    let label: String
    let total: Double
    var id: Date { periodStart }
}

private struct SpendingChartSeries: Identifiable {
    let category: ExpenseCategory?
    let points: [SpendingMonthSummary.Point]
    let color: Color
    var id: String { category?.rawValue ?? "Total" }
}

struct StatsView: View {
    @Environment(\.categoryColors) private var categoryColors
    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse)]) private var allExpenses: [Expense]
    @State private var selectedMonth = Calendar.current.dateInterval(of: .month, for: Date())!.start
    @State private var timeframe: StatsTimeframe = .monthly
    @State private var selectedCategory: ExpenseCategory?
    @State private var selectedTag: ExpenseTag?
    @State private var selectedBar: String?
    @State private var showsMonthPicker = false
    @GestureState private var chartTouch: (day: Int, location: CGPoint, highestLineY: CGFloat)?
    @State private var dailyOverviewHeight: CGFloat = 220
    @State private var statsViewport: CGRect = .zero
    @State private var isolatedLine: String?
    @AppStorage("statsShowsNeedsLine") private var showsNeedsLine = true
    @AppStorage("statsShowsWantsLine") private var showsWantsLine = true
    @AppStorage("statsShowsSavingsLine") private var showsSavingsLine = true

    private var selectedDay: Int? { chartTouch?.day }
    private var visibleCategories: [ExpenseCategory] {
        ExpenseCategory.allCases.filter { category in
            switch category {
            case .needs: showsNeedsLine
            case .wants: showsWantsLine
            case .savings: showsSavingsLine
            }
        }
    }

    private let calendar = Calendar.current
    private var currentMonth: Date { calendar.dateInterval(of: .month, for: Date())!.start }
    private var isCurrentMonth: Bool { selectedMonth == currentMonth }
    private var accentColor: Color {
        if let category = selectedCategory { return category.color(in: categoryColors) }
        if let tag = selectedTag, !tag.isDeleted { return tag.color }
        return .sage
    }
    private var filteredExpenses: [Expense] {
        allExpenses.filter { expense in
            (selectedCategory == nil || expense.category == selectedCategory) &&
            (selectedTag == nil || selectedTag?.isDeleted == true || (expense.tags ?? []).contains { $0.id == selectedTag?.id })
        }
    }
    private var summary: SpendingMonthSummary {
        SpendingMonthSummary(month: selectedMonth, expenses: filteredExpenses)
    }
    private var daysInMonth: Int { calendar.range(of: .day, in: .month, for: selectedMonth)!.count }

    private var chartData: [SpendingPeriodData] {
        let now = Date()
        if timeframe == .monthly {
            // Keep the recent window stable when selecting its bars. Older months get their own window.
            let earliestRecent = calendar.date(byAdding: .month, value: -5, to: currentMonth)!
            let end = selectedMonth < earliestRecent ? selectedMonth : currentMonth
            return (0..<6).reversed().map { offset in
                let start = calendar.date(byAdding: .month, value: -offset, to: end)!
                let interval = calendar.dateInterval(of: .month, for: start)!
                let total = filteredExpenses.filter { $0.date >= start && $0.date < interval.end && $0.date <= now }.total
                return SpendingPeriodData(periodStart: start, label: start.formatted(.dateTime.month(.abbreviated)), total: total)
            }
        }
        let month = calendar.dateInterval(of: .month, for: selectedMonth)!
        var start = month.start
        var result: [SpendingPeriodData] = []
        while start < month.end {
            let week = calendar.dateInterval(of: .weekOfYear, for: start)!
            let end = min(week.end, month.end)
            let lastDay = calendar.component(.day, from: calendar.date(byAdding: .day, value: -1, to: end)!)
            let label = "\(calendar.component(.day, from: start))–\(lastDay)"
            let total = filteredExpenses.filter { $0.date >= start && $0.date < end && $0.date <= now }.total
            result.append(SpendingPeriodData(periodStart: start, label: label, total: total))
            start = end
        }
        return result
    }

    var body: some View {
        let monthSummary = summary
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    monthlyChart(monthSummary)
                    SpendingComparisonCard(summary: monthSummary, isCurrentMonth: isCurrentMonth)
                    topTags(monthSummary)
                    historyChart
                }
                .padding()
            }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { statsViewport = $0 }
            .background(.sageBackground)
            .navigationTitle("Stats")
            .navigationSubtitle(selectedMonth.formatted(.dateTime.month(.wide).year()))
            .gradientBackground(color: accentColor)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button { changeMonth(by: -1) } label: { Label("Previous Month", systemImage: "chevron.left") }
                        .accessibilityIdentifier("stats-previous-month")
                    Button { changeMonth(by: 1) } label: { Label("Next Month", systemImage: "chevron.right") }
                        .disabled(isCurrentMonth)
                        .accessibilityIdentifier("stats-next-month")
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    StatsFilterMenu(selectedCategory: $selectedCategory, selectedTag: $selectedTag,
                                    showsMonthPicker: $showsMonthPicker)
                    Menu {
                        Section("Category Lines") {
                            Toggle("Needs", isOn: $showsNeedsLine)
                            Toggle("Wants", isOn: $showsWantsLine)
                            Toggle("Savings", isOn: $showsSavingsLine)
                        }
                    } label: {
                        Label("Chart Options", systemImage: "ellipsis")
                    }
                    .menuActionDismissBehavior(.disabled)
                    .accessibilityIdentifier("stats-chart-options")
                }
            }
            .onChange(of: selectedBar) { _, label in
                if timeframe == .monthly, let item = chartData.first(where: { $0.label == label }) {
                    selectedMonth = item.periodStart
                    selectedBar = nil
                }
            }
            .onChange(of: selectedCategory) { isolatedLine = nil }
            .onChange(of: selectedTag?.id) { isolatedLine = nil }
            .onChange(of: visibleCategories) { _, categories in
                if let isolatedLine, isolatedLine != "Total",
                   !categories.contains(where: { $0.rawValue == isolatedLine }) {
                    self.isolatedLine = nil
                }
            }
            .sheet(isPresented: $showsMonthPicker) {
                StatsMonthPicker(month: selectedMonth) { selectedMonth = $0 }
            }
        }
    }

    private func changeMonth(by offset: Int) {
        selectedMonth = min(calendar.date(byAdding: .month, value: offset, to: selectedMonth)!, currentMonth)
    }

    private func monthlyChart(_ summary: SpendingMonthSummary) -> some View {
        let series = [SpendingChartSeries(category: nil, points: summary.days, color: .primary)] +
            visibleCategories.filter { selectedCategory == nil || $0 == selectedCategory }.map {
                SpendingChartSeries(category: $0, points: summary.categoryDays[$0] ?? [], color: $0.color(in: categoryColors))
            }
        let visibleSeries = series.filter { isolatedLine == nil || $0.id == isolatedLine }
        let isolatedCategory = series.first(where: { $0.id == isolatedLine })?.category
        let displayedTotal = isolatedCategory.map { summary.categoryDays[$0]?.last?.total ?? 0 } ?? summary.total

        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(displayedTotal.currencyString)
                    .font(.largeTitle.bold()).monospacedDigit().textSelection(.enabled)
                    .accessibilityIdentifier("stats-month-total")
                Text(isCurrentMonth ? "Spent so far" : "Total spent")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Chart {
                if isolatedLine == nil {
                    ForEach(summary.averageDays) { point in
                        LineMark(x: .value("Day", point.day), y: .value("Spent", point.total), series: .value("Series", "Average"))
                            .foregroundStyle(Color.secondary.opacity(0.65))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    }
                }
                ForEach(visibleSeries) { line in
                    ForEach(line.points) { point in
                        LineMark(x: .value("Day", point.day), y: .value("Spent", point.total), series: .value("Series", line.id))
                            .foregroundStyle(line.color)
                            .lineStyle(StrokeStyle(lineWidth: line.category == nil ? 3 : 2))
                            .accessibilityLabel("\(line.id), day \(point.day)")
                            .accessibilityValue(point.total.currencyString)
                    }
                    if let point = line.points.first(where: { $0.day == selectedDay }) ?? line.points.last {
                        PointMark(x: .value("Day", point.day), y: .value("Spent", point.total))
                            .foregroundStyle(line.color)
                            .symbolSize(selectedDay == nil ? 25 : 65)
                    }
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
                    AxisValueLabel { if let amount = value.as(Double.self) { Text(amount.currencyStringRounded).font(.caption2) } }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    if let plotFrame = proxy.plotFrame {
                        let frame = geometry[plotFrame]
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .frame(width: frame.width, height: frame.height)
                            .gesture(
                                LongPressGesture(minimumDuration: 0.25)
                                    .sequenced(before: DragGesture(minimumDistance: 0))
                                    .updating($chartTouch) { value, touch, _ in
                                        guard case let .second(true, drag?) = value,
                                              let lastDay = summary.days.last?.day,
                                              let chartDay = proxy.value(atX: min(max(drag.location.x, 0), frame.width), as: Double.self)
                                        else { return }
                                        // Gesture coordinates are local to the plot, not the chart axes.
                                        let chartOrigin = geometry.frame(in: .named("stats-chart-card")).origin
                                        let points = visibleSeries.flatMap(\.points) + (isolatedLine == nil ? summary.averageDays : [])
                                        let highestLineY = points.compactMap { proxy.position(forY: $0.total) }.min() ?? 0
                                        touch = (
                                            day: min(max(Int(chartDay.rounded()), 1), lastDay),
                                            location: CGPoint(x: chartOrigin.x + frame.minX + drag.location.x,
                                                              y: chartOrigin.y + frame.minY + drag.location.y),
                                            highestLineY: chartOrigin.y + frame.minY + highestLineY
                                        )
                                    }
                            )
                            .simultaneousGesture(
                                SpatialTapGesture().onEnded { value in
                                    isolateLine(at: value.location, proxy: proxy, series: visibleSeries)
                                }
                            )
                            .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
            .frame(height: 200)
            .accessibilityLabel("Cumulative spending by day of the month")
            .accessibilityIdentifier("stats-daily-chart")
            HStack(spacing: 8) {
                ForEach(series) { line in
                    Button {
                        isolatedLine = isolatedLine == line.id ? nil : line.id
                    } label: {
                        HStack(spacing: 4) {
                            Capsule().fill(line.color).frame(width: 10, height: 3)
                            Text(line.id)
                                .fontWeight(isolatedLine == line.id ? .semibold : .regular)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .font(.caption)
                        .foregroundStyle(isolatedLine == nil || isolatedLine == line.id ? Color.primary : .secondary)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isolatedLine == line.id ? .isSelected : [])
                    .accessibilityHint(isolatedLine == line.id ? "Show all lines" : "Isolate this line")
                }
            }
            if isolatedLine == nil {
                chartLegend(summary)
            }
            if summary.expenses.isEmpty {
                Text("No expenses recorded for this month\(selectedCategory != nil || selectedTag != nil ? " with these filters" : "").")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            if summary.historicalMonthCount == 0 {
                Text("Your average will appear once you have a previous month of spending.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.cardBackground, in: .rect(cornerRadius: 15))
        .coordinateSpace(name: "stats-chart-card")
        .overlay {
            GeometryReader { geometry in
                if let chartTouch {
                    let cardFrame = geometry.frame(in: .global)
                    let visibleFrame = statsViewport.isEmpty ? cardFrame : statsViewport
                    let bounds = CGRect(x: 0, y: visibleFrame.minY - cardFrame.minY,
                                        width: geometry.size.width, height: visibleFrame.height)
                    dailyOverview(summary, day: chartTouch.day, category: isolatedCategory,
                                  finger: chartTouch.location, highestLineY: chartTouch.highestLineY, bounds: bounds)
                }
            }
            .allowsHitTesting(false)
        }
        .zIndex(chartTouch == nil ? 0 : 1)
    }

    private func dailyOverview(_ summary: SpendingMonthSummary, day: Int, category: ExpenseCategory?,
                               finger: CGPoint, highestLineY: CGFloat, bounds: CGRect) -> some View {
        let inset: CGFloat = 8
        let gap: CGFloat = 16
        let width = min(260, bounds.width - inset * 2)
        let height = dailyOverviewHeight
        let x = min(max(finger.x, inset + width / 2), bounds.width - inset - width / 2)
        // Anchor to the highest visible line, never the finger's vertical position.
        // Keep the overview readable at the top edge rather than flipping below the chart.
        let y = max(bounds.minY + inset + height / 2, highestLineY - gap - height / 2)

        return dailySpendingDetails(summary, day: day, category: category)
            .padding(12)
            .frame(width: width)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { dailyOverviewHeight = $0 }
            .background(.regularMaterial, in: .rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12).strokeBorder(.primary.opacity(0.1))
            }
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .position(x: x, y: y)
    }

    private func isolateLine(at location: CGPoint, proxy: ChartProxy, series: [SpendingChartSeries]) {
        // Hit-test the rendered segments, so taps between calendar days still select the line.
        var closest: (id: String, distance: CGFloat)?
        for line in series {
            let positions = line.points.compactMap { point -> CGPoint? in
                guard let x = proxy.position(forX: point.day), let y = proxy.position(forY: point.total) else { return nil }
                return CGPoint(x: x, y: y)
            }
            for (index, start) in positions.enumerated() {
                let end = positions[min(index + 1, positions.count - 1)]
                let dx = end.x - start.x
                let dy = end.y - start.y
                let lengthSquared = dx * dx + dy * dy
                let fraction = lengthSquared == 0 ? 0 : min(max(((location.x - start.x) * dx + (location.y - start.y) * dy) / lengthSquared, 0), 1)
                let distance = hypot(location.x - start.x - fraction * dx, location.y - start.y - fraction * dy)
                if distance <= 22, closest == nil || distance <= closest!.distance {
                    closest = (line.id, distance)
                }
            }
        }
        if let closest {
            isolatedLine = isolatedLine == closest.id ? nil : closest.id
        }
    }

    private func dailySpendingDetails(_ summary: SpendingMonthSummary, day: Int, category: ExpenseCategory?) -> some View {
        let date = calendar.date(byAdding: .day, value: day - 1, to: selectedMonth)!
        let expenses = summary.expenses.filter {
            calendar.isDate($0.date, inSameDayAs: date) && (category == nil || $0.category == category)
        }
            .sorted { $0.amount == $1.amount ? $0.date > $1.date : $0.amount > $1.amount }

        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(date.formatted(.dateTime.month(.wide).day()))
                    .font(.subheadline.weight(.semibold))
                if let category {
                    Text(category.rawValue).font(.caption).foregroundStyle(category.color(in: categoryColors))
                }
                Text("\(expenses.total.currencyString) spent this day")
                    .font(.headline).monospacedDigit()
                    .accessibilityIdentifier("stats-day-total")
            }
            if expenses.isEmpty {
                Text("No expenses recorded for this day.")
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                Text("Top Expenses").font(.caption).foregroundStyle(.secondary)
                ForEach(Array(expenses.prefix(3))) { expense in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(expense.category.color(in: categoryColors))
                                .baselineOffset(2)
                                .accessibilityHidden(true)
                            Text(expense.name).lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        Text(expense.amount.currencyString)
                            .monospacedDigit().fixedSize()
                    }
                    .font(.subheadline)
                    .accessibilityElement(children: .combine)
                    .accessibilityValue(expense.category.rawValue)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("stats-day-details")
    }

    @ViewBuilder private func chartLegend(_ summary: SpendingMonthSummary) -> some View {
        if summary.historicalMonthCount > 0 {
            Label {
                Text("Average")
            } icon: {
                HStack(spacing: 2) {
                    Capsule().frame(width: 7, height: 2)
                    Capsule().frame(width: 7, height: 2)
                }.foregroundStyle(.secondary)
            }
            .font(.caption).foregroundStyle(.secondary)
            .accessibilityHint("Average cumulative spending by calendar day. Shorter months carry their final total forward.")
        }
    }

    private func topTags(_ summary: SpendingMonthSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Tags").font(.headline)
            if summary.expenses.contains(where: { ($0.tags ?? []).contains { !$0.isDeleted } }) {
                TopSpendingBreakdown(expenses: summary.expenses, accentColor: accentColor,
                                     includesUntaggedExpenses: false, showsCardBackground: false)
                Text("Expenses with multiple tags count toward each tag.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Tagged expenses for this month will appear here.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(.cardBackground, in: .rect(cornerRadius: 15))
    }

    private var historyChart: some View {
        let periods = chartData
        return VStack(alignment: .leading, spacing: 16) {
            Text("Spending History").font(.headline)
            Picker("Breakdown", selection: $timeframe) {
                ForEach(StatsTimeframe.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            Text(timeframe == .monthly ? "Tap a bar to explore that month." : "Weekly totals within the selected month.")
                .font(.caption).foregroundStyle(.secondary)
            Chart(periods) { item in
                BarMark(x: .value("Period", item.label), y: .value("Spent", item.total))
                    .foregroundStyle(timeframe == .weekly || item.periodStart == selectedMonth ? accentColor : accentColor.opacity(0.35))
                    .cornerRadius(4)
                    .accessibilityLabel(timeframe == .monthly ? item.periodStart.formatted(.dateTime.month(.wide).year()) : "Days \(item.label)")
                    .accessibilityValue(item.total.currencyString)
            }
            .chartXSelection(value: $selectedBar)
            .chartGesture { proxy in
                SpatialTapGesture().onEnded { value in
                    guard timeframe == .monthly else { return }
                    proxy.selectXValue(at: value.location.x)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel { if let amount = value.as(Double.self) { Text(amount.currencyStringRounded).font(.caption2) } }
                }
            }
            .frame(height: 180)
            .accessibilityIdentifier("stats-history-chart")
            .accessibilityRepresentation {
                ForEach(periods) { item in
                    if timeframe == .monthly {
                        Button { selectedMonth = item.periodStart } label: {
                            Text("\(item.periodStart.formatted(.dateTime.month(.wide).year())), \(item.total.currencyString)")
                        }
                    } else {
                        Text("Days \(item.label), \(item.total.currencyString)")
                    }
                }
            }
        }
        .padding(16)
        .background(.cardBackground, in: .rect(cornerRadius: 15))
    }
}

private struct StatsMonthPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var month: Int
    @State private var year: Int
    let onSelect: (Date) -> Void
    private let calendar = Calendar.current
    init(month: Date, onSelect: @escaping (Date) -> Void) {
        _month = State(initialValue: Calendar.current.component(.month, from: month))
        _year = State(initialValue: Calendar.current.component(.year, from: month))
        self.onSelect = onSelect
    }
    private var selectedDate: Date { calendar.date(from: DateComponents(year: year, month: month, day: 1))! }
    var body: some View {
        NavigationStack {
            HStack {
                Picker("Month", selection: $month) {
                    ForEach(1...12, id: \.self) { index in Text(calendar.monthSymbols[index - 1]).tag(index) }
                }
                Picker("Year", selection: $year) {
                    ForEach(min(1900, year)...calendar.component(.year, from: Date()), id: \.self) { Text(String($0)).tag($0) }
                }
            }
            .pickerStyle(.wheel)
            .padding()
            .navigationTitle("Choose Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onSelect(selectedDate); dismiss() }
                        .disabled(selectedDate > Date())
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("This Month") { onSelect(calendar.dateInterval(of: .month, for: Date())!.start); dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview { StatsView().environmentInjection() }
