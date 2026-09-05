import Foundation
import SwiftData
import Testing
import UIKit
@testable import SageKit

@Suite("Persistent ledger currency")
struct LedgerCurrencyTests {
    @Test
    func failedSetupDoesNotLockCurrency() throws {
        enum SetupError: Error { case failed }
        let suite = "LedgerCurrencyTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        #expect(throws: SetupError.failed) {
            try LedgerCurrency.establish("EUR", defaults: defaults) { throw SetupError.failed }
        }
        #expect(LedgerCurrency.persistedCode(defaults: defaults) == nil)
        try LedgerCurrency.establish("GBP", defaults: defaults)
        #expect(LedgerCurrency.persistedCode(defaults: defaults) == "GBP")
    }

    @Test @MainActor
    func suggestedTagsDoNotRequireLegacyConfirmation() throws {
        let container = try SageModelContainer.make(for: .test)
        let context = container.mainContext
        context.insert(ExpenseTag(name: "Food", uiColor: .blue, emoji: ""))
        #expect(try !LedgerCurrency.hasMonetaryRecords(in: context))
    }

    @Test(arguments: ["expense", "rule", "budget"]) @MainActor
    func existingMoneyRequiresLegacyConfirmation(kind: String) throws {
        let container = try SageModelContainer.make(for: .test)
        let context = container.mainContext
        switch kind {
        case "expense":
            context.insert(Expense(name: "Coffee", amount: 4))
        case "rule":
            context.insert(RecurringExpenseRule(name: "Rent", amount: 100, note: "", category: .needs, frequency: .monthly, startDate: .now))
        default:
            context.insert(ExpenseTag(name: "Food", uiColor: .blue, emoji: "", budget: 100))
        }
        #expect(try LedgerCurrency.hasMonetaryRecords(in: context))
    }

    @Test
    func establishingCurrencyPersistsWithoutUsingLaterLocaleSuggestions() throws {
        let suite = "LedgerCurrencyTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        #expect(LedgerCurrency.persistedCode(defaults: defaults) == nil)
        try LedgerCurrency.establish("EUR", defaults: defaults)
        #expect(LedgerCurrency.suggestedCode(locale: Locale(identifier: "en_US")) == "USD")
        #expect(LedgerCurrency.suggestedCode(locale: Locale(identifier: "ja_JP")) == "JPY")
        let reopenedDefaults = try #require(UserDefaults(suiteName: suite))
        #expect(LedgerCurrency.persistedCode(defaults: reopenedDefaults) == "EUR")
        try LedgerCurrency.establish("EUR", defaults: reopenedDefaults)
        #expect(throws: LedgerCurrency.Error.alreadyEstablished("EUR")) {
            try LedgerCurrency.establish("JPY", defaults: reopenedDefaults)
        }
        #expect(LedgerCurrency.persistedCode(defaults: defaults) == "EUR")
    }

    @Test
    func resetAllowsNewCurrencyOnlyAfterExplicitEstablishment() throws {
        let suite = "LedgerCurrencyTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try LedgerCurrency.establish("USD", defaults: defaults)
        LedgerCurrency.reset(defaults: defaults)
        #expect(LedgerCurrency.persistedCode(defaults: defaults) == nil)
        try LedgerCurrency.establish("EUR", defaults: defaults)
        #expect(LedgerCurrency.persistedCode(defaults: defaults) == "EUR")
    }

    @Test(arguments: ["", "usd", "ZZZ", " USD "])
    func invalidCurrencyIsNeitherReadNorEstablished(code: String) throws {
        let suite = "LedgerCurrencyTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(code, forKey: LedgerCurrency.storageKey)
        #expect(LedgerCurrency.persistedCode(defaults: defaults) == nil)
        #expect(throws: LedgerCurrency.Error.invalidCode(code)) {
            try LedgerCurrency.establish(code, defaults: defaults)
        }
    }

    @Test
    func unavailableSharedStorageDoesNotFallBackToPrivateDefaults() {
        #expect(LedgerCurrency.persistedCode(defaults: nil) == nil)
        #expect(throws: LedgerCurrency.Error.storageUnavailable) {
            try LedgerCurrency.establish("USD", defaults: nil)
        }
    }

    @Test
    func minorUnitsFollowCurrencyRatherThanDeviceRegion() {
        #expect(LedgerCurrency.fractionDigits(for: "USD") == 2)
        #expect(LedgerCurrency.fractionDigits(for: "JPY") == 0)
        #expect(LedgerCurrency.fractionDigits(for: "KWD") == 3)
    }
}
