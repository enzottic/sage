import Foundation
import CoreFoundation
import SwiftUI
import WidgetKit
import SageKit


// Handles preserving settings for Sage, including wants/needs/savings percentages, smart tagging preferences, appearance, and more.
// Exist as a local storage only, but settings are persisted in iCloud via the PreferenceSyncService, if enabled.
@MainActor @Observable
class AppConfiguration {
    private typealias Key = PreferenceSyncService.Key
    private static let suite = "group.me.enzottic.SageAppGroup"
    private let isPreview: Bool
    private let isUITesting: Bool
    private let defaults: UserDefaults
    private let sharedDefaults: UserDefaults?
    private let preferenceSync: PreferenceSyncService
    private var isApplyingRemote = false
    private var isRestoringValue = false

    private(set) var ledgerCurrencyCode: String?
    private(set) var cloudLedgerCurrencyCode: String?
    private(set) var hasLedgerCurrencyConflict = false
    private(set) var hasCompletedSetupOnAnotherDevice = false
    private(set) var cloudSyncStatus: PreferenceSyncService.Status = .stopped

    var ledgerCurrencyConflictMessage: String? {
        guard hasLedgerCurrencyConflict else { return nil }
        if let local = ledgerCurrencyCode, let cloud = cloudLedgerCurrencyCode {
            return "This device uses \(local), but iCloud reports \(cloud). Monetary screens are blocked because these currencies do not match. Syl has not changed your currency or converted any amounts."
        }
        return "A currency conflict was previously detected, and Syl cannot currently verify the iCloud currency. Monetary screens remain blocked. No currency has been changed and no amounts have been converted."
    }

