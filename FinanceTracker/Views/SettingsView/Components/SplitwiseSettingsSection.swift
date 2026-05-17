//
//  SplitwiseSettingsSection.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/16/26.
//
import SwiftUI

struct SplitwiseSettingsSection: View {
    @Environment(SplitwiseService.self) private var splitwise
    @State private var showConnectSheet = false

    var body: some View {
        if splitwise.isConfigured {
            ConnectedView(splitwise: splitwise)
        } else {
            Button {
                showConnectSheet = true
            } label: {
                HStack {
                    Image(systemName: "link")
                    Text("Connect to Splitwise")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.ui.sage)
                .foregroundStyle(.white)
                .cornerRadius(15)
            }
            .sheet(isPresented: $showConnectSheet) {
                SplitwiseConnectSheet()
            }
        }
    }
}

// MARK: - Connected state

private struct ConnectedView: View {
    let splitwise: SplitwiseService

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Connected")
                        .font(.headline)
                    if let name = splitwise.connectedUserName {
                        Text(name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.ui.cardBackground)
            .cornerRadius(15)

            Button(role: .destructive) {
                splitwise.disconnect()
            } label: {
                Text("Disconnect")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ui.cardBackground)
                    .foregroundStyle(.red)
                    .cornerRadius(15)
            }
        }
    }
}

// MARK: - Connect sheet

private struct SplitwiseConnectSheet: View {
    @Environment(SplitwiseService.self) private var splitwise
    @Environment(\.dismiss) private var dismiss

    @State private var apiKeyInput = ""
    @State private var isConnecting = false
    @State private var errorMessage: String?

    var body: some View {
        @Bindable var splitwise = splitwise

        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.ui.sage)

                    Text("Connect Splitwise")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Paste your Splitwise API key below to import shared expenses into Sage.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .padding(.top, 12)

                VStack(alignment: .leading, spacing: 8) {
                    TextField("API Key", text: $apiKeyInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color.ui.cardBackground)
                        .cornerRadius(12)

                    Link("Get your API key at secure.splitwise.com/apps →",
                         destination: URL(string: "https://secure.splitwise.com/apps")!)
                        .font(.caption)
                        .padding(.horizontal, 4)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
            }
            .padding()
            .background(Color.ui.background)
            .navigationTitle("Connect Splitwise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isConnecting {
                        ProgressView()
                    } else {
                        Button("Connect") {
                            Task { await connect() }
                        }
                        .fontWeight(.semibold)
                        .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }

    private func connect() async {
        isConnecting = true
        errorMessage = nil
        splitwise.apiKey = apiKeyInput.trimmingCharacters(in: .whitespaces)
        do {
            try await splitwise.fetchCurrentUser()
            dismiss()
        } catch {
            splitwise.disconnect()
            errorMessage = error.localizedDescription
        }
        isConnecting = false
    }
}
