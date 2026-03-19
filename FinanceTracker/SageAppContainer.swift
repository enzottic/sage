//
//  SageAppContainer.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/17/26.
//
import Foundation
import SwiftData

@MainActor
let appContainer: ModelContainer = {
    do {
        let schema = Schema(versionedSchema: SageSchemaV1.self)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        let modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        // Generate any due recurring expenses through today
        let recurringService = RecurringExpenseService(modelContext: modelContainer.mainContext)
        recurringService.generateAllExpenses(through: Date())
        
        var expenseFetchDescriptor = FetchDescriptor<ExpenseTag>()
        expenseFetchDescriptor.fetchLimit = 1
        
        guard try modelContainer.mainContext.fetch(expenseFetchDescriptor).count == 0 else { return modelContainer }
        
        ExpenseTag.builtInTags.forEach { tag in
            modelContainer.mainContext.insert(tag)
        }
        try modelContainer.mainContext.save()
        
        return modelContainer
    } catch {
        fatalError("Failed to create model container: \(error)")
    }
}()

@MainActor
let previewAppContainer: ModelContainer = {
    do {
        let schema = Schema(versionedSchema: SageSchemaV1.self)
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
        let expenseTags: [String: ExpenseTag] = [
            "Other" : .other,
            "Dining" : .dining,
            "Shopping" : .shopping,
            "Entertainment" : .entertainment,
            "Groceries" : .groceries,
            "Travel" : .travel,
            "Subscriptions" : .subscriptions,
            "Bills" : .billsAndUtils,
        ]
        
        expenseTags.values.forEach { tag in
            container.mainContext.insert(tag)
        }
        
        let expenses = [
            Expense(name: "Coffee Shop", amount: 5.50, category: .wants, date: Calendar.current.date(byAdding: .day, value: 0, to: Date())!, tag: expenseTags["Dining"]),
            Expense(name: "Book Store", amount: 23.99, category: .wants, date: Calendar.current.date(byAdding: .day, value: 0, to: Date())!, tag: expenseTags["Shopping"]),
            Expense(name: "Groceries", amount: 52.75, category: .needs, date: Calendar.current.date(byAdding: .day, value: 0, to: Date())!, tag: expenseTags["Groceries"]),
            
            Expense(name: "Lunch at Cafe", amount: 15.00, category: .wants, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, tag: expenseTags["Dining"]),
            Expense(name: "Public Transport", amount: 3.00, category: .needs, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, tag: expenseTags["Other"]),
            
            Expense(name: "Gym Membership", amount: 45.00, category: .wants, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, tag: expenseTags["Other"]),
            Expense(name: "Electricity Bill", amount: 110.20, category: .needs, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, tag: expenseTags["Bills"]),
            Expense(name: "Savings Deposit", amount: 200.00, category: .savings, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, tag: expenseTags["Other"]),
            
            Expense(name: "Dinner Out", amount: 40.00, category: .wants, date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, tag: expenseTags["Dining"]),
            Expense(name: "Groceries at Market", amount: 80.50, category: .needs, date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, tag: expenseTags["Groceries"]),
            
            Expense(name: "Movie Night", amount: 20.00, category: .wants, date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, tag: expenseTags["Entertainment"]),
            Expense(name: "Prescription Medication", amount: 30.00, category: .needs, date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, tag: expenseTags["Other"]),
            Expense(name: "Emergency Fund", amount: 150.00, category: .savings, date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, tag: expenseTags["Other"]),
            
            Expense(name: "Car Insurance", amount: 210.00, category: .needs, date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, tag: expenseTags["Bills"]),
            Expense(name: "Streaming Service", amount: 12.99, category: .wants, date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, tag: expenseTags["Entertainment"]),
            
            Expense(name: "Coffee Beans", amount: 10.00, category: .wants, date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, tag: expenseTags["Groceries"]),
            Expense(name: "Water Bill", amount: 35.60, category: .needs, date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, tag: expenseTags["Bills"]),
            Expense(name: "Vacation Savings", amount: 250.00, category: .savings, date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, tag: expenseTags["Other"]),
            
            Expense(name: "Concert Ticket", amount: 75.00, category: .wants, date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, tag: expenseTags["Entertainment"]),
            Expense(name: "Upcoming Doctor Appointment", amount: 120.00, category: .needs, date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!, tag: expenseTags["Other"]),
            Expense(name: "Gift Purchase", amount: 60.00, category: .wants, date: Calendar.current.date(byAdding: .day, value: 3, to: Date())!, tag: expenseTags["Shopping"]),
            Expense(name: "Future Savings", amount: 300.00, category: .savings, date: Calendar.current.date(byAdding: .day, value: 4, to: Date())!, tag: expenseTags["Other"])
        ]
        
        expenses.forEach { expense in
            container.mainContext.insert(expense)
        }
        
        return container
        
    } catch {
        fatalError("Failed to create preview container: \(error)")
    }
}()
