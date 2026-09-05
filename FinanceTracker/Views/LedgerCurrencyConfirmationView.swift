import SwiftUI
import SageKit

struct LedgerCurrencyConfirmationView: View {
    @Environment(AppConfiguration.self) private var config
    @State private var selectedCode = LedgerCurrency.suggestedCode()
    @State private var errorMessage: String?
    @State private var didLoadSuggestion = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Choose the currency used by your expenses and budgets.")
                    Text("If you already have data in Sage, choose the currency those amounts were entered in. Older data does not record a currency. No amounts will be converted.")
                        .foregroundStyle(.secondary)
                }

                Section {
                    Picker("Ledger Currency", selection: $selectedCode) {
                        ForEach(LedgerCurrency.supportedCodes, id: \.self) { code in
                            Text("\(code) - \(Locale.current.localizedString(forCurrencyCode: code) ?? code)")
                                .tag(code)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .accessibilityIdentifier("ledger-currency-picker")
                } footer: {
                    Text("This currency stays fixed when your device region changes. All expenses, recurring rules, income, and budgets use it.")
                }

                if let cloudCode = config.cloudLedgerCurrencyCode {
                    Section {
                        Text("iCloud reports \(cloudCode). Confirm that this matches your existing amounts. Sage cannot combine ledgers with different currencies.")
                            .foregroundStyle(.secondary)
                        if selectedCode != cloudCode {
                            Text("Select \(cloudCode) only if that is the currency your amounts were entered in. If it is not, stop and contact support before continuing.")
                            if let supportURL = URL(string: "mailto:hi@enzottic.me") {
                                Link("Contact Sage Support", destination: supportURL)
                            }
                        }
                    }
                }

                Section {
                    Button("Use \(selectedCode)") {
                        do {
                            try config.establishLedgerCurrency(selectedCode)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                    .accessibilityIdentifier("confirm-ledger-currency-button")
                    .disabled(config.cloudLedgerCurrencyCode.map { $0 != selectedCode } ?? false)
                } footer: {
                    Text("You cannot change this currency without deleting all data in Sage. No currency conversion is performed.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Confirm Currency")
            .tint(.sage)
            .onAppear {
                guard !didLoadSuggestion else { return }
                didLoadSuggestion = true
                selectedCode = config.cloudLedgerCurrencyCode ?? LedgerCurrency.suggestedCode()
            }
        }
    }
}

struct LedgerCurrencyConflictView: View {
    @Environment(AppConfiguration.self) private var config
    let message: String

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Currencies Do Not Match", systemImage: "exclamationmark.triangle")
                        .font(.headline)
                    Text(message)
                }
                Section {
                    Text("Check the ledger currency in Sage on your other devices. Connect to the internet using the same iCloud account, then check again. If the currencies still disagree, contact Sage support before changing or deleting any data.")
                    Button("Check iCloud Again") {
                        config.recheckLedgerCurrency()
                    }
                    if let supportURL = URL(string: "mailto:hi@enzottic.me") {
                        Link("Contact Sage Support", destination: supportURL)
                    }
                } footer: {
                    Text("Checking iCloud does not repair existing data. If amounts were entered in different currencies, Sage cannot determine their original currencies or convert them automatically.")
                }
            }
            .navigationTitle("Currency Conflict")
            .tint(.sage)
        }
    }
}
