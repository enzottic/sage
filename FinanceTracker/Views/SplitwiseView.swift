//
//  SplitwiseView.swift
//  FinanceTracker
//
//  Created by Claude on 2/22/26.
//

import SwiftUI
import SwiftData
import AuthenticationServices

struct SplitwiseView: View {
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession

    @State private var currentUserId: Int?
    @State private var expenses: [SplitwiseExpense] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedExpense: SplitwiseExpense?

    private let service = SplitwiseService.shared

    var body: some View {
        NavigationStack {
            Group {
                if !service.isAuthenticated {
                    notConnectedView
                } else if isLoading {
                    loadingView
                } else {
                    expenseListView
                }
            }
            .background(Color.ui.background)
            .navigationTitle("Splitwise")
            .toolbar {
                if service.isAuthenticated {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Disconnect") {
                            service.logout()
                            expenses = []
                            currentUserId = nil
                        }
                    }
                }
            }
            .sheet(item: $selectedExpense) { expense in
                ImportExpenseSheet(
                    splitwiseExpense: expense,
                    owedShare: owedShare(for: expense)
                )
                .presentationDetents([.medium])
                .presentationBackground(Color.ui.background)
            }
        }
    }

    // MARK: - Not Connected

    private var notConnectedView: some View {
        ContentUnavailableView {
            Label("Splitwise", systemImage: "arrow.triangle.branch")
        } description: {
            Text("Connect your Splitwise account to browse and import expenses.")
        } actions: {
            Button("Connect to Splitwise") {
                Task {
                    await startOAuth()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.ui.sageColor)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading expenses...")
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Expense List

    private var filteredExpenses: [SplitwiseExpense] {
        expenses.filter { expense in
            expense.deletedAt == nil && owedShare(for: expense) != 0
        }
    }

    private var groupedExpenses: [Date: [SplitwiseExpense]] {
        Dictionary(grouping: filteredExpenses) { expense in
            Calendar.current.startOfDay(for: expense.parsedDate ?? Date.distantPast)
        }
    }

    private var sortedDates: [Date] {
        groupedExpenses.keys.sorted(by: >)
    }

    private var expenseListView: some View {
        VStack {
            if filteredExpenses.isEmpty {
                ContentUnavailableView(
                    "No expenses found",
                    systemImage: "tray"
                )
            } else {
                ScrollView {
                    VStack(spacing: 25) {
                        ForEach(sortedDates, id: \.self) { date in
                            let dayExpenses = groupedExpenses[date] ?? []
                            splitwiseExpensesList(in: date, expenses: dayExpenses)
                        }
                    }
                }
            }
        }
        .padding([.horizontal, .top], 10)
        .frame(maxWidth: .infinity)
        .refreshable {
            await fetchExpenses()
        }
        .task {
            if expenses.isEmpty {
                await fetchExpenses()
            }
        }
    }

    private func splitwiseExpensesList(in date: Date, expenses: [SplitwiseExpense]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .foregroundStyle(.secondary)
                .font(.caption)

            Grid(alignment: .leading, horizontalSpacing: 8) {
                ForEach(expenses) { expense in
                    GridRow {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 10)

                        Text(expense.description)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: 150, alignment: .leading)

                        if let category = expense.category {
                            Text(category.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(owedShare(for: expense).currencyStringWithFraction)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedExpense = expense
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func owedShare(for expense: SplitwiseExpense) -> Double {
        guard let userId = currentUserId,
              let user = expense.users.first(where: { $0.userId == userId }),
              let share = Double(user.owedShare) else {
            return 0
        }
        return share
    }

    // MARK: - OAuth

    private func startOAuth() async {
        guard let authURL = service.getAuthorizationURL() else { return }
        
        do {
            let urlWithToken = try await webAuthenticationSession.authenticate( using: authURL, callbackURLScheme: "financetracker")
            
            try await service.handleOAuthCallback(url: urlWithToken)
            await fetchExpenses()
        } catch {
            errorMessage = error.localizedDescription
        }
        
    }

    // MARK: - Fetch

    private func fetchExpenses() async {
        isLoading = true
        defer { isLoading = false }

        do {
            if currentUserId == nil {
                let user = try await service.getCurrentUser()
                currentUserId = user.id
            }

            let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())
            expenses = try await service.getExpenses(
                datedAfter: threeMonthsAgo,
                limit: 100
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    SplitwiseView()
        .modelContainer(ModelContainer.preview)
}
