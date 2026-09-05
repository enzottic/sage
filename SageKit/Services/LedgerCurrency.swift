import Foundation

/// One denomination for all expenses, recurring rules, and budgets. Never converts amounts.
public enum LedgerCurrency {
    #if DEBUG
    public static let storageKey = "dev.ledgerCurrencyCode"
    #else
    public static let storageKey = "ledgerCurrencyCode"
    #endif

    public static let supportedCodes = Locale.commonISOCurrencyCodes.sorted()
    public static var cloudConflictKey: String { storageKey + ".conflict" }

    public enum Error: LocalizedError, Equatable {
        case invalidCode(String)
        case notEstablished
        case alreadyEstablished(String)
        case storageUnavailable
        case cloudConflict

        public var errorDescription: String? {
            switch self {
            case .invalidCode(let code): "Choose a supported ISO currency code instead of '\(code)'."
            case .notEstablished: "Open Sage and confirm the currency for your expenses and budgets first."
            case .alreadyEstablished(let code): "This ledger already uses \(code). Sage does not convert currencies."
            case .storageUnavailable: "Sage could not access the shared currency setting. Try opening the app again."
            case .cloudConflict: "Your devices disagree about the ledger currency. Resolve the currency conflict before saving monetary changes. Sage does not convert currencies."
            }
        }
    }

    public static func validatedCode(_ code: String?) -> String? {
        guard let code, supportedCodes.contains(code) else { return nil }
        return code
    }

    public static func suggestedCode(locale: Locale = .current) -> String {
        validatedCode(locale.currency?.identifier) ?? "USD"
    }

    public static var currentCode: String? {
        // UI tests use an in-memory ledger and must not change the real shared setting.
        if ProcessInfo.processInfo.environment["SAGE_UI_TESTING"] == "1" { return "USD" }
        return persistedCode()
    }

    public static func persistedCode(
        defaults: UserDefaults? = UserDefaults(suiteName: SageModelContainer.appGroupIdentifier)
    ) -> String? {
        validatedCode(defaults?.string(forKey: storageKey))
    }

    public static func requireCode() throws -> String {
        if ProcessInfo.processInfo.environment["SAGE_UI_TESTING"] != "1",
           UserDefaults(suiteName: SageModelContainer.appGroupIdentifier)?.bool(forKey: cloudConflictKey) == true {
            throw Error.cloudConflict
        }
        guard let code = currentCode else { throw Error.notEstablished }
        return code
    }

    public static func establish(
        _ code: String,
        defaults: UserDefaults? = UserDefaults(suiteName: SageModelContainer.appGroupIdentifier)
    ) throws {
        guard validatedCode(code) != nil else { throw Error.invalidCode(code) }
        guard let defaults else { throw Error.storageUnavailable }
        if let existing = persistedCode(defaults: defaults), existing != code {
            throw Error.alreadyEstablished(existing)
        }
        defaults.set(code, forKey: storageKey)
    }

    /// Call only after successfully deleting all monetary data and settings.
    public static func reset(
        defaults: UserDefaults? = UserDefaults(suiteName: SageModelContainer.appGroupIdentifier)
    ) {
        defaults?.removeObject(forKey: storageKey)
        defaults?.removeObject(forKey: cloudConflictKey)
    }

    public static func fractionDigits(for code: String) -> Int {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.maximumFractionDigits
    }
}
