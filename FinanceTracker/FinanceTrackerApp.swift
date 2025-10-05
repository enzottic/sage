//
//  FinanceTrackerApp.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import SwiftUI
import SwiftData

@main
struct FinanceTrackerApp: App {
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Expense.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            SageTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}

extension ModelContainer {
    static var preview: ModelContainer {
        do {
            let container = try ModelContainer(for: Expense.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            
            let expenses = [
                Expense(name: "Lunch at Cafe", amount: 25.50, category: .wants, date: Calendar.current.date(byAdding: .day, value: 0, to: Date())!),
                Expense(name: "Gas Station", amount: 45.00, category: .needs, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!),
                Expense(name: "Netflix Subscription", amount: 12.99, category: .wants, date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!),
                Expense(name: "Grocery Shopping", amount: 89.99, category: .needs, date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!),
                Expense(name: "Electric Bill", amount: 150.00, category: .needs, date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!),
                Expense(name: "Movie Tickets", amount: 35.00, category: .wants, date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!),
                Expense(name: "Coffee Shop", amount: 20.00, category: .wants, date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!),
                Expense(name: "New Shoes", amount: 75.50, category: .wants, date: Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!),
                Expense(name: "Doctor Visit", amount: 120.00, category: .needs, date: Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date())!),
                Expense(name: "Uber Rides", amount: 60.00, category: .needs, date: Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date())!),
                Expense(name: "Monthly Savings", amount: 500.00, category: .savings, date: Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date())!)
            ]
            
            expenses.forEach { expense in
                container.mainContext.insert(expense)
            }
            
            return container
            
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}
