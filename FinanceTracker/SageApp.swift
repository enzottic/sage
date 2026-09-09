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
import UserNotifications
import Playgrounds

@main
struct SageApp: App {
    @State private var appConfiguration = AppConfiguration()
    @State private var didCompleteUITestOnboarding = false
    @AppStorage("hasOpenedAppOnce") var hasOpenedAppOnce: Bool = false
    private let containerResult: Result<ModelContainer, any Error>
    private let recurringExpenseCoordinator: RecurringExpenseCoordinator?
    private let recurringReminders: RecurringReminderCoordinator?
    
    @MainActor
    init() {
        Self.configureNavigationBarAppearance()

        if UITestConfiguration.isEnabled {
            WhatsNewStore.markCurrentVersionSeen()
        }

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
                if UITestConfiguration.seedsSearch {
                    let date = Date.now
                    for index in 0..<101 {
                        container.mainContext.insert(Expense(
                            name: "Search Needle \(index)", amount: 1,
                            date: date.addingTimeInterval(Double(-index))
                        ))
                    }
                    try container.mainContext.save()
                }
                if UITestConfiguration.seedsCalendar {
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: .now)
                    let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
                    container.mainContext.insert(Expense(name: "Calendar Coffee", amount: 7.50, date: today))
                    container.mainContext.insert(RecurringExpenseRule(
                        name: "Calendar Subscription", amount: 15, note: "", category: .wants,
                        frequency: .daily, startDate: tomorrow
                    ))
                    container.mainContext.insert(RecurringExpenseRule(
                        name: "Expired Subscription", amount: 999, note: "", category: .wants,
                        frequency: .daily, startDate: today, endDate: today, lastGeneratedDate: today
                    ))
                    try container.mainContext.save()
                }
                return container
            }
        } else {
            containerResult = SageModelContainer.shared.flatMap { container in
                Result {
                    #if DEBUG
                    let context = ModelContext(container)
                    MockDataSeeder.seed(into: context)
                    try context.save()
                    #endif
                    return container
                }
            }
        }
        self.containerResult = containerResult
        if case let .success(container) = containerResult,
           !UITestConfiguration.isEnabled,
           ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            recurringReminders = RecurringReminderCoordinator(container: container)
        } else {
            recurringReminders = nil
        }

        // Present notifications that fire while the app is foreground
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared

        // Make ExpenseStore resolvable via @Dependency in App Intents.
        if case let .success(container) = containerResult {
            let expenseStore = ExpenseStore(modelContainer: container)
            AppDependencyManager.shared.add(dependency: expenseStore)
        }

        #if !DEBUG
        if case let .success(container) = containerResult {
            recurringExpenseCoordinator = RecurringExpenseCoordinator(
                modelContainer: container,
                cloudKitEnabled: SageModelContainer.isCloudKitEnabled
            )
        } else {
            recurringExpenseCoordinator = nil
        }
        #else
        recurringExpenseCoordinator = nil
        #endif

        recurringExpenseCoordinator?.start()

        // Register App Shortcuts phrases with Siri
        SageShortcutsProvider.updateAppShortcutParameters()

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
        .environment(\.recurringReminders, recurringReminders)
        .environment(\.categoryColors, appConfiguration.categoryColors)
    }

    @ViewBuilder
    private var mainContent: some View {
        Group {
            if UITestConfiguration.isEnabled {
                if UITestConfiguration.showsOnboarding, !didCompleteUITestOnboarding {
                    OnboardingView {
                        didCompleteUITestOnboarding = true
                    }
                } else {
                    RootTabView()
                }
            } else if !hasOpenedAppOnce {
                OnboardingView()
            } else {
                RootTabView()
            }
        }
        .textCase(nil)
        .fontDesign(.rounded)
        .preferredColorScheme(appConfiguration.selectedAppearance.colorScheme)
        .task {
            recurringReminders?.start(configuration: appConfiguration)
            // Local notifications deliver while suspended; this only replenishes the horizon.
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(3_600)) } catch { return }
                recurringReminders?.refresh()
            }
        }
        .onChange(of: appConfiguration.billRemindersEnabled) { recurringReminders?.refresh() }
        .onChange(of: appConfiguration.billReminderDaysBefore) { recurringReminders?.refresh() }
        .onChange(of: appConfiguration.billReminderTimeMinutes) { recurringReminders?.refresh() }
        .onChange(of: appConfiguration.dailyExpenseReminderEnabled) { recurringReminders?.refresh() }
        .onChange(of: appConfiguration.dailyExpenseReminderTimeMinutes) { recurringReminders?.refresh() }
        .onChange(of: appConfiguration.hideBillReminderDetails) { recurringReminders?.refresh() }
        .onChange(of: appConfiguration.ledgerCurrencyCode) { recurringReminders?.refresh() }
        .onChange(of: appConfiguration.hasCompletedSetupOnAnotherDevice, initial: true) { _, completed in
            if !UITestConfiguration.isEnabled,
               !hasOpenedAppOnce,
               completed {
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
            description: Text("Syl could not access its shared storage. Check available device storage, then close and reopen the app. \(error.localizedDescription)")
        )
    }
}

struct MainAppPackage: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [SageKitPackage.self]
    }
}


#Playground {

}
