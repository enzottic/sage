//
//  SettingsViewNew.swift
//  FinanceTracker
//
//  Created by Tyler McCormick on 5/18/26.
//
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppConfiguration.self) private var config: AppConfiguration
    @Environment(AppRouter.self) private var router: AppRouter
    
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
                    ForEach([SettingsPage.privacy, .termsOfUse], id: \.self) { page in
                        NavigationLink(value: page) {
                            SettingsListItem(text: page.rawValue, icon: page.icon, color: page.color)
                        }
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
                default: Text(page.rawValue)
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
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: 35, height: 35)
                    .foregroundStyle(color)
                Image(systemName: icon)
                    .foregroundStyle(.white)
                    .fontWeight(.black)
            }
            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 10))
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
    case termsOfUse = "Terms of Use"
    
    var icon: String {
        switch self {
        case .appearance: "paintpalette.fill"
        case .budget: "chart.bar.horizontal.page.fill"
        case .recurringExpenses: "arrow.trianglehead.clockwise"
        case .tags: "tag.fill"
        case .backup: "cloud.fill"
        case .splitwise: "arrow.trianglehead.branch"
        case .privacy: "hand.raised.fill"
        case .termsOfUse: "iphone.gen1"
        }
    }
    
    var color: Color {
        switch self {
        case .appearance:.sage
        case .budget: .green
        case .tags: .purple
        case .recurringExpenses: .orange
        case .backup: .blue
        case .splitwise: .green
        case .privacy: .red
        case .termsOfUse: .yellow
        }
    }
}

#Preview {
    @Previewable @State var appConfig: AppConfiguration = AppConfiguration()
    SettingsView()
        .environment(appConfig)
        .environment(AppRouter())
        .environment(SplitwiseService())
        .modelContainer(previewAppContainer)
}
