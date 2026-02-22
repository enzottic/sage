//
//  SplitwiseService.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 1/18/26.
//
import Foundation
import Security

// MARK: - URLSession Protocol for Testing

protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

// MARK: - SplitwiseService

class SplitwiseService {
    static let shared = SplitwiseService()

    private let baseUrl = "https://secure.splitwise.com/api/v3.0/"
    private let oauthUrl = "https://secure.splitwise.com/oauth/"

    private var accessToken: String?
    private var refreshToken: String?

    private let clientId: String
    private let clientSecret: String
    private let redirectURI: String

    private let keychainServiceName = "com.financetracker.splitwise"
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"

    private let urlSession: URLSessionProtocol
    private let keychainEnabled: Bool

    private convenience init() {
        self.init(
            clientId: "your_client_id",
            clientSecret: "your_client_secret",
            redirectURI: "financetracker://splitwise-callback",
            urlSession: URLSession.shared,
            keychainEnabled: true
        )
    }

    init(
        clientId: String,
        clientSecret: String,
        redirectURI: String,
        urlSession: URLSessionProtocol = URLSession.shared,
        keychainEnabled: Bool = true
    ) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
        self.urlSession = urlSession
        self.keychainEnabled = keychainEnabled

        if keychainEnabled {
            loadTokensFromKeychain()
        }
    }

    // For testing: allows setting tokens directly
    func setTokens(accessToken: String?, refreshToken: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    // MARK: - Public API

    var isAuthenticated: Bool {
        return accessToken != nil
    }

    func getAuthorizationURL() -> URL? {
        var components = URLComponents(string: oauthUrl + "authorize")
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "state", value: UUID().uuidString)
        ]
        return components?.url
    }

    func handleOAuthCallback(url: URL) async throws {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw SplitwiseServiceError.invalidOAuthCallback
        }

        try await exchangeCodeForToken(code: code)
    }

    func getExpenses(
        groupId: Int? = nil,
        friendId: Int? = nil,
        datedAfter: Date? = nil,
        datedBefore: Date? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [SplitwiseExpense] {
        var queryItems: [String] = []

        if let groupId = groupId {
            queryItems.append("group_id=\(groupId)")
        }
        if let friendId = friendId {
            queryItems.append("friend_id=\(friendId)")
        }
        if let datedAfter = datedAfter {
            queryItems.append("dated_after=\(ISO8601DateFormatter().string(from: datedAfter))")
        }
        if let datedBefore = datedBefore {
            queryItems.append("dated_before=\(ISO8601DateFormatter().string(from: datedBefore))")
        }
        queryItems.append("limit=\(limit)")
        queryItems.append("offset=\(offset)")

        let endpoint = "get_expenses?" + queryItems.joined(separator: "&")
        let response: SplitwiseExpensesResponse = try await makeAuthenticatedRequest(endpoint: endpoint, method: "GET")
        return response.expenses
    }

    func getCurrentUser() async throws -> SplitwiseUser {
        let response: SplitwiseCurrentUserResponse = try await makeAuthenticatedRequest(endpoint: "get_current_user", method: "GET")
        return response.user
    }

    func getGroups() async throws -> [SplitwiseGroup] {
        let response: SplitwiseGroupsResponse = try await makeAuthenticatedRequest(endpoint: "get_groups", method: "GET")
        return response.groups
    }

    func logout() {
        accessToken = nil
        refreshToken = nil
        if keychainEnabled {
            deleteTokensFromKeychain()
        }
    }
    
    private func makeAuthenticatedRequest<T: Decodable>(
        endpoint: String,
        method: String,
        body: Data? = nil
    ) async throws -> T {
         try ensureValidToken()
        
        guard let url = URL(string: baseUrl + endpoint) else {
            throw SplitwiseServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        let (data, response) = try await urlSession.data(for: request)
                
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SplitwiseServiceError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            // Token expired, refresh and retry
            try await refreshAccessToken()
            return try await makeAuthenticatedRequest(endpoint: endpoint, method: method, body: body)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw SplitwiseServiceError.httpError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    private func exchangeCodeForToken(code: String) async throws {
        guard let url = URL(string: oauthUrl + "token") else {
            throw SplitwiseServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "grant_type=authorization_code",
            "code=\(code)",
            "client_id=\(clientId)",
            "client_secret=\(clientSecret)",
            "redirect_uri=\(redirectURI)"
        ].joined(separator: "&")

        request.httpBody = bodyParams.data(using: .utf8)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SplitwiseServiceError.tokenExchangeFailed
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        self.accessToken = tokenResponse.accessToken
        self.refreshToken = tokenResponse.refreshToken
        if keychainEnabled {
            saveTokensToKeychain()
        }
    }

    private func refreshAccessToken() async throws {
        guard let refreshToken = refreshToken else {
            throw SplitwiseServiceError.notAuthenticated
        }

        guard let url = URL(string: oauthUrl + "token") else {
            throw SplitwiseServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "grant_type=refresh_token",
            "refresh_token=\(refreshToken)",
            "client_id=\(clientId)",
            "client_secret=\(clientSecret)"
        ].joined(separator: "&")

        request.httpBody = bodyParams.data(using: .utf8)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SplitwiseServiceError.tokenRefreshFailed
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        self.accessToken = tokenResponse.accessToken
        self.refreshToken = tokenResponse.refreshToken
        if keychainEnabled {
            saveTokensToKeychain()
        }
    }

    private func ensureValidToken() throws {
        if accessToken == nil {
            throw SplitwiseServiceError.notAuthenticated
        }
    }

    // MARK: - Keychain

    private func saveTokensToKeychain() {
        if let accessToken = accessToken {
            saveToKeychain(key: accessTokenKey, value: accessToken)
        }
        if let refreshToken = refreshToken {
            saveToKeychain(key: refreshTokenKey, value: refreshToken)
        }
    }

    private func loadTokensFromKeychain() {
        accessToken = loadFromKeychain(key: accessTokenKey)
        refreshToken = loadFromKeychain(key: refreshTokenKey)
    }

    private func deleteTokensFromKeychain() {
        deleteFromKeychain(key: accessTokenKey)
        deleteFromKeychain(key: refreshTokenKey)
    }

    private func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)

        var newItem = query
        newItem[kSecValueData as String] = data

        SecItemAdd(newItem as CFDictionary, nil)
    }

    private func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Token Response

struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

// MARK: - API Response Models

struct SplitwiseExpensesResponse: Decodable {
    let expenses: [SplitwiseExpense]
}

struct SplitwiseCurrentUserResponse: Decodable {
    let user: SplitwiseUser
}

struct SplitwiseGroupsResponse: Decodable {
    let groups: [SplitwiseGroup]
}

// MARK: - Splitwise Models

struct SplitwiseExpense: Decodable, Identifiable {
    let id: Int
    let groupId: Int?
    let description: String
    let cost: String
    let currencyCode: String
    let date: String
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?
    let category: SplitwiseCategory?
    let users: [SplitwiseExpenseUser]

    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case description
        case cost
        case currencyCode = "currency_code"
        case date
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case category
        case users
    }

    var costAsDecimal: Decimal? {
        Decimal(string: cost)
    }

    var parsedDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: date)
    }
}

