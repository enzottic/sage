//
//  SplitwiseService.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/16/26.
//
import Foundation
import Observation
import AuthenticationServices

// MARK: - API Models

struct SplitwisePerson: Codable {
    let id: Int
    let firstName: String
    let lastName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName  = "last_name"
    }

    var displayName: String {
        [firstName, lastName].compactMap { $0 }.joined(separator: " ")
    }
}

struct SplitwiseExpenseUser: Codable {
    let userId: Int
    let paidShare: String
    let owedShare: String
    let netBalance: String

    enum CodingKeys: String, CodingKey {
        case userId    = "user_id"
        case paidShare = "paid_share"
        case owedShare = "owed_share"
        case netBalance = "net_balance"
    }
}

struct SplitwiseFetchedExpense: Identifiable, Codable {
    let id: Int
    let description: String
    let date: Date
    let cost: String
    let currencyCode: String
    let users: [SplitwiseExpenseUser]
    let groupId: Int?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, description, date, cost, users
        case currencyCode = "currency_code"
        case groupId      = "group_id"
        case deletedAt    = "deleted_at"
    }

    func owedAmount(forUserId userId: Int) -> Double {
        users.first(where: { $0.userId == userId })
            .flatMap { Double($0.owedShare) } ?? 0.0
    }
}

struct SplitwiseGroup: Identifiable, Codable {
    let id: Int
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case id, name
    }
}

struct CreateSplitwiseExpenseRequest: Codable {
    let cost: String
    let description: String
    let groupId: Int
    let splitEqually: Bool

    enum CodingKeys: String, CodingKey {
        case cost, description
        case groupId = "group_id"
        case splitEqually = "split_equally"
    }
}

// MARK: - Errors

enum SplitwiseError: LocalizedError {
    case authCancelled
    case invalidAuthCode
    case tokenExchangeFailed
    case tokenRefreshFailed
    case notAuthenticated
    case invalidResponse(Int)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .authCancelled:        return "Sign-in was cancelled."
        case .invalidAuthCode:      return "Invalid authorisation code from Splitwise."
        case .tokenExchangeFailed:  return "Failed to complete sign-in. Please try again."
        case .tokenRefreshFailed:   return "Your session expired. Please sign in again."
        case .notAuthenticated:     return "Not signed in to Splitwise."
        case .invalidResponse(let code): return "Splitwise returned an unexpected response (HTTP \(code))."
        case .unauthorized:         return "Session expired. Please sign in again."
        }
    }
}

// MARK: - Service

@Observable
final class SplitwiseService {

    // MARK: Storage keys
    private enum Keys {
        static let accessToken   = "com.sage.splitwise.accessToken"
        static let refreshToken  = "com.sage.splitwise.refreshToken"
        static let tokenExpiry   = "com.sage.splitwise.tokenExpiry"
        static let userName      = "com.sage.splitwise.userName"
        static let userId        = "com.sage.splitwise.userId"
    }

    // MARK: Public state
    private(set) var isConnected: Bool
    private(set) var connectedUserName: String?
    private(set) var currentUserId: Int?

    // Alias kept so HomeView / ExpensesView don't need changes
    var isConfigured: Bool { isConnected }

    // MARK: Private token state
    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiresAt: Date?

    // Held strongly during the OAuth browser session
    @ObservationIgnored private var authSession: ASWebAuthenticationSession?
    @ObservationIgnored private var contextProvider: PresentationContextProvider?

    private let baseURL = URL(string: "https://secure.splitwise.com/api/v3.0")!

    // MARK: Init
    init() {
        // One-time migration: promote any existing device-local tokens to synchronizable
        // so they start syncing via iCloud Keychain going forward.
        for key in [Keys.accessToken, Keys.refreshToken] {
            if KeychainHelper.get(forKey: key, synchronizable: true) == nil,
               let existing = KeychainHelper.get(forKey: key, synchronizable: false) {
                KeychainHelper.set(existing, forKey: key, synchronizable: true)
                KeychainHelper.delete(forKey: key, synchronizable: false)
            }
        }

        let token = KeychainHelper.get(forKey: Keys.accessToken, synchronizable: true)
        self.accessToken       = token
        self.isConnected       = token != nil
        self.refreshToken      = KeychainHelper.get(forKey: Keys.refreshToken, synchronizable: true)
        self.connectedUserName = UserDefaults.standard.string(forKey: Keys.userName)
        self.currentUserId     = UserDefaults.standard.object(forKey: Keys.userId) as? Int
        if let ts = UserDefaults.standard.object(forKey: Keys.tokenExpiry) as? Double {
            self.tokenExpiresAt = Date(timeIntervalSince1970: ts)
        }
    }

