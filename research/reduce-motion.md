# Reduce Motion audit for #65

Apple guidance reviewed before implementation on September 9, 2026:

- [Accessibility HIG](https://developer.apple.com/design/human-interface-guidelines/accessibility):
  reduce automatic, repetitive, and spatial motion; replace movement with fades.
- [Reduced Motion evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria):
  evaluate each animation individually. Preserve meaningful feedback, using a
  dissolve, highlight, or color change where appropriate. Decorative motion can
  stop entirely; disabling every animation can hurt usability.
- [SwiftUI accessibilityReduceMotion](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion):
  read the system preference through the view environment. Avoid large animations,
  especially simulated depth, when it is enabled.
- [SwiftUI transactions](https://developer.apple.com/documentation/swiftui/transaction):
  bindings and `withAnimation` supply animations to state updates. Based on this,
  Sage keeps custom animation policy in the affected view instead of shared state.

## Implementation decisions

| Surface | Default motion | With Reduce Motion |
| --- | --- | --- |
| Toast appearance and dismissal | Existing 0.4-second spring and top-edge movement | 0.2-second opacity fade; no movement |
| Tag monthly-budget fields | Existing 0.2-second ease-in/out and top-edge transition | Immediate insertion/removal; no animated layout or transition |
| New expense recurring options | Existing 0.3-second spring and top-edge transition | Existing nil-animation guard retained; transition explicitly uses identity |
| Recurring rule end-date picker | Existing default animation | Immediate insertion/removal; no custom layout animation |

These are product choices for the four surfaces in #65, based on the guidance
above. A short toast fade retains status feedback. The form's switch state and
newly visible labeled fields make the result clear without animating their size
or position. Native switches, pickers, sheets, navigation, and the toast's
`ProgressView` remain system controls. There is no app-wide animation override.

`RootTabView` owns toast presentation animation inside the overlay. `AppRouter`
only changes toast state, cancels the previous dismissal task, and schedules
the existing three-second dismissal for non-progress toasts. Replacing a visible
toast updates its content immediately, avoiding a spring-driven size change.
Progress messages still persist until replaced; success haptics and accessibility
labels/announcements remain in place.

The tag editor scopes budget animation to its editor content, and the recurring
editor scopes end-date animation to its options. Each reads
`@Environment(\.accessibilityReduceMotion)` so subsequent interactions and toast
dismissal use the current preference, including after a Settings change. Existing
progress, tag-selection, expense-date, and Stats month guards are outside this
issue's remaining scope and are preserved.

## Evidence and pending verification

Implementation evidence:

- [Toast state](../FinanceTracker/Router/AppRouter.swift) and
  [presentation](../FinanceTracker/Views/RootTabView.swift).
- [Budget editor](../FinanceTracker/Views/SettingsView/Components/AddExpenseTagSheet.swift),
  [recurring options](../FinanceTracker/Views/Components/AddExpenseView.swift), and
  [end-date editor](../FinanceTracker/Views/SettingsView/Components/EditRecurringRuleSheet.swift).

Source and diff review only. No local build, automated tests, or simulator/device
tests were run, as requested; build and automated test results belong to PR CI.
The existing CI does not replace visual motion verification. Device/release
verification remains pending, including:

- With Reduce Motion off and on, show success/error toasts and replace a progress
  toast. Check presentation, replacement, three-second dismissal, and persistence
  of progress feedback. Change the setting while a toast is visible and check its
  dismissal uses the new preference.
- Toggle Monthly Budget, Recurring, and End Date in both modes. Check all fields
  remain usable, toggling off/on retains draft values, and saved values are
  unaffected. Change the setting while each editor is open and repeat.
- Check native sheets, pickers, switches, navigation, toast announcements, and
  success haptics on the supported iPhone/iPad configurations.

Completing this source audit does not establish release-device verification or
an App Store accessibility-support claim.
