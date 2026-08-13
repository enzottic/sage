//
//  ExpenseCSVCodecTests.swift
//  FinanceTrackerUITests
//

import XCTest
import SageKit

final class ExpenseCSVCodecTests: XCTestCase {
    func testExportThenImportPreservesSpecialCharactersAndEmptyFields() throws {
        let date = Date(timeIntervalSince1970: 1_723_500_000.125)
        let source = ExportableExpense(
            name: "Coffee, \"large\"",
            date: date,
            amount: 12.34,
            category: ExpenseCategory.wants.rawValue,
            tag: "",
            note: "First line\nSecond \"quoted\" line"
        )

        let decoded = try ExpenseCSVCodec.decode(ExpenseCSVCodec.encode([source]))

        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].name, source.name)
        XCTAssertEqual(decoded[0].date.timeIntervalSince1970, source.date.timeIntervalSince1970, accuracy: 0.000_001)
        XCTAssertEqual(decoded[0].amount, source.amount)
        XCTAssertEqual(decoded[0].category, source.category)
        XCTAssertEqual(decoded[0].tag, source.tag)
        XCTAssertEqual(decoded[0].note, source.note)
    }

    func testDecodeSupportsEscapedQuotesAndEmbeddedLineBreaks() throws {
        let csv = """
        name,date,amount,category,tag,note
        "Dinner, with friends",2026-08-12T18:30:00Z,42.5,Wants,Dining,"She said ""hello"".
        Then we left."
        """

        let decoded = try ExpenseCSVCodec.decode(csv)

        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].name, "Dinner, with friends")
        XCTAssertEqual(decoded[0].note, "She said \"hello\".\nThen we left.")
    }

    func testDecodeKeepsEmptyFields() throws {
        let csv = "name,date,amount,category,tag,note\n,2026-08-12T18:30:00Z,0,Needs,,"

        let decoded = try ExpenseCSVCodec.decode(csv)

        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].name, "")
        XCTAssertEqual(decoded[0].tag, "")
        XCTAssertEqual(decoded[0].note, "")
    }

    func testDecodeRejectsInvalidHeader() {
        let csv = "title,date,amount,category,tag,note"

        XCTAssertThrowsError(try ExpenseCSVCodec.decode(csv)) { error in
            XCTAssertEqual(
                error as? ExpenseCSVError,
                .invalidHeader(
                    expected: ExpenseCSVCodec.header,
                    actual: ["title", "date", "amount", "category", "tag", "note"]
                )
            )
        }
    }

    func testDecodeReportsInvalidColumnCount() {
        let csv = "name,date,amount,category,tag,note\nCoffee,2026-08-12T18:30:00Z,4.5,Wants,Food"

        XCTAssertThrowsError(try ExpenseCSVCodec.decode(csv)) { error in
            XCTAssertEqual(error as? ExpenseCSVError, .invalidColumnCount(row: 2, expected: 6, actual: 5))
        }
    }

    func testDecodeReportsInvalidDate() {
        let csv = "name,date,amount,category,tag,note\nCoffee,not-a-date,4.5,Wants,Food,"

        XCTAssertThrowsError(try ExpenseCSVCodec.decode(csv)) { error in
            XCTAssertEqual(error as? ExpenseCSVError, .invalidDate(row: 2, value: "not-a-date"))
        }
    }

    func testDecodeReportsInvalidAmountWithoutReturningPartialData() {
        let csv = """
        name,date,amount,category,tag,note
        Coffee,2026-08-12T18:30:00Z,4.5,Wants,Food,
        Rent,2026-08-01T12:00:00Z,not-a-number,Needs,Housing,
        """

        XCTAssertThrowsError(try ExpenseCSVCodec.decode(csv)) { error in
            XCTAssertEqual(error as? ExpenseCSVError, .invalidAmount(row: 3, value: "not-a-number"))
        }
    }

    func testDecodeReportsThePhysicalRowAfterEmbeddedLineBreaks() {
        let csv = """
        name,date,amount,category,tag,note
        Coffee,2026-08-12T18:30:00Z,4.5,Wants,Food,"Line one
        Line two"
        Rent,2026-08-01T12:00:00Z,bad,Needs,Housing,
        """

        XCTAssertThrowsError(try ExpenseCSVCodec.decode(csv)) { error in
            XCTAssertEqual(error as? ExpenseCSVError, .invalidAmount(row: 4, value: "bad"))
        }
    }

    func testDecodeRejectsAnUnclosedQuotedField() {
        let csv = "name,date,amount,category,tag,note\nCoffee,2026-08-12T18:30:00Z,4.5,Wants,Food,\"not closed"

        XCTAssertThrowsError(try ExpenseCSVCodec.decode(csv)) { error in
            XCTAssertEqual(
                error as? ExpenseCSVError,
                .malformedCSV(row: 2, reason: "quoted field is not closed.")
            )
        }
    }
}
