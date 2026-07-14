//
//  CategoryUtilizationWidget.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 7/12/26.
//
import SwiftUI
import SwiftData
import SageKit

struct CategoryUtilizationWidget: View {
    @Environment(AppConfiguration.self) private var config
    
    @Query var monthlyExpenses: [Expense]
    private let selectedMonth: Date

    init(selectedMonth: Date) {
        self.selectedMonth = selectedMonth
        _monthlyExpenses = expenseQuery(for: selectedMonth)
    }
    
    func utilization(for category: ExpenseCategory) -> Double {
        switch category {
        case .wants: config.wantsBudget == 0 ? 0 : monthlyExpenses.wantsUsed / config.wantsBudget
        case .needs: config.needsBudget == 0 ? 0 : monthlyExpenses.needsUsed / config.needsBudget
        case .savings: config.savingsBudget == 0 ? 0 : monthlyExpenses.savingsUsed / config.savingsBudget
        @unknown default: fatalError("Unknown expense category")
        }
    }

    func spent(for category: ExpenseCategory) -> Double {
        switch category {
        case .wants: monthlyExpenses.wantsUsed
        case .needs: monthlyExpenses.needsUsed
        case .savings: monthlyExpenses.savingsUsed
        @unknown default: fatalError("Unknown expense category")
        }
    }

    func budget(for category: ExpenseCategory) -> Double {
        switch category {
        case .wants: config.wantsBudget
        case .needs: config.needsBudget
        case .savings: config.savingsBudget
        @unknown default: fatalError("Unknown expense category")
        }
    }

    var body: some View {
        Section {
            ForEach(ExpenseCategory.allCases, id: \.self) { category in
                NavigationLink(value: AppRoute.categoryDetail(category, selectedMonth)) {
                    CategoryUtilizationView(
                        for: category,
                        utilization(for: category),
                        spent(for: category),
                        budget(for: category),
                    )
                }
                .tint(.primary)
                .listRowSeparator(.hidden)
            }
        } header: {
            Text("Categories")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    @Previewable @State var selectedMonth: Date = .now
    CategoryUtilizationWidget(selectedMonth: selectedMonth)
        .environmentInjection()
}
