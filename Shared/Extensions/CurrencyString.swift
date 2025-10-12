//
//  CurrencyString.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/1/25.
//
import Foundation

extension Double {
    var currencyString: String {
        return self.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD").precision(.fractionLength(0)))
    }
}

extension Int {
    var currencyString: String {
        return self.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD").precision(.fractionLength(0)))
    }
}
