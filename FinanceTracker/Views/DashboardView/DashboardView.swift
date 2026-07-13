//
//  DashboardView.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 7/12/26.
//
import SwiftUI
import SwiftData
import SageKit

/// A displayable dashboard row: either one full-width widget or a pair of
/// half-width widgets sharing a single (chrome-less) list row.
private enum DashboardRow: Hashable {
    case full(DashboardWidgetConfiguration)
    case pair(DashboardWidgetConfiguration, DashboardWidgetConfiguration?)
}

struct DashboardView: View {
    @Environment(AppRouter.self) var appRouter
    @Environment(SplitwiseService.self) private var splitwiseService
    @Environment(AppConfiguration.self) var config
    
    @State private var selectedMonth: Date
    @State private var showSplitwiseImportSheet: Bool = false

    @State private var widgets: [DashboardWidgetConfiguration] = [
        .init(widget: .monthlyOverview, size: .full),
        .init(widget: .recentExpenses, size: .full),
        .init(widget: .categoryUtilization, size: .full),
    ]

    init() {
        _selectedMonth = State(initialValue: .now)
    }

    /// Groups consecutive half-size widgets into pairs; full-size widgets get
    /// their own row. An unpaired half stays at half width next to an empty slot.
    private var rows: [DashboardRow] {
        var result: [DashboardRow] = []
        var pendingHalf: DashboardWidgetConfiguration?
        for config in widgets {
            switch config.size {
            case .full:
                if let pending = pendingHalf {
                    result.append(.pair(pending, nil))
                    pendingHalf = nil
                }
                result.append(.full(config))
            case .half:
                if let pending = pendingHalf {
                    result.append(.pair(pending, config))
                    pendingHalf = nil
                } else {
                    pendingHalf = config
                }
            }
        }
        if let pending = pendingHalf {
            result.append(.pair(pending, nil))
        }
        return result
    }

    var body: some View {
        NavigationStack{
            List {
                ForEach(rows, id: \.self) { row in
                    switch row {
                    case .full(let config):
                        widgetView(for: config)
                    case .pair(let leading, let trailing):
                        Section {
                            halfWidgetPair(leading, trailing)
                        }
                    }
                }
            }
            .navigationTitle(selectedMonth.formatted(.dateTime.month(.wide).year()))
            .scrollContentBackground(.hidden)
            .background(.sageBackground)
            .sheet(isPresented: $showSplitwiseImportSheet) {
                SplitwiseImportView()
            }
            .toolbar {
                SageToolbar(
                    onPrevious: {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth)!
                    },
                    onNext: {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth)!
                    },
                    onAdd: { appRouter.homeRouter.navigateTo(route: .addExpense(expense: nil)) },
                    onImportFromSplitwise: splitwiseService.isConfigured
                        ? { showSplitwiseImportSheet = true }
                        : nil,
                )
            }
            .gradientBackground()
//            .navigationDestination(for: HomeRouter.Route.self) { route in
//                switch route {
//                case .categoryDetail(let category):
//                    HomeContentView.CategoryDetailRoute(category: category)
//                case .addExpense(let expense):
//                    AddExpenseView(expense: expense)
//                }
//            }
            .navigationDestination(for: Expense.self) { expense in
                ExpenseDetailView(expense: expense)
            }
        }
    }

    @ViewBuilder
    func widgetView(for config: DashboardWidgetConfiguration) -> some View {
        switch config.widget {
        case .monthlyOverview: MonthlyOverviewWidget(selectedMonth: .now)
        case .categoryUtilization: CategoryUtilizationWidget(selectedMonth: .now)
        case .recentExpenses: RecentExpensesWidget(selectedMonth: .now)
        case .singleCategoryUtilization(let category):
            SingleCategoryUtilizationWidget(category: category, size: config.size, selectedMonth: .now)
        }
    }

    /// Two half widgets in one list row. The row's own background/insets are
    /// cleared so each widget can draw its own card, sized to half the width
    /// a regular inset-grouped section would occupy.
    private func halfWidgetPair(
        _ leading: DashboardWidgetConfiguration,
        _ trailing: DashboardWidgetConfiguration?
    ) -> some View {
        HStack(spacing: 16) {
            halfWidgetCard(for: leading)
            if let trailing {
                halfWidgetCard(for: trailing)
            } else {
                Color.clear.frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderless)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func halfWidgetCard(for config: DashboardWidgetConfiguration) -> some View {
        widgetView(for: config)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 10))
    }
}

func expenseQuery(for month: Date, limit: Int? = nil) -> Query<Expense, [Expense]> {
    let cal = Calendar.current
    let startOfMonth = cal.dateInterval(of: .month, for: month)?.start ?? month
    let endOfMonth = cal.dateInterval(of: .month, for: month)?.end ?? month
    return expenseQuery(start: startOfMonth, end: endOfMonth)
}

func expenseQuery(start: Date, end: Date, limit: Int? = nil) -> Query<Expense, [Expense]> {
    var descriptor = FetchDescriptor<Expense>(
        predicate: #Predicate { $0.date > start && $0.date < end },
        sortBy: [SortDescriptor(\.date, order: .reverse)]
    )
    descriptor.fetchLimit = limit
    
    return Query(descriptor)
}

#Preview {
    DashboardView()
        .environmentInjection()
}
