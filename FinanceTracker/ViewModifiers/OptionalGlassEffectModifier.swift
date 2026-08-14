//
//  OptionalGlassEffectModifier.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 6/6/26.
//
import SwiftUI

extension View {
    @ViewBuilder func optionalGlassEffect(in shape: some Shape) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular, in: shape)
        } else {
            self.background(.regularMaterial, in: shape)
        }
    }
}
