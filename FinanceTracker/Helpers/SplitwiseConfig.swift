//
//  SplitwiseConfig.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/16/26.
//
//  Credentials are injected at build time from FinanceTracker/Config/Secrets.xcconfig
//  (which is gitignored). See Secrets.xcconfig.template for the required keys.
//
import Foundation

enum SplitwiseConfig {
    static let consumerKey: String = {
        Bundle.main.infoDictionary?["SplitwiseConsumerKey"] as? String ?? ""
    }()

    static let consumerSecret: String = {
        Bundle.main.infoDictionary?["SplitwiseConsumerSecret"] as? String ?? ""
    }()

    static let redirectScheme = "sage"
    static let redirectURI    = "sage://splitwise-callback"
}
