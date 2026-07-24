# Daily Thread

Daily Thread is a word-connection puzzle shipped as three related but operationally separate surfaces:

- a React/Vite website
- a lightweight Vercel/Postgres backend
- a native SwiftUI iPhone app

The website and native app share the same puzzle pool, round IDs, and daily puzzle schedule, but they do **not** share user progress.

## Read This First

If you are joining this repo cold, read these in order:

1. `README.md`
2. `CURRENT_STATE.md`
3. `AGENTS.md`
4. `native-ios/README.md` for native app work
5. `native-ios/docs/app-store-launch.md` for release/privacy/reminder/analytics work
6. `docs/thread-backend.md` for backend/admin/dashboard work

Do not trust docs blindly. Check `git status --short`, `git diff --stat`, and the actual implementation before assuming the current scope or release target.

## Current Working Slice Warning

This repo currently has a mixed dirty tree.

At minimum, the local changes span:

- native iOS feature work
- website app changes
- backend/API additions
- static site/doc changes
- generated Xcode changes
- local Xcode state

Do not assume all local changes are part of one release.

Before editing:

1. check `git status --short`
2. check `git diff --stat`
3. decide which surface is actually in scope
4. verify whether draft/untracked files are intended work or local experiments

Right now, the following are present as local/untracked additions and should not be assumed to be committed or canonical:

- `CURRENT_STATE.md`
- `AGENTS.md`
- `api/`
- `docs/thread-backend.md`
- `public/dashboard/`
- `docs/dashboard/`

## Repo Map

- `src/`
  - website app source
- `public/`
  - editable static site content and private tools
- `docs/`
  - committed static output used for the deployed site
- `api/`
  - lightweight backend for analytics, daily-result aggregation, support contact, and future push scaffolding
- `native-ios/`
  - native SwiftUI app
- `scripts/`
  - repo utilities, including daily-round export helpers

## Product Boundaries You Must Not Blur

- Daily puzzle rollover for both website and native app: midnight `Europe/London`
- Website progress: website-local
- Native app progress: app-local, with private iCloud sync in `Release`
- There is no account-based sync between website and app

These are intentional product decisions, not accidental drift.

## Architecture

### Website

- Entry point: `src/App.jsx`
- Built with Vite + React
- Uses local website state and bundled round data
- Public legal/support pages live in `public/` and must stay aligned with `docs/`

### Native iPhone app

- Entry/config:
  - `native-ios/project.yml`
  - `native-ios/Thread/Info.plist`
  - `native-ios/ThreadApp.xcodeproj/project.pbxproj` (generated output, not source of truth)
- App entry and routing:
  - `native-ios/Thread/App/ThreadApp.swift`
  - `native-ios/Thread/App/ThreadRootViewModel.swift`
- Core UI/features:
  - `native-ios/Thread/Features/`
  - `native-ios/Thread/Features/ArchiveView.swift`
  - `native-ios/Thread/Shared/ThreadUI.swift`
- Runtime helpers:
  - `native-ios/Thread/Services/ThreadServices.swift`
  - `native-ios/Thread/Services/ThreadStores.swift`
  - `native-ios/Thread/Services/ThreadRepository.swift`
  - `native-ios/Thread/Services/ThreadNotifications.swift`
  - `native-ios/Thread/Services/ThreadCloudKitSync.swift`
  - `native-ios/Thread/Services/ThreadArchivePurchases.swift`
- App delegate / notification presentation:
  - `native-ios/Thread/App/ThreadAppDelegate.swift`
- Bundled app daily rounds:
  - `native-ios/Thread/Resources/daily-rounds.json`

### Backend

- Vercel serverless functions in `api/`
- Shared backend helpers:
  - `api/_lib/auth.js`
  - `api/_lib/db.js`
  - `api/_lib/http.js`
  - `api/_lib/validation.js`
- Main public endpoints:
  - `POST /v1/events`
  - `POST /v1/daily-results`
  - `GET /v1/histograms/:roundID`
  - `POST /v1/push/installations`
  - `POST /v1/support/contact`
- Admin endpoints:
  - `GET /v1/admin/round-summary`
  - `GET /v1/admin/product-summary`

## Runtime and Data Flow

### Website runtime flow

1. `src/App.jsx` picks the website round of the day using the shared `Europe/London` daily schedule
2. practice and daily gameplay live entirely in the web app
3. support/privacy/terms content comes from `public/`, with `docs/` as committed static output

### Native app runtime flow

1. `ThreadApp.swift` creates the root app container and routes directly into the local app state
2. `ThreadRootViewModel.swift` bootstraps local state, daily routing, reminders, analytics, and CloudKit coordination
3. `ThreadServices.swift` and repository/scheduler helpers determine today’s round and calculate streak/stat summaries
4. `DailyGameView.swift` runs the shared clue/guess/completion flow for today's Thread and past Archive Threads
5. `ArchiveView.swift` lists past Threads, resumes unfinished Archive games, and revisits completed results
6. `StatsView.swift` and `ThreadUI.swift` render stats, streak badges, and shared UI
7. `ThreadNotifications.swift` and `ThreadAppDelegate.swift` handle local reminder authorization/presentation
8. `ThreadStores.swift` persists preferences, daily history/snapshots, separate Archive history/snapshots, and debug-preview state
9. `ThreadCloudKitSync.swift` reconciles private iCloud state in release builds

Current launch behavior: iOS shows a plain warm native launch background while the process starts, then SwiftUI routes directly to the first local app screen. The first resolved screen gets a one-time `0.16s` non-blocking opacity/settle polish pass, disabled by Reduce Motion. There is no custom reveal, logo splash, launch streak overlay, or root screen transition. Streak copy now belongs to the post-solve success state and the one-time badge unlock overlay.