    func establishLedgerCurrency(_ code: String, savingSetup: () throws -> Void = {}) throws {
        guard LedgerCurrency.validatedCode(code) != nil else { throw LedgerCurrency.Error.invalidCode(code) }
        if isPreview || isUITesting {
            try savingSetup()
            ledgerCurrencyCode = code
            return
        }
        preferenceSync.recheck()
        guard !hasLedgerCurrencyConflict,
              cloudLedgerCurrencyCode == nil || cloudLedgerCurrencyCode == code else {
            throw LedgerCurrency.Error.cloudConflict
        }
        try LedgerCurrency.establish(code, defaults: sharedDefaults, beforeSaving: savingSetup)
        ledgerCurrencyCode = code
        preferenceSync.recheck()
        preferenceSync.publishCurrencyIfAbsent(code, hasKnownConflict: hasLedgerCurrencyConflict)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func recheckLedgerCurrency() { preferenceSync.recheck() }

    /// Local-only flags use the same store as init, including the DEBUG sandbox.
    static var localDefaults: UserDefaults {
        #if DEBUG
        .standard
        #else
        UserDefaults(suiteName: suite) ?? .standard
        #endif
    }

    static var isBillRemindersEnabled: Bool {
        localDefaults.bool(forKey: Keys.billRemindersEnabled)
    }

    private enum Keys {
        static let isCloudSyncEnabled = SageModelContainer.cloudKitPreferenceKey
        static let needsColor = "categoryColorNeeds"
        static let wantsColor = "categoryColorWants"
        static let savingsColor = "categoryColorSavings"
        static let billRemindersEnabled = "billRemindersEnabled"
        static let billReminderDaysBefore = "billReminderDaysBefore"
        static let hideBillReminderDetails = "hideBillReminderDetails"
        static let billReminderTimeMinutes = "billReminderTimeMinutes"
        static let dailyExpenseReminderEnabled = "dailyExpenseReminderEnabled"
        static let dailyExpenseReminderTimeMinutes = "dailyExpenseReminderTimeMinutes"
    }

    var selectedAppearance: Appearance {
        didSet { persist(selectedAppearance.rawValue, key: .appearance) }
    }
    var totalMonthlyIncome: Int {
        didSet {
            guard !isRestoringValue else { return }
            guard totalMonthlyIncome >= 0 else {
                isRestoringValue = true
                totalMonthlyIncome = oldValue
                isRestoringValue = false
                return
            }
            persist(totalMonthlyIncome, key: .totalMonthlyIncome)
        }
    }
    var needsPercent: Double {
        didSet {
            guard !isRestoringValue else { return }
            guard needsPercent.isFinite, (0...1).contains(needsPercent) else {
                isRestoringValue = true
                needsPercent = oldValue
                isRestoringValue = false
                return
            }
            persist(needsPercent, key: .needsPercent)
        }
    }
    var wantsPercent: Double {
        didSet {
            guard !isRestoringValue else { return }
            guard wantsPercent.isFinite, (0...1).contains(wantsPercent) else {
                isRestoringValue = true
                wantsPercent = oldValue
                isRestoringValue = false
                return
            }
            persist(wantsPercent, key: .wantsPercent)
        }
    }
    var savingsPercent: Double {
        didSet {
            guard !isRestoringValue else { return }
            guard savingsPercent.isFinite, (0...1).contains(savingsPercent) else {
                isRestoringValue = true
                savingsPercent = oldValue
                isRestoringValue = false
                return
            }
            persist(savingsPercent, key: .savingsPercent)
        }
    }
    var smartTaggingMode: SmartTaggingMode {
        didSet { persist(smartTaggingMode.rawValue, key: .smartTaggingMode) }
    }

    var isCloudSyncEnabled: Bool {
        didSet {
            guard !isPreview, !isUITesting else { return }
            sharedDefaults?.set(isCloudSyncEnabled, forKey: Keys.isCloudSyncEnabled)
            if isCloudSyncEnabled {
                preferenceSync.start()
            } else {
                preferenceSync.stop()
                hasCompletedSetupOnAnotherDevice = false
                cloudLedgerCurrencyCode = nil
            }
        }
    }

    /// Reports local consent persistence, not iCloud availability or server confirmation.
    @discardableResult
    func updateCloudSyncEnabled(_ enabled: Bool) -> Bool {
        isCloudSyncEnabled = enabled
        guard !isPreview, !isUITesting else { return true }
        return sharedDefaults?.bool(forKey: Keys.isCloudSyncEnabled) == enabled
    }

    var needsColor: Color {
        didSet {
            guard !isPreview else { return }
            defaults.setSageColor(needsColor, forKey: Keys.needsColor)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    var wantsColor: Color {
        didSet {
            guard !isPreview else { return }
            defaults.setSageColor(wantsColor, forKey: Keys.wantsColor)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    var savingsColor: Color {
        didSet {
            guard !isPreview else { return }
            defaults.setSageColor(savingsColor, forKey: Keys.savingsColor)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    var billRemindersEnabled: Bool {
        didSet {
            guard !isPreview else { return }
            defaults.set(billRemindersEnabled, forKey: Keys.billRemindersEnabled)
        }
    }

    var billReminderDaysBefore: Int {
        didSet {
            guard !isRestoringValue else { return }
            guard (1...7).contains(billReminderDaysBefore) else {
                isRestoringValue = true
                billReminderDaysBefore = oldValue
                isRestoringValue = false
                return
            }
            if !isPreview { defaults.set(billReminderDaysBefore, forKey: Keys.billReminderDaysBefore) }
        }
    }

    var hideBillReminderDetails: Bool {
        didSet {
            if !isPreview { defaults.set(hideBillReminderDetails, forKey: Keys.hideBillReminderDetails) }
        }
    }

    var billReminderTimeMinutes: Int {
        didSet {
            guard !isRestoringValue else { return }
            guard (0..<1440).contains(billReminderTimeMinutes) else {
                isRestoringValue = true
                billReminderTimeMinutes = oldValue
                isRestoringValue = false
                return
            }
            if !isPreview { defaults.set(billReminderTimeMinutes, forKey: Keys.billReminderTimeMinutes) }
        }
    }

    var dailyExpenseReminderEnabled: Bool {
        didSet {
            if !isPreview { defaults.set(dailyExpenseReminderEnabled, forKey: Keys.dailyExpenseReminderEnabled) }
        }
    }

    var dailyExpenseReminderTimeMinutes: Int {
        didSet {
            guard !isRestoringValue else { return }
            guard (0..<1440).contains(dailyExpenseReminderTimeMinutes) else {
                isRestoringValue = true
                dailyExpenseReminderTimeMinutes = oldValue
                isRestoringValue = false
                return
            }
            if !isPreview { defaults.set(dailyExpenseReminderTimeMinutes, forKey: Keys.dailyExpenseReminderTimeMinutes) }
        }
    }

    var categoryColors: CategoryColors {
        CategoryColors(needs: needsColor, wants: wantsColor, savings: savingsColor)
    }
    var needsBudget: Double { Double(totalMonthlyIncome) * needsPercent }
    var wantsBudget: Double { Double(totalMonthlyIncome) * wantsPercent }
    var savingsBudget: Double { Double(totalMonthlyIncome) * savingsPercent }

    private func persist(_ value: Any, key: Key) {
        guard !isPreview else { return }
        defaults.set(value, forKey: key.storageKey)
        guard !isApplyingRemote else { return }
        var values = [key: value]
        if Key.allocation.contains(key) {
            guard abs(needsPercent + wantsPercent + savingsPercent - 1) < 0.000001 else { return }
            values = [.needsPercent: needsPercent, .wantsPercent: wantsPercent, .savingsPercent: savingsPercent]
        }
        preferenceSync.publish(values, localCurrency: ledgerCurrencyCode, hasKnownCurrencyConflict: hasLedgerCurrencyConflict)
    }

    func resetAllSettings() {
        preferenceSync.reset() // Removal is authorized only before disabling consent.
        isCloudSyncEnabled = false
        selectedAppearance = .system
        totalMonthlyIncome = 0
        needsPercent = 0.5
        wantsPercent = 0.3
        savingsPercent = 0.2
        smartTaggingMode = .history
        needsColor = Color("NeedColor")
        wantsColor = Color("WantColor")
        savingsColor = Color("SavingColor")
        billRemindersEnabled = false
        billReminderDaysBefore = 1
        hideBillReminderDetails = true
        billReminderTimeMinutes = 540
        dailyExpenseReminderEnabled = false
        dailyExpenseReminderTimeMinutes = 1200
        ledgerCurrencyCode = nil
        cloudLedgerCurrencyCode = nil
        hasLedgerCurrencyConflict = false
        hasCompletedSetupOnAnotherDevice = false
        
        guard !isPreview else { return }
        
        if !isUITesting { LedgerCurrency.reset(defaults: sharedDefaults) }
        let localKeys = Key.allCases.filter { $0 != .ledgerCurrency }.map(\.storageKey) + [
            Keys.isCloudSyncEnabled, Keys.needsColor, Keys.wantsColor, Keys.savingsColor, Keys.billRemindersEnabled,
            Keys.billReminderDaysBefore, Keys.hideBillReminderDetails,
            Keys.billReminderTimeMinutes, Keys.dailyExpenseReminderEnabled, Keys.dailyExpenseReminderTimeMinutes,
        ]
        
        for key in localKeys { defaults.removeObject(forKey: key) }
        
        if !isUITesting { sharedDefaults?.set(false, forKey: Keys.isCloudSyncEnabled) }
        WidgetCenter.shared.reloadAllTimelines()
    }

    convenience init() {
        if UITestConfiguration.isEnabled {
            self.init(defaults: UserDefaults(suiteName: "Sage.UITests.\(UUID().uuidString)")!, sharedDefaults: nil, isUITesting: true)
        } else {
            self.init(
                defaults: Self.localDefaults,
                sharedDefaults: UserDefaults(suiteName: Self.suite),
                isPreview: ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            )
        }
    }

    static var preview: AppConfiguration {
        AppConfiguration(defaults: .standard, sharedDefaults: nil, isPreview: true)
    }

    init(
        defaults: UserDefaults,
        sharedDefaults: UserDefaults?,
        isPreview: Bool = false,
        isUITesting: Bool = false,
        makeCloudStore: (() -> any CloudPreferenceStore)? = nil,
        notificationCenter: NotificationCenter = .default
    ) {
        self.isPreview = isPreview
        self.isUITesting = isUITesting
        self.defaults = defaults
        self.sharedDefaults = sharedDefaults
        
        preferenceSync = PreferenceSyncService(
            hasConsent: { !isPreview && !isUITesting && sharedDefaults?.bool(forKey: Keys.isCloudSyncEnabled) == true },
            makeStore: makeCloudStore,
            notificationCenter: notificationCenter
        )
        ledgerCurrencyCode = isPreview || isUITesting ? "USD" : LedgerCurrency.persistedCode(defaults: sharedDefaults)
        hasLedgerCurrencyConflict = !isPreview && !isUITesting && sharedDefaults?.bool(forKey: LedgerCurrency.cloudConflictKey) == true
        isCloudSyncEnabled = !isPreview && !isUITesting && sharedDefaults?.bool(forKey: Keys.isCloudSyncEnabled) == true
        selectedAppearance = isPreview ? .system : Appearance(rawValue: defaults.string(forKey: Key.appearance.storageKey) ?? "") ?? .system
        
        let income = Self.number(defaults.object(forKey: Key.totalMonthlyIncome.storageKey))
        totalMonthlyIncome = isPreview ? 5_000 : income.flatMap { $0 >= 0 ? Int(exactly: $0) : nil } ?? 0
        
        let needs = Self.number(defaults.object(forKey: Key.needsPercent.storageKey)) ?? 0.5
        let wants = Self.number(defaults.object(forKey: Key.wantsPercent.storageKey)) ?? 0.3
        let savings = Self.number(defaults.object(forKey: Key.savingsPercent.storageKey)) ?? 0.2
        let validAllocation = [needs, wants, savings].allSatisfy { (0...1).contains($0) }
            && abs(needs + wants + savings - 1) < 0.000001
        
        needsPercent = !isPreview && validAllocation ? needs : 0.5
        wantsPercent = !isPreview && validAllocation ? wants : 0.3
        savingsPercent = !isPreview && validAllocation ? savings : 0.2
        smartTaggingMode = isPreview ? .none : SmartTaggingMode(rawValue: defaults.string(forKey: Key.smartTaggingMode.storageKey) ?? "") ?? .history
        needsColor = isPreview ? Color("NeedColor") : defaults.sageColor(forKey: Keys.needsColor) ?? Color("NeedColor")
        wantsColor = isPreview ? Color("WantColor") : defaults.sageColor(forKey: Keys.wantsColor) ?? Color("WantColor")
        savingsColor = isPreview ? Color("SavingColor") : defaults.sageColor(forKey: Keys.savingsColor) ?? Color("SavingColor")
        billRemindersEnabled = !isPreview && defaults.bool(forKey: Keys.billRemindersEnabled)
        let reminderDays = defaults.integer(forKey: Keys.billReminderDaysBefore)
        billReminderDaysBefore = !isPreview && (1...7).contains(reminderDays) ? reminderDays : 1
        hideBillReminderDetails = isPreview || (defaults.object(forKey: Keys.hideBillReminderDetails) as? Bool ?? true)
        let reminderTime = defaults.object(forKey: Keys.billReminderTimeMinutes) as? Int ?? 540
        billReminderTimeMinutes = !isPreview && (0..<1440).contains(reminderTime) ? reminderTime : 540
        dailyExpenseReminderEnabled = !isPreview && defaults.bool(forKey: Keys.dailyExpenseReminderEnabled)
        let dailyTime = defaults.object(forKey: Keys.dailyExpenseReminderTimeMinutes) as? Int ?? 1200
        dailyExpenseReminderTimeMinutes = !isPreview && (0..<1440).contains(dailyTime) ? dailyTime : 1200

        // All observable fields must exist before a synchronous startup snapshot is delivered.
        preferenceSync.onChange = { [weak self] in self?.applyRemote($0) }
        preferenceSync.onStatusChange = { [weak self] status in
            guard let self else { return }
            if status == .accountChanged { self.updateCloudSyncEnabled(false) }
            self.cloudSyncStatus = status
        }
        if isCloudSyncEnabled { preferenceSync.start() }
        // Keep widget-facing defaults populated without sending fallback values to iCloud.
        if !isPreview {
            let localValues: [Key: Any] = [
                .appearance: selectedAppearance.rawValue, .totalMonthlyIncome: totalMonthlyIncome,
                .needsPercent: needsPercent, .wantsPercent: wantsPercent, .savingsPercent: savingsPercent,
                .smartTaggingMode: smartTaggingMode.rawValue,
            ]
            for (key, value) in localValues { defaults.set(value, forKey: key.storageKey) }
            defaults.setSageColor(needsColor, forKey: Keys.needsColor)
            defaults.setSageColor(wantsColor, forKey: Keys.wantsColor)
            defaults.setSageColor(savingsColor, forKey: Keys.savingsColor)
        }
    }

    private static func number(_ value: Any?) -> Double? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(),
              number.doubleValue.isFinite else { return nil }
        return number.doubleValue
    }

    private func applyRemote(_ snapshot: PreferenceSyncService.Snapshot) {
        isApplyingRemote = true
        defer { isApplyingRemote = false }
        if snapshot.keys.contains(.ledgerCurrency) {
            cloudLedgerCurrencyCode = LedgerCurrency.validatedCode(snapshot[.ledgerCurrency] as? String)
            let previousConflict = hasLedgerCurrencyConflict
                || sharedDefaults?.bool(forKey: LedgerCurrency.cloudConflictKey) == true
            if let local = ledgerCurrencyCode, let remote = cloudLedgerCurrencyCode {
                hasLedgerCurrencyConflict = local != remote
            } else {
                hasLedgerCurrencyConflict = previousConflict
            }
            sharedDefaults?.set(hasLedgerCurrencyConflict, forKey: LedgerCurrency.cloudConflictKey)
        }
        if let raw = snapshot[.appearance] as? String, let value = Appearance(rawValue: raw) {
            selectedAppearance = value
        }
        if let raw = snapshot[.smartTaggingMode] as? String, let value = SmartTaggingMode(rawValue: raw) {
            smartTaggingMode = value
        }
        if snapshot.keys.contains(.hasCompletedSetup) {
            let value = snapshot[.hasCompletedSetup] as? NSNumber
            hasCompletedSetupOnAnotherDevice = value.map { CFGetTypeID($0) == CFBooleanGetTypeID() && $0.boolValue } ?? false
        }
        // Never adopt a remote denomination or apply money whose denomination is unknown.
        if !hasLedgerCurrencyConflict, let local = ledgerCurrencyCode, local == cloudLedgerCurrencyCode {
            if let number = Self.number(snapshot[.totalMonthlyIncome]), number >= 0, let income = Int(exactly: number) {
                totalMonthlyIncome = income
            }
            if let needs = Self.number(snapshot[.needsPercent]), let wants = Self.number(snapshot[.wantsPercent]),
               let savings = Self.number(snapshot[.savingsPercent]),
               [needs, wants, savings].allSatisfy({ (0...1).contains($0) }),
               abs(needs + wants + savings - 1) < 0.000001 {
                needsPercent = needs
                wantsPercent = wants
                savingsPercent = savings
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    func markSetupComplete() { preferenceSync.markSetupComplete() }

    func resetRemoteSetup() {
        preferenceSync.publish([.hasCompletedSetup: false], localCurrency: nil, hasKnownCurrencyConflict: false)
        hasCompletedSetupOnAnotherDevice = false
    }

    func updateNeeds(_ newNeeds: Double) {
        guard newNeeds.isFinite else { return }
        let needs = min(max(newNeeds, 0), 1)
        let wants = needs + wantsPercent > 1
            ? min(round((1 - needs) / 0.05) * 0.05, 1 - needs) : wantsPercent
        needsPercent = needs
        wantsPercent = wants
        savingsPercent = max(1 - needs - wants, 0)
        if !isPreview { WidgetCenter.shared.reloadAllTimelines() }
    }

    func updateWants(_ newWants: Double) {
        guard newWants.isFinite else { return }
        let wants = min(max(newWants, 0), 1)
        let needs = needsPercent + wants > 1
            ? min(round((1 - wants) / 0.05) * 0.05, 1 - wants) : needsPercent
        needsPercent = needs
        wantsPercent = wants
        savingsPercent = max(1 - needs - wants, 0)
        if !isPreview { WidgetCenter.shared.reloadAllTimelines() }
    }
}

enum Appearance: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

enum SmartTaggingMode: String, CaseIterable {
    case history = "History"
    case ai = "AI"
    case both = "History + AI"
    case none = "None"
}
