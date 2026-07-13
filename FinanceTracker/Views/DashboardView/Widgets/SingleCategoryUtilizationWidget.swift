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

    @Query var monthlyExpenses: [Expense]

    init(category: ExpenseCategory, layout: DashboardWidgetLayout, selectedMonth: Date) {
        self.category = category
        self.layout = layout
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
                NavigationLink(value: AppRoute.categoryDetail(category)) {
                    fullContent
                }
                .tint(.primary)
                .listRowSeparator(.hidden)
            }
        case .compact:
            // Rendered inside a cleared list row (see DashboardView.sharedWidgetRow),
            // so no Section: the dashboard draws the card background around this.
            // A Button (not NavigationLink) so List doesn't add a disclosure chevron.
            Button {
                appRouter.push(.categoryDetail(category))
            } label: {
                compactContent
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var fullContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.rawValue)
                    .font(.title2)
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
            CircularProgressBar(progress: utilization, tint: tint)
                .frame(width: 64, height: 64)

            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(spent.currencyString)
                .font(.caption)
                .foregroundStyle(.secondary)
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
