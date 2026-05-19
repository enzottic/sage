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
        List {
            if splitwise.isConnected {
                ConnectedView(splitwise: splitwise)
            } else {
                DisconnectedView(splitwise: splitwise)
            }
        }
        .navigationTitle("Splitwise")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Connected

private struct ConnectedView: View {
    let splitwise: SplitwiseService

    var body: some View {
        Section {
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
        } header: {
            Text("Connect to Splitwise")
        }
            
        Section {
            Button(role: .destructive) {
                splitwise.disconnect()
            } label: {
                Text("Disconnect")
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
        Section {
            Button {
                Task { await connect() }
            } label: {
                Group {
                    if isConnecting {
                        ProgressView().tint(.white)
                    } else {
                        HStack {
                            Image(systemName: "link")
                            Text("Connect")
                        }
                    }
                }
            }
        } header: {
            Text("Connect to Splitwise")
        } footer: {
            Text("Connect your Splitwise account with Sage to import any shared expenses. You can also export expenses from Sage to a Splitwise group.")
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

#Preview {
    SplitwiseSettingsSection()
        .environment(SplitwiseService())
}