Current Archive release boundary: the dirty native tree contains a playable Archive UX for every past Thread, protected in all builds by a non-consumable StoreKit 2 entitlement. The paywall loads Apple's localized price, supports purchase and explicit restore, and listens for entitlement updates. Archive progress remains separate and device-local so it cannot alter daily stats, streaks, badges, reminders, aggregate results, or CloudKit daily state. The next release still requires signed-device/TestFlight purchase and restore QA plus the App Store Connect review screenshot before submission.

### Backend flow

1. clients can send product analytics to `api/v1/events.js`
2. anonymous daily results can be stored via `api/v1/daily-results.js`
3. round-level and product-level summaries come from admin endpoints
4. a private owner dashboard can query those admin endpoints using `THREAD_ADMIN_API_KEY`

## Important Files To Read First By Area

### Native app release / runtime / current focus

- `native-ios/README.md`
- `native-ios/docs/app-store-launch.md`
- `native-ios/project.yml`
- `native-ios/Thread/Info.plist`
- `native-ios/ThreadApp.xcodeproj/project.pbxproj`
- `native-ios/Thread/App/ThreadAppDelegate.swift`
- `native-ios/Thread/App/ThreadRootViewModel.swift`
- `native-ios/Thread/App/ThreadApp.swift`
- `native-ios/Thread/Features/DailyGameView.swift`
- `native-ios/Thread/Features/StatsView.swift`
- `native-ios/Thread/Features/SettingsView.swift`
- `native-ios/Thread/Shared/ThreadUI.swift`
- `native-ios/Thread/Models/ThreadModels.swift`
- `native-ios/Thread/Services/ThreadStores.swift`
- `native-ios/Thread/Services/ThreadServices.swift`
- `native-ios/Thread/Services/ThreadNotifications.swift`
- `native-ios/Thread/Services/ThreadRepository.swift`
- `native-ios/Thread/Resources/Assets.xcassets`
- `native-ios/ThreadTests/ThreadCoreTests.swift`

### Feature design/spec artifacts currently relevant

- `native-ios/docs/stats-page-streak-badges.html`
- `native-ios/docs/stats-page-streak-badges-compare.html`
- `native-ios/docs/streak-badge-unlock-moment.html`
- `native-ios/docs/first-daily-nudge-mock.html`
- `native-ios/docs/composer-affordance-mock.html`

These are reference artifacts, not source of truth. Always verify the shipped behavior in SwiftUI.

### Backend / dashboard

- `docs/thread-backend.md`
- `vercel.json`
- `api/v1/admin/round-summary.js`
- `api/v1/admin/product-summary.js`
- `public/dashboard/index.html`

## Commands

### Website

```bash
npm install
npm run dev
npm run build
```

### Native app

```bash
cd native-ios
xcodegen generate
open ThreadApp.xcodeproj
```

Device build from CLI:

```bash
xcodebuild -project ThreadApp.xcodeproj -scheme ThreadApp -configuration Debug -sdk iphoneos build
```

### Native tests

Typical simulator test command:

```bash
xcodebuild -project /Users/zacellis/thread-game-site/native-ios/ThreadApp.xcodeproj -scheme ThreadApp -destination 'platform=iOS Simulator,name=iPhone 17' test
```

This is currently vulnerable to local Xcode / platform-component drift on this machine. Treat destination/runtime failures separately from app-code failures.

If you change native build config:

```bash
cd native-ios
xcodegen generate
```

Do not assume `project.pbxproj` is authoritative.

## Current Implementation Patterns

- `native-ios/project.yml` is the source of truth for native build settings; regenerate the project instead of hand-editing generated config
- native debug tools are gated in `#if DEBUG`, mainly in `SettingsView.swift`
- stats/streak UI is built from persisted local history, not a remote profile system
- backend analytics events are anonymous and session-scoped; daily-result aggregation is a separate installation-keyed stream
- design mocks under `native-ios/docs/` are part of the working context, but they are not proof that code matches

## Known Risks And Traps

- The working tree is currently mixed and dirty across native app, website, backend, docs, assets, and generated files
- `native-ios/ThreadApp.xcodeproj/project.xcworkspace/xcuserdata/` is local Xcode state and should not be committed
- `CURRENT_STATE.md` and `AGENTS.md` were added as handoff docs and must now be kept current
- Some docs in the tree are untracked/new; do not assume they are committed or canonical
- `api/`, `public/dashboard/`, and `docs/thread-backend.md` currently exist locally but may still be draft/untracked in the current tree
- The native app’s future puzzles are bundled locally; changing them requires a new app build
- The website and app share daily puzzle timing, but intentionally do not share user progress
- The local machine can hit Apple tooling issues involving simulator destinations and installed platform components

## Debugging Notes

- If a native build fails, separate:
  - Swift/app logic issues
  - Xcode/CoreSimulator/platform-component issues
- If release/debug behavior is unclear, compare:
  - `native-ios/project.yml`
  - `native-ios/Thread/Info.plist`
  - `native-ios/ThreadApp.xcodeproj/project.pbxproj`
- If design intent is unclear, compare the relevant `native-ios/docs/*.html` artifact with the actual SwiftUI view that implements it

## Documentation Discipline

For meaningful structural changes, feature milestones, workflow discoveries, debugging lessons, or release-sensitive behavior changes, update:

- `README.md`
- `CURRENT_STATE.md`
- and, if the working rules or maintenance expectations changed, `AGENTS.md`

Do not leave the handoff docs stale and assume someone else will fix them later.
