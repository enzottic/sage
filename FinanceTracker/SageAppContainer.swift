//
//  SageAppContainer.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/17/26.
//
import Foundation
import SwiftData
import SageKit

// Copies SQLite files (main + WAL + SHM) from src to dst. Safe to call if src doesn't exist.
private func copyStoreFiles(from src: URL, to dst: URL) {
    let fm = FileManager.default
    for suffix in ["", "-wal", "-shm"] {
        let srcFile = URL(fileURLWithPath: src.path + suffix)
        let dstFile = URL(fileURLWithPath: dst.path + suffix)
        guard fm.fileExists(atPath: srcFile.path) else { continue }
        try? fm.copyItem(at: srcFile, to: dstFile)
    }
}

// Migrates the store from the app's private sandbox to the shared app group container.
// Only runs once, tracked by a flag in the app group UserDefaults.
private func migrateStoreToAppGroupIfNeeded(destination: URL) {
    let defaults = UserDefaults(suiteName: "group.me.enzottic.SageAppGroup")
    let migrationKey = "hasCompletedStoreMigration"
    guard !(defaults?.bool(forKey: migrationKey) ?? false) else { return }
    defer { defaults?.set(true, forKey: migrationKey) }

    let fm = FileManager.default
    // Only migrate if new store doesn't exist yet — avoids clobbering a store already opened there
    guard !fm.fileExists(atPath: destination.path) else { return }

    #if DEBUG
    let candidates = [URL.applicationSupportDirectory.appending(path: "SageDev.sqlite")]
    #else
    // CloudKit will re-sync all data to the new location — no need to copy stale local files,
    // and doing so can confuse CloudKit's change tracking metadata.
    let cloudSyncEnabled = (UserDefaults(suiteName: "group.me.enzottic.SageAppGroup")?.bool(forKey: "isCloudSyncEnabled")) ?? false
    guard !cloudSyncEnabled else { return }

    // SwiftData's default name when no url is given varies; try the most common candidates
    let candidates = [
        URL.applicationSupportDirectory.appending(path: "default.store"),
        URL.applicationSupportDirectory.appending(path: "Sage.store"),
        URL.applicationSupportDirectory.appending(path: "FinanceTracker.store"),
    ]
    #endif

    for candidate in candidates where fm.fileExists(atPath: candidate.path) {
        copyStoreFiles(from: candidate, to: destination)
        return
    }
}

@MainActor
let appContainer: ModelContainer = {
    do {
        // iCloud KVS is authoritative for the sync preference
        let cloudKVS = NSUbiquitousKeyValueStore.default
        let cloudSyncEnabled: Bool
        if cloudKVS.object(forKey: "isCloudSyncEnabled") != nil {
            cloudSyncEnabled = cloudKVS.bool(forKey: "isCloudSyncEnabled")
        } else {
            let defaults = UserDefaults(suiteName: "group.me.enzottic.SageAppGroup")
            cloudSyncEnabled = defaults?.bool(forKey: "isCloudSyncEnabled") ?? false
        }

        let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: SageModelContainer.appGroupIdentifier)!

        #if DEBUG
        let storeURL = groupURL.appending(path: "SageDev.sqlite")
        #else
        let storeURL = groupURL.appending(path: "Sage.sqlite")
        #endif

        migrateStoreToAppGroupIfNeeded(destination: storeURL)

        let modelContainer = try SageModelContainer.make(cloudKitEnabled: cloudSyncEnabled)
        
        // Generate any due recurring expenses through today
        let recurringService = RecurringExpenseService(modelContext: modelContainer.mainContext)
        recurringService.generateAllExpenses(through: Date())
        
        return modelContainer
    } catch {
        fatalError("Failed to create model container: \(error)")
    }
}()

@MainActor
let previewAppContainer: ModelContainer = {
    do {
        let schema = Schema(versionedSchema: SageSchemaV2.self)
        let container = try ModelContainer(for: schema, migrationPlan: SageSchemaMigrationPlan.self ,configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
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
        
        let recurringExpenseRules = [
            RecurringExpenseRule(name: "Rent", amount: 1500, note: "", category: .needs, tag: expenseTags["Bills"], frequency: .monthly, startDate: .now),
            RecurringExpenseRule(name: "Car Insurance", amount: 150, note: "", category: .needs, tag: expenseTags["Bills"], frequency: .monthly, startDate: .now),
        ]
        
        recurringExpenseRules.forEach { rule in
            container.mainContext.insert(rule)
        }
        
        return container
        
    } catch {
        fatalError("Failed to create preview container: \(error)")
    }
}()
