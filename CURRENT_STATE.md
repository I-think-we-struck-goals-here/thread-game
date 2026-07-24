# Current State

Last updated: 2026-07-24

This file is an operational snapshot of the repo as it exists locally right now. It is intentionally specific to the current working tree, not a timeless product overview.

## Verified Facts

### Repo state

- Current branch: `main`
- Current HEAD commit: `8d71f34 fix website daily rollover bundle`
- The working tree is currently mixed and dirty across:
  - native iOS app code and assets
  - website app code
  - backend/API code
  - static site/docs output
  - generated Xcode files
  - local Xcode user state
- `CURRENT_STATE.md` and `AGENTS.md` were absent before this handoff and are currently local additions in this working tree.
- `.gitignore` now excludes `xcuserdata`; local Xcode user state must remain uncommitted.
- The following currently appear as untracked local additions in this working tree:
  - `CURRENT_STATE.md`
  - `AGENTS.md`
  - `api/`
  - `docs/thread-backend.md`
  - `public/dashboard/`
  - `docs/dashboard/`

### Current dirty-tree scope by area

Verified from `git status --short` and `git diff --stat`:

- Native iOS tracked modifications:
  - app flow, stats, settings, shared UI, models, stores, tests, `Info.plist`, `project.yml`, generated `project.pbxproj`
- Native iOS untracked additions:
  - streak badge asset sets in `native-ios/Thread/Resources/Assets.xcassets/`
  - multiple design/spec HTML files in `native-ios/docs/`
- Website tracked modifications:
  - `src/App.jsx`
  - `public/privacy/index.html`
  - `public/support/index.html`
  - `public/terms/index.html`
  - `docs/` static output equivalents
- Backend/untracked additions:
  - `api/`
  - `.env.example`
  - `vercel.json`
  - `docs/thread-backend.md`
  - `public/dashboard/`
  - `docs/dashboard/`
- Repo/tooling tracked modifications:
  - `package.json`
  - `package-lock.json`
  - `.gitignore`

### Native iOS release/config

- Source of truth: `native-ios/project.yml`
- Current app version/build in config:
  - `MARKETING_VERSION: 1.1.0`
  - `CURRENT_PROJECT_VERSION: 10`
- Current app identities:
  - `Debug`: `Daily Thread Dev` / `co.dailythread.threadapp.dev`
  - `Release`: `Daily Thread` / `co.dailythread.threadapp`
- Current reminder times from config:
  - `Release`: `21:00`
  - `Debug`: `11:40`
- Remote analytics and aggregate endpoints are empty in the audited `1.1.0` Release config.

### Website/native daily schedule

- The website and native app now use the same daily puzzle schedule.
- Canonical daily puzzle rollover: midnight `Europe/London`.
- User progress remains separate:
  - website progress is website-local
  - native app progress is app-local plus private iCloud sync in `Release`
- The native app scheduler no longer uses the device's local time zone for daily puzzle selection.

### Native iOS feature work visible in code

Recent native app work is concentrated in:

- `native-ios/Thread/App/ThreadRootViewModel.swift`
- `native-ios/Thread/App/ThreadApp.swift`
- `native-ios/Thread/Features/DailyGameView.swift`
- `native-ios/Thread/Features/SettingsView.swift`
- `native-ios/Thread/Features/StatsView.swift`
- `native-ios/Thread/Shared/ThreadUI.swift`
- `native-ios/Thread/Models/ThreadModels.swift`
- `native-ios/Thread/Services/ThreadStores.swift`
- `native-ios/Thread/Services/ThreadServices.swift`
- `native-ios/ThreadTests/ThreadCoreTests.swift`

Verified implemented areas:

