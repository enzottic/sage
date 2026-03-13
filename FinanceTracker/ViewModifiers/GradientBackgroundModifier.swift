//
//  GradientBackgroundModifier.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/13/26.
//
import SwiftUI

struct GradientBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            LinearGradient(
                colors: [Color.sage.opacity(0.8), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)
            .ignoresSafeArea()
        }
    }
}

extension View {
    func gradientBackground() -> some View {
        modifier(GradientBackgroundModifier())
    }
}
