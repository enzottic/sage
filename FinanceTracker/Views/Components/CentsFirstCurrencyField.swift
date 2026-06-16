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

    private var isEmptyState: Bool {
        (Int(centsValue) ?? 0) == 0
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Hidden text field for keyboard input.
            // Full-width frame so VoiceOver can find and activate it;
            // allowsHitTesting(false) lets normal taps fall through to the Text views below.
            TextField("", text: $centsValue)
                .keyboardType(.numberPad)
                .opacity(0)
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false)
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
                .accessibilityLabel("Amount")
                .accessibilityValue(displayValue)
                .accessibilityHint("Enter expense amount using number keys")


            Text(displayValue)
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture { isFocused = true }
                .accessibilityHidden(true)

        }
        .onAppear {
            if let amount = amount {
                let cents = Int(amount * 100)
                centsValue = String(cents)
            }
        }
        .onChange(of: amount) { _, newAmount in
            let currentCents = Int(centsValue) ?? 0
            let currentAmount = currentCents > 0 ? Double(currentCents) / 100.0 : nil
            guard currentAmount != newAmount else { return }
            if let newAmount {
                centsValue = String(Int((newAmount * 100).rounded()))
            } else {
                centsValue = "0"
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
