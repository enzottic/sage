//
//  SageApp.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import SwiftUI
import SwiftData
import CloudKit
import Combine
import CoreData
import AppIntents

@main
struct SageApp: App {
    @State private var appConfiguration = AppConfiguration()
    @State private var splitwiseService = SplitwiseService()
    @AppStorage("hasOpenedAppOnce") var hasOpenedAppOnce: Bool = false
    
    init() {
        UIColorValueTransformer.register()
        configureNavigationBarAppearance()

        // Pull latest iCloud KVS values before checking setup state
        NSUbiquitousKeyValueStore.default.synchronize()

        // Register before the app finishes launching (BGTaskScheduler requirement)
        RecurringNotificationService.registerBackgroundTask()

        // Register App Shortcuts phrases with Siri
        SageShortcutsProvider.updateAppShortcutParameters()

        // If onboarding was completed on another device, skip it here
        if !UserDefaults.standard.bool(forKey: "hasOpenedAppOnce"),
           AppConfiguration.hasCompletedSetupOnAnotherDevice {
            UserDefaults.standard.set(true, forKey: "hasOpenedAppOnce")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasOpenedAppOnce {
                    WelcomeView()
                } else {
                    RootTabView()
                }
            }
            .preferredColorScheme(appConfiguration.selectedAppearance.colorScheme)
            .task {
                await seedBuiltInTagsIfNeeded()
                deduplicateTags()
                await scheduleRecurringNotifications()
                RecurringNotificationService.scheduleNextBackgroundRefresh()
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange).receive(on: DispatchQueue.main)) { _ in
                deduplicateTags()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification).receive(on: DispatchQueue.main)) { _ in
                // KVS values may arrive after launch — check if onboarding was completed on another device
                if !hasOpenedAppOnce, AppConfiguration.hasCompletedSetupOnAnotherDevice {
                    hasOpenedAppOnce = true
                }
            }
        }
        .environment(appConfiguration)
        .environment(\.categoryColors, appConfiguration.categoryColors)
        .environment(splitwiseService)
        .modelContainer(appContainer)
    }
    
    /// Seeds built-in tags, checking CloudKit first when sync is enabled to avoid duplicates.
    private func seedBuiltInTagsIfNeeded() async {
        let context = appContainer.mainContext
        
        // Check which built-in tags already exist locally
        let builtInIDs = ExpenseTag.builtInTags.compactMap { $0.id }
        let descriptor = FetchDescriptor<ExpenseTag>(
            predicate: #Predicate { builtInIDs.contains($0.id) }
        )
        let localIDs = Set((try? context.fetch(descriptor))?.map(\.id) ?? [])
        
        // If all built-in tags exist locally, nothing to do
        if localIDs.count == ExpenseTag.builtInTags.count {
            return
        }
        
        // If CloudKit sync is enabled, check the cloud for tags that may not have synced yet
        var cloudTagIDs: Set<String> = []
        if appConfiguration.isCloudSyncEnabled {
            let db = CKContainer(identifier: "iCloud.me.enzottic.FinanceTracker").privateCloudDatabase
            let query = CKQuery(recordType: "CD_ExpenseTag", predicate: NSPredicate(value: true))
            
            if let results = try? await db.records(matching: query) {
                for (_, result) in results.matchResults {
                    if let record = try? result.get(),
                       let id = record["CD_id"] as? String {
                        cloudTagIDs.insert(id)
                    }
                }
            }
        }
        
        // Only insert tags that don't exist locally or in CloudKit
        for tag in ExpenseTag.builtInTags {
            if !localIDs.contains(tag.id) && !cloudTagIDs.contains(tag.id.uuidString) {
                context.insert(tag)
            }
        }
        try? context.save()
    }
    
    private func configureNavigationBarAppearance() {
        if let largeDescriptor = UIFont.systemFont(ofSize: 34, weight: .bold).fontDescriptor.withDesign(.rounded) {
            UINavigationBar.appearance().largeTitleTextAttributes = [.font: UIFont(descriptor: largeDescriptor, size: 34)]
        }
        if let inlineDescriptor = UIFont.systemFont(ofSize: 17, weight: .semibold).fontDescriptor.withDesign(.rounded) {
            UINavigationBar.appearance().titleTextAttributes = [.font: UIFont(descriptor: inlineDescriptor, size: 17)]
        }
    }

    @MainActor
    private func scheduleRecurringNotifications() async {
        let rules = (try? appContainer.mainContext.fetch(FetchDescriptor<RecurringExpenseRule>())) ?? []
        await RecurringNotificationService.scheduleAll(rules: rules, enabled: appConfiguration.billRemindersEnabled)
    }

    private func deduplicateTags() {
        let service = TagDeduplicationService(modelContext: appContainer.mainContext)
        let removed = service.deduplicateTags()
        if removed > 0 {
            print("Deduplicated \(removed) tag(s)")
        }
    }
}