struct SplitwiseCategory: Decodable {
    let id: Int
    let name: String
}

struct SplitwiseExpenseUser: Decodable {
    let userId: Int
    let paidShare: String
    let owedShare: String
    let netBalance: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case paidShare = "paid_share"
        case owedShare = "owed_share"
        case netBalance = "net_balance"
    }
}

struct SplitwiseUser: Decodable, Identifiable {
    let id: Int
    let firstName: String
    let lastName: String?
    let email: String?
    let defaultCurrency: String?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case defaultCurrency = "default_currency"
    }

    var fullName: String {
        [firstName, lastName].compactMap { $0 }.joined(separator: " ")
    }
}

struct SplitwiseGroup: Decodable, Identifiable {
    let id: Int
    let name: String
    let createdAt: String
    let updatedAt: String
    let members: [SplitwiseUser]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case members
    }
}

// MARK: - Errors

enum SplitwiseServiceError: Error, LocalizedError {
    case invalidURL
    case notAuthenticated
    case invalidResponse
    case httpError(Int)
    case invalidOAuthCallback
    case tokenExchangeFailed
    case tokenRefreshFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .notAuthenticated:
            return "Not authenticated. Please log in to Splitwise."
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .invalidOAuthCallback:
            return "Invalid OAuth callback URL"
        case .tokenExchangeFailed:
            return "Failed to exchange authorization code for token"
        case .tokenRefreshFailed:
            return "Failed to refresh access token"
        }
    }
}

