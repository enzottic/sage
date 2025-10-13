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
        ZStack {
            Text(String(tag.rawValue))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(tag.color))
                .foregroundStyle(.white)
                .font(.footnote)
        }
    }
}

#Preview {
    TagCapsule(tag: ExpenseTag.billsAndUtils)
}
