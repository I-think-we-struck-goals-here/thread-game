# Daily Thread iPhone App

This is the native SwiftUI app for Daily Thread.

It is not a wrapper around the website. The website remains separate and the app is built as a local-first iPhone product with optional first-party services layered on top.

## Current product state

- Platform: `iPhone only`
- Orientation: portrait only
- App Store name: `Daily Thread`
- In-app wordmark: `THREAD`
- Gameplay: local-first and offline-first
- Day rollover: device local midnight
- Cross-device sync: private iCloud sync in `Release`
- Website sync: none
- Remote push: off
- Local reminders: supported
- First-party analytics: supported
- Anonymous aggregate daily score upload: off

## What is separate from the website

The app and website intentionally behave differently in two important ways:

1. Day boundary
- Website unlocks the next thread at midnight `Europe/London`
- App unlocks the next thread at midnight in the device's local time zone

2. User progress
- Website progress is website-local
- App progress is app-local plus private iCloud sync in `Release`
- There is no account-based sync between website and app

They still share the same round order and puzzle IDs.

## Main files

- [`project.yml`](/Users/zacellis/thread-game-site/native-ios/project.yml)
  - source of truth for Xcode project generation and build settings
- [`Thread/App/ThreadApp.swift`](/Users/zacellis/thread-game-site/native-ios/Thread/App/ThreadApp.swift)
  - app entry and root screen composition
- [`Thread/App/ThreadRootViewModel.swift`](/Users/zacellis/thread-game-site/native-ios/Thread/App/ThreadRootViewModel.swift)
  - root state machine, daily routing, notifications, analytics triggers, CloudKit sync coordination
- [`Thread/Services/ThreadServices.swift`](/Users/zacellis/thread-game-site/native-ios/Thread/Services/ThreadServices.swift)
  - date formatting, daily scheduler, external link resolution, stats helpers
- [`Thread/Services/ThreadRepository.swift`](/Users/zacellis/thread-game-site/native-ios/Thread/Services/ThreadRepository.swift)
  - loads bundled practice and daily rounds
- [`Thread/Resources/daily-rounds.json`](/Users/zacellis/thread-game-site/native-ios/Thread/Resources/daily-rounds.json)
  - bundled daily puzzle dataset for the app
- [`Thread/Features/`](/Users/zacellis/thread-game-site/native-ios/Thread/Features)
  - gameplay, tutorial, results, settings, stats screens
- [`Thread/Shared/ThreadTheme.swift`](/Users/zacellis/thread-game-site/native-ios/Thread/Shared/ThreadTheme.swift)
  - palette, typography, spacing, motion tokens
- [`Thread/Shared/ThreadUI.swift`](/Users/zacellis/thread-game-site/native-ios/Thread/Shared/ThreadUI.swift)
  - shared UI primitives and launch/reveal components

## Build and run

Generate the Xcode project:

```bash
xcodegen generate
```

Open the project:

```bash
open ThreadApp.xcodeproj
```

Device build from CLI:

```bash
xcodebuild -project ThreadApp.xcodeproj -scheme ThreadApp -configuration Debug -sdk iphoneos build
```

Archive:

```bash
THREAD_DEVELOPMENT_TEAM=YOURTEAMID ./scripts/archive-thread-ios.sh
```

Optional export after archive:

```bash
THREAD_DEVELOPMENT_TEAM=YOURTEAMID \
THREAD_EXPORT_OPTIONS_PLIST=/absolute/path/ExportOptions.plist \
./scripts/archive-thread-ios.sh
```

## Important build settings

Defined in [`project.yml`](/Users/zacellis/thread-game-site/native-ios/project.yml):

- `THREAD_DISPLAY_NAME`
- `THREAD_BUNDLE_IDENTIFIER`
- `THREAD_SUPPORT_URL`
- `THREAD_SUPPORT_EMAIL`
- `THREAD_PRIVACY_POLICY_URL`
- `THREAD_APP_STORE_URL`
- `THREAD_ANALYTICS_BASE_URL`
- `THREAD_ANALYTICS_API_KEY`
- `THREAD_ANALYTICS_BUILD_CHANNEL`
- `THREAD_AGGREGATE_BASE_URL`
- `THREAD_AGGREGATE_API_KEY`
- `THREAD_ENABLE_REMOTE_PUSH`
- `THREAD_PUSH_BASE_URL`
- `THREAD_PUSH_API_KEY`
- `THREAD_ICLOUD_CONTAINER_IDENTIFIER`
- `THREAD_ENABLE_ICLOUD_SYNC`
- `THREAD_RESET_PROGRESS_ON_LAUNCH`

Current effective behavior:

- `Debug`
  - analytics base URL: on
  - analytics build channel: `debug`
  - iCloud sync: off
  - reset progress on launch: off

- `Release`
  - analytics base URL: on
  - analytics build channel: `release`
  - iCloud sync: on
  - reset progress on launch: off

## Current startup and routing behavior

- First true launch with no history and no snapshot:
  - app opens to tutorial/practice
