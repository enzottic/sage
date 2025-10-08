//
//  FinanceTrackerWidgetBundle.swift
//  FinanceTrackerWidget
//
//  Created by Tyler McCormick on 10/5/25.
//

import WidgetKit
import SwiftUI

@main
struct SageWidgetBundle: WidgetBundle {
    var body: some Widget {
        ExpenseUtilizationWidget()
        ExpensePieChartWidget()
    }
}
