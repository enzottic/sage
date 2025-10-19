//
//  TagPicker.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/15/25.
//

import SwiftUI
import SwiftData

struct TagPicker: View {
    @Binding var selectedTag: ExpenseTag?
    @State private var isExpanded = false
    
    @Query var expenseTags: [ExpenseTag]
    
    var body: some View {
        Group {
            if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 10) {
                        ForEach(expenseTags, id: \.self) { option in
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
            } else {
                Button {
                    withAnimation(.easeInOut) {
                        isExpanded = true
                    }
                } label: {
                    TagCapsule(tag: selectedTag, .medium)
                }
            }
        }
        .animation(.easeInOut, value: isExpanded)
    }
}

#Preview {
    @Previewable @State var selectedTag: ExpenseTag? = .dining
    TagPicker(selectedTag: $selectedTag)
        .modelContainer(ModelContainer.preview)
}
