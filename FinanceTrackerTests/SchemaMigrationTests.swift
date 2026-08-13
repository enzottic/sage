import SwiftData
import Testing
import UIKit
@testable import SageKit

@Suite("Schema migration", .serialized)
struct SchemaMigrationTests {
    @Test @MainActor
    func v1StoreMigratesToCurrentSchema() throws {
        UIColorValueTransformer.register()
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "SageMigration-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appending(path: "Migration.sqlite")

        try createV1Store(at: storeURL)

        let schema = Schema(versionedSchema: SageSchemaV4.self)
        let configuration = ModelConfiguration(
            "Migration",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: schema,
            migrationPlan: SageSchemaMigrationPlan.self,
            configurations: [configuration]
        )
        let expenses = try container.mainContext.fetch(FetchDescriptor<Expense>())

        #expect(expenses.count == 1)
        let expense = try #require(expenses.first)
        #expect(expense.name == "Legacy Rent")
        #expect(expense.amount == 900)
        #expect(expense.category == .needs)
        #expect(expense.note == "V1 record")
        #expect(expense.account == nil)
    }

    private func createV1Store(at url: URL) throws {
        let schema = Schema(versionedSchema: SageSchemaV1.self)
        let configuration = ModelConfiguration(
            "Migration",
            schema: schema,
            url: url,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        context.insert(
            SageSchemaV1.Expense(
                name: "Legacy Rent",
                amount: 900,
                category: .needs,
                note: "V1 record"
            )
        )
        try context.save()
    }
}
