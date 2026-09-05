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
}
