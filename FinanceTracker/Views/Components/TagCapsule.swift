//
//  TagCapsule.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/12/25.
//

import SwiftUI

struct TagCapsule: View {
    let tag: ExpenseTag
    
    var body: some View {
        HStack {
            Text("\(tag.emoji) \(tag.rawValue)")
                .foregroundStyle(tag.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(tag.color.tertiary).stroke(tag.color))
                .foregroundStyle(.white)
                .font(.caption)
        }
    }
}

#Preview {
    TagCapsule(tag: ExpenseTag.billsAndUtils)
}
