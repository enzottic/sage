# Sage App Store Readiness

Updated: September 4, 2026. Source baseline: `806beb0`.

This is the remaining backlog from the App Store audit, adjusted for the fixes
already committed. Sage still needs privacy/compliance corrections, data-integrity
fixes, and release-device verification before submission.

Unchecked items are not complete. Source findings describe identifiable code
paths; verification items are risks to test, not claims of reproduced failures.
No build or simulator test pass is implied by this checklist. Build and device
verification are being handled by the project owner.

## Priority 1: Submission And Privacy

- [ ] **Declare active-keyboard API use.** `UITextInputMode.activeInputModes`
  requires an active-keyboards required-reason API declaration. Review approved
  reason `54BD.1` for this use and include it in the app privacy manifest, or
  remove the API use. Verify the final archive's privacy report.
  Sources: [EmojiKeyboardField](FinanceTracker/Views/SettingsView/Components/EmojiKeyboardField.swift),
  [app manifest](FinanceTracker/PrivacyInfo.xcprivacy).

- [ ] **Verify the unified iCloud opt-out on release devices.** Implemented a
  consent-controlled preference sync service: device-local/default-off consent,
  no KVS acquisition or operations while off, no remote echo writes, and guarded
  startup, incoming notifications, currency confirmation, and reset. Standard
  unit tests cover the service and production AppConfiguration source. Preference
  access stops immediately; the existing SwiftData store changes only after a
  full restart, and previously queued iCloud activity can finish. The UI explains
  this distinction. Two-device and Release network verification remain open.
  Sources: [AppConfiguration](FinanceTracker/Helpers/AppConfiguration.swift),
  [preference sync](SageKit/Services/PreferenceSyncService.swift).

- [ ] **Publish the corrected privacy policy at the URL users actually open.**
  `https://enzottic.me/sage/privacy` is reachable, but the audit found the older
  June 15 policy rather than the September 4 repository version. Reconcile the
  implementation first, then publish accurate collection, synchronization,
  retention, deletion, and consent-withdrawal information. Remove unsupported
  notification claims if reminders are not shipping.
  Sources: [repository policy](PRIVACY_POLICY.md),
  [policy presentation](FinanceTracker/Views/SettingsView/SettingsView.swift).

- [ ] **Remove or disclose the privacy page's third-party network behavior.**
  The live page inspected during the audit loaded Cloudflare Web Analytics and
  Adobe-hosted fonts inside a `WKWebView`. Prefer an analytics-free page or local
  policy content. Otherwise inspect the actual traffic and vendor retention and
  reconcile App Privacy disclosures. Analytics alone does not establish ATT
  tracking; do not add an ATT prompt without evidence that tracking occurs.
  Source: [web view](FinanceTracker/Views/SettingsView/SettingsView.swift).

- [ ] **Make Delete All Data account for Sage-owned exports.**
  `Documents/sage-export.csv` survives the current reset. Remove the app-owned
  copy or explicitly disclose that it remains and how to delete it. Explain
  separately that copies exported outside Sage cannot be recalled.
  Sources: [backup service](FinanceTracker/Services/ExpenseBackupService.swift),
  [reset](FinanceTracker/Views/SettingsView/SettingsView.swift),
  [deletion service](SageKit/Services/DataDeletionService.swift).

- [ ] **Ship the required icon license notice.** The Feather/MIT notice exists
  at repository root but is not configured as an app resource. Bundle the full
  required notice and verify it is included in the distributed product. A
  dedicated acknowledgments screen is optional.
  Source: [third-party notices](THIRD_PARTY_NOTICES.md).

## Priority 1: Data Integrity

- [x] **Retire pre-TestFlight store-location migration.** The project owner
  confirmed that relocation from `default.store`, `Sage.store`, and
  `FinanceTracker.store` is no longer required. Removed relocation code and
  its tests; Release opens the App Group's `Sage.sqlite` directly. Old files
  are neither imported nor deleted. Database schema upgrades are a separate
  compatibility decision and remain supported for now.
  Source: [SageModelContainer](SageKit/Services/SageModelContainer.swift).

- [ ] **Prevent intentionally removed legacy tags from returning.** Startup
  backfill copies a legacy single tag whenever the new tags array is empty.
  Clear or explicitly mark converted legacy relationships so a deliberate
  removal stays removed, including after late CloudKit imports.
  Acceptance: removing every tag from a migrated expense or rule survives
  relaunch and synchronization.
  Source: [multi-tag backfill](SageKit/Services/SageModelContainer.swift).

