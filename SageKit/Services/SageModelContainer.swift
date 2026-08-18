//
//  SageModelContainer.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/21/26.
//

import Foundation
import OSLog
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
    private nonisolated static let logger = Logger(subsystem: "me.enzottic.SageKit", category: "ModelContainer")

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

        let schema = Schema(versionedSchema: SageSchemaV4.self)
        let config = try configuration(for: purpose, schema: schema)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: SageSchemaMigrationPlan.self,
            configurations: [config]
        )

        if case .app = purpose {
            backfillMultiTags(container)
        }

        #if DEBUG
        if case .test = purpose {
            return container
        }
        
        if case .previewEmpty = purpose {
            return container
        }

        let seedContext = ModelContext(container)
        MockDataSeeder.seed(into: seedContext)
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
        migrateStoreToAppGroupIfNeeded(destination: storeURL)
        return ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: isCloudKitEnabled ? .automatic : .none
        )
        #endif
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

    // Migrates legacy single-tag data into the V3 `tags` array.
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
            logger.error("Multi-tag backfill failed: \(error.localizedDescription, privacy: .private(mask: .hash))")
        }
    }
}
