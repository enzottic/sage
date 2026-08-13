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

    @State private var rows: [DashboardRowConfiguration] = [
        .init(widgets: [.monthlyOverview]),
        .init(widgets: [.singleCategoryUtilization(.needs)]),
        .init(widgets: [.singleCategoryUtilization(.wants)]),
        .init(widgets: [.singleCategoryUtilization(.savings)]),
        .init(widgets: [.upcomingRecurring]),
        .init(widgets: [.recentExpenses(.regular)]),
    ]

    init() {
        _selectedMonth = State(initialValue: .now)
    }

    var body: some View {
        @Bindable var appRouter = appRouter
        NavigationStack(path: $appRouter.homePath) {
            List {
                ForEach(rows, id: \.self) { row in
                    if row.widgets.count == 1, let widget = row.widgets.first {
                        widgetView(for: widget, layout: .full)
                    } else {
                        Section {
                            sharedWidgetRow(row.widgets)
                        }
                    }
                }
            }
            .navigationTitle(selectedMonth.formatted(.dateTime.month(.wide).year()))
            .listSectionSpacing(12)
            .scrollContentBackground(.hidden)
            .background(.sageBackground)
            .gradientBackground()
            .toolbar {
                SageToolbar(
                    onPrevious: {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                    },
                    onNext: {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                    },
                    onAdd: { appRouter.presentSheet(.addExpense(nil)) }
                )
            }
            .appRouteDestinations()
        }
    }

    @ViewBuilder
    func widgetView(for widget: DashboardWidget, layout: DashboardWidgetLayout) -> some View {
        switch widget {
        case .monthlyOverview: MonthlyOverviewWidget(selectedMonth: selectedMonth)
        case .categoryUtilization: CategoryUtilizationWidget(selectedMonth: selectedMonth)
        case .upcomingRecurring: UpcomingRecurringWidget()
        case .recentExpenses(let rowStyle): RecentExpensesWidget(selectedMonth: selectedMonth, rowStyle: rowStyle)
        case .singleCategoryUtilization(let category):
            SingleCategoryUtilizationWidget(category: category, layout: layout, selectedMonth: selectedMonth)
        }
    }

    private func sharedWidgetRow(_ widgets: [DashboardWidget]) -> some View {
        HStack(spacing: 16) {
            ForEach(widgets, id: \.self) { widget in
                widgetView(for: widget, layout: .compact)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 10))
            }
        }
        .buttonStyle(.borderless)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

func expenseQuery(for month: Date, limit: Int? = nil) -> Query<Expense, [Expense]> {
    let cal = Calendar.current
    let startOfMonth = cal.dateInterval(of: .month, for: month)?.start ?? month
    let endOfMonth = cal.dateInterval(of: .month, for: month)?.end ?? month
    return expenseQuery(start: startOfMonth, end: endOfMonth, limit: limit)
}

func expenseQuery(start: Date, end: Date, limit: Int? = nil) -> Query<Expense, [Expense]> {
    var descriptor = FetchDescriptor<Expense>(
        predicate: #Predicate { $0.date >= start && $0.date < end },
        sortBy: [SortDescriptor(\.date, order: .reverse)]
    )
    descriptor.fetchLimit = limit
    
    return Query(descriptor)
}

#Preview {
    DashboardView()
        .environmentInjection()
}
