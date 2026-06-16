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

        let schema = Schema(versionedSchema: SageSchemaV2.self)
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

        #if DEBUG
        let seedContext = ModelContext(container)
        MockDataSeeder.seed(into: seedContext)
        try seedContext.save()
        #endif

        return container
    }
}
