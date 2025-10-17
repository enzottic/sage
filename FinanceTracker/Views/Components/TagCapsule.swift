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
        case small
        case medium
    }
    
    init(tag: ExpenseTag, _ size: TagCapsuleSize = .small) {
        self.tag = tag
        self.size = size
    }
    
    var body: some View {
        HStack {
            Text("\(tag.emoji) \(tag.rawValue)")
                .foregroundStyle(tag.color)
                .padding(size == .small ? 5 : 10)
                .background(Capsule().fill(tag.color.tertiary).stroke(tag.color))
                .foregroundStyle(.white)
                .font(size == .small ? .caption : .headline)
        }
    }
}

#Preview {
    TagCapsule(tag: ExpenseTag.billsAndUtils, .small)
    TagCapsule(tag: ExpenseTag.billsAndUtils, .medium)
}
