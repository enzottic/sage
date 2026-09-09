//
//  DashboardView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 7/12/26.
//
import SwiftUI
import SwiftData
import SageKit

struct DashboardView: View {
    @Environment(AppRouter.self) var appRouter
    @Environment(AppConfiguration.self) var config
    
    @State private var selectedMonth: Date

    @State private var isShowingWidgetOrder = false

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    init() {
        _selectedMonth = State(initialValue: .now)
    }

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedMonth, equalTo: .now, toGranularity: .month)
    }

    var body: some View {
        @Bindable var appRouter = appRouter
        NavigationStack(path: $appRouter.homePath) {
            dashboardContent
            .navigationTitle(selectedMonth.formatted(.dateTime.month(.wide).year()))
            .scrollContentBackground(.hidden)
            .background(.sageBackground)
            .gradientBackground()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Reorder Widgets", systemImage: "arrow.up.arrow.down") {
                            isShowingWidgetOrder = true
                        }
                    } label: {
                        Label("Dashboard Options", systemImage: "ellipsis")
                    }
                    .accessibilityIdentifier("dashboard-options")
                }
                SageToolbar(
                    onPrevious: {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                    },
                    onNext: {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                    },
                    onAdd: { appRouter.presentSheet(.addExpense(nil)) },
                    isNextDisabled: isCurrentMonth
                )
            }
            .sheet(isPresented: $isShowingWidgetOrder) {
                DashboardWidgetOrderSheet()
            }
            .appRouteDestinations()
        }
    }

    @ViewBuilder
    private var dashboardContent: some View {
        DashboardVisibleWidgets(selectedMonth: selectedMonth, order: config.dashboardWidgetOrder) { widgets in
            let rows = DashboardWidgetID.rows(for: widgets, isPad: isPad)
            dashboardRows(rows)
        }
    }

    @ViewBuilder
    private func dashboardRows(_ rows: [DashboardRowConfiguration]) -> some View {
        if isPad {
            // Each card owns its corners; a grouped List clips the entire
            // two-column row and rounds only its outside corners.
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(rows, id: \.self) { row in
                        composedWidgetRow(row)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        } else {
            List {
                ForEach(rows, id: \.self) { row in
                    if let widget = row.standaloneWidget {
                        widgetView(for: widget, layout: .full)
                    } else {
                        Section {
                            composedWidgetRow(row)
                        }
                    }
                }
            }
            .listSectionSpacing(12)
        }
    }

    @ViewBuilder
    func widgetView(for widget: DashboardWidget, layout: DashboardWidgetLayout) -> some View {
        switch widget {
        case .monthlyOverview: MonthlyOverviewWidget(selectedMonth: selectedMonth)
        case .expenseCalendar: ExpenseCalendarWidget(selectedMonth: selectedMonth)
        case .mostSpentTags:
            MostSpentTagsWidget(selectedMonth: selectedMonth, layout: layout)
        case .categoryUtilization: CategoryUtilizationWidget(selectedMonth: selectedMonth)
        case .upcomingRecurring: UpcomingRecurringWidget(layout: layout)
        case .recentExpenses(let rowStyle):
            RecentExpensesWidget(selectedMonth: selectedMonth, rowStyle: rowStyle, embedsList: isPad)
        case .singleCategoryUtilization(let category):
            SingleCategoryUtilizationWidget(category: category, layout: layout, selectedMonth: selectedMonth)
        }
    }

    private func composedWidgetRow(_ row: DashboardRowConfiguration) -> some View {
        AdaptiveEqualColumnsLayout(
            minimumColumnWidth: 340,
            horizontalSpacing: 16,
            verticalSpacing: 16
        ) {
            ForEach(row.columns, id: \.self) { column in
                VStack(spacing: 12) {
                    ForEach(column.widgets, id: \.self) { widget in
                        composedWidget(
                            widget,
                            presentation: column.presentation
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .buttonStyle(.borderless)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private func composedWidget(
        _ widget: DashboardWidget,
        presentation: DashboardWidgetLayout
    ) -> some View {
        if presentation == .compact && (widget == .mostSpentTags || widget == .upcomingRecurring) {
            // These widgets own their cards so empty content has no background.
            widgetView(for: widget, layout: presentation)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else if presentation == .full {
            // Keep Section headers and rows in one card before applying sizing
            // and backgrounds; otherwise SwiftUI styles each child separately.
            VStack(alignment: .leading, spacing: 12) {
                widgetView(for: widget, layout: presentation)
            }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: .rect(cornerRadius: DashboardCardStyle.cornerRadius)
                )
        } else {
            VStack(alignment: .leading, spacing: 12) {
                widgetView(for: widget, layout: presentation)
            }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: .rect(cornerRadius: DashboardCardStyle.cornerRadius)
                )
        }
    }
}

private struct AdaptiveEqualColumnsLayout: Layout {
    let minimumColumnWidth: CGFloat
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let availableWidth = proposal.width ?? minimumWideWidth(for: subviews.count)

        if usesColumns(width: availableWidth, count: subviews.count) {
            let columnWidth = wideColumnWidth(
                availableWidth: availableWidth,
                count: subviews.count
            )
            let height = subviews
                .map { $0.sizeThatFits(.init(width: columnWidth, height: nil)).height }
                .max() ?? 0

            return CGSize(width: availableWidth, height: height)
        }

        let heights = subviews.map {
            $0.sizeThatFits(.init(width: availableWidth, height: nil)).height
        }
        let spacing = verticalSpacing * CGFloat(max(0, subviews.count - 1))

        return CGSize(
            width: availableWidth,
            height: heights.reduce(0, +) + spacing
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        guard !subviews.isEmpty else { return }

        if usesColumns(width: bounds.width, count: subviews.count) {
            let columnWidth = wideColumnWidth(
                availableWidth: bounds.width,
                count: subviews.count
            )

            for (index, subview) in subviews.enumerated() {
                let x = bounds.minX + CGFloat(index) * (columnWidth + horizontalSpacing)
                subview.place(
                    at: CGPoint(x: x, y: bounds.minY),
                    anchor: .topLeading,
                    proposal: .init(width: columnWidth, height: bounds.height)
                )
            }
        } else {
            var y = bounds.minY

            for subview in subviews {
                let size = subview.sizeThatFits(.init(width: bounds.width, height: nil))
                subview.place(
                    at: CGPoint(x: bounds.minX, y: y),
                    anchor: .topLeading,
                    proposal: .init(width: bounds.width, height: size.height)
                )
                y += size.height + verticalSpacing
            }
        }
    }

    private func usesColumns(width: CGFloat, count: Int) -> Bool {
        width >= minimumWideWidth(for: count)
    }

    private func minimumWideWidth(for count: Int) -> CGFloat {
        let columns = max(2, count)
        return minimumColumnWidth * CGFloat(columns)
            + horizontalSpacing * CGFloat(columns - 1)
    }

    private func wideColumnWidth(availableWidth: CGFloat, count: Int) -> CGFloat {
        // An odd final widget keeps the left column's width in a wide layout.
        let columns = max(2, count)
        let spacing = horizontalSpacing * CGFloat(columns - 1)
        return (availableWidth - spacing) / CGFloat(columns)
    }
}

func expenseQuery(for month: Date, limit: Int? = nil) -> Query<Expense, [Expense]> {
    var descriptor = ExpenseFetchDescriptors.month(month)
    descriptor.fetchLimit = limit
    return Query(descriptor)
}

func expenseQuery(start: Date, end: Date, limit: Int? = nil) -> Query<Expense, [Expense]> {
    var descriptor = ExpenseFetchDescriptors.range(start: start, end: end)
    descriptor.fetchLimit = limit
    return Query(descriptor)
}

#Preview {
    DashboardView()
        .environmentInjection()
}

#Preview("Empty State") {
    DashboardView()
        .environmentInjection(empty: true)
}
