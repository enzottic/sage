//
//  SageModelContainer.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/21/26.
//

import Foundation
import SwiftData

public enum SageModelContainer {
    public enum Purpose: Sendable {
        case app
        case test
        case preview
        case previewEmpty
    }

    public enum Error: LocalizedError, Equatable {
        case appGroupUnavailable

        public var errorDescription: String? {
            switch self {
            case .appGroupUnavailable:
                return "The shared app storage is unavailable."
            }
        }
    }

    public nonisolated static let appGroupIdentifier = "group.me.enzottic.SageAppGroup"
    public nonisolated static let cloudKitPreferenceKey = "isCloudSyncEnabled"
    private nonisolated static let activeCloudKitPreferenceKey = "activeCloudSyncEnabled"

    // The CloudKit setting used by every process that opens the shared store.
    public nonisolated static var isCloudKitEnabled: Bool {
        let defaults = UserDefaults(suiteName: appGroupIdentifier)
        if defaults?.object(forKey: activeCloudKitPreferenceKey) != nil {
            return defaults?.bool(forKey: activeCloudKitPreferenceKey) ?? false
        }
        return defaults?.bool(forKey: cloudKitPreferenceKey) ?? false
    }

    public nonisolated static func setCloudKitPreference(_ enabled: Bool) {
        UserDefaults(suiteName: appGroupIdentifier)?.set(enabled, forKey: cloudKitPreferenceKey)
    }

    /// Applies the requested setting before the main app opens the store.
    public nonisolated static func activateCloudKitPreference() {
        let defaults = UserDefaults(suiteName: appGroupIdentifier)
        let requestedValue = defaults?.bool(forKey: cloudKitPreferenceKey) ?? false
        defaults?.set(requestedValue, forKey: activeCloudKitPreferenceKey)
    }

    public static nonisolated func make(for purpose: Purpose = .app) throws -> ModelContainer {
        UIColorValueTransformer.register()

        let schema = Schema(versionedSchema: SageSchemaV6.self)
        let config = try configuration(for: purpose, schema: schema)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: SageSchemaMigrationPlan.self,
            configurations: [config]
        )

        if case .app = purpose {
            try backfillMultiTags(container)
        }

        #if DEBUG
        if case .test = purpose {
            return container
        }
        
        if case .previewEmpty = purpose {
            return container
        }

        let seedContext = ModelContext(container)
        MockDataSeeder.seed(into: seedContext, seedsAppConfiguration: purpose == .app)
        try seedContext.save()
        #endif

        return container
    }

    // The shared store result. Callers handle a failed store open instead of terminating.
    @MainActor
    public static let shared: Result<ModelContainer, any Swift.Error> = Result {
        try make(for: .app)
    }

    @MainActor
    public static let preview: ModelContainer = {
        do {
            return try make(for: .preview)
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()
    
    @MainActor
    public static let previewEmpty: ModelContainer = {
        do {
            return try make(for: .previewEmpty)
        } catch {
            fatalError("Failed to create empty preview container: \(error)")
        }
    }()

    /// Fresh, context-owned rules without invoking the debug app's sample-data seeder.
    @MainActor
    public static func makeRecurringPreview() throws -> ModelContainer {
        let container = try make(for: .previewEmpty)
        let calendar = Calendar.current
        let now = Date.now
        let bills = ExpenseTag.billsAndUtils
        let subscriptions = ExpenseTag.subscriptions
        container.mainContext.insert(bills)
        container.mainContext.insert(subscriptions)

        let rules = [
            RecurringExpenseRule(
                name: "Internet", amount: 55, note: "", category: .needs, tag: bills,
                frequency: .monthly, startDate: calendar.date(byAdding: .day, value: 1, to: now)!
            ),
            RecurringExpenseRule(
                name: "Music", amount: 10.99, note: "", category: .wants, tag: subscriptions,
                frequency: .monthly, startDate: calendar.date(byAdding: .day, value: 3, to: now)!
            ),
            RecurringExpenseRule(
                name: "Meal Delivery", amount: 65, note: "", category: .needs, tag: bills,
                frequency: .weekly, startDate: calendar.date(byAdding: .day, value: 7, to: now)!
            ),
        ]
        rules.forEach { container.mainContext.insert($0) }
        try container.mainContext.save()
        return container
    }

    private static nonisolated func configuration(
        for purpose: Purpose,
        schema: Schema
    ) throws -> ModelConfiguration {
        switch purpose {
        case .test, .preview, .previewEmpty:
            return ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
        case .app:
            return try appConfiguration(schema: schema)
        }
    }

    private static nonisolated func appConfiguration(schema: Schema) throws -> ModelConfiguration {
        guard let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            throw Error.appGroupUnavailable
        }

        #if DEBUG
        return ModelConfiguration(
            "SageDev",
            schema: schema,
            url: groupURL.appending(path: "SageDev.sqlite"),
            cloudKitDatabase: .none
        )
        #else
        let storeURL = groupURL.appending(path: "Sage.sqlite")
        return ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: isCloudKitEnabled ? .automatic : .none
        )
        #endif
    }

    // Migrates legacy single-tag data into the V3 `tags` array.
    static nonisolated func backfillMultiTags(_ container: ModelContainer) throws {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let expenses = try context.fetch(FetchDescriptor<Expense>())
        for expense in expenses {
            if let legacyTag = expense.tag {
                if (expense.tags ?? []).isEmpty {
                    expense.tags = [legacyTag]
                }
                expense.tag = nil
            }
        }

        let rules = try context.fetch(FetchDescriptor<RecurringExpenseRule>())
        for rule in rules {
            if let legacyTag = rule.tag {
                if (rule.tags ?? []).isEmpty {
                    rule.tags = [legacyTag]
                }
                rule.tag = nil
            }
        }

        // Conversion and consumption are one transaction. An explicit modern selection
        // wins; consuming its stale legacy value also prevents later tag resurrection.
        // No global flag: legacy-only records arriving later still need conversion.
        // Older clients can write `tag` again via CloudKit; without a per-record
        // synchronized tombstone we cannot distinguish that from a late legacy record.
        if context.hasChanges {
            try context.save()
        }
    }
}
