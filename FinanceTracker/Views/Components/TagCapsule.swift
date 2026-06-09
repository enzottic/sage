//
//  TagCapsule.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/12/25.
//

import SwiftUI
import SwiftData
import SageKit

struct TagCapsule: View {
    let tag: ExpenseTag?
    let size: TagCapsuleSize
    var aiSuggested: Bool = false

    enum TagCapsuleSize {
        case xsmall
        case small
        case medium
    }
    
    init(tag: ExpenseTag?, _ size: TagCapsuleSize = .small, aiSuggested: Bool = false) {
        self.tag = tag
        self.size = size
        self.aiSuggested = aiSuggested
    }
    
    var verticalPadding: CGFloat {
        switch size {
        case .xsmall: 2
        case .small: 4
        case .medium: 6
        }
    }
    
    var horizontalPadding: CGFloat {
        switch size {
        case .xsmall: 6
        case .small: 8
        case .medium: 12
        }
    }
    
    var font: Font {
        switch size {
        case .xsmall: .caption
        case .small: .footnote
        case .medium: .subheadline
        }
    }

    /// Border thickness scales with capsule size.
    var borderWidth: CGFloat {
        switch size {
        case .xsmall: 1.5
        case .small: 2
        case .medium: 2.5
        }
    }

    @State private var gradientRotation: Double = 0

    var body: some View {
        if let tag, !tag.isDeleted {
            Text("\(tag.emoji) \(tag.name)")
                .foregroundStyle(tag.color)
                .font(font)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .background(Capsule().fill(tag.color.quaternary))
                .accessibilityLabel("Tag: \(tag.name)")
                .overlay {
                    if aiSuggested {
                        Capsule()
                            .strokeBorder(
                                AngularGradient(
                                    colors: [.red, .orange, .yellow, .green, .blue, .purple, .red],
                                    center: .center,
                                    angle: .degrees(gradientRotation)
                                ),
                                lineWidth: borderWidth
                            )
                    }
                }
                .onAppear {
                    if aiSuggested {
                        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                            gradientRotation = 360
                        }
                    }
                }
                .onChange(of: aiSuggested) { _, newValue in
                    if newValue {
                        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                            gradientRotation = 360
                        }
                    } else {
                        withAnimation(.default) {
                            gradientRotation = 0
                        }
                    }
                }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        TagCapsule(tag: ExpenseTag.dining, .xsmall)
        TagCapsule(tag: ExpenseTag.dining, .small)
        TagCapsule(tag: ExpenseTag.dining, .medium)
        TagCapsule(tag: ExpenseTag.dining, .medium, aiSuggested: true)
    }
}
