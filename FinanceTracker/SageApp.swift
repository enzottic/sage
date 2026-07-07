//
//  SageApp.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import SwiftUI
import SwiftData
import AppIntents
import SageKit
import Combine

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

        // Make ExpenseStore resolvable via @Dependency in App Intents.
        AppDependencyManager.shared.add(dependency: ExpenseStore.shared)

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
                await scheduleRecurringNotifications()
                RecurringNotificationService.scheduleNextBackgroundRefresh()
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

}

struct MainAppPackage: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [SageKitPackage.self]
    }
}
