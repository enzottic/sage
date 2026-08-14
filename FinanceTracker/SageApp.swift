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
    
    init() {
        UIColorValueTransformer.register()
        configureNavigationBarAppearance()

        if UITestConfiguration.isEnabled {
            hasOpenedAppOnce = !UITestConfiguration.showsOnboarding
            WhatsNewStore.markCurrentVersionSeen()
        }

        // Pull latest iCloud KVS values before checking setup state
        NSUbiquitousKeyValueStore.default.synchronize()

        // Keep the store configuration stable across the app, widgets, and App Intents until
        // the next app launch.
        SageModelContainer.activateCloudKitPreference()

        // Present notifications that fire while the app is foreground
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared

        // Make ExpenseStore resolvable via @Dependency in App Intents.
        if UITestConfiguration.isEnabled,
           case let .success(container) = appContainerResult {
            AppDependencyManager.shared.add(dependency: ExpenseStore(modelContainer: container))
        } else if let expenseStore = ExpenseStore.shared {
            AppDependencyManager.shared.add(dependency: expenseStore)
        }

        // Register App Shortcuts phrases with Siri
        SageShortcutsProvider.updateAppShortcutParameters()

        // If onboarding was completed on another device, skip it here
        if !UITestConfiguration.isEnabled,
           !UserDefaults.standard.bool(forKey: "hasOpenedAppOnce"),
           AppConfiguration.hasCompletedSetupOnAnotherDevice {
            UserDefaults.standard.set(true, forKey: "hasOpenedAppOnce")
            // Still a fresh install here — skip What's New, the same as after onboarding.
            WhatsNewStore.markCurrentVersionSeen()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            switch appContainerResult {
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
            // UI tests control their initial screen through launch environment.
            // Do not let persisted onboarding state from an earlier test change it.
            if UITestConfiguration.isEnabled, !UITestConfiguration.showsOnboarding {
                RootTabView()
            } else if !hasOpenedAppOnce {
                WelcomeView()
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
    
    private func configureNavigationBarAppearance() {
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
