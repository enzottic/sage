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
    @State private var splitwiseService = SplitwiseService()
    @AppStorage("hasOpenedAppOnce") var hasOpenedAppOnce: Bool = false
    
    init() {
        UIColorValueTransformer.register()
        configureNavigationBarAppearance()

        // Pull latest iCloud KVS values before checking setup state
        NSUbiquitousKeyValueStore.default.synchronize()

        // Present notifications that fire while the app is foreground
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared

        // Make ExpenseStore resolvable via @Dependency in App Intents.
        let expenseStore = ExpenseStore.shared
        AppDependencyManager.shared.add(dependency: expenseStore)

        // Register App Shortcuts phrases with Siri
        SageShortcutsProvider.updateAppShortcutParameters()

        // If onboarding was completed on another device, skip it here
        if !UserDefaults.standard.bool(forKey: "hasOpenedAppOnce"),
           AppConfiguration.hasCompletedSetupOnAnotherDevice {
            UserDefaults.standard.set(true, forKey: "hasOpenedAppOnce")
            // Still a fresh install here — skip What's New, the same as after onboarding.
            WhatsNewStore.markCurrentVersionSeen()
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
            .onReceive(NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification).receive(on: DispatchQueue.main)) { _ in
                // KVS values may arrive after launch — check if onboarding was completed on another device
                if !hasOpenedAppOnce, AppConfiguration.hasCompletedSetupOnAnotherDevice {
                    WhatsNewStore.markCurrentVersionSeen()
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
}

struct MainAppPackage: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [SageKitPackage.self]
    }
}
