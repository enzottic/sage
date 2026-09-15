# Syl App Store submission audit

**Verdict: not ready to submit.** There are confirmed privacy-policy and packaging defects, a reproduced unsupported SwiftData query, and unresolved core-flow verification failures. Syl has substantial native functionality, but a successful compile is not sufficient release evidence.

Audited September 14, 2026, at commit `7538b4f`, version **1.0 (3)**. The worktree was clean at the start. `APP_STORE_READINESS.md` is excluded as evidence at the owner's request. This report makes no implementation changes.

## Evidence and interpretation

- Inspected current app, SageKit, widget, Watch, persistence/migration, import/export, money, notification, receipt/AI, navigation, onboarding, settings, and test sources; checked target configuration and generated Release bundles. The repository contains 187 tracked Swift files, including tests and a separate sample app.
- Retrieved Apple's live App Review Guidelines and relevant HIG chapters. JavaScript-only HIG pages were read through Apple's own documentation JSON endpoints.
- Ran the existing PR test plan and targeted follow-ups, built Release device/simulator products, launched a normally signed simulator Release app, and reviewed selected screenshot/AX attachments.
- **Confirmed** means supported by source, built-product inspection, a live URL response, or a reproducible check. **Risk** means the relevant code path exists but the end-to-end failure needs device verification. **HIG** findings are design/accessibility shortcomings, not automatically individual rejection grounds.
- Review guideline **2.1(a)** applies to obvious functional problems; **Section 4** supports the overall design-quality assessment. Neither means every minor HIG deviation inevitably causes rejection. Apple makes the final decision.
- No access to App Store Connect, CloudKit production configuration, distribution provisioning, paired physical devices, actual customer stores, or an Apple review decision. This is a broad engineering/design audit, not proof of exhaustive runtime coverage.

## Submission blockers and high-priority findings

### R1 — The in-app privacy policy URL returns 404

