# Sage App Intents Siri Reproduction

This is a deliberately small iOS project extracted from Sage. It preserves the part of the production architecture involved in App Intent discovery:

- `SageIntentsSample` is the host app.
- `SageIntentsKit` is an embedded framework containing the intents, entities, and `AppShortcutsProvider`.
- The host app exposes `SageIntentsKitPackage` through `MainAppPackage` and calls `updateAppShortcutParameters()` at launch, as Sage does.
- A small SwiftData store supplies realistic expense and tag data to the intents through `AppDependencyManager`.

There are no test targets or third-party dependencies.

## Reproduce

1. Open `SageIntentsSample.xcodeproj` in Xcode.
2. Select your development team for the `SageIntentsSample` target if Xcode requests one.
3. Install and launch the app on a Siri-enabled iPhone once. The app seeds a few sample expenses and shows the registered phrases.
4. Close the app and ask Siri one of these phrases:
   - “Add an expense to Sage Intent Sample”
   - “How much have I spent this month in Sage Intent Sample”
   - “How much budget do I have left this month in Sage Intent Sample”
   - “Find my expenses in Sage Intent Sample”
5. Observe that Siri does not discover or route to the corresponding App Intent as expected.

The intents can also be inspected in the Shortcuts app to compare explicit shortcut execution with Siri discovery.