- After tutorial or once any puzzle history exists:
  - app opens directly to the current daily thread
- If today's daily is already completed:
  - app opens to the compact already-played state
- Cold launch no longer uses a separate loading splash
- Startup now resolves directly into the `Thread #...` reveal

## Notifications and reminders

The app uses local notifications only.

Reminder schedule:

- `9:00 AM`
  - title: `A new Thread is live`
  - body: `Today's puzzle is ready.`
- `9:00 PM`
  - unsolved day: `Still time to solve`
  - if current streak is `10+`: `Keep your X-day run alive`

Permission prompt behavior:

- reminders default to off on a fresh install
- turning reminders on in Settings triggers the prompt immediately
- first automatic ask:
  - `15 seconds` after the user's first solved daily Thread
- second automatic ask:
  - `15 seconds` after the user's third completed daily Thread
  - only if permission still is not granted and one prompt has already been shown

Current prompt copy:

- title: `Never miss a Thread`
- message: `Turn on reminders when each new Thread goes live.`
- CTA: `Turn on reminders`

Relevant files:

- [`Thread/Services/ThreadNotifications.swift`](/Users/zacellis/thread-game-site/native-ios/Thread/Services/ThreadNotifications.swift)
- [`Thread/App/ThreadRootViewModel.swift`](/Users/zacellis/thread-game-site/native-ios/Thread/App/ThreadRootViewModel.swift)

## Analytics

The app uses first-party analytics only.

Behavior:

- falls back to local logging if no analytics base URL is configured
- uploads anonymous product events when the remote analytics endpoint is configured
- distinguishes `debug` and `release` using `ThreadAnalyticsBuildChannel`

Important:

- no Apple ID
- no email
- no contact data
- no ad SDK
- no cross-app tracking

Contracts:

- [`docs/analytics-service-contract.md`](/Users/zacellis/thread-game-site/native-ios/docs/analytics-service-contract.md)
- [`../docs/thread-backend.md`](/Users/zacellis/thread-game-site/docs/thread-backend.md)

## Private iCloud sync

CloudKit private-database sync is enabled in `Release` only.

Synced data:

- preferences
- daily history
- in-progress daily snapshots

Design rules:

- local-first always
- CloudKit is additive
- app still works offline
- no in-app account or profile system

Relevant files:

- [`Thread/Services/ThreadCloudKitSync.swift`](/Users/zacellis/thread-game-site/native-ios/Thread/Services/ThreadCloudKitSync.swift)
- [`Thread/Thread.entitlements`](/Users/zacellis/thread-game-site/native-ios/Thread/Thread.entitlements)
- [`Thread/Info.plist`](/Users/zacellis/thread-game-site/native-ios/Thread/Info.plist)

## Settings and debug tools

Release settings should only expose real user preferences and support/privacy links.

Debug-only local QA tools are hidden behind `#if DEBUG` in:

- [`Thread/Features/SettingsView.swift`](/Users/zacellis/thread-game-site/native-ios/Thread/Features/SettingsView.swift)

Those tools currently include:

- `Reset app to first launch`
- `Replay launch animation`

They should never be surfaced in `Release`.

## Updating future daily puzzles

The app ships future puzzles in a bundled local dataset:

- [`Thread/Resources/daily-rounds.json`](/Users/zacellis/thread-game-site/native-ios/Thread/Resources/daily-rounds.json)

If you need to change a future app puzzle:

1. edit the bundled round data
2. if the website should match, update the website side too
3. ship a new app build

There is no remote puzzle override system in the app today.

To regenerate the native bundled dataset from the website reference app:

```bash
node ../scripts/export-thread-rounds.mjs
```

## Supporting docs

- [`docs/app-store-launch.md`](/Users/zacellis/thread-game-site/native-ios/docs/app-store-launch.md)
  - current App Store / privacy / release assumptions
- [`docs/app-store-copy.md`](/Users/zacellis/thread-game-site/native-ios/docs/app-store-copy.md)
  - listing copy and submission content
- [`docs/aggregate-service-contract.md`](/Users/zacellis/thread-game-site/native-ios/docs/aggregate-service-contract.md)
  - optional anonymous aggregate score upload

## Practical handoff notes

- Treat `project.yml` as the source of truth, not the generated `.xcodeproj`.
- Do not assume the website and app share a day boundary.
- Do not assume the app and website should sync user progress.
- If privacy, analytics, reminders, or CloudKit behavior changes, update:
  - this README
  - `docs/app-store-launch.md`
  - App Privacy answers in App Store Connect if needed

## Fresh-agent Q&A

### If I need to change the app's daily thread schedule, where is the real logic?

Two places matter:

1. bundled data
- [`Thread/Resources/daily-rounds.json`](/Users/zacellis/thread-game-site/native-ios/Thread/Resources/daily-rounds.json)

2. scheduler logic
- [`Thread/Services/ThreadServices.swift`](/Users/zacellis/thread-game-site/native-ios/Thread/Services/ThreadServices.swift)

Do not assume the bundled file order is the live daily order.

Important:

