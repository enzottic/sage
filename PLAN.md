# Splitwise Tab — Implementation Plan

## Summary
Add a "Splitwise" tab to Sage that lets users authenticate via OAuth, browse their Splitwise expenses, and import them as Sage expenses. Builds on the existing `SplitwiseService` (OAuth2, models, Keychain, tests all done).

## New Files

### 1. `FinanceTracker/Views/SplitwiseView.swift`
The main tab view with three states:
- **Not connected**: Shows a "Connect to Splitwise" button that kicks off `ASWebAuthenticationSession` using `SplitwiseService.getAuthorizationURL()`.
- **Loading**: Progress spinner while fetching expenses.
- **Expense list**: Splitwise expenses grouped by date (same visual pattern as `ExpensesView`). Each row shows: description, date, your owed share amount, and Splitwise category name. Pull-to-refresh. Tapping a row opens `ImportExpenseSheet`.

Filters out:
- Deleted expenses (`deleted_at != nil`)
- Settlements/payments (owed share == 0)

On appear, calls `getCurrentUser()` to get the user's ID, then `getExpenses(datedAfter: 3 months ago)`. Stores the current user ID to look up the correct `owed_share` from each expense's `users` array.

A "Disconnect" option (e.g. toolbar button) calls `SplitwiseService.logout()`.

### 2. `FinanceTracker/Views/Components/ImportExpenseSheet.swift`
A `.sheet` that reuses `ExpenseInfoForm` (same form used by `AddExpenseSheet`). Pre-fills:
- **name** → Splitwise `description`
- **amount** → the user's `owedShare` as a `Double`
- **date** → `parsedDate` from the Splitwise expense
- **note** → `"Imported from Splitwise"`
- **category** → defaults to `.wants` (user picks)
- **tag** → `nil` (user picks)

Save logic identical to `AddExpenseSheet`: `modelContext.insert()` + `modelContext.save()` + `WidgetCenter.shared.reloadAllTimelines()`.

## Modified Files

### 3. `FinanceTracker/Views/SageTabView.swift`
Add a 4th tab between Expenses and Settings:
```swift
SplitwiseView()
    .tabItem {
        Label("Splitwise", systemImage: "arrow.triangle.branch")
    }
    .tag(2)
```
Bump Settings to `.tag(3)`.

### 4. `FinanceTracker/SageApp.swift`
Register the OAuth callback URL scheme handler with `.onOpenURL` so the app can receive the `financetracker://splitwise-callback` redirect after the user authorizes in the browser.

## Out of Scope
- Changing the existing `SplitwiseService` (it's already complete)
- Pagination (initial version loads last 3 months, can add "load more" later)
- Tracking which Splitwise expenses have already been imported (can add later)
