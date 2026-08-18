//
//  UITestConfiguration.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 8/17/26.
//
import Foundation

enum UITestConfiguration {
    private static let environment = ProcessInfo.processInfo.environment

    static var isEnabled: Bool { environment["SAGE_UI_TESTING"] == "1" }
    static var showsOnboarding: Bool { environment["SAGE_UI_TEST_ONBOARDING"] == "1" }
    static var seedExpenseName: String? { environment["SAGE_UI_TEST_SEED_EXPENSE"] }
}
