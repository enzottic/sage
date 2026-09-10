# Sage App Store Readiness

Updated: September 8, 2026 (currency-policy documentation only). September 6
source audit: `2f8b8d7` plus then-current working-tree privacy-manifest and
import-test changes. Original audit baseline: `806beb0`. The currency update
reflects the current working-tree diff; unrelated audit status is unchanged.

This is the remaining backlog from the App Store audit, adjusted for the fixes
already implemented. Sage still needs privacy/compliance corrections, data-integrity
fixes, and release-device verification before submission.

Unchecked items are not complete. Source findings describe identifiable code
paths; verification items are risks to test, not claims of reproduced failures.
Checked implementation items do not imply device or release verification. Existing
tests were inspected, not rerun for this documentation audit; the import entry
records the targeted test run from the preceding implementation task. Device,
distribution, and App Store Connect checks remain open without execution evidence.

## Priority 1: Submission And Privacy

- [x] **Declare active-keyboard API use.** Added
  `NSPrivacyAccessedAPICategoryActiveKeyboards` with approved reason `54BD.1`
  to the app privacy manifest. `EmojiKeyboardField` uses
  `UITextInputMode.activeInputModes` only to select the emoji keyboard when
  available, visibly adapting text input; keyboard information is not sent
  off-device. This matches Apple's customized text-input UI reason.
  Sources: [EmojiKeyboardField](FinanceTracker/Views/SettingsView/Components/EmojiKeyboardField.swift),
  [app manifest](FinanceTracker/PrivacyInfo.xcprivacy),
  [Apple's approved reasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype).

- [ ] **Verify the active-keyboard declaration in the final archive.** Confirm
  the distributed app includes the updated privacy manifest and its privacy
  report lists active-keyboard access with reason `54BD.1`.

- [x] **Implement consent-controlled preference sync.** Implemented a
  consent-controlled preference sync service: device-local/default-off consent,
  no KVS acquisition or operations while off, no remote echo writes, and guarded
  startup, incoming notifications, preference edits, and reset. The original
  currency-confirmation handshake is superseded by editable denomination sync.
  Unit tests cover the service and production AppConfiguration source. Preference
  access stops immediately; the existing SwiftData store changes only after a
  full restart, and previously queued iCloud activity can finish. The UI explains
  this distinction.
  Sources: [AppConfiguration](FinanceTracker/Helpers/AppConfiguration.swift),
  [preference sync](FinanceTracker/Services/PreferenceSyncService.swift).

- [ ] **Verify the unified iCloud opt-out on release devices.** Check two-device
  behavior and network activity before and after opt-out/restart, including queued
  activity and reset while opted out. Source tests do not establish real transport behavior.

- [ ] **Publish the corrected privacy policy at the URL users actually open.**
  `https://enzottic.me/sage/privacy` is reachable, but the audit found the older
  June 15 policy; the September 6 recheck still serves it. The repository draft is
  now dated September 6. Reconcile collection, synchronization, retention, and
  consent withdrawal before publishing. Include accounts, local-export deletion,
  and external-copy limits; remove unsupported reminder-permission claims.
  Sources: [repository policy](PRIVACY_POLICY.md),
  [policy presentation](FinanceTracker/Views/SettingsView/SettingsView.swift).

- [ ] **Remove or disclose the privacy page's third-party network behavior.**
  The current public HTML still references Cloudflare Web Analytics and
  Adobe-hosted fonts, and Sage loads it in a `WKWebView`. Prefer an analytics-free page or local
  policy content. Otherwise inspect the actual traffic and vendor retention and
  reconcile App Privacy disclosures. Analytics alone does not establish ATT
  tracking; do not add an ATT prompt without evidence that tracking occurs.
  Source: [web view](FinanceTracker/Views/SettingsView/SettingsView.swift).

- [x] **Make Delete All Data account for Sage-owned exports.** Reset removes
  `Documents/sage-export.csv` before deleting user models, reports removal failures,
  and explains that external copies must be deleted separately. Tests cover repeated
  reset, missing files, failures, and preservation of unrelated files and symlink
  targets. File removal cannot be rolled back if a later model operation fails.
  Sources: [backup service](FinanceTracker/Services/ExpenseBackupService.swift),
  [reset](FinanceTracker/Views/SettingsView/SettingsView.swift),
  [deletion service](FinanceTracker/Services/DataDeletionService.swift),
  [deletion tests](FinanceTrackerTests/Services/DataDeletionServiceTests.swift).

- [x] **Configure the required icon license notice as an app resource.** The full
  Feather/MIT notice is included in the FinanceTracker target's Resources phase.
  Sources: [third-party notices](THIRD_PARTY_NOTICES.md),
  [project resource configuration](FinanceTracker.xcodeproj/project.pbxproj).

- [ ] **Verify the icon license notice in the distributed product.** Confirm
  `THIRD_PARTY_NOTICES.md` and its complete license text are present in the final app.
  A dedicated acknowledgments screen is optional.

## Priority 1: Data Integrity

- [x] **Retire pre-TestFlight store-location migration.** The project owner
  confirmed that relocation from `default.store`, `Sage.store`, and
  `FinanceTracker.store` is no longer required. Removed relocation code and
  its tests; Release opens the App Group's `Sage.sqlite` directly. Old files
  are neither imported nor deleted. Database schema upgrades are a separate
  compatibility decision and remain supported for now.
  Source: [SageModelContainer](SageKit/Persistence/SageModelContainer.swift).

- [x] **Consume converted legacy tag relationships.** Startup backfill clears
  legacy single-tag fields in the same save as conversion and preserves nonempty
  modern selections. Disk-backed tests cover deliberate removal/reopen and
  simulated late legacy records.
  Sources: [multi-tag backfill](SageKit/Persistence/SageModelContainer.swift),
  [legacy safety tests](FinanceTrackerTests/Persistence/SageLegacySafetyTests.swift).

- [ ] **Resolve legacy-tag synchronization edge cases.** Backfill runs at startup,
  and older clients can repopulate consumed fields. Define mixed-version behavior
  or a synchronized conversion marker, then verify deliberate removal and late
  imports across Release devices. Local reopen tests do not prove synchronization safety.

- [x] **Give CSV import an isolated commit boundary.** Implemented a fresh,
  autosave-disabled context with context-local tags, one local save for the
  complete batch, and rollback isolated from UI edits. Passing in-memory tests
  cover an injected save failure and an explicit interleaved UI save. No imported
  records or new tags persist before commit or after failure; committed UI edits
  survive, and pending UI relationship edits remain unsaved on success or failure.
  Existing tests also cover later-save resurrection. This verifies local import
  isolation, not automatic-save timing, real disk exhaustion, or CloudKit atomicity.
  Sources: [import service](FinanceTracker/Services/ExpenseImportService.swift),
  [backup settings](FinanceTracker/Views/SettingsView/Components/ExpenseBackupSettingsSection.swift),
  [import tests](FinanceTrackerTests/Services/ExpenseImportServiceTests.swift).

- [x] **Define backup restore versus append behavior (#48).** Implemented version-2
  JSON expense backups with precise saved amounts/dates, expense UUIDs and stored
  recurrence identity, plus recurring rules with schedules, time zones, end dates,
  generation cursors and conversion boundaries. Version-1 expense-only JSON remains
  readable. Missing rules are added by UUID; existing rules stay unchanged, and
  rule-only backups are supported. Add-missing import preserves local edits, rejects relevant
  ambiguous/crossed identities, and does not save all-skipped batches. A read-only
  summary is replanned at execution; a fresh-reader check, import currency
  compatibility check and cancellation check precede the isolated commit. Six/seven-column CSV stays
  append-only with explicit duplicate warnings and separate six-column currency
  consent. Exports snapshot persisted data without saving UI drafts, write unique
  atomic staging files, then open the native save picker directly for JSON and CSV.
  Success appears only after saving; completion/cancellation cleans up staging files.
  Exports disclose exclusions and unencrypted financial content.
  Targeted simulator tests cover repeat/partial imports, recurrence repair/date
  edits, collisions/replacements, rollback/cancellation, interleaved UI saves,
  disk reopen, and suppression of restored recurring generation.
  Rule-backup tests additionally cover legacy/fixed schedules, rule-only restores,
  preserved local edits, repeated imports, stale cursors, invalid schedule metadata,
  interleaved rule/tag changes, rollback/cancellation and disk-backed rule reopen.
  Recurring rules resume through normal maintenance and may catch up after restore;
  multi-device rule restoration and the rule-specific review UI remain unverified.
  Native UI tests cover JSON export, Save to Files, silent picker cancellation, and all-skipped
  reimport in light and dark/enlarged-text appearances. Full CSV handoff/error/
  cancellation UI coverage, large-ledger performance, release-device behavior,
  and multi-device CloudKit safety remain unverified. Import is local sequential
  safety, not a distributed transaction.
  Sources: [JSON codec](FinanceTracker/Serialization/ExpenseBackupCodec.swift),
  [import tests](FinanceTrackerTests/Services/ExpenseBackupImportTests.swift),
  [file tests](FinanceTrackerTests/Services/ExpenseBackupFileTests.swift),
  [UI tests](FinanceTrackerUITests/Settings/ExpenseBackupUITests.swift),
  [backup settings](FinanceTracker/Views/SettingsView/Components/ExpenseBackupSettingsSection.swift).

- [x] **Make tag names and identities round-trip through backups (#49).** JSON
  uses structured UUID/name definitions and UUID references, preserving pipe names
  and distinct same-name tags. Matching local UUIDs keep local name/metadata;
  only added expenses or recurring rules create tags. Snapshots prefer nonempty modern tags, otherwise
  the legacy singleton, without union or mutation. CSV remains name-based and
  lossy for pipe names, rejects referenced ambiguous saved names, and deduplicates
  repeated names per row. Tests cover special names/identities, modern/legacy
  snapshots, skipped-only tags, local renames, and fresh-reader tag replacement.
  JSON also preserves SF Symbol names/emoji and light/dark extended-sRGB tag colors.
  Appearance is restored only for newly created tags; older backups without it keep
  the neutral fallback. Focused tests cover icon/emoji, opacity, wide-gamut and
  light/dark colors through persistence, local appearance edits, and invalid color
  components. Tag budgets remain excluded.
  Sources: [JSON codec](FinanceTracker/Serialization/ExpenseBackupCodec.swift),
  [codec tests](FinanceTrackerTests/Serialization/ExpenseBackupCodecTests.swift),
  [import tests](FinanceTrackerTests/Services/ExpenseBackupImportTests.swift).

- [ ] **Expose conflicting recurring copies for resolution.** Exact duplicates
  are repaired, but differently edited copies of the same occurrence are retained
  and counted twice with only a log message. Preserve user edits while providing
  a visible conflict-resolution path and an explicit accounting policy.
  Source: [recurring repair](FinanceTracker/Services/RecurringExpenses/RecurringExpenseRepairService.swift).

## Priority 2: Correctness And Errors

- [x] **Implement the unknown-tags import handoff.** Create/Skip dismisses the
  resolution sheet; its `onDismiss` presents import confirmation. Unresolved sheet
  dismissal and confirmation cancellation clear pending import state.
  Source: [backup settings](FinanceTracker/Views/SettingsView/Components/ExpenseBackupSettingsSection.swift).

- [ ] **Verify the unknown-tags handoff on device.** Exercise Create, Skip,
  Continue Without Creating, swipe dismissal, and confirmation cancellation.
  Check presentation order and that subsequent imports have no stale state.

- [x] **Use half-open store month queries.** ExpenseStore month and range fetches,
  derived totals, and monthly snapshots exclude the end boundary. Month-boundary
  regression tests are present.
  Sources: [ExpenseStore](SageKit/Persistence/ExpenseStore.swift),
  [store tests](FinanceTrackerTests/Persistence/ExpenseStoreTests.swift).

- [x] **Finish half-open filtering in category detail and Home comparisons (#52).**
  Category detail and Home share persisted queries with exclusive month-end bounds.
  Home's month summary independently excludes selected-month midnight from the
  previous total while retaining inclusive as-of cutoffs. Persisted query tests
  cover both paths, fractional end-of-month timestamps, leap February, DST, and
  year rollover; summary tests also cover shorter-month comparison cutoffs.
  Device/distribution verification remains unperformed.
  Sources: [shared queries](SageKit/Persistence/ExpenseFetchDescriptors.swift),
  [query tests](FinanceTrackerTests/Persistence/ExpenseFetchDescriptorTests.swift),
  [summary tests](FinanceTrackerTests/Analytics/SpendingMonthSummaryTests.swift),
  [category detail](FinanceTracker/Views/HomeView/Components/CategoryDetailView.swift),
  [monthly overview](FinanceTracker/Views/DashboardView/Widgets/MonthlyOverviewWidget.swift).

- [ ] **Separate unavailable financial data from zero spending.** Range fetches
  can suppress errors into an empty array, and Monthly Spending can fall back
  from a failed filtered request to a broader total. Propagate read failures;
  never silently change the user's query.
  Sources: [ExpenseStore](SageKit/Persistence/ExpenseStore.swift),
  [Find Expenses](SageKit/AppIntents/Intents/FindExpensesIntent.swift),
  [Monthly Spending](SageKit/AppIntents/Intents/GetMonthlySpendingIntent.swift).

- [x] **Remove invented transactions from production widget error states.**
  All four widgets distinguish store/fetch failures with an unavailable state;
  Monthly Summary no longer substitutes sample expenses. Sample data remains
  limited to preview and placeholder paths.
  Sources: [timeline provider](FinanceTrackerWidget/TimelineProvider.swift),
  [entries](FinanceTrackerWidget/WidgetTimelineEntry.swift),
  [daily widget](FinanceTrackerWidget/DailyChartWidget.swift).

- [ ] **Verify widget failure states in live timelines.** Confirm unavailable
  messaging under store/fetch failure and recovery after reopening Sage.

- [x] **Remove the inconsistent Stats forecast presentation.** Stats now shows
  recorded spending only; forecast bars and annotations were removed. Current
  actual totals intentionally exclude future-dated records.
  Sources: [Stats](FinanceTracker/Views/StatsView/StatsView.swift),
  [month summary](SageKit/Analytics/SpendingMonthSummary.swift).

- [x] **Remove the unused projection API.** Spending forecasts are no longer a
  product feature, so `SpendingProjection` and its tests were removed rather
  than defining semantics for a dormant API (#55).

- [ ] **Use the same comparison cutoff on Home and Stats.** Home's previous-month
  cutoff drops the time of day, unlike its current-period cutoff, and lacks Stats'
  shorter-month cap. Share the definition and test corresponding times, shorter
  previous months, and month boundaries.
  Sources: [monthly overview](FinanceTracker/Views/DashboardView/Widgets/MonthlyOverviewWidget.swift),
  [Stats summary](SageKit/Analytics/SpendingMonthSummary.swift).

- [x] **Use calendar-day comparisons for upcoming labels.** Both surfaces now
  compare start-of-day dates in the display calendar through `UpcomingExpenseDays`,
  including the three-day highlighting threshold. Regression coverage in
  `UpcomingExpenseDaysTests` includes midnight, past dates, multi-day thresholds,
  daylight-saving changes, and display time zones. All 6 tests (12 cases) passed
  using the exact helper and test sources in a standalone macOS Swift package.
  Simulator verification was intentionally skipped at the user's request (#57).
  Sources: [upcoming widget](FinanceTracker/Views/DashboardView/Widgets/UpcomingRecurringWidget.swift),
  [recurring settings](FinanceTracker/Views/SettingsView/Components/RecurringExpensesSettingsSection.swift).

- [ ] **Protect newer edits from asynchronous suggestions.** Receipt completion
  can overwrite fields edited during parsing; AI tagging can apply a result for
  an obsolete name. Use request identity and unchanged-input checks, or explicitly
  protect affected fields while work runs.
  Sources: [expense creation](FinanceTracker/Views/Components/AddExpenseView.swift),
  [expense form](FinanceTracker/Views/Components/ExpenseInfoForm.swift).

- [x] **Make the recurring start-date presentation honest.** (#59) The editor
  stages start-date changes and confirms start/frequency edits before
  applying `editSchedule`. Existing expenses and occurrence keys are preserved.
  Edits automatically capture the current time zone without exposing a selector
  and use a fixed Gregorian schedule. They skip catch-up through the latest of save
  time, the previous cursor/boundary and recorded occurrence identities, and reset
  the cursor to follow the new start's cadence. Monthly rules resume after the
  boundary month; daily/weekly/biweekly rules take the first anchored occurrence
  after the boundary. A start beyond the boundary remains the first occurrence.
  End dates before the start are rejected; an end before the next occurrence
  leaves the rule inactive. End-only edits retain the current cadence and catch-up
  behavior. Cancel/discard leaves the stored rule unchanged.
  Evidence: recurrence and reminder-plan suites passed (39 tests on iOS 26.5),
  covering persistence, preserved history, all frequencies, future starts,
  invalid ends, monotonic boundaries, and idempotent generation. A focused
  simulator UI test passed for confirmation, save/reopen, and removed time-zone
  controls.
  Source: [rule editor](FinanceTracker/Views/SettingsView/Components/EditRecurringRuleSheet.swift),
  [schedule operation](FinanceTracker/Services/RecurringExpenses/RecurringExpenseSchedule.swift),
  [tests](FinanceTrackerTests/Services/RecurringExpenses/RecurringExpenseServiceTests.swift).
  Multi-device concurrent edits and older-client compatibility still require
  device validation; older clients do not honor the schedule boundary.

## Priority 2: Polish And Accessibility

- [x] **Protect changed drafts on dismissal and navigation.** Changed expense,
  tag, and recurring-rule forms require discard confirmation on Cancel and
  custom back navigation; sheet swipe dismissal is disabled while changed.
  Untouched forms exit directly.
  The router defers Home's Show All stack clear to the active expense editor,
  which can keep editing or discard before navigation continues (#60).
  Sources: [expense creation](FinanceTracker/Views/Components/AddExpenseView.swift),
  [expense editor](FinanceTracker/Views/Components/ExpenseDetailView.swift),
  [router](FinanceTracker/Router/AppRouter.swift).

- [x] **Provide accessible glyph choices.** The glyph-picker sheet has labeled
  symbol/emoji choices, selected-state semantics, and 56-point cells. Ordinary
  tag selection also exposes its selected state.
  Sources: [glyph picker](FinanceTracker/Views/SettingsView/Components/TagGlyphPickerSheet.swift),
  [tag picker](FinanceTracker/Views/Components/TagPicker.swift).

- [x] **Finish tag-editor control labels and hit areas.** (#61) The glyph launcher
  announces its action and current icon/emoji; the native custom color picker is
  labeled. Named presets expose selection and use 48-point minimum cells in an
  adaptive grid, allowing for medium-sheet scaling. The form scrolls with Cancel
  and Save kept outside it; the Settings add sheet can expand to large. Preset
  matching uses UIColor equality so reopening a saved tag retains selection.
  Unknown-tag import choices already expose conditional selected traits and were
  left unchanged.
  Evidence: both `TagEditorUITests` passed on iPhone 17 Pro and iPhone 17e
  simulators (iOS 26.5), covering light/dark appearance, accessibility XL text,
  all ten preset edge taps, minimum target dimensions, selection changes, native
  picker presentation, glyph value, and save/reopen/cancel. Screenshots were
  reviewed. The compact light test needed a test-only correction for the native
  color picker's different dismissal label, then passed.
  Results: `SageTagEditorVerified.xcresult` (2 passed),
  `SageTagEditorCompact.xcresult` (dark passed), and
  `SageTagEditorCompactRetry.xcresult` (light passed), under the local OpenCode
  temporary directory. VoiceOver on device, the unknown-tag import interaction,
  and full-motion/release verification remain unperformed. Existing budget-help
  truncation at accessibility sizes and palette-dependent text contrast are not
  addressed by this control-label/hit-area change.
  Sources: [tag editor](FinanceTracker/Views/SettingsView/Components/AddExpenseTagSheet.swift),
  [import choices](FinanceTracker/Views/SettingsView/Components/ExpenseBackupSettingsSection.swift),
  [UI tests](FinanceTrackerUITests/Settings/TagEditorUITests.swift).

- [x] **Use a dark foreground on the onboarding primary action.** The action no
  longer uses white text on Sage. Full rendered contrast verification remains open.
  Source: [onboarding](FinanceTracker/Views/OnboardingView.swift).

- [ ] **Fix remaining insufficient text contrast.** (#62) Applied targeted foreground
  changes without altering palette assets or stored colors. Add-tag and What's New
  actions use black text; the import action already did. Gauge markers and multi-tag
  counts choose black or white against their resolved opaque fill. Tag labels,
  category headings, budget percentages, refund/date labels, and comparison text
  use semantic foregrounds; imminent reminder badges use black on orange.
  The tag editor uses primary Cancel text and black-on-Sage Add/Save actions.
  Evidence: simulator build-for-testing succeeded on iPhone 17 Pro (iOS 26.5).
  Existing tag-editor UI tests passed in light and dark/accessibility XL appearances,
  with screenshots reviewed (`SageContrastVerified.xcresult` in the local OpenCode
  temporary directory). No contrast tests were added. These checks preceded the
  user's direction to skip automated tests for visual-only changes.
  Remaining: rendered verification of the other changed surfaces, native tinted
  controls, chart marks, tag-icon contrast, and full-motion/device verification.
  Existing tag-editor truncation at accessibility sizes remains outside this change.
  Keep this item open until the remaining visual review is complete.
  Sources: [tag picker](FinanceTracker/Views/Components/TagPicker.swift),
  [gauge](FinanceTracker/Views/Components/ArcProgressGauge.swift).

- [ ] **Constrain oversized tag chips.** Flow layout measures children at
  unconstrained intrinsic width. Long names or accessibility text sizes can
  overflow the available width. Measure oversized children with a width bound
  and account for their resulting height.
  Source: [FlowLayout](FinanceTracker/Views/Components/FlowLayout.swift).

- [ ] **Represent zero budgets and over-budget values accurately.** Positive
  spending against zero allocation or income should not say 0% used. Arc-gauge
  VoiceOver and both compact circular-gauge text and VoiceOver should report actual
  utilization, not the drawing's clamped 100% maximum.
  Sources: [category utilization](FinanceTracker/Views/DashboardView/Widgets/SingleCategoryUtilizationWidget.swift),
  [gauge](FinanceTracker/Views/Components/ArcProgressGauge.swift),
  [circular gauge](FinanceTracker/Views/Components/CircularProgressBar.swift).

- [x] **Complete Reduce Motion support.** (#65) Audited the four remaining
  surfaces against Apple's guidance. Toast presentation uses an opacity fade
  under Reduce Motion; animation is owned by the overlay instead of the router.
  Budget and end-date fields update without custom layout animation. Recurring
  options retain their existing guard and explicitly remove the moving transition.
  Native controls and existing progress, tag-selection, expense-date, and Stats
  month guards are preserved. Evidence: source/diff review and the
  [research, implementation decisions, and pending device checks](research/reduce-motion.md).
  No local build or tests were run as requested; automated verification is
  deferred to PR CI. Visual/device and release verification remain pending.

- [ ] **Finish regional date and income input handling.** Older relative dates
  still use US ordering, and onboarding filters out non-ASCII digits. Use
  locale-aware dates and normalize supported localized digits in onboarding and
  Settings income fields. Shared amount parsing already normalizes digits, but
  these income controls do not. English-only
  translation is acceptable; regional correctness remains necessary.
  Sources: [relative dates](SageKit/Extensions/Date+Relative.swift),
  [onboarding](FinanceTracker/Views/OnboardingView.swift),
  [Settings income field](FinanceTracker/Views/Components/WholeNumberCurrencyField.swift).

## Priority 3: Quality Of Life

- [x] **Replace immutable currency with a freely editable synced denomination.**
  The current working tree allows currency selection during onboarding and later
  in Settings, including populated ledgers. Settings confirms the change and
  explains that it applies to existing and future expenses, recurring rules,
  income, and budgets without converting or changing stored amounts. Currency
  edits sync when consent is enabled; valid remote denominations are adopted
  without echo writes or a currency-conflict gate. Legacy conflict flags no longer
  block access or monetary edits. The former empty-ledger-only correction proposal
  and immutable lock/conflict requirement are superseded.
  Sources: [currency](SageKit/Money/LedgerCurrency.swift),
  [AppConfiguration](FinanceTracker/Helpers/AppConfiguration.swift),
  [budget settings](FinanceTracker/Views/SettingsView/Components/BudgetSettingsSection.swift),
  [onboarding](FinanceTracker/Views/OnboardingView.swift).
- [ ] **Verify denomination changes without conversion.** Check confirm/cancel,
  populated and empty ledgers, relaunch and region changes, and immediate refresh
  across app screens, widgets, reminders, and shortcuts. Confirm stored expenses,
  recurring amounts, income, and tag budgets retain their numeric values. Exercise
  USD/EUR, JPY, and KWD changes with open drafts and historical fractional amounts;
  unchanged amounts must not be rounded on save, while new or changed amounts
  follow the selected currency's precision rules. Verify JSON/CSV export and
  import currency validation, including a denomination change during import review.
  Changed unit tests and a new UI test are present in the diff, not run in this audit.
- [ ] **Copy the note when duplicating an expense**, unless deliberately excluded
  and explained. Resetting date or recurrence is a separate product decision.
- [ ] **Improve expense deletion feedback.** Generic success/error feedback exists;
  identify the expense in confirmation, explain whether future recurring occurrences
  remain, and consider Undo. Recurring-rule deletion already has explanatory copy.
- [x] **Add jump-to-month and return-to-current-month navigation in Stats.** Choose
  Month and This Month controls are implemented, with a dedicated UI test.
  Sources: [Stats](FinanceTracker/Views/StatsView/StatsView.swift),
  [Stats UI tests](FinanceTrackerUITests/Stats/StatsViewUITests.swift).
- [ ] **Add equivalent month navigation to Home and Expenses.** These still offer
  previous/next arrows only. Verify picker accessibility and presentation on device.
- [x] **Paginate search beyond 100 matches.** Load more results reveals another
  100 matches without changing search terms; a new query resets the visible window.
  Sources: [Search](FinanceTracker/Views/ExpensesView/Components/SearchExpensesView.swift),
  [search query tests](FinanceTrackerTests/Persistence/ExpenseSearchPredicateTests.swift),
  [pagination UI test](FinanceTrackerUITests/AppFlows/FinanceTrackerUITests.swift).
- [x] **Explain overlapping tag totals in Stats.** Stats explains that expenses
  with multiple tags count toward each tag.
  Source: [Stats top tags](FinanceTracker/Views/StatsView/StatsView.swift).
- [ ] **Explain overlapping tag totals on Home and category detail.** One expense
  contributes its full amount to several tags, so their sum may exceed total spending.
- [x] **Add Stats empty-state explanations.** Empty months, missing history,
  absent tags, and missing comparison baselines have explanatory messages.
  Sources: [Stats](FinanceTracker/Views/StatsView/StatsView.swift),
  [comparison card](FinanceTracker/Views/StatsView/Components/SpendingComparisonCard.swift).
- [ ] **Finish uneven empty states.** Category detail and hidden dashboard sections
  still need clear explanations and useful actions. Stats' comparison fallback must
  distinguish missing records from zero/negative net totals rather than label both
  "No spending recorded."
- [ ] **Clean up What's New.** Fix "improvments," remove inappropriate beta
  wording, and avoid referring to a Settings tab on layouts without one.
  Source: [What's New](FinanceTracker/Views/WhatsNewSheet.swift).

## Device And Release Verification

These checks still require runtime evidence. They are not established failures.

- [ ] Validate upgrades from supported released stores to V6, including actual
  store locations, relationships, occurrence keys, interrupted launches, and reopening.
  SQLite fixture tests cover V1/V5 migration and V2 legacy-tag backfill/reopening;
  these are not released-store or interrupted-launch evidence. The migration plan
  still includes V1-V6 despite removal of old store-location relocation.
  Sources: [migration tests](FinanceTrackerTests/Persistence/SchemaMigrationTests.swift),
  [legacy tests](FinanceTrackerTests/Persistence/SageLegacySafetyTests.swift).
- [ ] Test two-device CloudKit synchronization, offline edits, deletion
  propagation, and late-arriving records. Separately verify denomination preference
  propagation and convergence after concurrent/offline edits, opt-out/re-enable,
  and missing or invalid remote values, without blocking monetary access or
  converting amounts. Preference sync and CloudKit records are not one atomic
  transaction. Define mixed-version behavior for older clients that still enforce
  the superseded currency lock/conflict policy; historical per-record currencies
  cannot be reconstructed automatically.
- [ ] Define the supported mixed-version behavior before converting legacy
  recurring rules. Older clients do not honor fixed time zones or conversion
  boundaries. Current confirmation warns users to update all devices first.
- [ ] Validate CloudKit production schema and background delivery. The checked-in
  app has CloudKit/App Group entitlements but lacks push/background setup normally
  used for remote changes. The widget uses a CloudKit-capable Release container path
  while declaring only App Groups. Choose its local-reader or CloudKit role, align
  configuration and entitlements, then test.
- [ ] Validate Siri discovery, cold launch, and parameterized phrases. Shortcut
  registration and direct intent tests exist, but voice discovery remains unverified.
  Recheck previously reported parameter-type and SSU training diagnostics against
  a retained build log; direct Shortcuts execution does not prove voice discovery.
- [ ] Choose and test locked-device privacy for financial App Intents. They
  inherit the default `.alwaysAllowed` authentication policy. Consider explicit authentication
  requirements and privacy-sensitive widget redaction; an app-wide biometric
  lock is not automatically required.
- [ ] Test fresh onboarding, regional currency selection, back navigation,
  failed completion, and upgrades with missing currency or legacy conflict flags
  without relying only on UI-test bypasses. Confirm no legacy confirmation or
  conflict screen blocks access, and selected currency persists across relaunch.
- [ ] Test amount entry and immediate Save in USD, EUR/comma-decimal locales,
  JPY, and KWD; include refunds, invalid replacement text, and pasted grouping.
- [ ] Exercise all editors on small iPhones and at the largest accessibility
  sizes with the keyboard visible. The tag editor remains non-scrolling; the
  recurring editor scrolls only its schedule section, not the expense-information
  form. Both still need keyboard and accessibility-size verification.
- [ ] Verify VoiceOver can discover and edit the Settings income field, not
  merely read its visible value. Verify progress-to-success toast announcements.
- [ ] Verify iPad Settings discovery with collapsed/sidebar layouts and whether
  toasts remain visible above presented settings sheets.
- [ ] Verify light/dark contrast, long content, keyboard transitions, Reduce
  Motion, and the new onboarding picker at large text sizes.
- [ ] Test camera denial/restriction/cancellation, receipt errors, iCloud photo
  loading, and manual entry on devices without Apple Intelligence.
- [ ] Test realistic large ledgers, import sizes, and recurring catch-up for
  responsiveness and memory use. Do not infer production performance from mocks.
- [ ] Validate a distribution-signed archive: provisioning, App Groups,
  CloudKit environment, icons, privacy manifests, license resources, and widget
  embedding. Use the standard FinanceTracker scheme; the Dev scheme archives
  Debug. Existing Debug/in-memory tests do not cover all production paths.

## App Store Connect

- [ ] Reconcile App Privacy answers with native behavior and the embedded web
  page. Do not automatically classify all on-device expense data as collected.
- [ ] Confirm working Support and Privacy Policy URLs and reachable contact
  details in the actual submission metadata.
- [ ] Complete age rating, export compliance, territories, agreements, and EU
  trader-status requirements where applicable.
- [ ] Use accurate iPhone/iPad screenshots with fictional financial data. Do not
  claim unsupported notifications, languages, platforms, or conversion features.
- [ ] Provide review notes covering optional iCloud/restart behavior, freely
  editable synced denomination without conversion, Apple Intelligence availability,
  widgets, shortcuts, and no account requirement.

## Implemented In Source

These items record implementations in checked-in source; superseded policies are
labeled below rather than treated as current requirements. Regression tests cover
many, but not all, changes; targeted coverage was not found for Settings persistence-failure
handling or recurring-coordinator retry/due scheduling. Relevant runtime checks
above remain open. Do not reopen these items as entirely unimplemented.

- [x] Locale-safe tag-budget editing and invalid-limit rejection (`edfff76`).
- [x] Tag and recurring-rule save/delete errors and rollback instead of false
  success (`e28cf61`).
- [x] Isolated shortcut writes and propagated persistence errors (`3f93604`).
- [x] Persistent ledger currency, legacy confirmation, and currency-aware CSV
  compatibility/validation (`defea81`). The immutable lock, legacy confirmation,
  and currency-conflict policy are superseded by freely editable synced denomination
  in the current working tree. Persistence and import currency validation remain.
- [x] Fixed-zone anchored recurrence for new/explicitly converted rules and
  shared generation/upcoming-date stepping (`c223aa6`). Legacy rules intentionally
  keep their old schedule until confirmed.
- [x] Shared entry-time monetary precision/range validation, refunds, and immediate
  amount binding updates (`35b5981`). Invalid amounts require correction when saved
  through validated editors; existing records are not migrated or rounded. CSV
  backups intentionally preserve historical fractional precision. The requirement
  to correct an unchanged amount before saving unrelated edits is superseded in
  the current expense and recurring-rule editors; denomination changes do not
  rewrite historical amounts. New or changed amounts still require validation.
- [x] Recurring-maintenance retries and foreground due scheduling (`a477a2c`).
- [x] Malformed grouping rejection and localized refund signs (`c2e6f31`).
- [x] Regional currency default and picker on the onboarding income screen,
  with draft-currency previews and completion checks (`806beb0`).

## References

- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Required-reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- [App Privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [Core Data and CloudKit setup](https://developer.apple.com/documentation/coredata/setting-up-core-data-with-cloudkit)

Recheck Apple's current requirements when preparing the submission. This
engineering checklist is not a guarantee of App Review approval.
