//
//  RecurringRulesList.swift
//  FinanceTracker
//
import SwiftUI
import SwiftData

struct RecurringRulesList: View {
    @Environment(\.modelContext) private var modelContext
    let rules: [RecurringExpenseRule]

    @State private var ruleToEdit: RecurringExpenseRule? = nil
    @State private var ruleToDelete: RecurringExpenseRule? = nil
    @State private var showDeleteConfirmation = false

    var body: some View {
        if rules.isEmpty {
            Text("No recurring expenses yet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .background(Color.ui.cardBackground)
                .cornerRadius(15)
        } else {
            VStack(spacing: 1) {
                ForEach(rules) { rule in
                    RecurringRuleRow(rule: rule)
                        .contentShape(Rectangle())
                        .onTapGesture { ruleToEdit = rule }
                        .contextMenu {
                            Button("Edit") { ruleToEdit = rule }
                            Button("Delete", role: .destructive) {
                                ruleToDelete = rule
                                showDeleteConfirmation = true
                            }
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 15))
        }
    }

    // MARK: - Helpers

    /// Deletes the rule only — already-generated expenses are kept.
    private func deleteRule(_ rule: RecurringExpenseRule) {
        modelContext.delete(rule)
        try? modelContext.save()
    }

    // MARK: - Sheet / Alert

    var sheets: some View {
        EmptyView()
            .sheet(item: $ruleToEdit) { rule in
                EditRecurringRuleSheet(rule: rule)
                    .presentationBackground(Color.ui.background)
                    .presentationDetents([.large])
            }
            .alert("Delete Recurring Rule?", isPresented: $showDeleteConfirmation, presenting: ruleToDelete) { rule in
                Button("Delete Rule", role: .destructive) { deleteRule(rule) }
                Button("Cancel", role: .cancel) {}
            } message: { rule in
                Text("'\(rule.name)' will stop generating future expenses. Past expenses will not be deleted.")
            }
    }
}

// MARK: - Row

private struct RecurringRuleRow: View {
    let rule: RecurringExpenseRule

    var body: some View {
        HStack(spacing: 12) {
            // Category color accent
            RoundedRectangle(cornerRadius: 3)
                .fill(categoryColor)
                .frame(width: 4, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(rule.frequency.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let next = nextOccurrence {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("next \(next.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let endDate = rule.endDate {
                        Text("· ends \(endDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Text(rule.amount.currencyStringWithFraction)
                .font(.subheadline)
                .fontWeight(.semibold)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.ui.cardBackground)
    }

    private var categoryColor: Color {
        switch rule.category {
        case .needs: return Color.ui.need
        case .wants: return Color.ui.want
        case .savings: return .teal
        }
    }

    /// The next date this rule will generate an expense, or nil if it has expired.
    private var nextOccurrence: Date? {
        let calendar = Calendar.current
        let after = rule.lastGeneratedDate ?? rule.startDate
        let next: Date?
        switch rule.frequency {
        case .daily:    next = calendar.date(byAdding: .day, value: 1, to: after)
        case .weekly:   next = calendar.date(byAdding: .weekOfYear, value: 1, to: after)
        case .biweekly: next = calendar.date(byAdding: .weekOfYear, value: 2, to: after)
        case .monthly:  next = calendar.date(byAdding: .month, value: 1, to: after)
        }
        if let next, let endDate = rule.endDate, next > endDate { return nil }
        return next
    }
}

// MARK: - Wrapper that attaches sheets (used in SettingsView)

struct RecurringRulesSection: View {
    @Query(sort: \RecurringExpenseRule.name) private var rules: [RecurringExpenseRule]

    @State private var ruleToEdit: RecurringExpenseRule? = nil
    @State private var ruleToDelete: RecurringExpenseRule? = nil
    @State private var showDeleteConfirmation = false

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if rules.isEmpty {
                ContentUnavailableView(
                    "No Recurring Expense Rules",
                    systemImage: "arrow.trianglehead.clockwise",
                    description: Text("When you create a recurring expense, you can edit them here.")
                )
            } else {
                VStack(spacing: 1) {
                    ForEach(rules) { rule in
                        RecurringRuleRow(rule: rule)
                            .contentShape(Rectangle())
                            .onTapGesture { ruleToEdit = rule }
                            .contextMenu {
                                Button("Edit") { ruleToEdit = rule }
                                Button("Delete", role: .destructive) {
                                    ruleToDelete = rule
                                    showDeleteConfirmation = true
                                }
                            }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
        }
        .sheet(item: $ruleToEdit) { rule in
            EditRecurringRuleSheet(rule: rule)
                .presentationBackground(Color.ui.background)
                .presentationDetents([.large])
        }
        .navigationTitle("Recurring Expenses")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Recurring Rule?", isPresented: $showDeleteConfirmation, presenting: ruleToDelete) { rule in
            Button("Delete Rule", role: .destructive) {
                modelContext.delete(rule)
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        } message: { rule in
            Text("'\(rule.name)' will stop generating future expenses. Past expenses will not be deleted.")
        }
    }
}
