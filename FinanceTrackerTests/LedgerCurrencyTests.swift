import Foundation
import Testing
@testable import SageKit

@Suite("Persistent ledger currency")
struct LedgerCurrencyTests {
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
