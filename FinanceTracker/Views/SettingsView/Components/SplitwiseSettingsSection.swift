//
//  SplitwiseSettingsSection.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/16/26.
//
import SwiftUI
import AuthenticationServices

struct SplitwiseSettingsSection: View {
    @Environment(SplitwiseService.self) private var splitwise

    var body: some View {
        if splitwise.isConnected {
            ConnectedView(splitwise: splitwise)
        } else {
            DisconnectedView(splitwise: splitwise)
        }
    }
}

// MARK: - Connected

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

// MARK: - Disconnected

private struct DisconnectedView: View {
    let splitwise: SplitwiseService

    @State private var isConnecting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                Task { await connect() }
            } label: {
                Group {
                    if isConnecting {
                        ProgressView().tint(.white)
                    } else {
                        HStack {
                            Image(systemName: "link")
                            Text("Connect to Splitwise")
                                .fontWeight(.medium)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.ui.sage)
                .foregroundStyle(.white)
                .cornerRadius(15)
            }
            .disabled(isConnecting)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 4)
            }
        }
    }

    private func connect() async {
        isConnecting = true
        errorMessage = nil
        do {
            try await splitwise.connect()
        } catch {
            // Swallow the cancellation — user just closed the browser
            let asError = error as? ASWebAuthenticationSessionError
            if asError?.code != .canceledLogin {
                errorMessage = error.localizedDescription
            }
        }
        isConnecting = false
    }
}
