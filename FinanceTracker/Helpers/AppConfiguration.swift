//
//  ApperanceManager.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/15/25.
//

import Foundation
import SwiftUI
import WidgetKit

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

@Observable
class AppConfiguration {
    private let defaults: UserDefaults
    private let suite = "group.me.enzottic.SageAppGroup"
    
    var selectedAppearance: Appearance {
        didSet {
            UserDefaults.standard.set(selectedAppearance.rawValue, forKey: "appearance")
        }
    }
    
    var totalMonthlyIncome: Int {
        didSet {
            defaults.set(totalMonthlyIncome, forKey: "totalMonthlyIncome")
        }
    }
    
    var needsPercent: Double {
        didSet {
            defaults.set(needsPercent, forKey: "needsPercent")
        }
    }
    
    var wantsPercent: Double {
        didSet {
            defaults.set(wantsPercent, forKey: "wantsPercent")
        }
    }
    
    var savingsPercent: Double {
        didSet {
            defaults.set(savingsPercent, forKey: "savingsPercent")
        }
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
        
        if let savedAppearance = UserDefaults.standard.string(forKey: "appearance"),
           let appearance = Appearance(rawValue: savedAppearance) {
            self.selectedAppearance = appearance
        } else {
            self.selectedAppearance = .system
        }
        
        self.totalMonthlyIncome = defaults.integer(forKey: "totalMonthlyIncome") // 0 if not found
       
        let needsPercent = defaults.double(forKey: "needsPercent")
        self.needsPercent = needsPercent == 0 ? 0.5 : needsPercent
       
        let wantsPercent = defaults.double(forKey: "wantsPercent")
        self.wantsPercent = wantsPercent == 0 ? 0.3 : wantsPercent
        
        let savingsPercent = defaults.double(forKey: "savingsPercent")
        self.savingsPercent = savingsPercent == 0 ? 0.2 : savingsPercent
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
