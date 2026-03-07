//
//  SplitwiseServiceTests.swift
//  FinanceTrackerTests
//
//  Created on 2/22/26.
//

import Testing
import Foundation
@testable import FinanceTracker

// MARK: - Mock URLSession

final class MockURLSession: URLSessionProtocol {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    var lastRequest: URLRequest?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request

        if let error = mockError {
            throw error
        }

        guard let data = mockData, let response = mockResponse else {
            throw URLError(.badServerResponse)
        }

        return (data, response)
    }

    func mockSuccess(json: String, statusCode: Int = 200) {
        mockData = json.data(using: .utf8)
        mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
    }

    func mockFailure(statusCode: Int) {
        mockData = Data()
        mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
    }
}

// MARK: - SplitwiseService Tests

@Suite("SplitwiseService Tests")
struct SplitwiseServiceTests {

    let mockSession: MockURLSession
    let sut: SplitwiseService

    init() {
        mockSession = MockURLSession()
        sut = SplitwiseService(
            clientId: "test_client_id",
            clientSecret: "test_client_secret",
            redirectURI: "testapp://callback",
            urlSession: mockSession,
            keychainEnabled: false
        )
    }

    // MARK: - Authorization URL Tests

    @Test("Authorization URL returns valid URL")
    func authorizationURLReturnsValidURL() {
        let url = sut.getAuthorizationURL()

        #expect(url != nil)
        #expect(url?.host == "secure.splitwise.com")
        #expect(url?.path == "/oauth/authorize")
    }

