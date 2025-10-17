//
//  AppearancePicker.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/15/25.
//
import SwiftUI

struct AppearancePicker: View {
    @Binding var appearance: Appearance
    
    func appearanceFill(_ appearance: Appearance) -> UIColor {
        switch appearance {
        case .light:
            return UIColor(Color.ui.background).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        case .dark:
            return UIColor(Color.ui.background).resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        case .system: return .darkGray
        }
    }
    
    var body: some View {
        VStack {
            ForEach(Appearance.allCases, id: \.self) { appearance in
                Button {
                    self.appearance = appearance
                } label: {
                    HStack {
                        ZStack(alignment: .center) {
                            Rectangle()
                                .fill(Color(uiColor: appearanceFill(appearance)))
                                .frame(width: 50, height: 50)
                                .cornerRadius(10)
                            
                            Text("Aa")
                                .font(.title3)
                                .foregroundStyle(appearance == .light ? .black : .white)
                        }

                        VStack(alignment: .leading) {
                            Text(appearance.rawValue).tag(appearance)
                                .font(.title2)
                            Text(
                                appearance == .system ? "Use the default system appearance"
                                : "Always use a \(appearance.rawValue.lowercased()) appearance"
                            )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if self.appearance == appearance {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.ui.cardBackground)
                .cornerRadius(15)
                .foregroundStyle(.primary)
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedAppearance: Appearance = .light
    AppearancePicker(appearance: $selectedAppearance)
        .preferredColorScheme(selectedAppearance.colorScheme)
}
