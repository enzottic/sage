//
//  TagPicker.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/15/25.
//

import SwiftUI

struct TagPicker: View {
    @Binding var selectedTag: ExpenseTag
    @State private var isExpanded = false
    
    var body: some View {
        Group {
            if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 10) {
                        ForEach(ExpenseTag.allCases, id: \.self) { option in
                            Button {
                                withAnimation(.easeInOut) {
                                    selectedTag = option
                                    isExpanded = false
                                }
                            } label: {
                                TagCapsule(tag: option, .medium)
                            }
                        }
                    }
                    .padding(2)
                }
//                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Button {
                    withAnimation(.easeInOut) {
                        isExpanded = true
                    }
                } label: {
                    TagCapsule(tag: selectedTag, .medium)
//                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut, value: isExpanded)
    }
}

#Preview {
    @Previewable @State var selectedTag: ExpenseTag = .other
    TagPicker(selectedTag: $selectedTag)
}
