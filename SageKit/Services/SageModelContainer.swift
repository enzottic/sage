//
//  SageModelContainer.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/21/26.
//

import Foundation
import SwiftData

public enum SageModelContainer {
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

    /// The CloudKit setting used by every process that opens the shared store.
    ///
    /// The user-facing preference is copied to this value when the main app launches. Keeping
    /// the active value stable until the next launch prevents a widget or App Intent from opening
    /// the store with a different configuration while the app is still running.
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

    public static nonisolated func makeInMemory() throws -> ModelContainer {
        UIColorValueTransformer.register()

        let schema = Schema(versionedSchema: SageSchemaV4.self)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: SageSchemaMigrationPlan.self,
            configurations: [config]
        )
    }

    /// The shared store result. Callers handle a failed store open instead of terminating.
    @MainActor
    public static let shared: Result<ModelContainer, any Swift.Error> = Result(catching: make)

    private static nonisolated func make() throws -> ModelContainer {
        UIColorValueTransformer.register()

        let schema = Schema(versionedSchema: SageSchemaV4.self)
        guard let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            throw Error.appGroupUnavailable
        }

        #if DEBUG
        let config = ModelConfiguration(
            "SageDev",
            schema: schema,
            url: groupURL.appending(path: "SageDev.sqlite"),
            cloudKitDatabase: .none
        )
        #else
        let storeURL = groupURL.appending(path: "Sage.sqlite")
        migrateStoreToAppGroupIfNeeded(destination: storeURL)
        let config = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: isCloudKitEnabled ? .automatic : .none
        )
        #endif

        let container = try ModelContainer(for: schema, migrationPlan: SageSchemaMigrationPlan.self, configurations: [config])

        backfillMultiTags(container)

        #if DEBUG
        let seedContext = ModelContext(container)
        MockDataSeeder.seed(into: seedContext)
        try seedContext.save()
        #endif

        return container
    }

    private static nonisolated func migrateStoreToAppGroupIfNeeded(destination: URL) {
        let defaults = UserDefaults(suiteName: appGroupIdentifier)
        let migrationKey = "hasCompletedStoreMigration"
        guard !(defaults?.bool(forKey: migrationKey) ?? false) else { return }
        defer { defaults?.set(true, forKey: migrationKey) }

        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: destination.path), !isCloudKitEnabled else { return }

        let candidates = [
            URL.applicationSupportDirectory.appending(path: "default.store"),
            URL.applicationSupportDirectory.appending(path: "Sage.store"),
            URL.applicationSupportDirectory.appending(path: "FinanceTracker.store"),
        ]

        guard let source = candidates.first(where: { fileManager.fileExists(atPath: $0.path) }) else {
            return
        }

        for suffix in ["", "-wal", "-shm"] {
            let sourceFile = URL(fileURLWithPath: source.path + suffix)
            guard fileManager.fileExists(atPath: sourceFile.path) else { continue }
            let destinationFile = URL(fileURLWithPath: destination.path + suffix)
            try? fileManager.copyItem(at: sourceFile, to: destinationFile)
        }
    }

    /// Migrates legacy single-tag data into the V3 `tags` array.
    ///
    /// The V2→V3 schema change is lightweight/additive (CloudKit-safe), so the actual data copy
    /// happens here in code: every expense/rule that still has a legacy `tag` but an empty `tags`
    /// gets `tags = [tag]`.
    ///
    /// This runs on every launch rather than being gated by a one-shot flag. The per-record
    /// emptiness check makes it idempotent, and a `save()` only happens when something actually
    /// changed, so a fully-migrated store adds just one cheap fetch at startup. Running every
    /// launch is important for CloudKit: legacy records may sync down *after* the first V3 launch,
    /// and a one-shot flag would leave those permanently untagged.
    private static nonisolated func backfillMultiTags(_ container: ModelContainer) {
        let context = ModelContext(container)
        do {
            let expenses = try context.fetch(FetchDescriptor<Expense>())
            for expense in expenses where (expense.tags ?? []).isEmpty {
                if let legacyTag = expense.tag {
                    expense.tags = [legacyTag]
                }
            }

            let rules = try context.fetch(FetchDescriptor<RecurringExpenseRule>())
            for rule in rules where (rule.tags ?? []).isEmpty {
                if let legacyTag = rule.tag {
                    rule.tags = [legacyTag]
                }
            }

            if context.hasChanges {
                try context.save()
            }
        } catch {
            print("Multi-tag backfill failed: \(error)")
        }
    }
}
