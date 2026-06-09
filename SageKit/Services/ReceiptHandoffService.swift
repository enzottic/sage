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

