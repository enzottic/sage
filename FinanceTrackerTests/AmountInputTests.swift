import Foundation
import Testing
@testable import SageKit

struct AmountInputTests {
    @Test(arguments: ["en_US", "de_DE", "fr_FR", "ar_EG"])
    func unchangedAmountRoundTrips(localeIdentifier: String) {
        let locale = Locale(identifier: localeIdentifier)
        for amount in [12.34, 100, 12.345] {
            let text = AmountInput.text(for: amount, locale: locale)
            #expect(AmountInput.parse(text, locale: locale) == amount)
        }
    }

    @Test
    func parsesLocalizedDecimalsAndRejectsInvalidInput() {
        let german = Locale(identifier: "de_DE")
        #expect(AmountInput.parse("1.234,56", locale: german) == 1234.56)
        for text in ["", " ", "NaN", "inf", "1e309", "12,34,56", "EUR 12"] {
            #expect(AmountInput.parse(text, locale: german) == nil)
        }
    }

    @Test
    func monetaryParsingRejectsInvalidTextInsteadOfKeepingPreviousAmount() {
        let locale = Locale(identifier: "en_US")
        var amount: Double? = 12.34
        for text in ["", "-", "12..34", "0", "0.004", "1000000001", "NaN", "inf"] {
            amount = AmountInput.parse(text, currencyCode: "USD", locale: locale)
            #expect(amount == nil)
        }
        amount = AmountInput.parse("-12.34", currencyCode: "USD", locale: locale)
        #expect(amount == -12.34)
    }

    @Test(arguments: [("USD", "12.34"), ("JPY", "123"), ("KWD", "12.345")])
    func monetaryParsingUsesCurrencyPrecision(currencyCode: String, text: String) {
        let locale = Locale(identifier: "en_US")
        #expect(AmountInput.parse(text, currencyCode: currencyCode, locale: locale) != nil)
        let tooPrecise = currencyCode == "JPY" ? text + ".1" : text + "1"
        #expect(AmountInput.parse(tooPrecise, currencyCode: currencyCode, locale: locale) == nil)
        #expect(AmountInput.parse("-" + text, currencyCode: currencyCode, requiresPositive: true, locale: locale) == nil)
    }

    @Test
    func monetaryParsingPreservesLocalizedRefundsAndTrailingZeroes() {
        let locale = Locale(identifier: "de_DE")
        #expect(AmountInput.parse("-1.234,560", currencyCode: "USD", locale: locale) == -1234.56)
        #expect(AmountInput.parse("1.234,567", currencyCode: "USD", locale: locale) == nil)
        #expect(AmountInput.parse("1.234,567", currencyCode: "KWD", requiresPositive: true, locale: locale) == 1234.567)
    }
}
