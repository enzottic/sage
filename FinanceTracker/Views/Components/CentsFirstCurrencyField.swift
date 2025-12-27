//
//  CentsFirstCurrencyField.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/21/25.
//

import SwiftUI

struct CentsFirstCurrencyField: View {
    @Binding var amount: Double?
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

    var body: some View {
        ZStack {
            // Hidden text field for keyboard input
            TextField("", text: $centsValue)
                .keyboardType(.numberPad)
                .opacity(0)
                .frame(width: 0, height: 0)
                .focused($isFocused)
                .onChange(of: centsValue) { oldValue, newValue in
                    // Remove any non-digit characters
                    let filtered = newValue.filter { $0.isNumber }

                    // Prevent leading zeros and limit to reasonable amount
                    if filtered.isEmpty {
                        centsValue = "0"
                        amount = nil
                    } else if filtered.count > 10 { // Max $99,999,999.99
                        centsValue = String(filtered.prefix(10))
                    } else {
                        centsValue = filtered
                    }

                    // Update the binding
                    if let cents = Int(centsValue), cents > 0 {
                        amount = Double(cents) / 100.0
                    } else {
                        amount = nil
                    }
                }
                .accessibilityIdentifier("Expense Amount Field")

            // Display text
            Text(displayValue)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(isFocused ? .primary : .secondary)
                .onTapGesture {
                    isFocused = true
                }
        }
        .onAppear {
            // Initialize from existing amount
            if let amount = amount {
                let cents = Int(amount * 100)
                centsValue = String(cents)
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
