//
//  CentsFirstCurrencyField.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/21/25.
//

import SwiftUI

struct CentsFirstCurrencyField: View {
    @Binding var amount: Double?
    var autoFocus: Bool = false
    @State private var centsValue: String = "0"
    @FocusState private var isFocused: Bool

    private var displayValue: String {
        let cents = Int(centsValue) ?? 0
        let dollars = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }

    private var isEmptyState: Bool {
        (Int(centsValue) ?? 0) == 0
    }

    // Attributed string splitting the integer and decimal parts at different sizes.
    private var emptyAttributedDisplay: AttributedString {
        let full = displayValue
        let separator = Locale.current.decimalSeparator ?? "."
        if let range = full.range(of: separator) {
            var main = AttributedString(String(full[..<range.lowerBound]))
            main.font = .system(size: 52, weight: .bold)
            main.foregroundColor = isFocused ? .primary : .secondary

            var cents = AttributedString(String(full[range.lowerBound...]))
            cents.font = .system(size: 34, weight: .bold)
            cents.foregroundColor = isFocused ? Color.secondary : Color.secondary.opacity(0.5)

            return main + cents
        }
        var fallback = AttributedString(full)
        fallback.font = .system(size: 52, weight: .bold)
        fallback.foregroundColor = isFocused ? .primary : .secondary
        return fallback
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Hidden text field for keyboard input
            TextField("", text: $centsValue)
                .keyboardType(.numberPad)
                .opacity(0)
                .frame(width: 0, height: 0)
                .focused($isFocused)
                .onChange(of: centsValue) { oldValue, newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered.isEmpty {
                        centsValue = "0"
                        amount = nil
                    } else if filtered.count > 10 {
                        centsValue = String(filtered.prefix(10))
                    } else {
                        centsValue = filtered
                    }
                    if let cents = Int(centsValue), cents > 0 {
                        amount = Double(cents) / 100.0
                    } else {
                        amount = nil
                    }
                }
                .accessibilityIdentifier("Expense Amount Field")

            if isEmptyState {
                Text(emptyAttributedDisplay)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture { isFocused = true }
            } else {
                Text(displayValue)
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(isFocused ? Color.primary : Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture { isFocused = true }
            }
        }
        .onAppear {
            if let amount = amount {
                let cents = Int(amount * 100)
                centsValue = String(cents)
            }
            if autoFocus {
                Task {
                    try? await Task.sleep(for: .seconds(0.6))
                    isFocused = true
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var amount: Double? = nil

    VStack(spacing: 30) {
        CentsFirstCurrencyField(amount: $amount)

        Text("Current amount: \(amount?.description ?? "nil")")
            .foregroundStyle(.secondary)

        Button("Clear") {
            amount = nil
        }
    }
    .padding()
}