    @Test("Authorization URL contains required parameters")
    func authorizationURLContainsRequiredParameters() {
        let url = sut.getAuthorizationURL()
        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value) })

        #expect(params["response_type"] == "code")
        #expect(params["client_id"] == "test_client_id")
        #expect(params["redirect_uri"] == "testapp://callback")
        #expect(params["state"] != nil)
    }

    // MARK: - OAuth Callback Tests

    @Test("Handle OAuth callback with valid code exchanges token")
    func handleOAuthCallbackWithValidCodeExchangesToken() async throws {
        let callbackURL = URL(string: "testapp://callback?code=auth_code_123&state=some_state")!

        mockSession.mockSuccess(json: """
            {
                "access_token": "test_access_token",
                "refresh_token": "test_refresh_token",
                "expires_in": 3600
            }
            """)

        try await sut.handleOAuthCallback(url: callbackURL)

        #expect(sut.isAuthenticated)
        #expect(mockSession.lastRequest != nil)
        #expect(mockSession.lastRequest?.httpMethod == "POST")
    }

    @Test("Handle OAuth callback without code throws error")
    func handleOAuthCallbackWithoutCodeThrowsError() async {
        let callbackURL = URL(string: "testapp://callback?error=access_denied")!

        await #expect(throws: SplitwiseServiceError.invalidOAuthCallback) {
            try await sut.handleOAuthCallback(url: callbackURL)
        }
    }

    // MARK: - isAuthenticated Tests

    @Test("isAuthenticated returns false when no token")
    func isAuthenticatedReturnsFalseWhenNoToken() {
        #expect(!sut.isAuthenticated)
    }

    @Test("isAuthenticated returns true when token set")
    func isAuthenticatedReturnsTrueWhenTokenSet() {
        sut.setTokens(accessToken: "test_token", refreshToken: nil)

        #expect(sut.isAuthenticated)
    }

    // MARK: - GetExpenses Tests

    @Test("getExpenses returns expenses when authenticated")
    func getExpensesReturnsExpensesWhenAuthenticated() async throws {
        sut.setTokens(accessToken: "test_token", refreshToken: nil)

        mockSession.mockSuccess(json: """
            {
                "expenses": [
                    {
                        "id": 1,
                        "group_id": 100,
                        "description": "Dinner",
                        "cost": "50.00",
                        "currency_code": "USD",
                        "date": "2026-02-20",
                        "created_at": "2026-02-20T12:00:00Z",
                        "updated_at": "2026-02-20T12:00:00Z",
                        "deleted_at": null,
                        "category": {
                            "id": 1,
                            "name": "Food"
                        },
                        "users": [
                            {
                                "user_id": 1,
                                "paid_share": "50.00",
                                "owed_share": "25.00",
                                "net_balance": "25.00"
                            }
                        ]
                    }
                ]
            }
            """)

        let expenses = try await sut.getExpenses()

        #expect(expenses.count == 1)
        #expect(expenses[0].id == 1)
        #expect(expenses[0].description == "Dinner")
        #expect(expenses[0].cost == "50.00")
        #expect(expenses[0].currencyCode == "USD")
        #expect(expenses[0].category?.name == "Food")
    }

    @Test("getExpenses throws error when not authenticated")
    func getExpensesThrowsErrorWhenNotAuthenticated() async {
        await #expect(throws: SplitwiseServiceError.notAuthenticated) {
            _ = try await sut.getExpenses()
        }
    }

    @Test("getExpenses includes query parameters when filters provided")
    func getExpensesIncludesQueryParametersWhenFiltersProvided() async throws {
        sut.setTokens(accessToken: "test_token", refreshToken: nil)

        mockSession.mockSuccess(json: """
            {"expenses": []}
            """)

        let dateAfter = ISO8601DateFormatter().date(from: "2026-01-01T00:00:00Z")!

        _ = try await sut.getExpenses(groupId: 123, friendId: 456, datedAfter: dateAfter, limit: 50, offset: 10)

        let requestURL = mockSession.lastRequest?.url?.absoluteString ?? ""
        #expect(requestURL.contains("group_id=123"))
        #expect(requestURL.contains("friend_id=456"))
        #expect(requestURL.contains("limit=50"))
        #expect(requestURL.contains("offset=10"))
        #expect(requestURL.contains("dated_after="))
    }

    // MARK: - GetCurrentUser Tests

    @Test("getCurrentUser returns user")
    func getCurrentUserReturnsUser() async throws {
        sut.setTokens(accessToken: "test_token", refreshToken: nil)

        mockSession.mockSuccess(json: """
            {
                "user": {
                    "id": 123,
                    "first_name": "John",
                    "last_name": "Doe",
                    "email": "john@example.com",
                    "default_currency": "USD"
                }
            }
            """)

        let user = try await sut.getCurrentUser()

        #expect(user.id == 123)
        #expect(user.firstName == "John")
        #expect(user.lastName == "Doe")
        #expect(user.email == "john@example.com")
        #expect(user.fullName == "John Doe")
    }

    // MARK: - GetGroups Tests

    @Test("getGroups returns groups")
    func getGroupsReturnsGroups() async throws {
        sut.setTokens(accessToken: "test_token", refreshToken: nil)

        mockSession.mockSuccess(json: """
            {
                "groups": [
                    {
                        "id": 1,
                        "name": "Roommates",
                        "created_at": "2026-01-01T00:00:00Z",
                        "updated_at": "2026-01-15T00:00:00Z",
                        "members": [
                            {
                                "id": 123,
                                "first_name": "John",
                                "last_name": "Doe"
                            }
                        ]
                    }
                ]
            }
            """)

        let groups = try await sut.getGroups()

        #expect(groups.count == 1)
        #expect(groups[0].id == 1)
        #expect(groups[0].name == "Roommates")
        #expect(groups[0].members?.count == 1)
    }

    // MARK: - HTTP Error Tests

    @Test("getExpenses throws HTTP error on server error")
    func getExpensesThrowsHTTPErrorOnServerError() async {
        sut.setTokens(accessToken: "test_token", refreshToken: nil)

        mockSession.mockFailure(statusCode: 500)

        await #expect {
            _ = try await sut.getExpenses()
        } throws: { error in
            guard let serviceError = error as? SplitwiseServiceError,
                  case .httpError(let code) = serviceError else {
                return false
            }
            return code == 500
        }
    }

    // MARK: - Logout Tests

    @Test("logout clears tokens")
    func logoutClearsTokens() {
        sut.setTokens(accessToken: "test_token", refreshToken: "refresh_token")
        #expect(sut.isAuthenticated)

        sut.logout()

        #expect(!sut.isAuthenticated)
    }

    // MARK: - Request Headers Tests

    @Test("Authenticated request includes bearer token")
    func authenticatedRequestIncludesBearerToken() async throws {
        sut.setTokens(accessToken: "my_access_token", refreshToken: nil)

        mockSession.mockSuccess(json: """
            {"expenses": []}
            """)

        _ = try await sut.getExpenses()

        let authHeader = mockSession.lastRequest?.value(forHTTPHeaderField: "Authorization")
        #expect(authHeader == "Bearer my_access_token")
    }

    @Test("Authenticated request includes content type JSON")
    func authenticatedRequestIncludesContentTypeJSON() async throws {
        sut.setTokens(accessToken: "test_token", refreshToken: nil)

        mockSession.mockSuccess(json: """
            {"expenses": []}
            """)

        _ = try await sut.getExpenses()

        let contentType = mockSession.lastRequest?.value(forHTTPHeaderField: "Content-Type")
        #expect(contentType == "application/json")
    }
}

