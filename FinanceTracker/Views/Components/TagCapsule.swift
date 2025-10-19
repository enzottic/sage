//
//  TagCapsule.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/12/25.
//

import SwiftUI

struct TagCapsule: View {
    let tag: ExpenseTag
    let size: TagCapsuleSize
    
    enum TagCapsuleSize {
        case xsmall
        case small
        case medium
    }
    
    init(tag: ExpenseTag, _ size: TagCapsuleSize = .small) {
        self.tag = tag
        self.size = size
    }
    
    var padding: CGFloat {
        switch size {
        case .xsmall: 2
        case .small: 5
        case .medium: 10
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
        HStack {
            Text("\(tag.emoji) \(tag.rawValue)")
                .foregroundStyle(tag.color)
                .padding(padding)
                .background(Capsule().fill(tag.color.tertiary).stroke(tag.color))
                .foregroundStyle(.white)
                .font(font)
        }
    }
}

#Preview {
    TagCapsule(tag: ExpenseTag.billsAndUtils, .xsmall)
    TagCapsule(tag: ExpenseTag.billsAndUtils, .small)
    TagCapsule(tag: ExpenseTag.billsAndUtils, .medium)
}