- first-daily nudge system exists in the app state model and daily flow
- custom composer affordance work exists in the daily round screen
- streak badge milestones and display logic exist
- streak badge assets exist in `native-ios/Thread/Resources/Assets.xcassets/StreakBadge*.imageset`
- stats screen has a streak badge section
- daily completion can show a one-time streak badge unlock overlay
- debug-only badge preview tools exist in Settings
- debug notification diagnostics/tools exist in Settings
- Settings dev/QA controls are compiled only under `#if DEBUG`; Release settings exposes only real preferences and support/privacy links
- debug notification diagnostics/test-reminder code is compiled out of `Release`, not just hidden from the Settings UI
- debug badge preview storage/model code is compiled out of `Release`, not just hidden from the Settings UI
- the Settings daily-reminder toggle confirmation flow has a regression fix for SwiftUI alert dismissal racing the async permission-confirm action
- daily completion now immediately reschedules local reminders with a solved-today context, preventing stale 9:00 PM reminders after completion
- the custom SwiftUI launch reveal/streak overlay and root screen transition have been removed; the first resolved local screen gets only a tiny non-blocking entrance polish pass, and streak messaging now appears after solving the daily thread
- an Archive UX is implemented in the current dirty native tree: past Threads can be filtered, played/resumed, and revisited after completion
- Archive history/snapshots are stored separately from daily progress, so Archive plays do not affect daily stats, streaks, badges, reminders, aggregate results, or daily routing
- Archive entry points are now available in all builds behind a verified non-consumable StoreKit 2 entitlement
- the Archive paywall loads Apple's localized price, supports verified purchase and explicit restore, and listens for transaction entitlement updates
- the App Store Connect IAP is `Daily Thread Archive` / `Thread Archive`, product ID `co.dailythread.threadapp.archive`, Apple ID `6793079865`, configured at `£0.99`
- Archive progress is still device-local and is not included in CloudKit sync; StoreKit restores access, not completion state
- unfinished daily progress now moves into the Archive after London-day rollover instead of becoming inaccessible
- Archive entitlement startup, restore, and revocation races are covered by regression tests

### Website/backend work visible in the tree

- `api/` exists locally with public and admin endpoints
- `public/dashboard/index.html` exists locally as a private owner dashboard
- `docs/thread-backend.md` exists locally and documents the backend shape
- `src/App.jsx` is modified in the current tree
- `public/` and `docs/` both have legal/support changes in flight

### Current local build/test signal

- `native-ios/Thread/Info.plist` passes `plutil -lint`.
- `native-ios/project.yml` and `native-ios/ThreadApp.xcodeproj/project.pbxproj` currently agree on the release version/build. The project was regenerated successfully on 2026-07-21; `project.yml` remains the source of truth.
- Archive Debug and Release iPhoneOS builds pass with signing disabled.
- Simulator tests pass on iPhone 17 / iOS 26.5: `64 tests, 0 failures`.
- StoreKit coverage includes purchase, cancellation, pending, successful and unsuccessful restore, startup entitlement races, revocation, product retry, and an exact local configuration contract for product ID, non-consumable type, UK price, display name, and description.
- Release iPhoneOS build passed with signing disabled:
  - latest audit command: `xcodebuild -project ThreadApp.xcodeproj -scheme ThreadApp -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/thread-ios-redteam-release-final2 CODE_SIGNING_ALLOWED=NO build -quiet`
  - built product reports `CFBundleShortVersionString = 1.1.0`, `CFBundleVersion = 10`, `CFBundleIdentifier = co.dailythread.threadapp`
  - built product reports `ThreadResetProgressOnLaunch = NO`
  - built product reports empty analytics and aggregate base URLs
  - built launch screen plist contains only `UIColorName = LaunchBackground`
  - the local `.storekit` configuration is not bundled in the Release app
  - release binary string scan found no debug Settings reset, notification test, or badge-preview labels
  - unsigned Release app is approximately `10 MB`; `Assets.car` is approximately `3.9 MB`
- Signed Release archive passed:
  - command: `xcodebuild -project ThreadApp.xcodeproj -scheme ThreadApp -configuration Release -destination 'generic/platform=iOS' -archivePath /private/tmp/ThreadApp-1.0.3-6-AppStorePrep.xcarchive archive`
  - archive path: `/private/tmp/ThreadApp-1.0.3-6-AppStorePrep.xcarchive`
  - archive reports `CFBundleShortVersionString = 1.0.3`, `CFBundleVersion = 6`, `CFBundleIdentifier = co.dailythread.threadapp`
