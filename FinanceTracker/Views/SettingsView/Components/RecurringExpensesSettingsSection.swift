//
//  RecurringRulesSection.swift
//  FinanceTracker
//
import SwiftUI
import SwiftData
import SageKit
import UserNotifications

struct RecurringExpensesSettingsSection: View {
    @Environment(AppRouter.self) var router
    @Environment(\.modelContext) private var modelContext
    @Environment(AppConfiguration.self) private var config
    @Environment(\.recurringReminders) private var reminders
    @Environment(\.openURL) private var openURL

    @Query private var rules: [RecurringExpenseRule]

    private var sortedRules: [RecurringExpenseRule] {
        rules.sorted {
            let a = $0.nextOccurrence() ?? .distantFuture
            let b = $1.nextOccurrence() ?? .distantFuture
            return a < b
        }
    }

    @State private var ruleToEdit: RecurringExpenseRule? = nil
    @State private var ruleToDelete: RecurringExpenseRule? = nil
    @State private var showDeleteConfirmation = false
    @State private var isRequestingPermission = false
    @State private var permissionError: String?

    var body: some View {
        @Bindable var config = config
        List {
            Section {
                Toggle("Bill Reminders", isOn: Binding(
                    get: { config.billRemindersEnabled },
                    set: { setRemindersEnabled($0) }
                ))
                .disabled(isRequestingPermission)
                .accessibilityIdentifier("bill-reminders-toggle")

                Picker("Remind Me", selection: $config.billReminderDaysBefore) {
                    Text("1 day before").tag(1)
                    ForEach(2...7, id: \.self) { days in
                        Text("\(days) days before").tag(days)
                    }
                }
                .disabled(!config.billRemindersEnabled)
                .accessibilityIdentifier("bill-reminder-days")
                .accessibilityValue(config.billReminderDaysBefore == 1
                    ? Text("1 day before")
                    : Text("\(config.billReminderDaysBefore) days before"))

                ReminderTimePicker(minutes: $config.billReminderTimeMinutes)
                    .disabled(!config.billRemindersEnabled)
                    .accessibilityIdentifier("bill-reminder-time")

                Toggle("Hide Expense Details", isOn: $config.hideBillReminderDetails)
                    .accessibilityIdentifier("bill-reminder-privacy")
            } header: {
                Text("Reminders")
            } footer: {
                Text("One summary at your chosen local time for all recurring expenses scheduled on the target day. When details are visible, expense names and amounts may appear on your Lock Screen.")
            }

            if config.billRemindersEnabled {
                Section {
                    if isRequestingPermission {
                        ProgressView("Requesting notification permission")
                    } else if reminders?.scheduler.authorizationStatus == .denied {
                        Text("Notifications are blocked in iOS Settings.")
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                        }
                    } else if let error = permissionError ?? reminders?.scheduler.errorMessage {
                        Text("Sage could not update reminders. \(error)")
                        Button("Retry") { setRemindersEnabled(true) }
                    } else if reminders?.scheduler.authorizationStatus == .provisional {
                        Text("Notifications are delivered quietly. You can enable alerts in iOS Settings.")
                    } else if reminders?.scheduler.isRefreshing == true {
                        ProgressView("Updating reminders")
                    } else if rules.isEmpty {
                        Text("Reminders will begin when you add a recurring expense.")
                    }
                }
                .font(.footnote)
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
                        RecurringRuleRow(rule: rule, nextOccurrence: rule.nextOccurrence())
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
                        if let index = indexSet.first, sortedRules.indices.contains(index) {
                            ruleToDelete = sortedRules[index]
                            showDeleteConfirmation = true
                        }
                    }
                } header: {
                    Text("Recurring Expenses")
                }
            }
        }
        .settingsBackground()
        .onChange(of: config.billReminderDaysBefore) { reminders?.refresh() }
        .onChange(of: config.billReminderTimeMinutes) { reminders?.refresh() }
        .onChange(of: config.hideBillReminderDetails) { reminders?.refresh() }
        .sheet(item: $ruleToEdit) { rule in
            EditRecurringRuleSheet(rule: rule)
                .presentationBackground(.sageBackground)
                .presentationDetents([.large])
        }
        .navigationTitle("Recurring Expenses")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Recurring Rule?", isPresented: $showDeleteConfirmation, presenting: ruleToDelete) { rule in
            Button("Delete Rule", role: .destructive) {
                ruleToDelete = nil
                modelContext.delete(rule)
                do {
                    try modelContext.save()
                    reminders?.refresh()
                    router.showToast(SageToast(message: "Expense Recurrence Rule Deleted", kind: .success))
                } catch {
                    modelContext.rollback()
                    router.showToast(SageToast(message: "Sage could not delete this recurring rule. Please try again.", kind: .error))
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { rule in
            Text("'\(rule.name)' will stop generating future expenses. Past expenses will not be deleted.")
        }
    }

    private func setRemindersEnabled(_ enabled: Bool) {
        config.billRemindersEnabled = enabled
        permissionError = nil
        guard enabled, reminders != nil else {
            reminders?.refresh()
            return
        }
        isRequestingPermission = true
        Task { @MainActor in
            defer {
                isRequestingPermission = false
                reminders?.refresh()
            }
            let center = UNUserNotificationCenter.current()
            if await center.notificationSettings().authorizationStatus == .notDetermined {
                do { _ = try await center.requestAuthorization(options: [.alert, .sound]) }
                catch { permissionError = error.localizedDescription }
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

            Text(rule.amount.currencyString)
                .font(.subheadline)
                .fontWeight(.semibold)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private func daysLabel(for date: Date) -> String {
        let days = UpcomingExpenseDays.count(until: date)
        if days == 0 { return "today" }
        if days == 1 { return "in 1 day" }
        return "in \(days) days"
    }

    private func isImminent(_ date: Date) -> Bool {
        let days = UpcomingExpenseDays.count(until: date)
        return days <= 3
    }
}

#Preview {
    @Previewable @State var container = try! SageModelContainer.makeRecurringPreview()

    NavigationStack {
        RecurringExpensesSettingsSection()
    }
    .environmentInjection(container: container)
}
