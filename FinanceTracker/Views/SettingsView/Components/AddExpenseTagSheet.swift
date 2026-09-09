//
//  AddExpenseTagSheet.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 10/19/25.
//

import SwiftUI
import SwiftData
import SageKit

struct AddExpenseTagSheet: View {
    @Environment(AppConfiguration.self) private var config
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    var tagToEdit: ExpenseTag? = nil
    var onTagAdded: ((ExpenseTag) -> Void)? = nil

    @State private var name: String = ""
    @State private var color: Color = .gray
    @State private var glyph: TagGlyph = .emoji("💰")

    /// Budgets are opt-in: when this stays off the tag's `budget` is left nil.
    @State private var hasBudget: Bool = false
    /// Held as text rather than a formatted `Double` binding: a currency `TextField(value:format:)`
    /// only commits its parsed value when focus resigns, so tapping "Save" straight from the
    /// keyboard would silently discard what the user typed.
    @State private var budgetText: String = ""

    @State private var showingGlyphPicker: Bool = false
    @State private var saveErrorMessage: String?
    /// The last emoji the user settled on. `emoji` stays populated on the model even while an
    /// icon is showing, so string-only surfaces (Shortcuts, entity subtitles) keep a mark and
    /// clearing the icon later restores something better than the default.
    @State private var fallbackEmoji: String = "💰"
    @State private var showDiscardConfirmation = false
    @State private var initialDraft: TagDraft?

    private var isEditing: Bool { tagToEdit != nil }

    /// The `emoji` / `symbolName` pair to persist for the currently picked glyph.
    private var storedGlyphFields: (emoji: String, symbolName: String?) {
        (glyph.emojiValue ?? fallbackEmoji, glyph.symbolValue)
    }
    
