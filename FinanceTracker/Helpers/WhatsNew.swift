//
//  WhatsNew.swift
//  FinanceTracker
//
//  The release-notes sheet shown once after the app updates to a new version.
//

import SwiftUI
import SageKit

// MARK: - Content

/// One highlight in a release's What's New sheet.
struct WhatsNewFeature: Identifiable, Hashable {
    let icon: String
    let title: String
    let description: String
    var tint: Color = .sage

    var id: String { "\(icon)-\(title)" }
}

/// The highlights for a single marketing version, looked up by that version string.
struct WhatsNewRelease: Identifiable, Hashable {
    let version: String
    let features: [WhatsNewFeature]

    var id: String { version }
}

/// Every release that has a What's New sheet. A version missing from here shows no sheet at
/// all, so shipping a bug-fix build doesn't require inventing highlights for it.
enum WhatsNewCatalog {
    static let releases: [WhatsNewRelease] = [
        WhatsNewRelease(
            version: "0.9.1",
            features: [
                WhatsNewFeature(
                    icon: "square.grid.2x2.fill",
                    title: "Redesigned Home Screen",
                    description: "Home is now a dashboard of widgets, including a look at your upcoming recurring expenses.",
                    tint: .need
                ),
                WhatsNewFeature(
                    icon: "tag.fill",
                    title: "Multiple Tags per Expense",
                    description: "An expense is no longer limited to a single tag. Add every tag that fits.",
                    tint: .sage
                ),
                WhatsNewFeature(
                    icon: "paintpalette.fill",
                    title: "Icons for Your Tags",
                    description: "Tag glyphs can now be an icon, picked from a searchable icon set.",
                    tint: .want
                )
            ]
        )
    ]

    static func release(for version: String) -> WhatsNewRelease? {
        releases.first { $0.version == version }
    }
}

// MARK: - Persistence

/// Tracks the last version whose What's New sheet the user has seen.
enum WhatsNewStore {
    private static let lastSeenVersionKey = "lastSeenWhatsNewVersion"

    /// Matches where the other local-only flags live (see `AppConfiguration.localDefaults`).
    private static var defaults: UserDefaults { AppConfiguration.localDefaults }

    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    /// The sheet to present on this launch, or `nil` when the current version has already been
    /// seen or has no highlights. Callers present the returned release and immediately
    /// `markCurrentVersionSeen()`, so a swipe-to-dismiss counts as seen just like the button.
    static func releaseToPresent() -> WhatsNewRelease? {
        let current = currentVersion
        guard defaults.string(forKey: lastSeenVersionKey) != current else { return nil }

        guard let release = WhatsNewCatalog.release(for: current) else {
            // No highlights for this version — record it so the sheet doesn't reappear later.
            markCurrentVersionSeen()
            return nil
        }
        return release
    }

    /// Suppresses the sheet for the running version. Called on a fresh install once setup
    /// finishes: everything in the sheet is new to that user already.
    static func markCurrentVersionSeen() {
        defaults.set(currentVersion, forKey: lastSeenVersionKey)
    }
}