- App Store export passed:
  - command: `xcodebuild -exportArchive -archivePath /private/tmp/ThreadApp-1.0.3-6-AppStorePrep.xcarchive -exportPath /private/tmp/ThreadApp-1.0.3-6-AppStoreExport -exportOptionsPlist /private/tmp/thread-app-store-export-options.plist -allowProvisioningUpdates`
  - export path: `/private/tmp/ThreadApp-1.0.3-6-AppStoreExport`
  - exported package: `/private/tmp/ThreadApp-1.0.3-6-AppStoreExport/Daily Thread.ipa`
  - distribution summary reports `versionNumber = 1.0.3`, `buildNumber = 6`, `arm64`, `Cloud Managed Apple Distribution`, `get-task-allow = false`, iCloud Production entitlements, and App Store provisioning profile `iOS Team Store Provisioning Profile: co.dailythread.threadapp`
  - this archive/export predates the reminder fixes and the current `1.1.0 (10)` Archive work; do not upload it
- Fresh clean-source `1.1.0 (10)` signed archive and App Store Connect export passed on 2026-07-24:
  - archive: `/private/tmp/ThreadApp-1.1.0-10-Publish.xcarchive`
  - exported IPA: `/private/tmp/ThreadApp-1.1.0-10-Publish-Export/Daily Thread.ipa`
  - IPA SHA-256: `f996680fe42a3e3597f1455358a299d7ec19602014dda46ac4f41ece4be3d26e`
  - the publish asset catalog excludes the untracked, unreferenced `ThreadLaunchScreenIcon` imageset
  - distribution summary reports `1.1.0 (10)`, `arm64`, Cloud Managed Apple Distribution, Production CloudKit, `get-task-allow = false`, and App Store provisioning for `co.dailythread.threadapp`
  - effective build settings disable Mac and Vision compatibility; exported `UIDeviceFamily` is `[1]`
  - use this archive lineage for validation/upload; do not use the older `1.0.3` archive
- Latest simulator audit command:
  - `xcodebuild -project ThreadApp.xcodeproj -scheme ThreadApp -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -derivedDataPath /private/tmp/thread-ios-archive-storekit-final2-tests test -quiet`
- Public App Review URLs checked after the 2026-07-24 GitHub Pages deployment:
  - `https://daily-thread.co/privacy/` returned `200`
  - `https://daily-thread.co/support/` returned `200`
  - `https://daily-thread.co/terms/` returned `200`
- The live pages now include the Archive IAP terms, the current support email, and guidance that matches the Release app's lack of a progress-reset control.
- Fresh simulator smoke check installed and launched `/private/tmp/thread-ios-tests-direct-start/Build/Products/Debug-iphonesimulator/Thread.app`; it reached the live daily game screen directly after the native launch screen.
- First-screen polish simulator smoke check installed and launched `/private/tmp/thread-ios-tests-first-screen-polish/Build/Products/Debug-iphonesimulator/Thread.app`; screenshot captured at `/private/tmp/thread-first-screen-polish-smoke.png`.
- Solved-state screenshots show the answer plus `1 day streak` before `See results`.
- App Store Connect rejected `1.0.3 (7)` because the `1.0.3` train is closed for new build submissions. Do not reuse any old archive; the next upload target is a fresh signed `1.1.0 (10)` Archive build.

## Confirmed 1.1.0 Archive Release Slice

The intended app update scope is:

1. playable Archive for every past Thread
2. separate Archive progress that cannot affect the daily game, stats, streaks, badges, reminders, or aggregate results
3. non-consumable StoreKit 2 purchase and entitlement gating
4. purchase, pending, cancellation, restore, revocation, and product-unavailable UX
5. the previously prepared stale evening-reminder hardening

Before submission, the remaining release checks are a signed-device/TestFlight purchase and restore pass, an IAP review screenshot, and attaching the IAP to the `1.1.0` app version for its first review.

The clean `1.1.0 (10)` archive upload succeeded through Xcode at 13:09 London time on 2026-07-24. App Store Connect reported that the uploaded package was processing.

## Historical 1.0.5 Patch Slice

The intended app update scope is now explicit:

1. stale 9:00 PM local reminder hardening after the daily thread has already been completed
2. reminder scheduling clears old pending reminder requests before adding the current schedule
3. daily completion reschedules reminders with a solved-today context