// MARK: - Model Tests

@Suite("Splitwise Model Tests")
struct SplitwiseModelTests {

    @Test("Expense costAsDecimal parses correctly")
    func expenseCostAsDecimalParsesCorrectly() throws {
        let json = """
            {
                "id": 1,
                "description": "Test",
                "cost": "123.45",
                "currency_code": "USD",
                "date": "2026-02-20",
                "created_at": "2026-02-20T12:00:00Z",
                "updated_at": "2026-02-20T12:00:00Z",
                "users": []
            }
            """.data(using: .utf8)!

        let expense = try JSONDecoder().decode(SplitwiseExpense.self, from: json)

        #expect(expense.costAsDecimal == Decimal(string: "123.45"))
    }

    @Test("Expense parsedDate parses correctly")
    func expenseParsedDateParsesCorrectly() throws {
        let json = """
            {
                "id": 1,
                "description": "Test",
                "cost": "10.00",
                "currency_code": "USD",
                "date": "2026-02-20",
                "created_at": "2026-02-20T12:00:00Z",
                "updated_at": "2026-02-20T12:00:00Z",
                "users": []
            }
            """.data(using: .utf8)!

        let expense = try JSONDecoder().decode(SplitwiseExpense.self, from: json)

        #expect(expense.parsedDate != nil)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: expense.parsedDate!)
        #expect(components.year == 2026)
        #expect(components.month == 2)
        #expect(components.day == 20)
    }

    @Test("User fullName with last name")
    func userFullNameWithLastName() throws {
        let json = """
            {
                "id": 1,
                "first_name": "Jane",
                "last_name": "Smith"
            }
            """.data(using: .utf8)!

        let user = try JSONDecoder().decode(SplitwiseUser.self, from: json)

        #expect(user.fullName == "Jane Smith")
    }

    @Test("User fullName without last name")
    func userFullNameWithoutLastName() throws {
        let json = """
            {
                "id": 1,
                "first_name": "Jane"
            }
            """.data(using: .utf8)!

        let user = try JSONDecoder().decode(SplitwiseUser.self, from: json)

        #expect(user.fullName == "Jane")
    }
}

// MARK: - Error Tests

@Suite("SplitwiseServiceError Tests")
struct SplitwiseServiceErrorTests {

    @Test("Error descriptions are correct")
    func errorDescriptionsAreCorrect() {
        #expect(SplitwiseServiceError.invalidURL.errorDescription == "Invalid URL")
        #expect(SplitwiseServiceError.notAuthenticated.errorDescription == "Not authenticated. Please log in to Splitwise.")
        #expect(SplitwiseServiceError.invalidResponse.errorDescription == "Invalid response from server")
        #expect(SplitwiseServiceError.httpError(404).errorDescription == "HTTP error: 404")
        #expect(SplitwiseServiceError.invalidOAuthCallback.errorDescription == "Invalid OAuth callback URL")
        #expect(SplitwiseServiceError.tokenExchangeFailed.errorDescription == "Failed to exchange authorization code for token")
        #expect(SplitwiseServiceError.tokenRefreshFailed.errorDescription == "Failed to refresh access token")
    }
}

// MARK: - Equatable for Testing

extension SplitwiseServiceError: Equatable {
    public static func == (lhs: SplitwiseServiceError, rhs: SplitwiseServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.notAuthenticated, .notAuthenticated),
             (.invalidResponse, .invalidResponse),
             (.invalidOAuthCallback, .invalidOAuthCallback),
             (.tokenExchangeFailed, .tokenExchangeFailed),
             (.tokenRefreshFailed, .tokenRefreshFailed):
            return true
        case (.httpError(let a), .httpError(let b)):
            return a == b
        default:
            return false
        }
    }
}
