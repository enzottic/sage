//
//  ReceiptHandoffService.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/23/26.
//
import UIKit

public struct ReceiptHandoffService {
    private static let groupID = "group.me.enzottic.SageAppGroup"
    private static let fileName = "pendingReceiptImage.jpg"
    
    /// Writes an image to the shared app-group container so a freshly presented
    /// `AddExpenseView` can pick it up via `consumePendingImage()` and parse it.
    @discardableResult
    public static func stashPendingImage(_ image: UIImage) -> Bool {
        guard
            let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)?.appendingPathComponent(fileName),
            let data = image.jpegData(compressionQuality: 0.8)
        else { return false }

        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    public static func consumePendingImage() -> UIImage? {
        guard
            let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)?.appendingPathComponent(fileName),
            let data = try? Data(contentsOf: url),
            let image = UIImage(data: data)
        else {return nil}
        
        try? FileManager.default.removeItem(at: url)
        return image
    }
}