The previous `1.0.4` update already carried the streak badges, stats polish, unlock overlay, solved-state streak line, resilient Results routing, and reminder-toggle permission confirmation fix.

Related native debug QA tooling and handoff docs may be included as supporting work.

Out of scope for this app update:

- `api/`
- `public/dashboard/`
- website app changes
- legal/static-site content changes
- backend/admin dashboard work
- local Xcode `xcuserdata`

## Active Native iOS Snapshot

### Streak badges

Code points:

- badge models and logic:
  - `native-ios/Thread/Models/ThreadModels.swift`
- persisted shown milestones and debug badge preview state:
  - `native-ios/Thread/Services/ThreadStores.swift`
- derived badge state and preview hooks:
  - `native-ios/Thread/App/ThreadRootViewModel.swift`
  - Debug badge preview persistence is covered by `testDebugBadgePreviewStatePersistsOverrides`.
- stats screen integration:
  - `native-ios/Thread/Features/StatsView.swift`
- shared badge rail / badge view / unlock overlay:
  - `native-ios/Thread/Shared/ThreadUI.swift`
- daily completion integration:
  - `native-ios/Thread/Features/DailyGameView.swift`
- debug preview entrypoints:
  - `native-ios/Thread/Features/SettingsView.swift`
  - `native-ios/Thread/App/ThreadApp.swift`

Current intended UI direction, based on code and local design artifacts:

- stats screen:
  - top 2x2 metrics
  - `Scores` card with average clue count in the header
  - streak badges below `Scores`
  - horizontal scrolling badge rail
  - earned badges in full color
  - future badges greyed out
- unlock moment:
  - one-time overlay above the solve screen
  - badge art + `New badge` + milestone title + continue button
- launch:
  - the native iOS launch screen now uses only the matching warm background instead of the system white default; no logo image is shown during launch
  - the custom SwiftUI launch reveal, launch animation, launch streak line, root screen transition, and launch snapshot cache have been removed
  - after the native launch screen, SwiftUI goes directly to the first local app screen
  - the first resolved SwiftUI screen gets a one-time `0.16s` opacity/5pt settle polish pass; Reduce Motion skips it
  - streak messaging now appears on the solved daily success state and the one-time streak badge unlock overlay
- results routing:
  - bootstrap chooses the first local screen before private cloud sync, then reconciles visible daily/tutorial state after sync completes
  - stale private-cloud sync responses are merged against fresh local state before being applied
  - this protects the just-completed daily result from being cleared by an in-flight sync finishing after completion

Known streak-rule caveat for this release:

- stats and badge earn state use consecutive played days through `ThreadStatisticsBuilder.bestStreak`
- the one-time unlock overlay uses `projectedSolvedDailyStreakCount`
- this means a failed daily can contribute to earned badge state in Stats, while the unlock overlay only appears for solved-day milestones
- this behavior has not been normalized in code for `1.0.3`; revisit in a future product decision if badges should strictly mean solved-day streaks or played-day streaks everywhere

Current validation notes:

- user reported the dev version was checked on device before confirming the release slice
- automated tests include regressions for cloud-only already-played bootstrap and the in-flight cloud-sync/results-screen race
- automated validation currently covers build/test health, not every possible on-device milestone path
- the native app release slice is ready to upload to App Store Connect

### Notifications/debug tools

There is meaningful debug-only tooling in:

- `native-ios/Thread/Features/SettingsView.swift`

This includes:

- reset app to first launch
- notification diagnostics/test reminder
- streak badge stats/unlock preview flows

This area is release-sensitive. Future sessions should verify that debug tooling remains compiled out of release UI/code paths and that release config still uses the production reminder schedule and bundle identity.

### Website/backend/admin snapshot

Verified file-level reality:

- the backend now has real public/admin endpoints in `api/`
- admin summary endpoints exist at:
  - `api/v1/admin/round-summary.js`
  - `api/v1/admin/product-summary.js`
- a private owner dashboard exists at:
  - `public/dashboard/index.html`
- `docs/thread-backend.md` documents the backend shape, but it is currently a local/untracked artifact in this working tree

