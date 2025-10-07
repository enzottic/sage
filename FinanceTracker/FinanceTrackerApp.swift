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
    
    var body: some Scene {
        WindowGroup {
            SageTabView()
                .fontDesign(.rounded)
        }
        .modelContainer(ExpenseDataService.sharedModelContainer)
    }
}

extension ModelContainer {
    static var preview: ModelContainer {
        do {
            let container = try ModelContainer(for: Expense.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            
            let expenses = [
                Expense(name: "Coffee Shop", amount: 5.50, category: .wants, date: Calendar.current.date(byAdding: .day, value: 0, to: Date())!, tag: .dining),
                Expense(name: "Book Store", amount: 23.99, category: .wants, date: Calendar.current.date(byAdding: .day, value: 0, to: Date())!, tag: .shopping),
                Expense(name: "Groceries", amount: 52.75, category: .needs, date: Calendar.current.date(byAdding: .day, value: 0, to: Date())!, tag: .groceries),
                
                Expense(name: "Lunch at Cafe", amount: 15.00, category: .wants, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, tag: .dining),
                Expense(name: "Public Transport", amount: 3.00, category: .needs, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, tag: .other),
                
                Expense(name: "Gym Membership", amount: 45.00, category: .wants, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, tag: .other),
                Expense(name: "Electricity Bill", amount: 110.20, category: .needs, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, tag: .billsAndUtils),
                Expense(name: "Savings Deposit", amount: 200.00, category: .savings, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, tag: .other),
                
                Expense(name: "Dinner Out", amount: 40.00, category: .wants, date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, tag: .dining),
                Expense(name: "Groceries at Market", amount: 80.50, category: .needs, date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, tag: .groceries),
                
                Expense(name: "Movie Night", amount: 20.00, category: .wants, date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, tag: .entertainment),
                Expense(name: "Prescription Medication", amount: 30.00, category: .needs, date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, tag: .other),
                Expense(name: "Emergency Fund", amount: 150.00, category: .savings, date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, tag: .other),
                
                Expense(name: "Car Insurance", amount: 210.00, category: .needs, date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, tag: .billsAndUtils),
                Expense(name: "Streaming Service", amount: 12.99, category: .wants, date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, tag: .entertainment),
                
                Expense(name: "Coffee Beans", amount: 10.00, category: .wants, date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, tag: .groceries),
                Expense(name: "Water Bill", amount: 35.60, category: .needs, date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, tag: .billsAndUtils),
                Expense(name: "Vacation Savings", amount: 250.00, category: .savings, date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, tag: .other),
                
                Expense(name: "Concert Ticket", amount: 75.00, category: .wants, date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, tag: .entertainment),
                Expense(name: "Upcoming Doctor Appointment", amount: 120.00, category: .needs, date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!, tag: .other),
                Expense(name: "Gift Purchase", amount: 60.00, category: .wants, date: Calendar.current.date(byAdding: .day, value: 3, to: Date())!, tag: .shopping),
                Expense(name: "Future Savings", amount: 300.00, category: .savings, date: Calendar.current.date(byAdding: .day, value: 4, to: Date())!, tag: .other)
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
