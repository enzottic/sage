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
import UserNotifications

@main
struct SageApp: App {
    @State private var appConfiguration = AppConfiguration()
    @AppStorage("hasOpenedAppOnce") var hasOpenedAppOnce: Bool = false
    private let containerResult: Result<ModelContainer, any Error>
    
    @MainActor
    init() {
        Self.configureNavigationBarAppearance()

        if UITestConfiguration.isEnabled {
            hasOpenedAppOnce = !UITestConfiguration.showsOnboarding
            WhatsNewStore.markCurrentVersionSeen()
        }

        // Pull latest iCloud KVS values before checking setup state
        NSUbiquitousKeyValueStore.default.synchronize()

        // Keep the store configuration stable across the app, widgets, and App Intents until
        // the next app launch.
        SageModelContainer.activateCloudKitPreference()

        let containerResult: Result<ModelContainer, any Error>
        if UITestConfiguration.isEnabled {
            containerResult = Result {
                let container = try SageModelContainer.make(for: .test)
                if let seedName = UITestConfiguration.seedExpenseName {
                    container.mainContext.insert(
                        Expense(name: seedName, amount: 42.50, category: .wants, date: .now)
                    )
                    try container.mainContext.save()
                }
                return container
            }
        } else {
            containerResult = SageModelContainer.shared
        }
        self.containerResult = containerResult

        // Present notifications that fire while the app is foreground
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared

        // Make ExpenseStore resolvable via @Dependency in App Intents.
        if case let .success(container) = containerResult {
            let expenseStore = ExpenseStore(modelContainer: container)
            AppDependencyManager.shared.add(dependency: expenseStore)

            #if !DEBUG
            let recurringService = RecurringExpenseService(modelContext: container.mainContext)
            recurringService.generateAllExpenses(through: Date())
            #endif
        }

        // Register App Shortcuts phrases with Siri
        SageShortcutsProvider.updateAppShortcutParameters()

        // If onboarding was completed on another device, skip it here
        if !UITestConfiguration.isEnabled,
           !UserDefaults.standard.bool(forKey: "hasOpenedAppOnce"),
           AppConfiguration.hasCompletedSetupOnAnotherDevice {
            UserDefaults.standard.set(true, forKey: "hasOpenedAppOnce")
            WhatsNewStore.markCurrentVersionSeen()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            switch containerResult {
            case let .success(container):
                mainContent
                    .modelContainer(container)
            case let .failure(error):
                DataStoreRecoveryView(error: error)
            }
        }
        .environment(appConfiguration)
        .environment(\.categoryColors, appConfiguration.categoryColors)
    }

    @ViewBuilder
    private var mainContent: some View {
        Group {
            if UITestConfiguration.isEnabled, !UITestConfiguration.showsOnboarding {
                RootTabView()
            } else if !hasOpenedAppOnce {
                OnboardingView()
            } else {
                RootTabView()
            }
        }
        .textCase(nil)
        .preferredColorScheme(appConfiguration.selectedAppearance.colorScheme)
        .onReceive(NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification).receive(on: DispatchQueue.main)) { _ in
            if !UITestConfiguration.isEnabled,
               !hasOpenedAppOnce,
               AppConfiguration.hasCompletedSetupOnAnotherDevice {
                WhatsNewStore.markCurrentVersionSeen()
                hasOpenedAppOnce = true
            }
        }
    }
    
    private static func configureNavigationBarAppearance() {
        if let largeDescriptor = UIFont.systemFont(ofSize: 34, weight: .bold).fontDescriptor.withDesign(.rounded) {
            UINavigationBar.appearance().largeTitleTextAttributes = [.font: UIFont(descriptor: largeDescriptor, size: 34)]
        }
        if let inlineDescriptor = UIFont.systemFont(ofSize: 17, weight: .semibold).fontDescriptor.withDesign(.rounded) {
            UINavigationBar.appearance().titleTextAttributes = [.font: UIFont(descriptor: inlineDescriptor, size: 17)]
        }
    }
}

private struct DataStoreRecoveryView: View {
    let error: any Swift.Error

    var body: some View {
        ContentUnavailableView(
            "Your data could not open",
            systemImage: "externaldrive.badge.exclamationmark",
            description: Text("Sage could not access its shared storage. Check available device storage, then close and reopen the app. \(error.localizedDescription)")
        )
    }
}

struct MainAppPackage: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [SageKitPackage.self]
    }
}