This means the repo is no longer just “website + app”; a future session should treat backend/dashboard changes as a real active surface when triaging scope.

## Fragile Areas / Risks

### 1. Mixed dirty working tree

This is the biggest operational risk.

The current tree mixes:

- native app feature work
- website changes
- backend changes
- static site/doc changes
- generated Xcode changes
- local Xcode state

Do not assume all of this belongs in one commit or one release.

### 2. Generated-vs-source confusion on native iOS

`native-ios/project.yml` is the source of truth.

`native-ios/ThreadApp.xcodeproj/project.pbxproj` is generated output and may be dirty simply because the project was regenerated after real source changes.

Do not hand-edit generated Xcode config unless you deliberately mean to.

### 3. Design mock vs shipped behavior confusion

There are multiple HTML design artifacts under `native-ios/docs/`:

- `composer-affordance-mock.html`
- `first-daily-nudge-mock.html`
- `stats-page-streak-badges.html`
- `stats-page-streak-badges-compare.html`
- `streak-badge-unlock-moment.html`
- `badge-system-visions.html`

These are useful context, but they are not proof of what the app currently ships. Always verify the live SwiftUI implementation.

### 4. Local Xcode/platform state

The machine currently shows signs of Xcode/platform drift for simulator/device destinations.

Do not over-interpret destination/runtime failures as app-code failures without checking the exact error.

### 5. Mixed-release-surface risk

The approved next app update is `1.1.0 (10)`: paid Archive plus the already-prepared stale evening-reminder hardening. StoreKit access and restore are implemented, but the signed/TestFlight transaction pass and App Store review metadata are still required. The rest of the dirty tree is still mixed and should not be swept into the app update unless there is a separate explicit decision.

## Unknowns

- Whether the current local design-mock docs are final enough to treat as approval artifacts
- Whether future streak badges should be based on consecutive played days or consecutive solved days everywhere
- Whether every possible streak-badge milestone edge case has been manually QAed on device
- Whether the first signed/TestFlight Archive purchase, restore, and revocation pass has completed
- Whether the Archive IAP review screenshot has been attached in App Store Connect
- Current live App Store Connect version/IAP attachment state; the release-audit browser session was logged out
- Whether Archive completion and in-progress state should join private CloudKit in a later release
- How the Archive schedule will become server-authoritative before the current future pool repeats on 26 November 2026
- Whether all unrelated website/backend/dashboard work should be split into separate commits or left local

These are real unknowns, not things that should be guessed from the current tree.

## Immediate Next Steps

1. Run the app from Xcode with `StoreKit/Archive.storekit` selected and capture the paywall screenshot required by IAP review.
2. Test buy, cancel, pending/Ask to Buy, restore, relaunch entitlement, and refund/revocation in the local StoreKit environment.
3. After build `10` finishes processing, make it available in TestFlight and repeat purchase/restore with a sandbox tester.
4. In App Store Connect, attach `Thread Archive` to the `1.1.0` version and submit the app and first IAP together.
5. Confirm daily stats, streaks, reminders, and today's saved game remain unchanged after Archive play.
6. Decide later whether Archive progress should join the existing private CloudKit model; it is device-local today.
7. Replace or pin the bundled future schedule before 26 November 2026; modifying the current future pool can remap historical Archive dates.

## Recommended Starting Point For The Next Session

Start with:

1. `README.md`
2. this file
3. `AGENTS.md`
4. `native-ios/README.md`
5. `native-ios/docs/app-store-launch.md`

Then inspect:

- `native-ios/project.yml`
- `native-ios/Thread/App/ThreadRootViewModel.swift`
- `native-ios/Thread/App/ThreadApp.swift`
- `native-ios/Thread/Features/DailyGameView.swift`
- `native-ios/Thread/Features/StatsView.swift`
- `native-ios/Thread/Features/SettingsView.swift`
- `native-ios/Thread/Shared/ThreadUI.swift`
- `native-ios/Thread/Models/ThreadModels.swift`
- `native-ios/Thread/Services/ThreadStores.swift`
- `native-ios/ThreadTests/ThreadCoreTests.swift`

Then verify the actual intended work by reading the current diff, not by trusting assumptions from docs alone.
