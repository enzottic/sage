//
//  GradientBackgroundModifier.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/13/26.
//
import SwiftUI

struct GradientBackgroundModifier: ViewModifier {
    var color: Color
    
    init(_ color: Color) {
        self.color = color
    }
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            LinearGradient(
                colors: [color.opacity(0.5), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}

extension View {
    func gradientBackground(color: Color = .sage) -> some View {
        modifier(GradientBackgroundModifier(color))
    }
}
