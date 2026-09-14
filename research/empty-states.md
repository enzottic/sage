# Empty-state audit — issue #73

September 13, 2026. Reviewed the current SwiftUI views against the September 6
snapshot in [issue #73](https://github.com/enzottic/sage/issues/73).

## Findings and decisions

| Surface | Current result |
| --- | --- |
| Category detail | Replaced the empty Recent Purchases section with a month/category explanation and Add Expense. The draft keeps the selected category and month. |
| Dashboard | Existing filtering already removes empty cards before laying out rows. Keep Recent Expenses, Top Tags, and Upcoming Expenses hidden until their data exists; explain each rule in Reorder Widgets. The monthly overview now explains an empty month and offers Add Expense. |
| Stats comparison | Record count is tracked separately from net total, using the same filtered history and exact comparison cutoff. Missing records get a missing-record explanation; zero/negative baselines show the net amount and explain why a percentage is unavailable. An empty selected period no longer implies a 100% spending reduction in Stats or Home. |
| Stats empty chart | Offer Clear Filters for an empty filtered result, or Add Expense for an unfiltered empty month. Ignore a deleted tag when deciding whether filters are active. |
| Monthly expense list | Explain empty months and provide Add Expense with the selected month. No-match results suggest changing the search or month. |
| Global search | Existing initial search prompt was already explanatory. Added recovery guidance to no-match results. |
| Tags settings | Added an explanation and Add Tag when no active tags exist. |
| Recurring settings | Existing copy explained where rules appear but offered no action. Added Add Recurring Expense with recurrence enabled. Present locally so it can also appear above the iPad Settings sheet. |
| Calendar day details and glyph search | Already distinguish empty past/future days and use native search feedback, respectively. Kept these existing states. |
| Untagged breakdowns | Existing category/untagged rows retain recorded expenses even without tags. Kept this behavior. |

All additions use existing SwiftUI components, Sage colors, and native sheets.
Starting category/date/recurrence values do not count as unsaved edits until the
user changes the draft. Historical months default to their first day; the current
month defaults to today.

## Verification

- `FinanceTracker` simulator build-for-testing passed with Xcode beta 27.
  Stable Xcode 26.6 could not test the scheme because its required watchOS 26.5
  runtime is absent; the beta matches the installed watchOS 27 runtime.
- All 10 `SpendingMonthSummaryTests` passed, including five parameterized baseline
  cases: no records, a zero record, offsetting purchase/refund, negative net, and
  positive net. Existing wall-time, month-end, and shorter-month checks passed.
- UI tests verify saving into the original category/month, cancelling untouched
  contextual drafts, dashboard/month Add Expense, hidden-widget explanations,
  opening Add Tag, opening a recurring draft with its toggle enabled, and restoring
  Stats results with Clear Filters.
- The initial iOS 27 UI run passed the dashboard/month flow but failed on keyboard
  toolbar and menu lookup interactions. The three failed checks passed on iPhone
  17 Pro / iOS 26.5 after the new draft tests stopped depending on the toolbar.
- The final three empty-state UI tests passed again after increasing button sizes.
  The dashboard/month/widget-order flow also passed with Dark appearance and XL
  Dynamic Type; its exported month and widget-order screenshots were inspected.
- Screenshot attachments were inspected for the empty and populated category,
  dashboard, month list, widget explanation, Tags, recurring expenses, and Stats.
- `git diff --check` passed. No full test suite was run.

Sources: [summary tests](../FinanceTrackerTests/Analytics/SpendingMonthSummaryTests.swift),
[empty-state UI tests](../FinanceTrackerUITests/EmptyStates/EmptyStateUITests.swift),
[Stats UI test](../FinanceTrackerUITests/Stats/StatsViewUITests.swift).

This is simulator implementation evidence. Physical-device, iPad, release-build
performance, full-motion review, and a complete appearance/accessibility matrix
remain unverified.
Direct Computer Use access to Simulator was not approved; verification used XCTest
and its exported attachments. No distribution or release-readiness claim is made.
