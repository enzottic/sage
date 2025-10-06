//
//  FinanceTrackerWidget.swift
//  FinanceTrackerWidget
//
//  Created by Tyler McCormick on 10/5/25.
//

import WidgetKit
import SwiftUI


struct ExpensesEntry: TimelineEntry {
    let date: Date
    let totalSpent: Double
    let wantsUtilization: Double
    let needsUtilization: Double
    let expenses: [Expense]
}

struct ExpensesProvider: AppIntentTimelineProvider {
    
    let data = ExpenseDataService()
    
    func placeholder(in context: Context) -> ExpensesEntry {
        ExpensesEntry(date: Date(), totalSpent: 0.0, wantsUtilization: 0.0, needsUtilization: 0.0, expenses: [])
    }
    
    func snapshot(for configuration: UtilizationAppIntent, in context: Context) async -> ExpensesEntry {
        
        if context.isPreview {
            ExpensesEntry(date: Date(), totalSpent: 3562.23, wantsUtilization: 0.35, needsUtilization: 0.84, expenses: [])
        } else {
            ExpensesEntry(date: Date(), totalSpent: 0.0, wantsUtilization: 0.0, needsUtilization: 0.0, expenses: [])
        }
    }
    
    func timeline(for configuration: UtilizationAppIntent, in context: Context) async -> Timeline<ExpensesEntry> {
        let expenses = data.fetchExpenses(for: .now)
        let totalSpent = expenses.reduce(0) { $0 + $1.amount }
        let wantsUtilization = data.fetchWantsUtilizationThisMonth()
        let needsUtilization = data.fetchNeedsUtilizationThisMonth()

        let entry = ExpensesEntry(date: .now, totalSpent: totalSpent, wantsUtilization: wantsUtilization, needsUtilization: needsUtilization, expenses: expenses)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
        return timeline
    }
}

struct FinanceTrackerWidgetEntryView : View {
    var entry: ExpensesEntry

    var body: some View {
        VStack(alignment: .center) {
            Text("Total Spent")
                .font(.subheadline)
                .fontWeight(.thin)
            Text(entry.totalSpent.formatted(.currency(code: "USD")))
                .font(.title2)
                .bold()
                .padding([.top], 3)
            
            Spacer()
            
            VStack {
                utilizationView(title: "Wants", utilization: entry.wantsUtilization)
                utilizationView(title: "Needs", utilization: entry.needsUtilization)
            }
            
            Spacer()
        }
    }
    
    func utilizationView(title: String, utilization: Double) -> some View {
        VStack {
            
            HStack{
                Text("Wants")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(utilization, format: .percent.precision(.fractionLength(0)))
            }
            
            ProgressView(value: utilization)
                .tint(title == "Wants" ? .green : .red)
        }
    }
}

struct ExpenseUtilizationWidget: Widget {
    let kind: String = "SageExpenseUtilizationWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: UtilizationAppIntent.self, provider: ExpensesProvider()) { entry in
            FinanceTrackerWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("View Expense Utilization")
        .description(Text("View total spent this month, and wants and needs utilization"))
        .supportedFamilies([.systemSmall])
    }
}


extension LatestExpensesAppIntent {
    fileprivate static var expenses: LatestExpensesAppIntent {
        let intent = LatestExpensesAppIntent()
        return intent
    }
}

#Preview(as: .systemSmall) {
    ExpenseUtilizationWidget()
} timeline: {
    ExpensesEntry(date: .now, totalSpent: 5432.23, wantsUtilization: 0.23, needsUtilization: 0.56, expenses: [Expense.example, Expense.example])
}
