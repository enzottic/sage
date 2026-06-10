//
//  ApperanceManager.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/15/25.
//

import Foundation
import SwiftUI
import WidgetKit
import SageKit

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

@Observable
class AppConfiguration {
    private let defaults: UserDefaults
    private let cloudKVS = NSUbiquitousKeyValueStore.default
    private let suite = "group.me.enzottic.SageAppGroup"
    
    // Keys used in both UserDefaults and iCloud KVS
    private enum Keys {
        static let appearance = "appearance"
        static let totalMonthlyIncome = "totalMonthlyIncome"
        static let needsPercent = "needsPercent"
        static let wantsPercent = "wantsPercent"
        static let savingsPercent = "savingsPercent"
        static let isCloudSyncEnabled = "isCloudSyncEnabled"
        static let hasCompletedSetup = "hasCompletedSetup"
        static let smartTaggingMode = "smartTaggingMode"
        static let needsColor = "categoryColorNeeds"
        static let wantsColor = "categoryColorWants"
        static let savingsColor = "categoryColorSavings"
        // Stored locally only — notifications are per-device and don't sync to iCloud KVS
        static let billRemindersEnabled = "billRemindersEnabled"
    }
    
    var selectedAppearance: Appearance {
        didSet {
            defaults.set(selectedAppearance.rawValue, forKey: Keys.appearance)
            cloudKVS.set(selectedAppearance.rawValue, forKey: Keys.appearance)
            cloudKVS.synchronize()
        }
    }
    
    var totalMonthlyIncome: Int {
        didSet {
            defaults.set(totalMonthlyIncome, forKey: Keys.totalMonthlyIncome)
            cloudKVS.set(Int64(totalMonthlyIncome), forKey: Keys.totalMonthlyIncome)
            cloudKVS.synchronize()
        }
    }
    
    var needsPercent: Double {
        didSet {
            defaults.set(needsPercent, forKey: Keys.needsPercent)
            cloudKVS.set(needsPercent, forKey: Keys.needsPercent)
            cloudKVS.synchronize()
        }
    }
    
    var wantsPercent: Double {
        didSet {
            defaults.set(wantsPercent, forKey: Keys.wantsPercent)
            cloudKVS.set(wantsPercent, forKey: Keys.wantsPercent)
            cloudKVS.synchronize()
        }
    }
    
    var savingsPercent: Double {
        didSet {
            defaults.set(savingsPercent, forKey: Keys.savingsPercent)
            cloudKVS.set(savingsPercent, forKey: Keys.savingsPercent)
            cloudKVS.synchronize()
        }
    }
    
    var isCloudSyncEnabled: Bool {
        didSet {
            defaults.set(isCloudSyncEnabled, forKey: Keys.isCloudSyncEnabled)
            cloudKVS.set(isCloudSyncEnabled, forKey: Keys.isCloudSyncEnabled)
            cloudKVS.synchronize()
        }
    }

    var smartTaggingMode: SmartTaggingMode {
        didSet {
            defaults.set(smartTaggingMode.rawValue, forKey: Keys.smartTaggingMode)
            cloudKVS.set(smartTaggingMode.rawValue, forKey: Keys.smartTaggingMode)
            cloudKVS.synchronize()
        }
    }

