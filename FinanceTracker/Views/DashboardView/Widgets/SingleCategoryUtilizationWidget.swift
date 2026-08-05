//
//  SingleCategoryUtilizationWidget.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 7/12/26.
//
import SwiftUI
import SwiftData
import SageKit

struct SingleCategoryUtilizationWidget: View {
    @Environment(AppConfiguration.self) private var config
    @Environment(AppRouter.self) private var appRouter
    @Environment(\.categoryColors) private var categoryColors

    let category: ExpenseCategory
    let layout: DashboardWidgetLayout
    let isNavigable: Bool
    private let selectedMonth: Date

    @Query var monthlyExpenses: [Expense]

    init(category: ExpenseCategory, layout: DashboardWidgetLayout, selectedMonth: Date, isNavigable: Bool = true) {
        self.category = category
        self.layout = layout
        self.selectedMonth = selectedMonth
        self.isNavigable = isNavigable
        _monthlyExpenses = expenseQuery(for: selectedMonth)
    }

    private var spent: Double {
        switch category {
        case .wants: monthlyExpenses.wantsUsed
        case .needs: monthlyExpenses.needsUsed
        case .savings: monthlyExpenses.savingsUsed
        @unknown default: fatalError("Unknown expense category")
        }
    }

    private var budget: Double {
        switch category {
        case .wants: config.wantsBudget
        case .needs: config.needsBudget
        case .savings: config.savingsBudget
        @unknown default: fatalError("Unknown expense category")
        }
    }

    private var utilization: Double {
        budget == 0 ? 0 : spent / budget
    }

    private var remaining: Double { max(budget - spent, 0) }
    private var isOverBudget: Bool { spent > budget + 0.001 }
    private var tint: Color { isOverBudget ? .red : category.color(in: categoryColors) }

    var body: some View {
        switch layout {
        case .full:
            Section {
                if isNavigable {
                    NavigationLink(value: AppRoute.categoryDetail(category, selectedMonth)) {
                        fullContent
                    }
                    .tint(.primary)
                    .listRowSeparator(.hidden)
                } else {
                    fullContent
                        .listRowSeparator(.hidden)
                }
            }
        case .compact:
            if isNavigable {
                Button {
                    appRouter.push(.categoryDetail(category, selectedMonth))
                } label: {
                    compactContent
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                compactContent
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var fullContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.rawValue)
                    .fontWeight(.bold)

                Spacer()

                Text(utilization.formatted(.percent.precision(.fractionLength(0))))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: min(max(utilization, 0), 1))
                .tint(tint)

            HStack {
                HStack(spacing: 5) {
                    Text(spent.currencyString)
                        .fontWeight(.semibold)
                        .foregroundStyle(isOverBudget ? .red : .primary)
                    Text("of \(budget.currencyString)")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(isOverBudget ? "\((spent - budget).currencyString) over" : "\(remaining.currencyString) left")
                    .font(.caption)
                    .foregroundStyle(isOverBudget ? .red : .secondary)
            }
        }
    }

    private var compactContent: some View {
        VStack(spacing: 8) {
            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)

            CircularProgressBar(progress: utilization, tint: tint, lineWidth: 10)
                .frame(width: 64, height: 64)

            Text("\(spent.currencyString) of \(budget.currencyString)")
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Full") {
    SingleCategoryUtilizationWidget(category: .wants, layout: .full, selectedMonth: .now)
        .environmentInjection()
}

#Preview("Compact") {
    SingleCategoryUtilizationWidget(category: .wants, layout: .compact, selectedMonth: .now)
        .environmentInjection()
}
