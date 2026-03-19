//
//  TagCapsule.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/12/25.
//

import SwiftUI
import SwiftData

struct TagCapsule: View {
    let tag: ExpenseTag?
    let size: TagCapsuleSize
    
    enum TagCapsuleSize {
        case xsmall
        case small
        case medium
    }
    
    init(tag: ExpenseTag?, _ size: TagCapsuleSize = .small) {
        self.tag = tag
        self.size = size
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
    
    var body: some View {
        if let tag, !tag.isDeleted {
            VStack {
                Text("\(tag.emoji) \(tag.name)")
                    .foregroundStyle(tag.color)
                    .font(font)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                    .background(Capsule().fill(tag.color.quaternary))
            }
        }
    }
}

#Preview {
    TagCapsule(tag: ExpenseTag.dining, .xsmall)
    TagCapsule(tag: ExpenseTag.dining, .small)
    TagCapsule(tag: ExpenseTag.dining, .medium)
}