    var needsColor: Color {
        didSet {
            defaults.setSageColor(needsColor, forKey: Keys.needsColor)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    var wantsColor: Color {
        didSet {
            defaults.setSageColor(wantsColor, forKey: Keys.wantsColor)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    var savingsColor: Color {
        didSet {
            defaults.setSageColor(savingsColor, forKey: Keys.savingsColor)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    var billRemindersEnabled: Bool {
        didSet {
            defaults.set(billRemindersEnabled, forKey: Keys.billRemindersEnabled)
        }
    }

    var categoryColors: CategoryColors {
        CategoryColors(needs: needsColor, wants: wantsColor, savings: savingsColor)
    }

    func resetCategoryColors() {
        needsColor = Color("NeedColor")
        wantsColor = Color("WantColor")
        savingsColor = Color("SavingColor")
        // Remove persisted values so widgets fall back to asset catalog defaults on next load
        defaults.removeObject(forKey: Keys.needsColor)
        defaults.removeObject(forKey: Keys.wantsColor)
        defaults.removeObject(forKey: Keys.savingsColor)
    }
    
    var needsBudget: Double {
        Double(totalMonthlyIncome) * needsPercent
    }
    
    var wantsBudget: Double {
        Double(totalMonthlyIncome) * wantsPercent
    }
    
    var savingsBudget: Double {
        Double(totalMonthlyIncome) * savingsPercent
    }
    
    init() {
        self.defaults = UserDefaults(suiteName: suite) ?? .standard
        
        // iCloud KVS is the source of truth for all settings.
        // Fall back to local UserDefaults if iCloud KVS hasn't synced yet.
        
        // Appearance
        if let cloudAppearance = cloudKVS.string(forKey: Keys.appearance),
           let appearance = Appearance(rawValue: cloudAppearance) {
            self.selectedAppearance = appearance
        } else if let localAppearance = defaults.string(forKey: Keys.appearance),
                  let appearance = Appearance(rawValue: localAppearance) {
            self.selectedAppearance = appearance
        } else {
            self.selectedAppearance = .system
        }
        
        // Monthly income
        let cloudIncome = cloudKVS.object(forKey: Keys.totalMonthlyIncome) as? Int
        let localIncome = defaults.object(forKey: Keys.totalMonthlyIncome) as? Int
        self.totalMonthlyIncome = cloudIncome ?? localIncome ?? 0
        
        // Budget percentages — use iCloud KVS if available, else local defaults, else 50/30/20
        let cloudNeeds = cloudKVS.object(forKey: Keys.needsPercent) as? Double
        let localNeeds = defaults.object(forKey: Keys.needsPercent) as? Double
        self.needsPercent = cloudNeeds ?? localNeeds ?? 0.5
        
        let cloudWants = cloudKVS.object(forKey: Keys.wantsPercent) as? Double
        let localWants = defaults.object(forKey: Keys.wantsPercent) as? Double
        self.wantsPercent = cloudWants ?? localWants ?? 0.3
        
        let cloudSavings = cloudKVS.object(forKey: Keys.savingsPercent) as? Double
        let localSavings = defaults.object(forKey: Keys.savingsPercent) as? Double
        self.savingsPercent = cloudSavings ?? localSavings ?? 0.2
        
        // Cloud sync toggle — iCloud KVS is authoritative
        if cloudKVS.object(forKey: Keys.isCloudSyncEnabled) != nil {
            self.isCloudSyncEnabled = cloudKVS.bool(forKey: Keys.isCloudSyncEnabled)
        } else {
            self.isCloudSyncEnabled = defaults.bool(forKey: Keys.isCloudSyncEnabled)
        }

        // Auto tagging mode - default expense history and AI
        if let smartTaggingModeString = cloudKVS.string(forKey: Keys.smartTaggingMode),
           let mode = SmartTaggingMode(rawValue: smartTaggingModeString) {
            self.smartTaggingMode = mode
        } else if let localAutoTaggingModeString = defaults.string(forKey: Keys.smartTaggingMode),
                  let mode = SmartTaggingMode(rawValue: localAutoTaggingModeString) {
            self.smartTaggingMode = mode
        } else {
            self.smartTaggingMode = .history
        }

        // Category colors — stored locally only (not synced to iCloud KVS)
        self.needsColor = defaults.sageColor(forKey: Keys.needsColor) ?? Color("NeedColor")
        self.wantsColor = defaults.sageColor(forKey: Keys.wantsColor) ?? Color("WantColor")
        self.savingsColor = defaults.sageColor(forKey: Keys.savingsColor) ?? Color("SavingColor")

        // Bill reminders — stored locally only (not synced to iCloud KVS)
        self.billRemindersEnabled = defaults.bool(forKey: Keys.billRemindersEnabled)

        // Push current values to local defaults so widgets stay in sync
        syncToLocalDefaults()
        
        // Listen for changes from other devices
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudKVSDidChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudKVS
        )
    }
    
    @objc private func iCloudKVSDidChange(_ notification: Notification) {
        DispatchQueue.main.async { [self] in
            // Update local properties from iCloud KVS when another device pushes changes
            if let cloudAppearance = cloudKVS.string(forKey: Keys.appearance),
               let appearance = Appearance(rawValue: cloudAppearance) {
                selectedAppearance = appearance
            }
            
            if cloudKVS.object(forKey: Keys.totalMonthlyIncome) != nil {
                totalMonthlyIncome = Int(cloudKVS.longLong(forKey: Keys.totalMonthlyIncome))
            }
            
            if cloudKVS.object(forKey: Keys.needsPercent) != nil {
                needsPercent = cloudKVS.double(forKey: Keys.needsPercent)
            }
            
            if cloudKVS.object(forKey: Keys.wantsPercent) != nil {
                wantsPercent = cloudKVS.double(forKey: Keys.wantsPercent)
            }
            
            if cloudKVS.object(forKey: Keys.savingsPercent) != nil {
                savingsPercent = cloudKVS.double(forKey: Keys.savingsPercent)
            }
            
            if cloudKVS.object(forKey: Keys.isCloudSyncEnabled) != nil {
                isCloudSyncEnabled = cloudKVS.bool(forKey: Keys.isCloudSyncEnabled)
            }

            if let cloudAutoTaggingMode = cloudKVS.string(forKey: Keys.smartTaggingMode),
               let mode = SmartTaggingMode(rawValue: cloudAutoTaggingMode) {
                smartTaggingMode = mode
            }
            
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    /// Push current values to local UserDefaults (for widget access via app group)
    private func syncToLocalDefaults() {
        defaults.set(selectedAppearance.rawValue, forKey: Keys.appearance)
        defaults.set(totalMonthlyIncome, forKey: Keys.totalMonthlyIncome)
        defaults.set(needsPercent, forKey: Keys.needsPercent)
        defaults.set(wantsPercent, forKey: Keys.wantsPercent)
        defaults.set(savingsPercent, forKey: Keys.savingsPercent)
        defaults.set(isCloudSyncEnabled, forKey: Keys.isCloudSyncEnabled)
        defaults.set(smartTaggingMode.rawValue, forKey: Keys.smartTaggingMode)
        defaults.setSageColor(needsColor, forKey: Keys.needsColor)
        defaults.setSageColor(wantsColor, forKey: Keys.wantsColor)
        defaults.setSageColor(savingsColor, forKey: Keys.savingsColor)
    }
    
    func markSetupComplete() {
        cloudKVS.set(true, forKey: Keys.hasCompletedSetup)
        cloudKVS.synchronize()
    }
    
    static var hasCompletedSetupOnAnotherDevice: Bool {
        NSUbiquitousKeyValueStore.default.bool(forKey: "hasCompletedSetup")
    }
    
    func updateNeeds(_ newNeeds: Double) {
        let clampedNeeds = min(max(newNeeds, 0), 1)
        var newWants = wantsPercent
        if clampedNeeds + newWants > 1 {
            newWants = round((1 - clampedNeeds) / 0.05) * 0.05
        }
        let newSavings = max(1 - (clampedNeeds + newWants), 0)
        needsPercent = clampedNeeds
        wantsPercent = newWants
        savingsPercent = newSavings

        WidgetCenter.shared.reloadAllTimelines()
    }

    func updateWants(_ newWants: Double) {
        let clampedWants = min(max(newWants, 0), 1)
        var newNeeds = needsPercent
        if newNeeds + clampedWants > 1 {
            newNeeds = round((1 - clampedWants) / 0.05) * 0.05
        }
        let newSavings = max(1 - (newNeeds + clampedWants), 0)
        needsPercent = newNeeds
        wantsPercent = clampedWants
        savingsPercent = newSavings

        WidgetCenter.shared.reloadAllTimelines()
    }
}
