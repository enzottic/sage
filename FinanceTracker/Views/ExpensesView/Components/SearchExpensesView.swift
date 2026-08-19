//
//  SearchExpensesView.swift
//  FinanceTracker
//
//  Created on 4/10/26.
//

import SwiftUI
import SwiftData
import SageKit

struct SearchExpensesView: View {
    @Environment(AppRouter.self) private var appRouter
    @State private var searchText: String = ""
    @State private var activeSearchText: String = ""

    private var isSearchEmpty: Bool {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        @Bindable var appRouter = appRouter
        NavigationStack(path: $appRouter.searchPath) {
            VStack {
                if isSearchEmpty {
                    ContentUnavailableView(
                        "Search All Expenses",
                        systemImage: "magnifyingglass",
                        description: Text("Search by name, note, or tag")
                    )
                } else if activeSearchText.isEmpty {
                    Color.clear
                        .accessibilityHidden(true)
                } else {
                    ExpenseSearchResults(searchText: activeSearchText)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.sageBackground)
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search expenses")
            .task(id: searchText) {
                let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedSearchText.isEmpty else {
                    activeSearchText = ""
                    return
                }

                do {
                    try await Task.sleep(for: .milliseconds(150))
                    activeSearchText = trimmedSearchText
                } catch is CancellationError {
                    // A new character cancels this search before it reaches SwiftData.
                } catch {
                    // Task.sleep only throws when SwiftUI cancels this task.
                }
            }
            .appRouteDestinations()
            .gradientBackground()
        }
    }
}

private struct ExpenseSearchResults: View {
    private static let resultLimit = 100

    @Query private var expenses: [Expense]
    let searchText: String

    init(searchText: String) {
        self.searchText = searchText

        let query = searchText
        var descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { expense in
                expense.name.localizedStandardContains(query)
                || expense.note.localizedStandardContains(query)
                || (expense.tags?.contains { tag in
                    tag.name.localizedStandardContains(query)
                } == true)
            },
            sortBy: [SortDescriptor(\Expense.date, order: .reverse)]
        )
        descriptor.fetchLimit = Self.resultLimit
        _expenses = Query(descriptor)
    }

    var body: some View {
        let sections = makeSections()

        Group {
            if expenses.isEmpty {
                ContentUnavailableView(
                    "No matching expenses",
                    systemImage: "magnifyingglass"
                )
            } else {
                List {
                    ForEach(sections) { section in
                        Section {
                            ExpenseList(expenses: section.expenses)
                        } header: {
                            Text(section.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                        }
                    }

                    if expenses.count == Self.resultLimit {
                        Text("Showing the first \(Self.resultLimit) results")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
        }
    }

    private func makeSections() -> [ExpenseSearchSection] {
        let calendar = Calendar.current
        let groupedExpenses = Dictionary(grouping: expenses) { expense in
            calendar.startOfDay(for: expense.date)
        }

        return groupedExpenses
            .map { ExpenseSearchSection(date: $0.key, expenses: $0.value) }
            .sorted { $0.date > $1.date }
    }
}

private struct ExpenseSearchSection: Identifiable {
    let date: Date
    let expenses: [Expense]

    var id: Date { date }
}

#Preview {
    SearchExpensesView()
        .environmentInjection()
}
