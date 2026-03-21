//
//  EmojiPicker.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 3/19/26.
//
import SwiftUI

struct EmojiCategory: Identifiable {
    let id = UUID()
    let name: String
    let emojis: [String]
}

struct EmojiPickerView: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var emoji: String
    
    private let categories: [EmojiCategory] = [
        EmojiCategory(name: "Shopping & Retail", emojis: ["🛍️", "🛒", "👗", "👟", "💎"]),
        EmojiCategory(name: "Food & Dining", emojis: ["🍔", "🍕", "☕", "🍽️", "🥗"]),
        EmojiCategory(name: "Entertainment", emojis: ["🍿", "🎮", "🎵", "🎬", "🎭"]),
        EmojiCategory(name: "Home & Utilities", emojis: ["🏠", "💡", "🔧", "🧹", "📦"]),
        EmojiCategory(name: "Transport & Travel", emojis: ["✈️", "🚗", "⛽", "🚌", "🏖️"]),
        EmojiCategory(name: "Health & Fitness", emojis: ["💊", "🏋️", "🧘", "🩺", "❤️"]),
        EmojiCategory(name: "Tech & Subscriptions", emojis: ["💻", "📱", "🎧", "📺", "🔔"]),
        EmojiCategory(name: "Finance & Savings", emojis: ["💰", "🏦", "💳", "📈", "🐖"]),
        EmojiCategory(name: "Education & Work", emojis: ["📚", "🎓", "💼", "✏️", "🔖"]),
        EmojiCategory(name: "Pets & Kids", emojis: ["🐾", "🧸", "🎁", "🎂", "🐶"]),
    ]
    
    private let columns = Array(repeating: GridItem(.adaptive(minimum: 40), spacing: 8), count: 1)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8, pinnedViews: .sectionHeaders) {
                ForEach(categories) { category in
                    Section {
                        ForEach(category.emojis, id: \.self) { emoji in
                            Text(emoji)
                                .font(.largeTitle)
                                .onTapGesture {
                                    self.emoji = emoji
                                    dismiss()
                                }
                        }
                    } header: {
                        Text(category.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                    }
                }
            }
            .padding()
        }
    }
}

struct EmojiPickerViewModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selectedEmoji: String
    
    func body(content: Content) -> some View {
        content
            .popover(isPresented: $isPresented) {
                EmojiPickerView(emoji: $selectedEmoji)
                    .frame(width: 250, height: 350)
                    .presentationCompactAdaptation(.popover)
            }
    }
}

extension View {
    func emojiPicker(isPresented: Binding<Bool>, selectedEmoji: Binding<String>) -> some View {
        modifier(EmojiPickerViewModifier(isPresented: isPresented, selectedEmoji: selectedEmoji))
    }
}

#Preview {
    @Previewable @State var selectedEmoji: String = "😀"
    @Previewable @State var isPresented: Bool = false
    
    Button(selectedEmoji) {
        isPresented.toggle()
    }
    .emojiPicker(isPresented: $isPresented, selectedEmoji: $selectedEmoji)
}

