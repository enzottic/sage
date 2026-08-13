import Foundation
import Testing
@testable import SageKit

@Suite("Expense CSV codec")
struct ExpenseCSVCodecTests {
    @Test
    func exportThenImportPreservesSpecialCharactersAndEmptyFields() throws {
        let source = ExportableExpense(
            name: "Coffee, \"large\"",
            date: Date(timeIntervalSince1970: 1_723_500_000.125),
            amount: 12.34,
            category: ExpenseCategory.wants.rawValue,
            tag: "",
            note: "First line\nSecond \"quoted\" line"
        )

        let decoded = try ExpenseCSVCodec.decode(ExpenseCSVCodec.encode([source]))

        #expect(decoded.count == 1)
        let expense = try #require(decoded.first)
        #expect(expense.name == source.name)
        #expect(abs(expense.date.timeIntervalSince1970 - source.date.timeIntervalSince1970) < 0.000_001)
        #expect(expense.amount == source.amount)
        #expect(expense.category == source.category)
        #expect(expense.tag == source.tag)
        #expect(expense.note == source.note)
    }

    @Test
    func decodeSupportsQuotedFieldsAndEmbeddedLineBreaks() throws {
        let csv = """
        name,date,amount,category,tag,note
        "Dinner, with friends",2026-08-12T18:30:00Z,42.5,Wants,Dining,"She said ""hello"".
        Then we left."
        """

        let decoded = try ExpenseCSVCodec.decode(csv)

        #expect(decoded.count == 1)
        let expense = try #require(decoded.first)
        #expect(expense.name == "Dinner, with friends")
        #expect(expense.note == "She said \"hello\".\nThen we left.")
    }

    @Test
    func decodeRejectsInvalidHeader() {
        #expect(
            throws: ExpenseCSVError.invalidHeader(
                expected: ExpenseCSVCodec.header,
                actual: ["title", "date", "amount", "category", "tag", "note"]
            )
        ) {
            try ExpenseCSVCodec.decode("title,date,amount,category,tag,note")
        }
    }

    @Test
    func decodeReportsInvalidValuesWithoutPartialData() {
        let csv = """
        name,date,amount,category,tag,note
        Coffee,2026-08-12T18:30:00Z,4.5,Wants,Food,
        Rent,2026-08-01T12:00:00Z,not-a-number,Needs,Housing,
        """

        #expect(throws: ExpenseCSVError.invalidAmount(row: 3, value: "not-a-number")) {
            try ExpenseCSVCodec.decode(csv)
        }
    }

    @Test
    func decodeRejectsUnclosedQuotedField() {
        let csv = "name,date,amount,category,tag,note\nCoffee,2026-08-12T18:30:00Z,4.5,Wants,Food,\"not closed"

        #expect(
            throws: ExpenseCSVError.malformedCSV(row: 2, reason: "quoted field is not closed.")
        ) {
            try ExpenseCSVCodec.decode(csv)
        }
    }
}
