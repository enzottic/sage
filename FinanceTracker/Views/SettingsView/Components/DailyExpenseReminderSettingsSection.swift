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
        List {
            Section {
                Toggle("Daily Reminder", isOn: Binding(
                    get: { config.dailyExpenseReminderEnabled },
                    set: { setEnabled($0) }
                ))
                .disabled(requestingPermission)
                .accessibilityIdentifier("daily-expense-reminder-toggle")
                ReminderTimePicker(minutes: $config.dailyExpenseReminderTimeMinutes)
                    .disabled(!config.dailyExpenseReminderEnabled)
                    .accessibilityIdentifier("daily-expense-reminder-time")
            }

            if config.dailyExpenseReminderEnabled {
                Section {
                    if requestingPermission {
                        ProgressView("Requesting notification permission")
                    } else if reminders?.dailyScheduler.authorizationStatus == .denied {
                        Text("Notifications are blocked in iOS Settings.")
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                        }
                    } else if let error = permissionError ?? reminders?.dailyScheduler.errorMessage {
                        Text("Syl could not update your daily reminder. \(error)")
                        Button("Retry") { setEnabled(true) }
                    } else if reminders?.dailyScheduler.authorizationStatus == .provisional {
                        Text("Notifications are delivered quietly. You can enable alerts in iOS Settings.")
                    }
                }
                .font(.footnote)
            }
        }
        .settingsBackground()
        .navigationTitle("Daily Reminder")
        .navigationBarTitleDisplayMode(.inline)
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
