//
//  Item.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 9/21/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
