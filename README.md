# Syl

A simple expense tracking app

## Code Organization

- `SageKit/` contains code shared by the app and widget extension: models,
  persistence, preferences, currency rules, App Intents, and shared charts.
- `FinanceTracker/` owns app workflows, notifications, recurring-expense
  processing, amount input, serialization, and debug/preview seeding.
- `FinanceTrackerTests/` groups unit tests by responsibility, with test doubles
  in `Support/`. The hostless test target compiles selected app sources directly;
  their membership is configured in the Xcode project, not by copying files.
- `FinanceTrackerUITests/` groups UI tests by feature. Cross-feature journeys
  stay together in `AppFlows/` to preserve the existing suites and test identifiers.
