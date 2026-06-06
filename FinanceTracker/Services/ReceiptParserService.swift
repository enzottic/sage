//
//  ReceiptParserService.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/21/26.
//
import Foundation
import UIKit
import Vision
import FoundationModels

@available(iOS 26.0, *)
class ReceiptParserService {
    init() {}

    func parseReceipt(image: UIImage, tags: [ExpenseTag]) async -> ParsedExpense? {
        let text = await recgonizeTextInImage(image: image)
        guard text.isEmpty == false else { return nil }

        return await extractExpenseDataFromText(receiptText: text, tags: tags)
    }

    // Uses the Vision framework to pull text out of the image
    private func recgonizeTextInImage(image: UIImage) async  -> String {
        var text: String = ""
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate

        if let imageData = image.pngData(),
            let results = try? await request.perform(on: imageData) {
            for observation in results {
                let candidate = observation.topCandidates(1)
                if let observedText = candidate.first?.string {
                    text += "\n\(observedText)"
                }
            }
        }

        return text
    }


    // Uses a local AI model from FoundationModels framework to generate a parsed expense object, using the raw text
    // pulled from the receipt as input
    private func extractExpenseDataFromText(receiptText: String, tags: [ExpenseTag]) async -> ParsedExpense? {
        let instructions = Instructions("""
You are an experienced expense categorizer. You are given a string of text that has been recgonized from
an receipt. You are to determine the following information from the text:
1. The total price of the item purchased (MOST IMPORTANT)
2. The name of what was purchased. For example, if you see a grocery receipt, you would note "Groceries". If you see a receipt for a TV, you would say "TV". The name of the store would suffice as well if you cannot determine the exact item or if there are multiple items.
3. The category of what this item/purchase would generally be. There are only two options: Needs or Wants. Needs describe expenses that are needed/must be spent. This includes things like rent, groceries, utility bills, and other payments. Wants are things that are not needed and are leisure spends, such as new devices, eating out, shopping, clothes, etc. Pick which one best fits the receipt.
4. The date the transaction occured on. If no date is found, do NOT provide a date at all.
5. A tag that further describes the expense. You MUST pick EXACTLY ONE tag ONLY from the list provided. DO NOT respond with any other tag other than ones in the provided list that follows 'Available Tags'. If no tags match close enough, do not respond with ANY tag.
""")
        let session = LanguageModelSession(instructions: instructions)
        let prompt = "Receipt Text: \(receiptText). Available Tags: \(tags.compactMap { $0.name }.joined(separator: ","))"
        print(prompt)
        
        do {
            let response = try await session.respond(to: prompt, generating: ParsedExpense.self)
            return response.content
        } catch {
            return nil
        }
    }
}

    
@available(iOS 26.0, *)
@Generable(description: "A collection of details for an expense parsed from a receipt")
struct ParsedExpense {
    @Guide(description: "A short description of the expense, or where the expense came from. You should try to be as descriptive as possible in as little words as possible. For example, if the receipt seems to be a grocery receipt and is from the store 'Safeway', you would respond with 'Safeway'.")
let name: String
    @Guide(description: "The total price of goods stated on the receipt. You may seem an itemized receipt with individual charges, and then a total charge. In general, the price you will note down is the highest price you see from the receipt text.")
    let price: Double
    @Guide(description: "The date the the transaction occured on, in YYYY-MM-DD format. YOU MUST RESPOND IN THIS FORMAT. If no date can be found, do not return a date.")
    let date: String?
    @Guide(description: "The catagory that this expense, in general, would fall into. Must be exactly ONE of the following: Needs, Wants. Needs are considered goods/services that are needed by a person, such as food (groceries, not dining out), rent/mortgage, etc. Wants are things that are not necessary, such as shopping, dining out, etc.")
    let category: String
    @Guide(description: "Users can add optional tags that further describe what bucket an expense falls into. Must be provided exactly as what is described in the list. If no tag matches closely enough, or no tags are provided, do not provide a tag.")
    let tag: String?
}
