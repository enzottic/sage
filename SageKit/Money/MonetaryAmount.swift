import Foundation

/// Validation for monetary writes, not a migration or normalization of saved amounts.
public enum MonetaryAmount {
    public static let maximumMagnitude: Double = 1_000_000_000

    public static func validationMessage(currencyCode: String, requiresPositive: Bool = false) -> String {
        return "Please enter a valid amount"
    }

    /// Expenses may be negative (refunds); budgets and recurrences require positive amounts.
    /// Trailing decimal zeroes are harmless, but nonzero sub-minor-unit digits are rejected.
    public static func isValid(
        _ amount: Double,
        currencyCode: String,
        requiresPositive: Bool = false
    ) -> Bool {
        guard amount.isFinite,
              amount != 0,
              !requiresPositive || amount > 0,
              abs(amount) <= maximumMagnitude,
              LedgerCurrency.validatedCode(currencyCode) != nil else { return false }

        let locale = Locale(identifier: "en_US_POSIX")
        guard var decimal = Decimal(string: String(amount), locale: locale),
              !decimal.isNaN else { return false }
        var rounded = Decimal.zero
        NSDecimalRound(&rounded, &decimal, LedgerCurrency.fractionDigits(for: currencyCode), .plain)
        guard rounded != .zero else { return false }

        // Compare in Decimal; the tolerance covers binary arithmetic such as 0.1 + 0.2,
        // not a fraction of the currency's minor unit. The magnitude cap keeps two ULPs
        // below 0.00000024 even at the limit. Never return a rounded amount.
        let tolerance = Decimal(string: String(amount.ulp * 2), locale: locale) ?? .zero
        return abs(decimal - rounded) <= tolerance
    }
}
