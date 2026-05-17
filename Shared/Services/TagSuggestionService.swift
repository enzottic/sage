//
//  TagSuggestionService.swift
//  FinanceTracker
//
//  Created by enzo ! on 5/16/26.
//

import Foundation
import FoundationModels

class TagSuggestionService {

    @Generable(description: "A tag suggestion for an expense")
    struct TagSuggestion {
        @Guide(description: "The name of the most appropriate tag from the provided list, exactly as written in the list")
        var tagName: String
    }

    func suggestTag(
        for expenseName: String,
        existingExpenses: [(name: String, tagName: String?)],
        tagNames: [String],
        smartTaggingMode: SmartTaggingMode,
    ) async -> (tagName: String, source: SuggestionSource)? {
        let trimmed = expenseName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tagNames.isEmpty else { return nil }
        
        if let historySuggestion = self.suggestTagFromHistory(trimmed, existingExpenses, tagNames), smartTaggingMode == .history {
            return (historySuggestion, .history)
        }
        
        if smartTaggingMode == .ai || smartTaggingMode == .both {
            if let aiSuggestion = await self.suggestTagWithAI(trimmed, existingExpenses, tagNames) {
                return (aiSuggestion, .ai)
            }
        }

        return nil
    }
    
    private func suggestTagFromHistory(
        _ expenseName: String,
        _ existingExpenses: [(name: String, tagName: String?)],
        _ tagNames: [String]
    ) -> String? {
        if let historyTag = existingExpenses.first(where: {
            $0.name.lowercased() == expenseName.lowercased() && $0.tagName != nil
        })?.tagName {
            if let valid = tagNames.first(where: { $0.lowercased() == historyTag.lowercased() }) {
                return valid
            }
        }
        
        return nil
    }
    
    private func suggestTagWithAI(
        _ expenseName: String,
        _ existingExpenses: [(name: String, tagName: String?)],
        _ tagNames: [String]
    ) async -> String? {
        let model = SystemLanguageModel.default
        guard model.isAvailable else { return nil }
        
        let tagList = tagNames.joined(separator: ", ")
        let instructions = Instructions("""
            You are a tag classifier for a personal expense tracker. \
            Given an expense name, pick the single most appropriate tag from the provided list. \
            You MUST respond with exactly one tag name from the list, spelled exactly as provided. \
            If none fit well, respond with "Other".
            """)
        
        let session = LanguageModelSession(instructions: instructions)
        let prompt = "Expense: \"\(expenseName)\". Available tags: \(tagList)."
        
        do {
            let response = try await session.respond(to: prompt, generating: TagSuggestion.self)
            let suggested = response.content.tagName.trimmingCharacters(in: .whitespacesAndNewlines)
            if let valid = tagNames.first(where: { $0.lowercased() == suggested.lowercased() }) {
                return valid
            }
        } catch {
        }
        
        return nil
    }
}

enum SuggestionSource {
    case history
    case ai
}

