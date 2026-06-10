//
//  RecurringRulesSection.swift
//  FinanceTracker
//
import SwiftUI
import SwiftData
import UserNotifications
import SageKit

struct RecurringExpensesSettingsSection: View {
    @Environment(AppRouter.self) var router
    @Environment(AppConfiguration.self) private var config: AppConfiguration
    @Environment(\.modelContext) private var modelContext

    @Query private var rules: [RecurringExpenseRule]

    private var sortedRules: [RecurringExpenseRule] {
        rules.sorted {
            let a = nextOccurrence(for: $0) ?? .distantFuture
            let b = nextOccurrence(for: $1) ?? .distantFuture
            return a < b
        }
    }

    private func nextOccurrence(for rule: RecurringExpenseRule) -> Date? {
        let calendar = Calendar.current
        let after = rule.lastGeneratedDate ?? rule.startDate
        let next: Date?
        switch rule.frequency {
        case .daily:    next = calendar.date(byAdding: .day, value: 1, to: after)
        case .weekly:   next = calendar.date(byAdding: .weekOfYear, value: 1, to: after)
        case .biweekly: next = calendar.date(byAdding: .weekOfYear, value: 2, to: after)
        case .monthly:  next = calendar.date(byAdding: .month, value: 1, to: after)
        @unknown default:
            fatalError("Unknown frequency: \(rule.frequency)")
        }
        if let next, let endDate = rule.endDate, next > endDate { return nil }
        return next
    }

    @State private var ruleToEdit: RecurringExpenseRule? = nil
    @State private var ruleToDelete: RecurringExpenseRule? = nil
    @State private var showDeleteConfirmation = false
    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        List {
            Section {
                Toggle(isOn: Binding(
                    get: { config.billRemindersEnabled },
                    set: { handleReminderToggle($0) }
                )) {
                    Label("Bill Reminders", systemImage: "bell.badge")
                }

                if config.billRemindersEnabled && notificationAuthStatus == .denied {
                    Label {
                        Text("Notifications are disabled. Tap to open ") +
                        Text("Settings").foregroundColor(.accentColor) +
                        Text(" and enable them.")
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                    }
                    .font(.caption)
                    .onTapGesture {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                } else {
                    Text("Get notified at 9 AM the day before each bill is due.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Notifications")
            }

            if rules.isEmpty {
                ContentUnavailableView(
                    "No Recurring Expense Rules",
                    systemImage: "arrow.trianglehead.clockwise",
                    description: Text("When you create a recurring expense, you can manage them here.")
                )
            } else {
                Section {
                    ForEach(sortedRules) { rule in
                        RecurringRuleRow(rule: rule, nextOccurrence: nextOccurrence(for: rule))
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
                    .onDelete { indexSet in
                        ruleToDelete = sortedRules[indexSet.first!]
                        showDeleteConfirmation = true
                    }
                } header: {
                    Text("Recurring Expenses")
                }
            }
        }
        .task {
            notificationAuthStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task {
                notificationAuthStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            }
        }
        .sheet(item: $ruleToEdit) { rule in
            EditRecurringRuleSheet(rule: rule)
                .presentationBackground(.sageBackground)
                .presentationDetents([.large])
        }
        .navigationTitle("Recurring Expenses")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Recurring Rule?", isPresented: $showDeleteConfirmation, presenting: ruleToDelete) { rule in
            Button("Delete Rule", role: .destructive) {
                let remaining = rules.filter { $0.id != rule.id }
                Task {
                    await RecurringNotificationService.scheduleAll(rules: remaining, enabled: config.billRemindersEnabled)
                }
                modelContext.delete(rule)
                try? modelContext.save()
                router.showToast(SageToast(message: "Expense Recurrence Rule Deleted", kind: .success))
            }
            Button("Cancel", role: .cancel) {}
        } message: { rule in
            Text("'\(rule.name)' will stop generating future expenses. Past expenses will not be deleted.")
        }
    }

    private func handleReminderToggle(_ enabled: Bool) {
        if enabled {
            Task {
                let granted = await RecurringNotificationService.requestAuthorization()
                if granted {
                    config.billRemindersEnabled = true
                    notificationAuthStatus = .authorized
                    await RecurringNotificationService.scheduleAll(rules: rules, enabled: true)
                } else {
                    config.billRemindersEnabled = false
                    notificationAuthStatus = await RecurringNotificationService.authorizationStatus()
                }
            }
        } else {
            config.billRemindersEnabled = false
            Task {
                await RecurringNotificationService.scheduleAll(rules: rules, enabled: false)
            }
        }
    }
}

private struct RecurringRuleRow: View {
    @Environment(\.categoryColors) private var categoryColors
    let rule: RecurringExpenseRule
    let nextOccurrence: Date?

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(rule.category.color(in: categoryColors))
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
                        Text(daysLabel(for: next))
                            .font(.caption)
                            .foregroundStyle(isImminent(next) ? .orange : .secondary)
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
    }

    private func daysLabel(for date: Date) -> String {
        let days = max(0, Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0)
        if days == 0 { return "today" }
        if days == 1 { return "in 1 day" }
        return "in \(days) days"
    }

    private func isImminent(_ date: Date) -> Bool {
        let days = Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
        return days <= 3
    }
}

#Preview {
    RecurringExpensesSettingsSection()
        .environmentInjection()
}