- [ ] **Give CSV import an isolated commit boundary.** Import currently uses
  the shared UI context and yields during insertion. Autosave or an unrelated
  save may commit part of the batch, while rollback can affect unrelated edits.
  Use a dedicated context with controlled saving. Only promise that nothing was
  saved when that is guaranteed.
  Acceptance: an injected save failure leaves no imported records or tags and
  preserves unrelated pending edits.
  Source: [backup settings](FinanceTracker/Views/SettingsView/Components/ExpenseBackupSettingsSection.swift).

- [ ] **Define backup restore versus append behavior.** New exports preserve
  currency, but still omit expense IDs and recurrence identity. Reimporting the
  same file creates duplicates. Add an explicit restore/merge/append policy and
  preserve identities in a versioned format; retain support for existing exports.
  Acceptance: repeated restoration cannot silently double spending, and restored
  recurring occurrences retain their accounting identity.
  Sources: [CSV codec](SageKit/Services/ExpenseCSVCodec.swift),
  [backup settings](FinanceTracker/Views/SettingsView/Components/ExpenseBackupSettingsSection.swift).

- [ ] **Make tag names and identities round-trip through backups.** Pipe-separated
  tag names split a valid tag such as `Work|Travel`, and duplicate tag names lose
  identity. Use an escaped or structured representation with an explicit legacy
  decoding path.
  Source: [CSV codec](SageKit/Services/ExpenseCSVCodec.swift).

- [ ] **Expose conflicting recurring copies for resolution.** Exact duplicates
  are repaired, but differently edited copies of the same occurrence are retained
  and counted twice with only a log message. Preserve user edits while providing
  a visible conflict-resolution path and an explicit accounting policy.
  Source: [recurring repair](SageKit/Services/RecurringExpenseRepairService.swift).

## Priority 2: Correctness And Errors

- [ ] **Finish the unknown-tags import handoff.** Create/Skip requests the import
  alert without dismissing the resolution sheet. Dismiss first, then present
  confirmation; clear pending state on cancellation. Verify the exact SwiftUI
  presentation behavior on device.
  Source: [backup settings](FinanceTracker/Views/SettingsView/Components/ExpenseBackupSettingsSection.swift).

- [ ] **Use half-open month intervals everywhere.** Some store/category queries
  use `date <= endOfMonth`, including the first instant of the next month. Use
  `[start, end)` consistently across lists, totals, widgets, and intents.
  Acceptance: a transaction at next month's midnight belongs to exactly one month.
  Sources: [ExpenseStore](SageKit/Services/ExpenseStore.swift),
  [category detail](FinanceTracker/Views/HomeView/Components/CategoryDetailView.swift).

- [ ] **Separate unavailable financial data from zero spending.** Range fetches
  can suppress errors into an empty array, and Monthly Spending can fall back
  from a failed filtered request to a broader total. Propagate read failures;
  never silently change the user's query.
  Sources: [ExpenseStore](SageKit/Services/ExpenseStore.swift),
  [Find Expenses](SageKit/AppIntents/Intents/FindExpensesIntent.swift),
  [Monthly Spending](SageKit/AppIntents/Intents/GetMonthlySpendingIntent.swift).

- [ ] **Remove invented transactions from production widget error states.**
  Monthly Summary uses a sample-filled placeholder after real fetch/store
  failures. Keep sample records for previews only; show unavailable or explicitly
  stale data in live timelines. Other widget failures should not look like a
  successful zero-spend result.
  Sources: [timeline provider](FinanceTrackerWidget/TimelineProvider.swift),
  [entries](FinanceTrackerWidget/WidgetTimelineEntry.swift).

- [ ] **Include already-entered future expenses consistently in forecasts.**
  Shared recurrence stepping is fixed, but future records can still be omitted
  from the forecast, or included in the actual bar without being subtracted from
  the projected remainder. Deduplicate future records against projected
  occurrences and make the bar total agree with its annotation.
  Sources: [projection](SageKit/Analytics/SpendingProjection.swift),
  [Stats](FinanceTracker/Views/StatsView/StatsView.swift).

