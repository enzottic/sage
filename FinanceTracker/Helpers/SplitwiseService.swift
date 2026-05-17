//
//  SplitwiseService.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/16/26.
//
import Foundation
import Observation

// MARK: - API Models

struct SplitwisePerson: Codable {
    let id: Int
    let firstName: String
    let lastName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
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
        case userId = "user_id"
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
        case groupId = "group_id"
        case deletedAt = "deleted_at"
    }

    func owedAmount(forUserId userId: Int) -> Double {
        users.first(where: { $0.userId == userId })
            .flatMap { Double($0.owedShare) } ?? 0.0
    }
}

// MARK: - Errors

enum SplitwiseError: LocalizedError {
    case invalidResponse(Int)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Invalid API key. Check your Splitwise API key in Settings."
        case .invalidResponse(let code):
            return "Splitwise returned an unexpected response (HTTP \(code))."
        }
    }
}

// MARK: - Service

@Observable
final class SplitwiseService {
    private static let keychainKey = "com.sage.splitwise.apikey"
    private static let userNameKey = "com.sage.splitwise.username"
    private let baseURL = URL(string: "https://secure.splitwise.com/api/v3.0")!

    var apiKey: String {
        didSet {
            if apiKey.isEmpty {
                KeychainHelper.delete(forKey: Self.keychainKey)
            } else {
                KeychainHelper.set(apiKey, forKey: Self.keychainKey)
            }
            currentUserId = nil
        }
    }

    private(set) var currentUserId: Int?
    private(set) var connectedUserName: String?

    var isConfigured: Bool { !apiKey.isEmpty }

    init() {
        self.apiKey = KeychainHelper.get(forKey: Self.keychainKey) ?? ""
        self.connectedUserName = UserDefaults.standard.string(forKey: Self.userNameKey)
    }

    @discardableResult
    func fetchCurrentUser() async throws -> SplitwisePerson {
        let url = baseURL.appendingPathComponent("get_current_user")
        let data = try await request(url: url)
        let response = try Self.decoder.decode(CurrentUserResponse.self, from: data)
        currentUserId = response.user.id
        connectedUserName = response.user.displayName
        UserDefaults.standard.set(response.user.displayName, forKey: Self.userNameKey)
        return response.user
    }

    func disconnect() {
        apiKey = ""
        connectedUserName = nil
        currentUserId = nil
        UserDefaults.standard.removeObject(forKey: Self.userNameKey)
    }

    func fetchExpenses(limit: Int = 30) async throws -> [SplitwiseFetchedExpense] {
        if currentUserId == nil {
            try await fetchCurrentUser()
        }
        var components = URLComponents(
            url: baseURL.appendingPathComponent("get_expenses"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "0")
        ]
        let data = try await request(url: components.url!)
        let response = try Self.decoder.decode(ExpensesResponse.self, from: data)
        return response.expenses.filter { $0.deletedAt == nil }
    }

    private func request(url: URL) async throws -> Data {
        var req = URLRequest(url: url)
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw SplitwiseError.invalidResponse(0)
        }
        if http.statusCode == 401 { throw SplitwiseError.unauthorized }
        guard http.statusCode == 200 else {
            throw SplitwiseError.invalidResponse(http.statusCode)
        }
        return data
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

// MARK: - Response wrappers

private struct CurrentUserResponse: Codable {
    let user: SplitwisePerson
}

private struct ExpensesResponse: Codable {
    let expenses: [SplitwiseFetchedExpense]
}
