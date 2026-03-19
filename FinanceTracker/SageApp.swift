//
//  SageApp.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import SwiftUI
import SwiftData

@main
struct SageApp: App {
    @State private var appConfiguration = AppConfiguration()
    
    @AppStorage("hasOpenedAppOnce") var hasOpenedAppOnce: Bool = false
    @Query var expenses: [Expense]
    
    init() {
        UIColorValueTransformer.register()
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
        }
        .environment(appConfiguration)
        .modelContainer(appContainer)
    }
}