- [ ] **Use the same comparison cutoff on Home and Stats.** Home's previous-month
  cutoff drops the time of day, unlike its current-period cutoff. Choose one
  definition and test equal spending at the corresponding date/time.
  Sources: [monthly overview](FinanceTracker/Views/DashboardView/Widgets/MonthlyOverviewWidget.swift),
  [Stats](FinanceTracker/Views/StatsView/StatsView.swift).

- [ ] **Use calendar-day comparisons for upcoming labels.** A charge tomorrow
  morning can say "today" tonight when fewer than 24 hours remain. Compare
  calendar days rather than whole elapsed days.
  Sources: [upcoming widget](FinanceTracker/Views/DashboardView/Widgets/UpcomingRecurringWidget.swift),
  [recurring settings](FinanceTracker/Views/SettingsView/Components/RecurringExpensesSettingsSection.swift).

- [ ] **Protect newer edits from asynchronous suggestions.** Receipt completion
  can overwrite fields edited during parsing; AI tagging can apply a result for
  an obsolete name. Use request identity and unchanged-input checks, or explicitly
  protect affected fields while work runs.
  Sources: [expense creation](FinanceTracker/Views/Components/AddExpenseView.swift),
  [expense form](FinanceTracker/Views/Components/ExpenseInfoForm.swift).

- [ ] **Make the recurring start-date presentation honest.** The editor passes
  `.constant(rule.startDate)` to an interactive date picker. Show a read-only
  value or implement a real schedule-edit operation with explicit semantics.
  Source: [rule editor](FinanceTracker/Views/SettingsView/Components/EditRecurringRuleSheet.swift).

## Priority 2: Polish And Accessibility

- [ ] **Protect changed drafts on dismissal and navigation.** Add discard
  confirmation or draft preservation for expense/tag/rule editors. Include
  swipe dismissal, Cancel, back navigation, and Home's Show All action clearing
  the Expenses stack. Do not prompt for untouched forms.
  Sources: [expense creation](FinanceTracker/Views/Components/AddExpenseView.swift),
  [expense editor](FinanceTracker/Views/Components/ExpenseDetailView.swift),
  [router](FinanceTracker/Router/AppRouter.swift).

- [ ] **Label tag-editor controls and enlarge hit areas.** Give glyph and color
  controls meaningful VoiceOver labels, selected-state semantics, and at least
  44-point hit areas. Label the custom color picker. Add selected semantics to
  unknown-tag import choices. The ordinary tag picker already has selection
  accessibility; do not duplicate that work.
  Sources: [tag editor](FinanceTracker/Views/SettingsView/Components/AddExpenseTagSheet.swift),
  [import choices](FinanceTracker/Views/SettingsView/Components/ExpenseBackupSettingsSection.swift).

- [ ] **Fix insufficient text contrast.** Explicit white-on-Sage combinations
  measured approximately 2.65:1; white-on-SageAccent approximately 3.90:1. Review
  primary actions, the add-tag chip, and gauge marker in both appearances. Keep
  the palette but use foreground/background pairs appropriate for the text size.
  Sources: [tag picker](FinanceTracker/Views/Components/TagPicker.swift),
  [gauge](FinanceTracker/Views/Components/ArcProgressGauge.swift).

- [ ] **Constrain oversized tag chips.** Flow layout measures children at
  unconstrained intrinsic width. Long names or accessibility text sizes can
  overflow the available width. Measure oversized children with a width bound
  and account for their resulting height.
  Source: [FlowLayout](FinanceTracker/Views/Components/FlowLayout.swift).

- [ ] **Represent zero budgets and over-budget values accurately.** Positive
  spending against zero allocation should not say 0% used. VoiceOver should
  announce the actual utilization, not the drawing's clamped 100% maximum.
  Sources: [category utilization](FinanceTracker/Views/DashboardView/Widgets/SingleCategoryUtilizationWidget.swift),
  [gauge](FinanceTracker/Views/Components/ArcProgressGauge.swift).

- [ ] **Complete Reduce Motion support.** Audit explicit toast, budget-toggle,
  recurring-option, and end-date animations. Keep native behavior and replace
  unnecessary custom movement when Reduce Motion is enabled.

- [ ] **Finish regional date and income input handling.** Older relative dates
  still use US ordering, and onboarding filters out non-ASCII digits. Use
  locale-aware dates and normalize supported localized digits. English-only
  translation is acceptable; regional correctness remains necessary.
  Sources: [relative dates](SageKit/Extensions/Date+Relative.swift),
  [onboarding](FinanceTracker/Views/OnboardingView.swift).