    // MARK: - OAuth Connect

    func connect() async throws {
        var components = URLComponents(string: "https://secure.splitwise.com/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id",     value: SplitwiseConfig.consumerKey),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri",  value: SplitwiseConfig.redirectURI)
        ]
        guard let authURL = components.url else { throw SplitwiseError.invalidAuthCode }

        // Grab the window anchor on the main actor before entering the continuation
        let anchor = await MainActor.run { self.presentationAnchor }

        // Run the browser session on the main actor
        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let session = ASWebAuthenticationSession(
                    url: authURL,
                    callbackURLScheme: SplitwiseConfig.redirectScheme
                ) { url, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let url {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(throwing: SplitwiseError.authCancelled)
                    }
                }
                let provider = PresentationContextProvider(anchor: anchor)
                session.presentationContextProvider = provider
                session.prefersEphemeralWebBrowserSession = false
                self.authSession = session
                self.contextProvider = provider
                session.start()
            }
        }

        // Extract the authorisation code
        guard let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value
        else { throw SplitwiseError.invalidAuthCode }

        try await exchangeCode(code)
        try await fetchCurrentUser()
    }

    func disconnect() {
        accessToken    = nil
        refreshToken   = nil
        tokenExpiresAt = nil
        isConnected    = false
        connectedUserName = nil
        currentUserId  = nil

        KeychainHelper.delete(forKey: Keys.accessToken,  synchronizable: true)
        KeychainHelper.delete(forKey: Keys.refreshToken, synchronizable: true)
        UserDefaults.standard.removeObject(forKey: Keys.tokenExpiry)
        UserDefaults.standard.removeObject(forKey: Keys.userName)
        UserDefaults.standard.removeObject(forKey: Keys.userId)
    }

    // MARK: - API

    @discardableResult
    func fetchCurrentUser() async throws -> SplitwisePerson {
        let data = try await request(url: baseURL.appendingPathComponent("get_current_user"))
        let response = try Self.decoder.decode(CurrentUserResponse.self, from: data)
        let user = response.user
        currentUserId = user.id
        connectedUserName = user.displayName
        UserDefaults.standard.set(user.id,          forKey: Keys.userId)
        UserDefaults.standard.set(user.displayName, forKey: Keys.userName)
        return user
    }

    func fetchExpenses(limit: Int = 30) async throws -> [SplitwiseFetchedExpense] {
        if currentUserId == nil { try await fetchCurrentUser() }
        var components = URLComponents(
            url: baseURL.appendingPathComponent("get_expenses"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "limit",  value: "\(limit)"),
            URLQueryItem(name: "offset", value: "0")
        ]
        let data = try await request(url: components.url!)
        let response = try Self.decoder.decode(ExpensesResponse.self, from: data)
        return response.expenses.filter { $0.deletedAt == nil }
    }
    
    func fetchGroups() async throws -> [SplitwiseGroup] {
        if currentUserId == nil { try await fetchCurrentUser() }
        let components = URLComponents(
            url: baseURL.appendingPathComponent("get_groups"),
            resolvingAgainstBaseURL: false
        )!
        let data = try await request(url: components.url!)
        let response = try Self.decoder.decode(GroupsResponse.self, from: data)
        print(response)
        return response.groups
    }
    
    func createExpense(req: CreateSplitwiseExpenseRequest) async throws {
        if currentUserId == nil { try await fetchCurrentUser() }
        let components = URLComponents(
            url: baseURL.appendingPathComponent("create_expense"),
            resolvingAgainstBaseURL: false
        )!
        let body = try JSONEncoder().encode(req)
        _ = try await request(url: components.url!, body: body)
    }

    // MARK: - Token Exchange & Refresh

    private func exchangeCode(_ code: String) async throws {
        let params: [String: String] = [
            "grant_type":    "authorization_code",
            "client_id":     SplitwiseConfig.consumerKey,
            "client_secret": SplitwiseConfig.consumerSecret,
            "code":          code,
            "redirect_uri":  SplitwiseConfig.redirectURI
        ]
        let tokenResponse = try await postToTokenEndpoint(params)
        storeTokens(tokenResponse)
    }

    private func refreshAccessToken() async throws {
        guard let rt = refreshToken else { throw SplitwiseError.tokenRefreshFailed }
        let params: [String: String] = [
            "grant_type":    "refresh_token",
            "client_id":     SplitwiseConfig.consumerKey,
            "client_secret": SplitwiseConfig.consumerSecret,
            "refresh_token": rt
        ]
        do {
            let tokenResponse = try await postToTokenEndpoint(params)
            storeTokens(tokenResponse)
        } catch {
            disconnect()
            throw SplitwiseError.tokenRefreshFailed
        }
    }

    private func postToTokenEndpoint(_ params: [String: String]) async throws -> TokenResponse {
        let url = URL(string: "https://secure.splitwise.com/oauth/token")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw SplitwiseError.tokenExchangeFailed
        }
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    private func storeTokens(_ response: TokenResponse) {
        accessToken = response.accessToken
        KeychainHelper.set(response.accessToken, forKey: Keys.accessToken, synchronizable: true)

        if let rt = response.refreshToken {
            refreshToken = rt
            KeychainHelper.set(rt, forKey: Keys.refreshToken, synchronizable: true)
        }

        if let expiresIn = response.expiresIn {
            tokenExpiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
            UserDefaults.standard.set(tokenExpiresAt!.timeIntervalSince1970, forKey: Keys.tokenExpiry)
        }

        isConnected = true
    }

    // MARK: - Internal Request

    private func request(url: URL, body: Data? = nil) async throws -> Data {
        // Proactively refresh if the token is within 60 s of expiry
        if let expiry = tokenExpiresAt, Date() >= expiry.addingTimeInterval(-60), refreshToken != nil {
            try await refreshAccessToken()
        }
        guard let token = accessToken else { throw SplitwiseError.notAuthenticated }

        var req = URLRequest(url: url)
        req.httpMethod = body != nil ? "POST" : "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = body
        }

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw SplitwiseError.invalidResponse(0) }

        if http.statusCode == 401 {
            // Try a one-shot refresh before giving up
            if refreshToken != nil {
                try await refreshAccessToken()
                var retryReq = URLRequest(url: url)
                retryReq.httpMethod = req.httpMethod
                retryReq.setValue("Bearer \(accessToken ?? "")", forHTTPHeaderField: "Authorization")
                retryReq.httpBody = body
                let (retryData, retryResponse) = try await URLSession.shared.data(for: retryReq)
                if let http2 = retryResponse as? HTTPURLResponse, http2.statusCode == 200 { return retryData }
            }
            disconnect()
            throw SplitwiseError.unauthorized
        }

        guard http.statusCode == 200 else { throw SplitwiseError.invalidResponse(http.statusCode) }
        return data
    }

    // MARK: - Helpers

    @MainActor
    private var presentationAnchor: ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            return UIWindow(frame: .zero)
        }
        return windowScene.keyWindow ?? UIWindow(windowScene: windowScene)
    }

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        d.dateDecodingStrategy = .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)
            if let date = withFractional.date(from: string) { return date }
            if let date = plain.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Cannot decode date: \(string)"
            )
        }
        return d
    }()
}

// MARK: - Presentation Context Provider

private final class PresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    let anchor: ASPresentationAnchor
    init(anchor: ASPresentationAnchor) { self.anchor = anchor }
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { anchor }
}

// MARK: - Response models

private struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn    = "expires_in"
    }
}

private struct CurrentUserResponse: Codable {
    let user: SplitwisePerson
}

private struct ExpensesResponse: Codable {
    let expenses: [SplitwiseFetchedExpense]
}

private struct GroupsResponse: Codable {
    let groups: [SplitwiseGroup]
}
