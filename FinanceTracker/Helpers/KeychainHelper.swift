//
//  KeychainHelper.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/16/26.
//
import Foundation
import Security

struct KeychainHelper {

    /// Write a string value to the Keychain.
    /// Pass `synchronizable: true` to sync the item across devices via iCloud Keychain.
    static func set(_ value: String, forKey key: String, synchronizable: Bool = false) {
        let data = Data(value.utf8)
        var query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData:   data
        ]
        if synchronizable {
            // kSecAttrAccessibleAfterFirstUnlock is required for synchronizable items —
            // the "ThisDeviceOnly" variants are explicitly disallowed by iCloud Keychain.
            query[kSecAttrSynchronizable] = kCFBooleanTrue
            query[kSecAttrAccessible]     = kSecAttrAccessibleAfterFirstUnlock
        }
        // Delete any existing item (must match the same synchronizable flag)
        var deleteQuery: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        if synchronizable { deleteQuery[kSecAttrSynchronizable] = kCFBooleanTrue }
        SecItemDelete(deleteQuery as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    /// Read a string value from the Keychain.
    static func get(forKey key: String, synchronizable: Bool = false) -> String? {
        var query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        if synchronizable { query[kSecAttrSynchronizable] = kCFBooleanTrue }
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Delete a Keychain item.
    static func delete(forKey key: String, synchronizable: Bool = false) {
        var query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        if synchronizable { query[kSecAttrSynchronizable] = kCFBooleanTrue }
        SecItemDelete(query as CFDictionary)
    }
}