## Priority 3: Quality Of Life

- [ ] **Allow currency correction for genuinely empty onboarding ledgers.**
  Currently a previously established currency disables the picker even if no
  financial data remains. Consider allowing changes during onboarding only after
  checking expenses, rules, tag budgets, income, and cloud currency. Do not
  silently relabel an existing ledger or overwrite a conflicting cloud setting.
- [ ] **Copy the note when duplicating an expense**, unless deliberately excluded
  and explained. Resetting date or recurrence is a separate product decision.
- [ ] **Improve expense deletion feedback.** Identify the item, explain whether
  future recurring occurrences remain, and consider Undo.
- [ ] **Add jump-to-month and return-to-current-month navigation.**
- [ ] **Paginate search beyond 100 matches** or provide a way to reach older
  results without guessing narrower search terms.
- [ ] **Explain overlapping tag totals.** One expense can contribute its full
  amount to several tags, so their sum may exceed total spending.
- [ ] **Fill uneven empty states.** Review category detail, Stats comparisons,
  and hidden dashboard sections for clear explanations and useful actions.
- [ ] **Clean up What's New.** Fix "improvments," remove inappropriate beta
  wording, and avoid referring to a Settings tab on layouts without one.
  Source: [What's New](FinanceTracker/Views/WhatsNewSheet.swift).

## Device And Release Verification

These checks still require runtime evidence. They are not established failures.

- [ ] Test V1/V5 upgrades to V6 with real on-disk data, relationships, occurrence
  keys, and interrupted launches. Verify both migration and reopening.
- [ ] Test two-device CloudKit synchronization, offline edits, deletion
  propagation, currency conflicts, and late-arriving records. A currency conflict
  gate does not stop an already-open CloudKit store from synchronizing, and
  currency-less historical mixed data cannot be reconstructed automatically.
- [ ] Define the supported mixed-version behavior before converting legacy
  recurring rules. Older clients do not honor fixed time zones or conversion
  boundaries. Current confirmation warns users to update all devices first.
- [ ] Validate CloudKit production schema and background delivery. The checked-in
  app configuration lacks the push/background setup normally used for remote
  changes; decide whether the widget is a local shared-store reader or a CloudKit
  participant, then configure and test it accordingly.
- [ ] Validate Siri discovery, cold launch, and parameterized phrases. The audit
  builds emitted unresolved parameter-type and SSU training diagnostics despite
  completing; actual Siri behavior remains unverified. Direct Shortcuts execution
  does not prove voice discovery works.
- [ ] Choose and test locked-device privacy for financial App Intents. They
  inherit permissive authentication defaults. Consider explicit authentication
  requirements and privacy-sensitive widget redaction; an app-wide biometric
  lock is not automatically required.
- [ ] Test fresh onboarding, regional currency selection, back navigation,
  failed completion, and legacy confirmation without relying only on UI-test
  bypasses. Confirm selected currency persists across relaunch.
- [ ] Test amount entry and immediate Save in USD, EUR/comma-decimal locales,
  JPY, and KWD; include refunds, invalid replacement text, and pasted grouping.
- [ ] Exercise all editors on small iPhones and at the largest accessibility
  sizes with the keyboard visible. The tag editor remains non-scrolling; the
  recurring editor needs verification despite its added schedule scroll area.
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
- [ ] Provide review notes covering optional iCloud/restart behavior, currency
  setup, Apple Intelligence availability, widgets, shortcuts, and no account
  requirement.

## Implemented In Source

These items have commits and regression coverage added, but still need the
relevant runtime checks above. Do not reopen them as entirely unimplemented.

- [x] Locale-safe tag-budget editing and invalid-limit rejection (`edfff76`).
- [x] Settings save errors and rollback instead of false success (`e28cf61`).
- [x] Isolated shortcut writes and propagated persistence errors (`3f93604`).
- [x] Persistent ledger currency, legacy confirmation, and currency-aware CSV
  compatibility/validation (`defea81`).
- [x] Fixed-zone anchored recurrence for new/explicitly converted rules and
  shared generation/projection stepping (`c223aa6`). Legacy rules intentionally
  keep their old schedule until confirmed.
- [x] Shared monetary precision/range validation, refunds, and immediate amount
  binding updates (`35b5981`). Existing invalid amounts require correction;
  they are not silently rounded or rewritten.
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