    private let presetColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .blue, .indigo, .purple, .pink
    ]
    
    private var displayName: String {
        name.isEmpty ? "Tag Name" : name
    }
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (!hasBudget || parsedBudget != nil)
    }

    /// Invalid text never clears an existing budget; only turning the toggle off does.
    private var parsedBudget: Double? {
        guard hasBudget else { return nil }
        // Preserve historical precision when only other tag details change.
        if budgetText == initialDraft?.budgetText, let originalBudget = tagToEdit?.budget {
            return originalBudget
        }
        return AmountInput.parse(budgetText, currencyCode: config.ledgerCurrencyCode, requiresPositive: true)
    }

    private var budgetValidationMessage: String {
        return MonetaryAmount.validationMessage(currencyCode: config.ledgerCurrencyCode, requiresPositive: true)
            + " Turn off Monthly Budget to remove the limit."
    }
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button("Cancel") { requestDismissal() }
                    .accessibilityIdentifier("cancel-tag-button")
                Spacer()
            }
            .padding(.horizontal)
            Spacer()

            // Form fields
            VStack(spacing: 16) {
                // Glyph + Name row
                HStack(spacing: 12) {
                    Button {
                        showingGlyphPicker = true
                    } label: {
                        TagGlyphView(glyph)
                            .font(.title2)
                            .foregroundStyle(color)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(color.quaternary))
                    }

                    TextField("Tag Name", text: $name)
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.cardBackground))
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

                Divider()

                // Optional monthly budget
                VStack(spacing: 10) {
                    Toggle(isOn: $hasBudget.animation(.easeInOut(duration: 0.2))) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Monthly Budget")
                                .font(.subheadline)
                            Text("Cap how much you spend on this tag each month")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(color)

                    if hasBudget {
                        HStack(spacing: 4) {
                            Text("Limit")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(config.ledgerCurrencyCode)
                                .foregroundStyle(.secondary)
                            // Fills the row so the whole right side is a tap target.
                            TextField("0.00", text: $budgetText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.cardBackground))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        if parsedBudget == nil {
                            Text(budgetValidationMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(.cardBackground))
            .padding(.horizontal)
            
            // Live preview
            VStack(spacing: 12) {
                Text(glyph: glyph, name: displayName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(name.isEmpty ? color.opacity(0.4) : color)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(color.quaternary))
            }
            .animation(.easeInOut(duration: 0.2), value: color)
            .animation(.easeInOut(duration: 0.2), value: glyph)
            
            Spacer()
            
            // Add / Save button
            Button {
                guard canSave else { return }
                let currencyCode = config.ledgerCurrencyCode
                // Only turning the toggle off clears a previously set cap.
                let resolvedBudget = parsedBudget
                if hasBudget {
                    guard let resolvedBudget,
                          resolvedBudget == tagToEdit?.budget || MonetaryAmount.isValid(resolvedBudget, currencyCode: currencyCode, requiresPositive: true) else {
                        saveErrorMessage = budgetValidationMessage
                        return
                    }
                }
                let stored = storedGlyphFields
                do {
                    if let tag = tagToEdit {
                        tag.name = name
                        tag.uiColor = UIColor(color)
                        tag.emoji = stored.emoji
                        tag.symbolName = stored.symbolName
                        tag.budget = resolvedBudget
                        try modelContext.save()
                    } else {
                        let newExpenseTag = ExpenseTag(name: name, uiColor: UIColor(color), emoji: stored.emoji, symbolName: stored.symbolName, budget: resolvedBudget)
                        modelContext.insert(newExpenseTag)
                        try modelContext.save()
                        onTagAdded?(newExpenseTag)
                    }
                    dismiss()
                } catch {
                    modelContext.rollback()
                    saveErrorMessage = "Syl could not save this tag. Check available storage and try again."
                }
            } label: {
                Text(isEditing ? "Save Tag" : "Add Tag")
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
        .sheet(isPresented: $showingGlyphPicker) {
            TagGlyphPickerSheet(glyph: $glyph, tint: color)
        }
        .alert("Could not save tag", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveErrorMessage ?? "Please try again.")
        }
        .confirmationDialog("Discard changes?", isPresented: $showDiscardConfirmation, titleVisibility: .visible) {
            Button("Discard Changes", role: .destructive) { dismiss() }
                .accessibilityIdentifier("discard-tag-button")
            Button("Keep Editing", role: .cancel) {}
                .accessibilityIdentifier("keep-editing-tag-button")
        } message: {
            Text("Your unsaved tag changes will be lost.")
        }
        .interactiveDismissDisabled(hasChanges)
        .onChange(of: glyph) { _, newValue in
            if case .emoji(let value) = newValue { fallbackEmoji = value }
        }
        .onAppear {
            if let tag = tagToEdit {
                name = tag.name
                glyph = tag.glyph
                fallbackEmoji = tag.emoji
                color = Color(tag.uiColor)
                hasBudget = tag.budget != nil
                budgetText = tag.budget.map { AmountInput.text(for: $0) } ?? ""
            }
            initialDraft = currentDraft
        }
    }

    private var currentDraft: TagDraft {
        TagDraft(name: name, color: UIColor(color), glyph: glyph, hasBudget: hasBudget, budgetText: budgetText)
    }

    private var hasChanges: Bool {
        guard let initialDraft else { return false }
        return currentDraft != initialDraft
    }

    private func requestDismissal() {
        if hasChanges { showDiscardConfirmation = true } else { dismiss() }
    }
}

private struct TagDraft: Equatable {
    let name: String
    let color: UIColor
    let glyph: TagGlyph
    let hasBudget: Bool
    let budgetText: String

    static func == (lhs: TagDraft, rhs: TagDraft) -> Bool {
        lhs.name == rhs.name && lhs.color.isEqual(rhs.color) && lhs.glyph == rhs.glyph
            && lhs.hasBudget == rhs.hasBudget && lhs.budgetText == rhs.budgetText
    }
}

#Preview {
    @Previewable @State var container = try! SageModelContainer.make(for: .previewEmpty)

    AddExpenseTagSheet()
        .modelContainer(container)
        .environment(AppConfiguration.preview)
}
