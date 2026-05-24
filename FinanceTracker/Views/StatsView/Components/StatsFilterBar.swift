//
//  StatsFilterBar.swift
//  FinanceTracker
//
//  Created on 3/13/26.
//

import SwiftUI
import SwiftData

struct StatsFilterBar: View {
    @Environment(\.categoryColors) private var categoryColors
    @Binding var selectedCategory: ExpenseCategory?
    @Binding var selectedTag: ExpenseTag?
    @Query var expenseTags: [ExpenseTag]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterPill("All", tint: Color.ui.sage,
                           isActive: selectedCategory == nil && selectedTag == nil) {
                    withAnimation {
                        selectedCategory = nil
                        selectedTag = nil
                    }
                }

                ForEach(ExpenseCategory.allCases, id: \.self) { category in
                    filterPill(category.rawValue, tint: category.color(in: categoryColors),
                               isActive: selectedCategory == category) {
                        withAnimation {
                            selectedCategory = category
                            selectedTag = nil
                        }
                    }
                }

                ForEach(expenseTags, id: \.id) { tag in
                    if !tag.isDeleted {
                        Button {
                            withAnimation {
                                selectedTag = tag
                                selectedCategory = nil
                            }
                        } label: {
                            TagCapsule(tag: tag, .small)
                                .overlay(
                                    Capsule()
                                        .stroke(tag.color, lineWidth: selectedTag?.id == tag.id ? 2 : 0)
                                )
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func filterPill(_ text: String, tint: Color, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(isActive ? tint.opacity(0.25) : Color.ui.cardBackground))
                .foregroundStyle(isActive ? tint : .secondary)
        }
    }
}

#Preview {
    @Previewable @State var category: ExpenseCategory? = nil
    @Previewable @State var tag: ExpenseTag? = nil
    StatsFilterBar(selectedCategory: $category, selectedTag: $tag)
        .modelContainer(previewAppContainer)
}
