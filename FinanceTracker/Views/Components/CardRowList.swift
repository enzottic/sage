//
//  CardRowList.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/24/26.
//

import SwiftUI

struct CardRowList<Item, NavValue: Hashable, Content: View>: View {
    let items: [Item]
    let navigationValue: (Item) -> NavValue
    @ViewBuilder let content: (Item) -> Content

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                NavigationLink(value: navigationValue(item)) {
                    HStack {
                        content(item)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .tint(.primary)

                if index < items.count - 1 {
                    Divider()
                        .padding(.horizontal, 16)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.ui.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
}
