//
//  Color+SageColors.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/6/25.
//

import SwiftUI

extension Color {
    static let ui = Color.UI()

    struct UI {
        let sage = Color("Sage")
        let background = Color("Background")
        let cardBackground = Color("CardBackground")
        let want = Color("WantColor")
        let need = Color("NeedColor")
        let saving = Color("SavingColor")
        let selectedWant = Color("SelectedWant")
        let selectedNeed = Color("SelectedNeed")
    }
}

extension UserDefaults {
    func sageColor(forKey key: String) -> Color? {
        guard let components = array(forKey: key) as? [Double], components.count == 4 else { return nil }
        return Color(.sRGB, red: components[0], green: components[1], blue: components[2], opacity: components[3])
    }

    func setSageColor(_ color: Color, forKey key: String) {
        let resolved = color.resolve(in: EnvironmentValues())
        set([Double(resolved.red), Double(resolved.green), Double(resolved.blue), Double(resolved.opacity)], forKey: key)
    }
}

