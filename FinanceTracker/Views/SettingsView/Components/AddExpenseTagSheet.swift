//
//  AddExpenseTagSheet.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/19/25.
//

import SwiftUI
import SwiftData

struct AddExpenseTagSheet: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    var onTagAdded: ((ExpenseTag) -> Void)? = nil
    
    @State private var name: String = ""
    @State private var color: Color = .gray
    @State private var emoji: String = "💰"
    
    @State private var emojiPickerPresented: Bool = false
    
    private let presetColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .blue, .indigo, .purple, .pink
    ]
    
    private var displayName: String {
        name.isEmpty ? "Tag Name" : name
    }
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Form fields
            VStack(spacing: 16) {
                // Emoji + Name row
                HStack(spacing: 12) {
                    Button {
                        emojiPickerPresented.toggle()
                    } label: {
                        Text(emoji)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(color.quaternary))
                    }
                    .emojiPicker(
                        isPresented: $emojiPickerPresented,
                        selectedEmoji: $emoji
                    )
                    
                    TextField("Tag Name", text: $name)
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.ui.cardBackground))
                }
               
                // Color presets
                HStack(spacing: 0) {
                    ForEach(presetColors, id: \.self) { preset in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                color = preset
                            }
                        } label: {
                            Circle()
                                .fill(preset)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: color == preset ? 2.5 : 0)
                                        .padding(-2)
                                )
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    ColorPicker("", selection: $color)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.ui.cardBackground))
            .padding(.horizontal)
            
            // Live preview
            VStack(spacing: 12) {
                Text("\(emoji) \(displayName)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(name.isEmpty ? color.opacity(0.4) : color)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(color.quaternary))
            }
            .animation(.easeInOut(duration: 0.2), value: color)
            .animation(.easeInOut(duration: 0.2), value: emoji)
            
            Spacer()
            
            // Add button
            Button {
                let newExpenseTag = ExpenseTag(name: name, uiColor: UIColor(color), emoji: emoji)
                modelContext.insert(newExpenseTag)
                try? modelContext.save()
                onTagAdded?(newExpenseTag)
                dismiss()
            } label: {
                Text("Add Tag")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(color)
            .disabled(!canSave)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

#Preview {
    AddExpenseTagSheet()
}
