//
//  ApperanceManager.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/15/25.
//

import Foundation
import SwiftUI

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
    
    var selectedMode: Appearance {
        didSet {
            UserDefaults.standard.set(selectedMode.rawValue, forKey: "appearance")
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
        
        if let savedMode = UserDefaults.standard.string(forKey: "appearance"),
           let mode = Appearance(rawValue: savedMode) {
            self.selectedMode = mode
        } else {
            self.selectedMode = .system
        }
        
        self.totalMonthlyIncome = defaults.integer(forKey: "totalMonthlyIncome") // 0 if not found
       
        let needsPercent = defaults.double(forKey: "needsPercent")
        self.needsPercent = needsPercent == 0 ? 0.5 : needsPercent
       
        let wantsPercent = defaults.double(forKey: "wantsPercent")
        self.wantsPercent = wantsPercent == 0 ? 0.3 : wantsPercent
        
        let savingsPercent = defaults.double(forKey: "savingsPercent")
        self.savingsPercent = savingsPercent == 0 ? 0.2 : savingsPercent
    }
}
