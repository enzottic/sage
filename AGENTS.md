# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

**Sage** is an iOS/iPadOS expense tracking app built with SwiftUI, SwiftData, and WidgetKit. It implements 50/30/20 budget allocation across three expense categories: needs, wants, and savings.

## Build & Run

Open `FinanceTracker.xcodeproj` in Xcode 16+. No CLI build tools are configured — all builds, runs, and tests are done through Xcode.

- **Main app scheme**: `FinanceTracker`
- **UI tests scheme**: `FinanceTrackerUITests`
- **Minimum deployment**: iOS 17

No linting or formatting tooling is configured.

## Architecture

### Data Layer (SwiftData)

**`Shared/Model/SageSchema.swift`** defines versioned schemas with a V1→V2 migration plan:
- `Expense` — core model (amount, category, date, tag, account, recurring link)
- `ExpenseTag` — user/built-in tags with emoji + `UIColor`
- `RecurringExpenseRule` — generates expenses on a frequency (daily/weekly/biweekly/monthly)
- `ExpenseAccount` — bank account, credit card, or other (added in V2)
- `ExpenseCategory` — enum: `needs`, `wants`, `savings`

**`FinanceTracker/SageAppContainer.swift`** bootstraps the SwiftData `ModelContainer` on launch: applies migrations, seeds built-in tags, and triggers recurring expense generation. A separate preview container is provided for SwiftUI previews.

### Services (`Shared/Services/`)

- `ExpenseStore.swift` — CRUD operations for expenses
- `RecurringExpenseService.swift` — generates `Expense` records from `RecurringExpenseRule` based on `lastGeneratedDate`
- `ExpenseBackupService.swift` — CSV export/import

### App State

- **`AppConfiguration.swift`** (`@Observable`) — stores monthly income, budget allocation percentages, and appearance preference; syncs to the shared app group for widget access
- **`AppRouter.swift`** (`@Observable`) — tab selection (`SageTab`) and home navigation state (e.g. drilling into `CategoryDetailView`)

### View Structure

```
SageApp (@main)
├── WelcomeView (first launch)
└── RootTabView
    ├── HomeView — current month overview; CategoryUtilizationView, TotalSpentProgressView, CategoryDetailView
    ├── ExpensesView — month-based expense list with MonthExpensesList and SearchExpensesView
    ├── StatsView — spending comparison and analytics
    └── SettingsView — appearance, budget allocation, tag management, backup
```

### Widgets (`FinanceTrackerWidget/`)

Two widgets in `SageWidgetBundle`:
- `ExpenseUtilizationWidget` — per-category budget utilization
- `ExpensePieChartWidget` — spending pie chart (small/medium sizes)

Both read from the shared model container via `WidgetDataService` using the app group `group.me.enzottic.SageAppGroup`.

### Code Sharing

The `Shared/` directory contains models, services, extensions, and intents used by both the main app and widget targets. The app group entitlement enables SwiftData access across targets.
