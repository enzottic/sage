//
//  EnvironmentInjectionModifier.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/19/26.
//
import SwiftUI
import SwiftData
import SageKit

extension View {
    func environmentInjection(empty: Bool = false) -> some View {
        modifier(EnvironmentInjection(empty))
    }
}

struct EnvironmentInjection: ViewModifier {
    @State var config = AppConfiguration()
    @State var appRouter = AppRouter()
    
    let empty: Bool
    
    init(_ empty: Bool = false) {
        self.empty = empty
    }
    
    func body(content: Content) -> some View {
        content
            .modelContainer(empty ? SageModelContainer.previewEmpty : SageModelContainer.preview)
            .environment(config)
            .environment(appRouter)
            .fontDesign(.rounded)
    }
}
