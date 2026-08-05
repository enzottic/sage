//
//  Number+CurrencyString.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/1/25.
//
import Foundation

public extension Double {
    /// The app-wide currency format. Uses the currency's own fraction digits
    /// (cents for USD/EUR, none for JPY), so amounts read the same on every screen.
    var currencyString: String {
        return self.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    /// Whole-currency-unit format, for axis scales and other places showing a
    /// range rather than an amount. Prefer `currencyString` for anything the
    /// user reads as a real figure.
    var currencyStringRounded: String {
        return self.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD").precision(.fractionLength(0)))
    }
}

public extension Int {
    var currencyString: String {
        return self.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD").precision(.fractionLength(0)))
    }
}
