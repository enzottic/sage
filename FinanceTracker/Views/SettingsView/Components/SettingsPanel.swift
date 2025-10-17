//
//  SettingsPanel.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/5/25.
//
import SwiftUI

struct SettingsPanel<Content: View>: View {
    let title: String
    let description: String
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(title)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding([.bottom], 10)
            
            Spacer()
            
            VStack(alignment: .leading) {
                content()

            }
        }
        .padding(3)
    }
}
