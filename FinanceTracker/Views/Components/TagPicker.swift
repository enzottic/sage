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
    
    @State private var newTagSheetIsPresented: Bool = false
    
    @Query(sort: \ExpenseTag.name) var expenseTags: [ExpenseTag]
    
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
                        
                        Button {
                            newTagSheetIsPresented.toggle()
                        } label: {
                            Image(systemName: "plus")
                                .accessibilityLabel(Text("Add new tag"))
                        }
                    }
                    .padding(2)
                    .padding(.horizontal, 8)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    Button {
                        withAnimation(.easeInOut) {
                            isExpanded = true
                        }
                    } label: {
                        if selectedTag == nil {
                            Text("Add a Tag")
                        } else {
                            TagCapsule(tag: selectedTag, .medium)
                        }
                    }
                    .padding(2)
                    .containerRelativeFrame(.horizontal)
                }
            }
        }
        .animation(.easeInOut, value: isExpanded)
        .sheet(isPresented: $newTagSheetIsPresented) {
            AddExpenseTagSheet { newTag in
                selectedTag = newTag
                isExpanded = false
            }
        }

    }
}

#Preview {
    @Previewable @State var selectedTag: ExpenseTag? = .dining
    TagPicker(selectedTag: $selectedTag)
        .modelContainer(previewAppContainer)
}