**Confirmed; high rejection risk.** [Review 5.1.1(i)](https://developer.apple.com/app-store/review/guidelines/#data-collection-and-storage), [2.1(a)](https://developer.apple.com/app-store/review/guidelines/#app-completeness), [HIG Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy).

`FinanceTracker/Views/SettingsView/SettingsView.swift:318` opens `https://enzottic.me/sage/privacy`. A live GET returned **404**. Its browser fallback uses the same URL. The error view is helpful for network failure but does not satisfy the requirement for an accessible policy.

**Before submission:** publish a correct policy at the actual app URL or update the app and add a redirect. Verify it inside the release app and set the same working policy in App Store Connect. An offline-readable copy would improve resilience.

### R2 — The available replacement policy is materially incomplete

**Confirmed; high rejection risk if used as-is.** Review **5.1.1(i), 5.1.2(i), 2.3**.

`https://enzottic.me/syl/privacy` returns 200, but serves a **June 15, 2026 Sage policy**. It omits retention, deletion and consent-withdrawal instructions that Apple explicitly requires. Its assertion that data leaves the device only for optional iCloud sync is incomplete now that Syl also sends financial summaries to Apple Watch and exports user-chosen files.

The repository's `PRIVACY_POLICY.md` is more detailed, but also needs updating: lines 46–48 say notification permission is requested only for recurring reminders; daily reminders and onboarding toggles also request it. The draft omits Watch cache lifecycle, export-copy limits, and support correspondence/device details included in voluntary feedback (`SettingsView.swift:30–41`). Merely changing the URL to `/syl/privacy` will not resolve the content issue.

**Before submission:** accurately describe local storage, private CloudKit/KVS, Watch transfers/cache, receipt processing, voluntary support email, exports, retention/deletion and the restart-dependent expense-sync opt-out. Avoid absolute claims about deleting every copy or nobody else ever accessing data.

### R3 — Web-page privacy disclosures need reconciliation

**Confirmed external dependencies; actual collection/retention unverified.** Review **5.1.1(i–ii), 5.1.2(i), 2.3**; [Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/).

The replacement policy's HTML includes `static.cloudflareinsights.com/beacon.min.js` and `use.typekit.net/sdo3luh.css`. The app uses an unrestricted `WKWebView` (`SettingsView.swift:382–386`). Apple's privacy-label guidance explicitly says data collected through web views must be declared unless the app enables open-web navigation. An embedded policy page should not be presumed exempt.

**Before submission:** preferably serve a policy without analytics or third-party fonts. Otherwise inspect actual traffic, vendor purposes and retention, and reconcile consent, policy and App Privacy answers. Script presence alone does **not** establish ATT-defined tracking; no evidence here justifies automatically adding an ATT prompt or declaring advertising tracking.

### R4 — Both Watch executables lack required-reason privacy manifests

**Confirmed in source and generated Release device bundle; upload-validation blocker.** [Apple required-reason API requirements](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api), Review **5.1**.

`WatchShared/WatchSnapshotCache.swift:5–20` uses App Group `UserDefaults` in both the Watch app and Watch widget. Neither embedded bundle contains `PrivacyInfo.xcprivacy`. The main app and SageKit manifests exist, but Apple's current rule is explicit: **each executable or dynamic library's containing bundle must include its own manifest reporting its required-reason APIs**. The iPhone manifest cannot cover these Watch executables.

**Before submission:** include an appropriate manifest in both Watch targets, declaring UserDefaults with the applicable App Group reason `1C8F.1`; add other reasons only for actual use. Inspect the archive and generated privacy report. The existing iPhone/SageKit manifests already declare UserDefaults and the app declares active keyboards `54BD.1`.

### R5 — A dashboard query fails on supported iOS 26.5

**Reproduced; high functional rejection risk under Review 2.1(a), 2.5.1.** [HIG Charts](https://developer.apple.com/design/human-interface-guidelines/charts), [Feedback](https://developer.apple.com/design/human-interface-guidelines/feedback).

`SageKit/Persistence/ExpenseFetchDescriptors.swift:29–38` uses `recurringScheduledDate!` inside a SwiftData predicate. Actual fetches throw:

> Unsupported Predicate: The 'Foundation.PredicateExpressions.ForcedUnwrap' operator is not supported

Three PR tests fail through this query; the two month parameters in the query test fail again in a targeted rerun. The same warning appears in the UI-test runtime. `ExpenseCalendarWidget.swift:19` uses this query to find existing recurring occurrences, so failure can prevent correct suppression of projected duplicates when recorded occurrences move dates/months.

The migration test fails at its **post-migration query** (`SchemaMigrationTests.swift:158`), not at opening/migrating the database. This audit does not claim the migration itself crashes.

**Before submission:** use a SwiftData-supported optional predicate, pass the failing tests, and verify the real calendar on the minimum supported OS and current release OS, including moved recurring records.

### R6 — Bundled font redistribution notice is incomplete

**Confirmed licensing gap; Review 5.2.1 risk.** [Review Intellectual Property](https://developer.apple.com/app-store/review/guidelines/#intellectual-property).

The Release app contains `MomoTrustDisplay-Regular.ttf`. `THIRD_PARTY_NOTICES.md` contains only Feather's MIT license. Inspection of the font's `name` table found copyright and an OFL URL, but not the full license. [The upstream OFL](https://raw.githubusercontent.com/google/fonts/main/ofl/momotrustdisplay/OFL.txt), condition 2, requires each redistributed copy to include the copyright notice and license; appropriate readable metadata can qualify, but a URL alone is not the complete license text.

**Before submission:** bundle the full applicable OFL/copyright notice and verify resource inclusion. A separate acknowledgments screen is optional. Verify rights to the current Syl logo, website imagery and screenshots as part of the same asset review.

### R7 — Recurring conflict repair silently discards differently edited records

**Confirmed source behavior; high data-integrity risk, potential Review 2.1(a) issue.** HIG **Feedback** and **Privacy**.

`RecurringExpenseRepairService.swift:49–55` sorts all copies of an occurrence by UUID and deletes every copy except the lowest UUID, irrespective of amount, note, date, tags or edit recency. Release maintenance runs this automatically (`RecurringExpenseService.swift:39–58`, `SageApp.swift:107–120`). A newer correction on a higher-UUID copy can disappear without explanation or recovery. The current test deliberately chooses the edited copy as the lowest UUID, so its success does not establish preservation of arbitrary edits.

**Before submission:** define a conflict policy that preserves divergent user edits and surfaces resolution, or keep recoverable history with visible notification. Exact duplicate cleanup and conflicting-content resolution need different handling. Validate concurrent/offline devices.

### R8 — The iOS widget's CloudKit role conflicts with its entitlements

**Confirmed configuration mismatch; runtime impact unverified.** Review **2.1(a), 2.5.16**; [CloudKit setup](https://developer.apple.com/documentation/coredata/setting-up-core-data-with-cloudkit), [SwiftData automatic CloudKit database](https://developer.apple.com/documentation/swiftdata/modelconfiguration/cloudkitdatabase-swift.struct/automatic).

Widget providers call `ExpenseStore.shared`, which opens `SageModelContainer.shared`. In Release with sync active, this selects `.automatic` CloudKit (`SageModelContainer.swift:118–123`), while `FinanceTrackerWidgetExtension.entitlements` grants only App Groups. Apple's `.automatic` configuration obtains its CloudKit container from the current app's entitlements. Do not assume it inherits the containing iPhone app's capabilities.

**Before submission:** explicitly make the widget a local shared-store reader, or configure/test its intended CloudKit participation. Verify opt-in, opt-out/restart, store updates and failure/recovery in real widget timelines. Main-app push and remote-notification configuration are present and are not missing findings.

## Functional and privacy risks to resolve or verify

### R9 — Core expense-entry UI verification is failing

**Observed test failures; root cause not isolated.** Review **2.1(a)**; HIG **Feedback, Layout, Accessibility**.

`FinanceTrackerUITests.testNewExpenseAutofocusesNameAndRetainsMinorUnitAmount` failed after Save because its expected expense row was not found. The captured AX hierarchy shows Home selected and `$1.23` in spending totals; this is evidence against asserting that the expense was never saved. A focused rerun instead failed when the test selected a keyboard-toolbar `Other` element with an infinite origin and zero frame. The helper uses `.any.firstMatch`, so an automation-selector problem remains plausible.

**Release gate:** reproduce manually on device, verify returning to the originating tab, immediate Save, keyboard Done/Next, and reopen persistence. Fix either the app or inaccurate test selectors based on that evidence; do not label these tests passed or dismiss the failures without investigation. The native keyboard Return/Next test and refund save/reopen test passed in the PR run.

### R10 — Different surfaces disagree on future-dated spending

**Confirmed source semantics; visible inconsistency risk.** Review **2.1(a), 2.3**; HIG **Charts**.

Home's `MonthlyOverviewWidget.swift:21` and category queries include the whole selected month. Stats/Watch use `SpendingMonthSummary.swift:39–42`, which excludes dates after now. Monthly Summary/Category Spotlight widgets and monthly Siri totals use full-month `ExpenseStore` fetches, while Daily Spending uses the as-of-now summary. Home even uses the as-of summary for its comparison but the full-month amount for its headline.

**Action:** use a consistent definition or visibly distinguish recorded-to-date from future/planned amounts. Test with one expense tomorrow in the current month and compare all advertised surfaces.

### R11 — Stats clips over-budget and negative spending

**Confirmed source configuration.** Review **2.1(a)** if presented as complete financial information; HIG **Charts** directly recommends ranges that accommodate variable data.

`StatsView.swift:222–223` fixes the Y range to `0...max(monthlyIncome, 1)` and clips the plot. Supported refunds below zero and spending above income disappear outside that range. Income can become zero after reset or Settings edits.

**Action:** include actual extrema and refunds in the domain, with a separately drawn budget reference. Verify isolated categories, historical averages, negative net months and zero budgets.

### R12 — Budget gauges announce misleading percentages

**Confirmed source and AX evidence.** HIG **Charts, VoiceOver**; potential **2.1(a)** correctness issue.

`SingleCategoryUtilizationWidget.swift:50–52` and `MonthlyOverviewWidget.swift:25–27` return 0% for positive spending against a zero budget. Captured AX reports `Needs, 0%, $1.23, of $0.00, $1.23 over`. `ArcProgressGauge.swift:55` announces its clamped value, while the visible marker uses actual progress. `CircularProgressBar.swift:39–44` clamps both text and VoiceOver to 100%.

**Action:** distinguish no budget from zero utilization and use actual utilization in text/AX; clamp only the drawing. The compact gauge is an implementation issue but is not necessarily exercised by the default dashboard layout.

### R13 — Find Expenses reports zero when the fetch fails

**Confirmed source error suppression.** Review **2.1(a)**; HIG **Feedback, Siri**.

`ExpenseStore.swift:97–100` converts fetch failure into `[]`. `FindExpensesIntent.swift:94–118` then says the user spent zero. `GetMonthlySpendingTotalIntent` correctly propagates its fetch failure and should not be flagged for this problem.

**Action:** propagate the error and say the information is unavailable; never substitute zero financial activity for an unreadable store.

### R14 — Receipt/AI completion can overwrite newer user decisions

**Confirmed source race; asynchronous device reproduction pending.** HIG [Generative AI](https://developer.apple.com/design/human-interface-guidelines/generative-ai), **Feedback**; potential **2.1(a)**.

`AddExpenseView.swift:388–414` assigns name, amount, date, category and tags after awaiting parsing while those inputs remain editable. `ExpenseInfoForm.swift:356–380` applies a suggestion for a captured name without checking the name is still current. Cancellation/disappearance does not cancel every spawned operation.

**Action:** apply only to unchanged inputs with request identity/cancellation, or stage a result for acceptance. Make receipt-derived values visibly identifiable and invite review before Save. The current receipt flow does require Save and does not directly submit a transaction to a bank.

Receipt extraction also instructs the model that the price is generally the highest number (`ReceiptParserService.swift:160`), which can confuse tendered cash, balances and totals. Its catch blocks collapse `noReceipt` into generic parsing failure. Validate real receipts, supported languages, dates and wrong-currency receipts; the parser currently does not extract a currency to compare to the ledger.

### R15 — A spoken foreign currency is silently reinterpreted by the add intent

**Confirmed source behavior.** HIG **Siri, Feedback**; potential **2.1(a)** correctness issue.

`AddExpenseIntent.swift:45–55` explicitly ignores `IntentCurrencyAmount`'s currency and saves the numeric amount in the ledger currency. In a USD ledger, “10 euros” becomes $10 without a pre-save correction prompt. This is different from Settings' explicitly confirmed denomination change.

**Action:** reject or clarify mismatched currencies before saving, or make the no-conversion interpretation explicit in the interaction. No exchange-rate service is required.

### R16 — Sync consent withdrawal is only partially immediate

**Confirmed lifecycle; actual transport after revocation unverified.** Review **5.1.1(ii), 5.1.2(i)**; HIG **Privacy**.

PreferenceSyncService stops new KVS access when consent is off. The already-open CloudKit model container remains active until restart (`SageModelContainer.swift:41–62`; `ExpenseBackupSettingsSection.swift:71`). Thus a toggle reading off is not evidence that new expense edits stop syncing in that session; this is more than just a previously queued request finishing. The UI does explain the restart requirement, but Apple requires an understandable withdrawal mechanism.

**Action:** verify transport with edits before/after opt-out, ideally rebuild the store without requiring force-quit, and clearly expose pending versus effective state. Test account changes, multiple windows, extension processes and fresh-install sync enablement. Do not claim an observed unauthorized upload from this source inspection alone.

### R17 — Delete All Data does not cover all app-owned copies/settings

**Confirmed cleanup omissions; end-to-end retention impact needs verification.** Review **5.1.1(i)** and **2.3** for accurate deletion claims; HIG **Privacy, Feedback**.

- `DataDeletionService.swift:31–55` deletes models and one legacy CSV; current exports use unique `temporaryDirectory/syl-expenses-UUID` paths (`ExpenseBackupService.swift:45–49`). Normal picker completion cleans these files, but process termination before cleanup can leave app-owned exports that reset does not enumerate.
- Watch caches `watchMonthlySnapshot` indefinitely. There is no explicit reset/tombstone message or cache clear. The phone sends updated summaries only on scene changes (`SageApp.swift:141–144`), not directly on reset/save. Old summaries can remain on a disconnected Watch or after an interrupted reset workflow.
- `resetAllSettings()` does not clear the three Stats line-visibility `@AppStorage` keys or reminder scheduling history. “All settings” is therefore broader than the implemented reset.

**Action:** implement and test app-owned cache/temp cleanup and a Watch reset/update protocol; describe external user-exported copies and offline propagation honestly. Account deletion rule **5.1.1(v)** is not the basis here: Syl has no service-account creation.

### R18 — Notification controls can appear enabled when delivery is blocked

**Confirmed source UI omission.** HIG **Feedback, Notifications**; **2.1(a)** risk if advertised reminders appear broken.

Both Settings sections set `permissionError` but never display it; neither displays `.denied` status or scheduler errors (`NotificationsSettingsSection.swift:64–82`, `DailyExpenseReminderSettingsSection.swift:32–50`). The schedulers expose status/errors and correctly avoid scheduling without permission. Onboarding has denial messaging, Settings does not.

**Action:** show denied/unavailable/scheduling failure states and a deliberate link to iOS Settings. Keep reminders optional. Explain the finite recurring-reminder horizon if making long-term delivery promises; scheduled notifications do not require the app to remain running, but replenishment does.

### R19 — Large-ledger/import/recurring catch-up responsiveness is unproven

**Source risk, not measured production failure.** Review **2.1(a), 2.4.2**; HIG **Launching, Feedback**.

Several screens fetch all expenses; `SpendingMonthSummary` repeatedly scans history; `backfillMultiTags` runs full fetches on opening the app store. `RecurringExpenseService.swift:83–109` and `SpendingCalendarMonth.swift:54–64` have no iteration budget/yield for very old daily rules. Backup validation permits dates as early as `Date.distantPast`; import reads entire files into multiple representations. Receipt import decodes a full-sized image synchronously from the router.

**Action:** measure realistic large datasets and large imports on supported devices, bound/cancel untrusted workloads, batch catch-up and provide progress. Existing small fixtures do not establish acceptable memory, launch time or responsiveness.

## HIG/accessibility findings

These should be addressed before making accessibility claims. They are not all standalone review violations.

### H1 — Settings income is a hidden zero-sized text field

`WholeNumberCurrencyField.swift:25–29` makes the field invisible and 0×0, then uses a `Text.onTapGesture` as its visible entry point. It supplies no accessible edit action/label for that visible control. Unlike `CentsFirstCurrencyField`, it does not preserve a visible, hittable text-field representation.

**Action:** use an accessible native field or a proper button/AX representation that focuses it; verify VoiceOver, Voice Control and keyboard entry. HIG **VoiceOver, Accessibility**. A blocked primary control can become a **2.1/Section 4** issue.

### H2 — Mandatory seven-step onboarding excludes zero-income users

`OnboardingView.swift:45–46,179,463` requires a positive income and provides no setup skip. Tracking expenses does not inherently require positive income; students, retirees spending savings, and temporarily unemployed users must invent a value. Income is directly relevant to budgeting, so this is not automatically a **5.1.1(v)** personal-data violation.

**Action:** allow zero/no budget and deferring nonessential setup. HIG **Onboarding** recommends fast, optional onboarding and reasonable defaults. Localized digits are also discarded by the ASCII-only filter at line 257; normalize supported decimal digits.

### H3 — Remaining light-mode contrast shortcomings

`Sage` is `#87A96B`, identical in light/dark with no high-contrast asset variant. Against white its calculated WCAG contrast is **2.65:1**. `SageAccent` is `#6C8A4E`, **3.90:1** against white. Screenshots show Sage-colored Backup actions, selected tabs and pale receipt/type controls. Exact rendered contrast varies with Liquid Glass; these base-color calculations are not measurements of every pixel/background.

**Action:** check enabled text/icons in both appearances and Increase Contrast, including native tinted controls, chart lines and arbitrary tag colors. Use accessible foreground roles/variants. `TagsSettingsSection.swift:103–105` uses white symbols on any selected tag color, including yellow. HIG **Accessibility/Color** cites 4.5:1 for ordinary text and 3:1 for applicable larger/bold text; if normal appearance falls short, its guidance requires a suitable high-contrast alternative.

### H4 — Large text and constrained layouts still need work

- `SageApp.swift:275–277` supplies a fixed 34-point custom navigation font without UIFontMetrics scaling.
- `AddExpenseTagSheet.swift:241–245` limits budget help to two lines inside scrollable content. The dark/accessibility-XL screenshot reproduced truncation: “Cap how much you spend on thi…”, despite the control-reachability test passing.
- `TopSpendingBreakdown.swift:95–97` truncates tag names to one line with no drill-down in that component.
- Watch overview/category pages and charts repeatedly force one line and shrink text; test the smallest Watch and maximum text size.
- `UnknownTagsSheet` has non-scrolling header/footer and a medium-only sheet (`ExpenseBackupSettingsSection.swift:165,420–487`); many/long tags at accessibility sizes need verification.

The Release welcome screenshot at the largest accessibility size correctly reflows its heading and keeps Get Started visible. Expense/tag/recurring editors have scroll containers; absence of scrolling is not a current finding. HIG **Typography, Layout** asks for scalable custom fonts, meaningful text without truncation and adaptive stacking.

### H5 — Some touch targets and nonvisual interactions are weak

`TagPicker.swift:66–77` and medium `TagCapsule` use small text plus 6-point vertical padding with no 44-point minimum. These are below Apple's recommended default touch target; current HIG distinguishes the **44×44 default recommendation** from smaller minimum values, so “under 44” is not automatically a rejection.

Recurring rows rely on `onTapGesture` and a context menu without explicit button semantics (`RecurringExpensesSettingsSection.swift:39–55`). Tag budget input lacks a clear explicit accessibility label. AI-suggested tags expose selection but identify AI primarily with a transient rainbow glow. Stats' custom touch-only daily-detail overlay needs an equivalent nonvisual way to access its transaction detail, beyond the chart's cumulative-value labels.

**Action:** add meaningful semantics/alternative actions and test assistive technologies. HIG **Accessibility, VoiceOver, Charts, Generative AI**.

### H6 — Toast feedback can be missed, especially in iPad Settings

`AppRouter.swift:94–97` dismisses success and error toasts after three seconds. The overlay is attached beneath presented sheets (`RootTabView.swift:73–107`). Settings appears as a sheet on iPad, so important reset/sync/error feedback can be obscured. The announcement uses `.task` without toast identity; replacing progress with success while the view persists may not produce a new announcement.

**Action:** keep consequential failures visible in the affected screen and announce each update. Verify sheet stacking and progress-to-success with VoiceOver. HIG **Feedback, Accessibility** cautions against time-boxed essential information.

### H7 — Regional conventions are inconsistent

`Date+Relative.swift:35` hard-codes `M/d/yyyy`. `WholeNumberCurrencyField.swift:31–42` accepts non-ASCII `.isNumber` characters but passes them to `Int`, which does not normalize them. The custom calendar explicitly forces Sunday-first and left-to-right (`SpendingCalendarMonth.swift:34–35`, `ExpenseCalendarWidget.swift:77–78`).

**Action:** normalize digits and honor locale/calendar conventions or explain a deliberate user-selectable override. English-only translation is not itself a rejection; misleading regional dates and blocked input are the issues. HIG **Typography, Layout, Accessibility**.

### H8 — Chart summaries and empty-state explanations need accuracy

Top Tags counts the full amount under every tag (`TopSpendingBreakdown.swift:49–56`) without explaining that totals overlap. With untagged expenses present, Stats says “Add some expenses” although expenses exist (`StatsView.swift:408`). Empty category detail displays a Recent Purchases heading without a useful explanation/action. Calendar cells round every amount upward (`ExpenseCalendarWidget.swift:151–161`), so $1.23 appears as $2 and a small refund can appear as $0; exact values are available in detail/AX.

**Action:** explain overlapping totals and use precise empty-state causes; identify rounded values or use neutral rounding. HIG **Charts, Feedback**.

### H9 — Launch presentation is a branded splash rather than a matching launch screen

`Views/Launch Screen.storyboard:19–51` centers a logo/wordmark on solid Sage. This differs from the first interactive screen and does not adapt its background for dark mode. HIG [Launching](https://developer.apple.com/design/human-interface-guidelines/launching) recommends nearly matching the first screen and avoiding branding unless it is a fixed part of that screen.

**Action:** simplify the launch resource to match the first rendered background/layout. This is a low-severity HIG polish finding, not a probable standalone rejection.

## Conditional security, metadata and distribution checks

1. **Locked-device financial access:** all four financial App Intents omit `authenticationPolicy`; Apple's default is [alwaysAllowed, including while locked](https://developer.apple.com/documentation/appintents/appintent/authenticationpolicy). The iOS widgets do not mark financial views `.privacySensitive()`, whereas the Watch widget does. Choose and test the intended privacy model in Siri, StandBy, Lock Screen/Today access and system app locking. HIG **Privacy**, Review **1.6/5.1**; no claim here that an app-wide biometric lock is universally mandatory or that the device was exploited.
2. **iPad Settings discovery:** it exists only in the sidebar header and layout selection is based on idiom (`RootTabView.swift:42–69`). Verify compact/narrow windows with the sidebar collapsed still give access to settings, policy and deletion. HIG **Layout**, Review **5.1.1(i)/2.1** if those controls become inaccessible. Full-size portrait/landscape alone does not establish compact-window behavior.
3. **Support:** Feedback uses `mailto:hi@enzottic.me`, but no visible/copyable fallback address appears in the Settings row; a device without a mail handler may have no useful contact route, especially while the policy link is broken. Review **1.5** requires accessible contact information in the app and Support URL. The actual App Store Support URL is unknown.
4. **Financial-services classification:** Review **3.2.1(viii)** and **5.1.1(ix)** warrant checking seller identity and metadata. The inspected implementation is a manual personal ledger, with no banking connection, trading, lending, custody or payment execution. Do not assert it needs a bank license solely because it is in Finance. If marketed as regulated money management or requiring sensitive financial information, resolve entity/licensing applicability before submission.
5. **Beta copy:** `WhatsNewSheet.swift:20` includes “beta tester” and “improvments.” However, the release catalog contains only `0.9.1`, while the built version is `1.0`; `releaseToPresent()` returns nil for 1.0. This copy is **not established as reachable in this submission**. Clean it before adding 1.0 notes. Review **2.2/2.3** becomes relevant if exposed; compiling an unused string is not itself proof of shipping a beta experience.
6. **Public marketing:** `/syl` advertises a future macOS version, but the current target disables Catalyst and Designed for iPad on Mac. Future roadmap wording is not a false current-platform claim by itself; keep actual store screenshots, supported platforms, AI availability and descriptions aligned with the binary. Internal Sage identifiers and compatible file formats need not be renamed merely for branding. Review **2.3**.
7. **Siri discovery:** the simulator Release log reported failure connecting to `linkd` for shortcut parameter updates. This does not prove physical-device Siri discovery fails. Test cold launch, named tags/categories, locked-device policies and voice phrases. Review **2.5.11/2.1**.
8. **Production sync/archive:** validate CloudKit schema deployment, app groups, production push environment, all embedded target IDs/versions, manifests, font/icon licenses, icons and archive signing. A source `aps-environment=development` with automatic signing is not by itself proof that exported distribution signing is wrong. No distribution archive/upload validation was performed.
9. **Submission requirements:** Apple's live requirements page says Xcode 26+ and iOS/iPadOS/watchOS 26+ SDKs since April 28, 2026. Verify acceptance of the exact shipping toolchain; a locally installed beta SDK being able to build is not evidence App Store Connect accepts its binaries. Watch minimum is 26.6, phone minimum 26.0; verify the intended released-device compatibility matrix.
10. **App Store Connect:** complete accurate privacy labels, age questionnaire, screenshots with fictional financial data, contact/review notes, export-compliance answers, territories, agreements and applicable EU trader status. Source review cannot establish these are complete. Optional user-initiated support data may qualify for Apple's optional-disclosure exception only if all its criteria are satisfied.

Apple's App Privacy definition distinguishes data processed only on-device from data collected off-device and retained/accessed by the developer or partners. Do not automatically label every stored expense as developer-collected financial information. Equally, a native `NSPrivacyCollectedDataTypes` empty array does not settle the embedded website's collection behavior. Evaluate each actual data path against Apple's definition.

## Areas with positive current evidence

- Substantial native expense CRUD, budgets, tags, statistics, recurrence, backup/restore, widgets and Watch companion functionality: no source indication of a thin web wrapper or obvious **4.2** minimum-functionality problem.
- No app service-account login/creation, third-party social login, purchases/subscriptions, ads, public social feed or banking integration found in the shipped targets. Consequently no demonstrated missing Sign in with Apple, subscription restore, paywall disclosure, account-deletion flow or UGC reporting/blocking requirement for this feature set.
- Camera purpose string exists in the generated Release plist. Photos use the system picker without broad photo-library permission. Manual expense entry remains available when Apple Intelligence is unavailable. On-device Vision/FoundationModels are not evidence of third-party AI uploads.
- iCloud preference consent defaults off and the preference service guards acquisition/access after withdrawal. Push/background configuration is present in the main app.
- Money validation handles precision/range and refunds; explicit Settings denomination changes warn that values are not converted. Native JSON/CSV Files pickers are present, and import stages data in an autosave-disabled context with validation, cancellation checks and rollback.
- User-initiated destructive expense/reset operations have confirmation; changed drafts have discard protection. Recurring notification details default hidden and schedulers scrub sensitive pending/delivered content when requested.
- Most core navigation uses native TabView, NavigationStack, sheets, pickers, lists and controls. Many chart values, tag selections and calendar days have explicit AX semantics. Reduce Motion is honored in major animated flows, although a few generic animations still warrant device review rather than assuming every animation must be disabled.
- Production widget error paths use unavailable states rather than inventing sample expenses. Preview/demo fixtures alone are not a review violation.

## Verification performed

All build/test artifacts are under `/var/folders/2k/v3w5lqtn1xx019_h2vf061c00000gn/T/opencode/`.

- **Xcode 26.6 (17F113):** Release build attempts for generic simulator and device were blocked before compilation: “watchOS 26.5 must be installed.” Environment blocker, not an app compile error.
- **Xcode 27.0 (27A5252f), selected per command:** `build-for-testing`, scheme FinanceTracker, PR plan, iPhone 17e iOS 26.5 succeeded. One deprecation warning concerned `UIWindow(frame:)` in a layout test.
- **Release builds with Xcode 27:** unsigned device and simulator builds succeeded. Inspected generated version, camera purpose string, platforms, background mode, embedded Watch/widget products, main/framework manifests and bundled notices/font. No App Store upload or signing validation implied.
- **Real Release launch, iPhone 17e iOS 26.5:** initial unsigned install hit App Group recovery; a normal simulator-signing rebuild/install opened onboarding correctly. Reviewed light/default text and dark/maximum-accessibility-size welcome screenshots. This was a non-test-mode launch, but not completion of all Release workflows.
- **PR plan:** `SylReadinessPR.xcresult`: **292 logical tests, 288 passed, 4 failed, 0 skipped**. Parameterized device accounting reports 586 passed runs and 5 failed runs. Of the 15 UI tests actually discovered, 14 passed and one failed. `FinanceTracker-PR.xctestplan` lists a sixteenth `LedgerCurrencyUITests` selector whose class/method is absent from current sources; its absence is not currency UI coverage.
- **Focused rerun:** `SylReadinessFailureRecheck.xcresult`: 2 logical tests passed, 2 failed. Unsupported predicate reproduced for both month arguments. Expense-entry UI failed earlier on a non-hittable keyboard-toolbar AX element. No code edits between runs.
- **iPad:** `SylReadinessIPad.xcresult`, iPad mini A17 Pro, iOS 26.5: **1 passed**, covering category navigation and dashboard row-size/alignment assertions in portrait and landscape. The recurring-query runtime warning still occurs. The portrait screenshot was reviewed; the landscape attachment has rotation/cropping artifacts and does not establish full visual fidelity. Xcode's post-test simulator diagnostics collection timed out after 600 seconds; the test result itself finalized as passed.
- **Dark/enlarged text:** `SylReadinessAccessibility.xcresult`, iPhone 17e, iOS 26.5: **1 passed**, `TagEditorUITests.testTagControlsInDarkModeWithLargeText`. Screenshot reviewed; budget-help truncation remains (H4). After test execution ended, its separate post-test `simctl diagnose` process stalled and was terminated; the completed result bundle reports the test passed. This is not a full accessibility audit.
- Plist syntax checks passed for the app plist, app/SageKit manifests and app/widget/Watch entitlements. Syntax validity does not verify App Store completeness.
- Live HTTP checks confirmed `/sage/privacy` 404 and inspected `/syl/privacy` and `/syl` responses. No packet capture or vendor retention audit was performed.
- Screenshot/AX review included expense entry, Backup and native Files export/reimport, tag editor, Stats, and onboarding. This is not a comprehensive VoiceOver, contrast, motion or physical-device certification.
- `git diff --check` and a whitespace check of this new report passed. Only this audit report was added; the outdated readiness document and implementation were left untouched.

Representative commands (the alternate toolchain was selected with `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer`):

```sh
xcodebuild build-for-testing -project FinanceTracker.xcodeproj \
  -scheme FinanceTracker -testPlan FinanceTracker-PR \
  -destination 'platform=iOS Simulator,id=399D8A70-29AF-4A48-8CDA-D38B017D5077' \
  -derivedDataPath "$AUDIT_DIR/SylReadinessTests"

xcodebuild test-without-building -project FinanceTracker.xcodeproj \
  -scheme FinanceTracker -testPlan FinanceTracker-PR \
  -destination 'platform=iOS Simulator,id=399D8A70-29AF-4A48-8CDA-D38B017D5077' \
  -derivedDataPath "$AUDIT_DIR/SylReadinessTests" \
  -resultBundlePath "$AUDIT_DIR/SylReadinessPR.xcresult" \
  -parallel-testing-enabled NO
```

`AUDIT_DIR` above denotes the artifact directory listed at the start of this section. Retain the `.xcresult` bundles when tracking fixes; they contain the exact failure locations, runtime warnings and attachments.

## Exit criteria

1. Resolve R1–R8, including the reproducible query failure and Watch manifest omission.
2. Resolve the core UI-test failure with manual/device evidence; run a passing appropriate suite with real currency UI coverage restored.
3. Correct financial-information inconsistencies, meaningful accessibility barriers and misleading privacy/deletion/notification states.
4. Test the actual Release candidate on minimum/current iPhone and iPad OS versions and a paired Watch; include production iCloud, offline/concurrent edits, backups, deletion, locked-device behavior, permissions, Apple Intelligence unavailable/available, large text and large ledgers.
5. Validate the distribution archive and App Store Connect submission data. Provide review notes explaining the manual ledger, no service account, optional iCloud/restart behavior, non-converting denomination changes, AI availability, widgets/Watch and Siri.

## Primary Apple references

- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [HIG](https://developer.apple.com/design/human-interface-guidelines)
- [Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy), [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility), [VoiceOver](https://developer.apple.com/design/human-interface-guidelines/voiceover)
- [Typography](https://developer.apple.com/design/human-interface-guidelines/typography), [Layout](https://developer.apple.com/design/human-interface-guidelines/layout), [Charts](https://developer.apple.com/design/human-interface-guidelines/charts)
- [Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding), [Launching](https://developer.apple.com/design/human-interface-guidelines/launching), [Feedback](https://developer.apple.com/design/human-interface-guidelines/feedback)
- [Generative AI](https://developer.apple.com/design/human-interface-guidelines/generative-ai), [Motion](https://developer.apple.com/design/human-interface-guidelines/motion), [Notifications](https://developer.apple.com/design/human-interface-guidelines/notifications)
- [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [Required-reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api) and [approved API reasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)
- [Current submission requirements](https://developer.apple.com/news/upcoming-requirements/)
