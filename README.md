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

## Testing

- `FinanceTracker-PR.xctestplan` runs all unit/integration tests and 16 core UI
  scenarios on pull requests. Its explicit UI allowlist keeps new specialized
  tests from silently expanding the PR gate.
- `FinanceTracker.xctestplan` remains the default full suite, including keyboard
  regressions, pagination, accessibility-size checks, and widget gallery coverage.
  CI runs it nightly and on manual workflow dispatch. Both CI modes use an iPhone
  simulator and upload `.xcresult` artifacts for duration and failure analysis.
- Run device-specific checks separately before release, including the dashboard
  tests on iPad. The full iPhone suite does not exercise their iPad branches.
- Keep UI tests focused on interaction and integration. Test arithmetic, input
  permutations, and persistence rules below the UI. Screenshot attachments are
  diagnostic evidence, not automated visual comparisons.

Run the PR suite locally using an available iPhone simulator ID:

```sh
xcodebuild test -project FinanceTracker.xcodeproj -scheme FinanceTracker \
  -testPlan FinanceTracker-PR \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -parallel-testing-enabled NO
```

Use `-testPlan FinanceTracker` for the full suite, or add `-only-testing:` to
target a specific test while developing. The separate Dev scheme remains unchanged.
