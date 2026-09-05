import AppIntents
import SageIntentsKit
import SwiftData
import SwiftUI

@main
struct SageIntentsSampleApp: App {
    private let container: ModelContainer

    @MainActor
    init() {
        do {
            let container = try SampleModelContainer.make()
            self.container = container

            let store = ExpenseStore(modelContainer: container)
            AppDependencyManager.shared.add(dependency: store)
            try store.seedIfNeeded()

            // This is the same explicit registration call made by Sage.
            SageShortcutsProvider.updateAppShortcutParameters()
        } catch {
            fatalError("Unable to create the sample data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

// The production app uses this package to expose intents compiled into SageKit.
struct MainAppPackage: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [SageIntentsKitPackage.self]
    }
}

