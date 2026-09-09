import SwiftUI
import SageKit
import UserNotifications

struct DailyExpenseReminderSettingsSection: View {
    @Environment(AppConfiguration.self) private var config
    @Environment(\.recurringReminders) private var reminders
    @Environment(\.openURL) private var openURL
    @State private var requestingPermission = false
    @State private var permissionError: String?

    var body: some View {
        @Bindable var config = config
        Section {
            Toggle("Daily Reminder", isOn: Binding(
                get: { config.dailyExpenseReminderEnabled },
                set: { setEnabled($0) }
            ))
            .disabled(requestingPermission)
            .accessibilityIdentifier("daily-expense-reminder-toggle")

            if config.dailyExpenseReminderEnabled {
                ReminderTimePicker(minutes: $config.dailyExpenseReminderTimeMinutes)
                    .accessibilityIdentifier("daily-expense-reminder-time")
            }
        } header: {
            Text("Daily Reminder")
        }
        .onChange(of: config.dailyExpenseReminderTimeMinutes) { reminders?.refresh() }
    }

    private func setEnabled(_ enabled: Bool) {
        config.dailyExpenseReminderEnabled = enabled
        permissionError = nil
        guard enabled, reminders != nil else {
            reminders?.refresh()
            return
        }
        requestingPermission = true
        Task { @MainActor in
            defer {
                requestingPermission = false
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
