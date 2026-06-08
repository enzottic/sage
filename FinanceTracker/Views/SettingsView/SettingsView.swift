//
//  SettingsViewNew.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/18/26.
//
import SwiftUI
import SwiftData
import WebKit
import Darwin

struct SettingsView: View {
    @Environment(AppConfiguration.self) private var config: AppConfiguration
    @Environment(AppRouter.self) private var router: AppRouter

    private var feedbackURL: URL {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let ios = UIDevice.current.systemVersion
        let body = "\n\n\n--- Please do not remove the info below ---\nSage \(version) (\(build)) · iOS \(ios) · \(Self.deviceModel)"
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "hi@enzottic.me"
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Sage Feedback"),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url!
    }

    private static var deviceModel: String {
        #if targetEnvironment(simulator)
        return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "Simulator"
        #else
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
        #endif
    }

    var body: some View {
        NavigationStack(path: Bindable(router.settingsRouter).navigationPath) {
            List {

                Section {
                    let page = SettingsPage.appearance
                    NavigationLink(value: page) {
                        SettingsListItem(text: page.rawValue, icon: page.icon, color: page.color)
                    }
                }

                Section {
                    ForEach([SettingsPage.budget, .recurringExpenses, .tags], id: \.self) { page in
                        NavigationLink(value: page) {
                            SettingsListItem(text: page.rawValue, icon: page.icon, color: page.color)
                        }
                    }
                }

                Section {
                    ForEach([SettingsPage.backup, .splitwise], id: \.self) { page in
                        NavigationLink(value: page) {
                            SettingsListItem(text: page.rawValue, icon: page.icon, color: page.color)
                        }
                    }
                }

                Section {
                    Link(destination: feedbackURL) {
                        SettingsListItem(text: "Feedback", icon: "envelope.fill", color: .yellow)
                    }
                    let page = SettingsPage.privacy
                    NavigationLink(value: page) {
                        SettingsListItem(text: page.rawValue, icon: page.icon, color: page.color)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationDestination(for: SettingsPage.self) { page in
                switch page {
                case .appearance:
                    AppearanceSettingsSection()
                case .budget:
                    BudgetSettingsSection()
                case .recurringExpenses:
                    RecurringExpensesSettingsSection()
                case .tags:
                    TagsSettingsSection()
                case .backup:
                    ExpenseBackupSettingsSection()
                case .splitwise:
                    SplitwiseSettingsSection()
                case .privacy:
                    PrivacyWebView()
                }
            }
        }
    }
}

struct SettingsListItem: View {
    let text: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            if #available(iOS 26.0, *) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 35, height: 35)
                        .foregroundStyle(color)
                    Image(systemName: icon)
                        .foregroundStyle(.white)
                        .fontWeight(.black)
                }
                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 10))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 35, height: 35)
                        .foregroundStyle(color)
                    Image(systemName: icon)
                        .foregroundStyle(.white)
                        .fontWeight(.black)
                }
            }
            Text(text)
        }
    }
}

enum SettingsPage: String, Hashable, CaseIterable {
    case appearance = "Appearance"
    case budget = "Budget and Allocation"
    case recurringExpenses = "Recurring Expenses"
    case tags = "Tags"
    case backup = "Backup"
    case splitwise = "Splitwise"
    case privacy = "Privacy"

    var icon: String {
        switch self {
        case .appearance: "paintpalette.fill"
        case .budget: "chart.bar.horizontal.page.fill"
        case .recurringExpenses: "arrow.trianglehead.clockwise"
        case .tags: "tag.fill"
        case .backup: "cloud.fill"
        case .splitwise: "arrow.trianglehead.branch"
        case .privacy: "hand.raised.fill"
        }
    }

    var color: Color {
        switch self {
        case .appearance: .sage
        case .budget: .green
        case .tags: .purple
        case .recurringExpenses: .orange
        case .backup: .blue
        case .splitwise: .green
        case .privacy: .red
        }
    }
}

private struct PrivacyWebView: View {
    @State private var isReaderMode = false

    var body: some View {
        WebView(url: URL(string: "https://enzottic.me/sage/privacy")!, isReaderMode: isReaderMode)
            .ignoresSafeArea()
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isReaderMode.toggle()
                    } label: {
                        Image(systemName: isReaderMode ? "doc.plaintext.fill" : "doc.plaintext")
                    }
                }
            }
    }
}

private struct WebView: UIViewRepresentable {
    let url: URL
    let isReaderMode: Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let js = isReaderMode ? Self.enableReaderModeJS : Self.disableReaderModeJS
        webView.evaluateJavaScript(js)
    }

    private static let enableReaderModeJS = """
    (function() {
        var s = document.getElementById('sage-reader');
        if (!s) { s = document.createElement('style'); s.id = 'sage-reader'; document.head.appendChild(s); }
        s.textContent = `
            header, footer, nav, aside, .sidebar, .menu, .ad, [class*="cookie"], [class*="banner"] { display: none !important; }
            body { max-width: 660px !important; margin: 0 auto !important; padding: 24px 20px !important;
                   font-family: -apple-system, Georgia, serif !important; font-size: 17px !important;
                   line-height: 1.75 !important; color: #1c1c1e !important; background: #fff !important; }
            img { max-width: 100% !important; }
        `;
    })();
    """

    private static let disableReaderModeJS = """
    (function() { var s = document.getElementById('sage-reader'); if (s) s.remove(); })();
    """
}

#Preview {
    @Previewable @State var appConfig: AppConfiguration = AppConfiguration()
    SettingsView()
        .environment(appConfig)
        .environment(AppRouter())
        .environment(SplitwiseService())
        .modelContainer(previewAppContainer)
}