- the app can select from the `futureDaily` pool using a seeded shuffle
- the app uses the device's local time zone for day rollover
- the website does not share that same day boundary

### If I change a future app puzzle, do I need a new binary?

Yes.

The app ships future puzzles locally. There is no remote override system in the app today.

Changing a future app puzzle means:

1. edit bundled data
2. regenerate if needed
3. archive and ship a new app build

### If I want both website and app to stay aligned, what can still drift?

These can drift independently if changed carelessly:

- day boundary
  - website: `Europe/London`
  - app: device local time zone
- per-user progress
  - website: website-local
  - app: app-local plus private iCloud in `Release`
- future puzzle content
  - website deploy can change immediately
  - app requires a new binary

### If I need to change build settings, should I edit the Xcode project?

No, not as the primary source of truth.

Edit:

- [`project.yml`](/Users/zacellis/thread-game-site/native-ios/project.yml)

Then regenerate:

```bash
xcodegen generate
```

Common mistake:

- fixing something in `ThreadApp.xcodeproj`
- forgetting that regeneration will overwrite it

### Why might reminder behavior look inconsistent when testing?

Because there are three distinct reminder entry points:

1. Settings toggle
- turning reminders on triggers the prompt immediately if permission is not granted

2. First automatic ask
- `15s` after the first solved daily Thread

3. Second automatic ask
- `15s` after the third completed daily Thread if permission still is not granted and one prompt has already been shown

Do not look for the old reopen/day-based reminder logic. That was intentionally removed.

### Why might analytics look “wrong” between Debug and Release?

Because both can point at the same backend while still being separated by build channel.

Current behavior:

- `Debug` uploads with build channel `debug`
- `Release` uploads with build channel `release`

Relevant files:

- [`project.yml`](/Users/zacellis/thread-game-site/native-ios/project.yml)
- [`Thread/Info.plist`](/Users/zacellis/thread-game-site/native-ios/Thread/Info.plist)
- [`Thread/Services/ThreadAnalyticsRemoteServices.swift`](/Users/zacellis/thread-game-site/native-ios/Thread/Services/ThreadAnalyticsRemoteServices.swift)

### Why might the share button title change between builds?

Because the title is conditional:

- if `ThreadAppStoreURL` is present:
  - button title becomes `Share app link`
- if it is absent:
  - button title falls back to `Share website link`

Relevant file:

- [`Thread/Services/ThreadServices.swift`](/Users/zacellis/thread-game-site/native-ios/Thread/Services/ThreadServices.swift)

### Why might local CLI builds fail even when the app code is fine?

On this machine, local `xcodebuild` runs have repeatedly failed in Apple tooling, not app code, due to:

- `CoreSimulatorService`
- `actool`
- unavailable simulator runtimes during asset-catalog compilation

Treat these separately from real Swift compile errors.

If you are evaluating a patch:

- first check whether Swift compilation succeeded
- then check whether the remaining failure is only Apple local tooling

### Can the repo's version/build be behind the live App Store version?

Yes.

Do not assume `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in [`project.yml`](/Users/zacellis/thread-game-site/native-ios/project.yml) always match the already-live App Store build.

If you are doing release work:

1. check App Store Connect
2. check `project.yml`
3. call out any mismatch explicitly

Do not silently “fix” version numbers unless you know the intended next release target.

## Prompt guide for future agents

Use this prompt pattern when another AI agent needs to work on the native app:

```text
You are working on the Daily Thread native iPhone app.

Before editing:
- read native-ios/README.md
- read native-ios/docs/app-store-launch.md if the task touches release, privacy, notifications, analytics, App Store config, or CloudKit
- treat native-ios/project.yml as the build-settings source of truth

Do not assume:
- app and website share the same day boundary
- app and website share user progress
- the generated ThreadApp.xcodeproj is the source of truth
- daily-rounds.json file order is the live schedule
- future puzzle edits can ship without a new binary
- reminder prompts are app-open based; they are milestone-based

If behavior changes, update the relevant docs in the same patch.
If repo state and live App Store state differ, document the mismatch explicitly.
```

## README maintenance rules

### Why update this file

This file is the handoff memory for the iPhone app. If it falls behind the actual code/config, future agents are likely to break:

- release assumptions
- privacy answers
- reminder behavior
- CloudKit behavior
- daily scheduling
- App Store/share-link behavior

### When to update this file

Update it in the same patch when any of these change:

- platform support
- build flags in [`project.yml`](/Users/zacellis/thread-game-site/native-ios/project.yml)
- notification scheduling or prompt timing
- analytics or aggregate upload behavior
- CloudKit/sync behavior
- startup routing or launch flow
- support/privacy/share link behavior
- future-puzzle authoring workflow

### What to update as a minimum

When behavior changes, update:

1. the behavior description
2. the relevant source-of-truth file references
3. any agent-warning/Q&A section that would otherwise become stale

### Release-note discipline

If the live app has already moved ahead of the repo:

- say so explicitly in the docs
- do not let another agent infer that the repo is automatically the live source of truth
