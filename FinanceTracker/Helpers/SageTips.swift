//
//  SageTips.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 8/18/26.
//
import SwiftUI
import TipKit

struct AddExpenseTip: Tip {
    var title: Text {
        Text("Add a New Expense")
    }
    
    var message: Text? {
        Text("Use this button to add a new expense")
    }
    
    var image: Image? {
        Image(systemName: "lightbulb.fill")
    }
}

struct ParseReceiptTip: Tip {
    var title: Text {
        Text("Parse from Receipt")
    }
    
    var message: Text? {
        Text("You can also create an expense using a picture of a receipt")
    }
    
    var image: Image? {
        Image(systemName: "receipt.fill")
    }
}
