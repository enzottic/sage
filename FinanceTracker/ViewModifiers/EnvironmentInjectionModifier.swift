//
//  EnvironmentInjectionModifier.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/19/26.
//
import SwiftUI
import SwiftData

extension View {
    func environmentInjection() -> some View {
        modifier(EnvironmentInjection())
    }
}

struct EnvironmentInjection: ViewModifier {
    @State var config = AppConfiguration()
    @State var appRouter = AppRouter()
    
    func body(content: Content) -> some View {
        content
            .modelContainer(previewAppContainer)
            .environment(config)
            .environment(appRouter)
    }
}
