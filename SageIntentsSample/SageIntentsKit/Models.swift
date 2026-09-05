import AppIntents
import Foundation
import SwiftData

public enum ExpenseCategory: String, CaseIterable, Codable, AppEnum {
    case needs = "Needs"
    case wants = "Wants"
    case savings = "Savings"

    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Expense Category"
    public static var caseDisplayRepresentations: [ExpenseCategory: DisplayRepresentation] = [
        .needs: "Needs",
        .wants: "Wants",
        .savings: "Savings",
    ]
}

@Model
public final class Expense {
    public var id: UUID
    public var name: String
    public var amount: Double
    public var category: ExpenseCategory
    public var date: Date

    @Relationship(deleteRule: .nullify, inverse: \ExpenseTag.expenses)
    public var tags: [ExpenseTag]?

    public init(
        name: String,
        amount: Double,
        category: ExpenseCategory = .wants,
        date: Date = .now,
        tags: [ExpenseTag] = []
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.category = category
        self.date = date
        self.tags = tags
    }
}

@Model
public final class ExpenseTag {
    public var id: UUID
    public var name: String
    public var emoji: String
    public var symbolName: String?

    @Relationship
    public var expenses: [Expense]?

    public init(name: String, emoji: String, symbolName: String? = nil) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.symbolName = symbolName
    }
}

extension Collection where Element == Expense {
    var total: Double { reduce(0) { $0 + $1.amount } }
}

extension Double {
    var currencyString: String {
        formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}

