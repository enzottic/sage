//
//  PendingReceiptStore.swift
//  SageKit
//

import Foundation

public enum PendingReceiptStore {
    public enum Error: LocalizedError {
        case appGroupUnavailable

        public var errorDescription: String? {
            "The shared app storage is unavailable."
        }
    }

    public static let fileName = "pendingReceiptImage.jpg"

    public static func save(_ data: Data) throws {
        try save(data, in: appGroupDirectory())
    }

    /// Reads and deletes the pending receipt before it is parsed.
    /// This prevents a used or invalid receipt image from staying in app storage.
    public static func take() throws -> Data? {
        try take(from: appGroupDirectory())
    }

    public static func deleteIfPresent() throws {
        try deleteIfPresent(from: appGroupDirectory())
    }

    static func save(_ data: Data, in directory: URL) throws {
        try data.write(to: fileURL(in: directory), options: .atomic)
    }

    static func take(from directory: URL) throws -> Data? {
        let url = fileURL(in: directory)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw error
        }

        try FileManager.default.removeItem(at: url)
        return data
    }

    static func deleteIfPresent(from directory: URL) throws {
        let url = fileURL(in: directory)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    private static func appGroupDirectory() throws -> URL {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SageModelContainer.appGroupIdentifier
        ) else {
            throw Error.appGroupUnavailable
        }

        return containerURL
    }

    private static func fileURL(in directory: URL) -> URL {
        directory.appendingPathComponent(fileName)
    }
}
