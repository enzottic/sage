//
//  SageModelContainer.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/21/26.
//

import Foundation
import SwiftData

public enum SageModelContainer {
    public nonisolated static let appGroupIdentifier = "group.me.enzottic.SageAppGroup"

    public static nonisolated func make(cloudKitEnabled: Bool = false) throws -> ModelContainer {
        UIColorValueTransformer.register()

        let schema = Schema(versionedSchema: SageSchemaV4.self)
        let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)!

        #if DEBUG
        let config = ModelConfiguration(
            "SageDev",
            schema: schema,
            url: groupURL.appending(path: "SageDev.sqlite"),
            cloudKitDatabase: .none
        )
        #else
        let config = ModelConfiguration(
            schema: schema,
            url: groupURL.appending(path: "Sage.sqlite"),
            cloudKitDatabase: cloudKitEnabled ? .automatic : .none
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
