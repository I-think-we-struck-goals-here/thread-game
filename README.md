# Daily Thread

Daily Thread is a word-connection puzzle shipped in two separate products:

- a React/Vite website
- a native SwiftUI iPhone app

They share the same round order and puzzle IDs, but they are intentionally separate products from a user-data point of view.

## Repo map

- [`src/`](/Users/zacellis/thread-game-site/src)
  - website app source
- [`public/`](/Users/zacellis/thread-game-site/public)
  - static legal/support source files
- [`docs/`](/Users/zacellis/thread-game-site/docs)
  - committed static site output used for the live site
- [`api/`](/Users/zacellis/thread-game-site/api)
  - lightweight backend for first-party analytics, optional aggregates, and future push scaffolding
- [`native-ios/`](/Users/zacellis/thread-game-site/native-ios)
  - native SwiftUI app
- [`scripts/`](/Users/zacellis/thread-game-site/scripts)
  - repo utilities, including puzzle export helpers

## Current product behavior

- Website and iPhone app use the same puzzle pool and daily sequence.
- Website day rollover is pinned to `Europe/London`.
- iPhone app day rollover is pinned to the device's local time zone.
- Website progress and app progress are intentionally separate.
- There is no account system and no cross-product progress sync.

## Current release posture

- Website: static-first, backed by a small Vercel API for analytics/support
- iPhone app: iPhone only, portrait only
- App reminders: local notifications only
- Remote push broadcasts: off
- Private iCloud sync: on in `Release`, off in `Debug`
- First-party analytics: on in both `Debug` and `Release`, separated by build channel
- Anonymous aggregate daily score upload: off

## Handoff docs

Start here depending on the area you are touching:

- [`native-ios/README.md`](/Users/zacellis/thread-game-site/native-ios/README.md)
  - native app architecture, current product behavior, build config, and workflows
- [`native-ios/docs/app-store-launch.md`](/Users/zacellis/thread-game-site/native-ios/docs/app-store-launch.md)
  - App Store/privacy/release source of truth
- [`docs/thread-backend.md`](/Users/zacellis/thread-game-site/docs/thread-backend.md)
  - backend shape, endpoints, storage, and privacy posture
- [`native-ios/docs/analytics-service-contract.md`](/Users/zacellis/thread-game-site/native-ios/docs/analytics-service-contract.md)
  - analytics event model and admin summaries
- [`native-ios/docs/aggregate-service-contract.md`](/Users/zacellis/thread-game-site/native-ios/docs/aggregate-service-contract.md)
  - anonymous aggregate score upload contract

## Website workflow

Install dependencies:

```bash
npm install
```

Run the website locally:

```bash
npm run dev
```

Build the website:

```bash
npm run build
```

Notes:

- `src/` contains the interactive website app.
- `public/` contains static support/privacy/terms source content.
- `docs/` is the committed static output for the live website and should stay in sync with public-facing content changes.

## Native iPhone workflow

Primary native app docs live in [`native-ios/README.md`](/Users/zacellis/thread-game-site/native-ios/README.md).

Typical commands:

```bash
cd native-ios
xcodegen generate
open ThreadApp.xcodeproj
```

The app project is generated from:

- [`native-ios/project.yml`](/Users/zacellis/thread-game-site/native-ios/project.yml)

## Updating future puzzles

Future app puzzles are bundled locally in the native app:

- [`native-ios/Thread/Resources/daily-rounds.json`](/Users/zacellis/thread-game-site/native-ios/Thread/Resources/daily-rounds.json)

If you change future puzzle content:

1. update the native bundled round data
2. update the website source/schedule if both products should stay aligned
3. ship a new app build if the native app needs that change

There is no remote CMS or server-controlled daily puzzle override in the app today.

## Backend notes

The backend is intentionally small.

It currently exists for:

- first-party product analytics
- optional anonymous daily-result aggregation
- future remote-push token storage
- support/contact handling

Primary backend doc:

- [`docs/thread-backend.md`](/Users/zacellis/thread-game-site/docs/thread-backend.md)

## Practical guidance for the next engineer

- Treat the website and native app as related but operationally separate.
- Do not assume the website’s day boundary applies to the app.
- Do not assume web progress should sync to native progress.
- Check `project.yml` before assuming any iOS release capability or environment flag.
- Check the App Store launch doc before changing privacy, analytics, reminder, or CloudKit behavior.

## Fresh-agent Q&A

### If I change a future puzzle, will both products update automatically?

No.

- Website content changes ship with the website deploy/build.
- App puzzle changes are bundled locally and require a new app build.

### Does the app use the literal order of `daily-rounds.json`?

Not always.

- The app's scheduler can use the `futureDaily` pool with a seeded shuffle rather than the raw file order.
- Do not assume `round index == day number`.
- Check the scheduler implementation before changing the round pool or anchor dates.

Relevant file:

- [`native-ios/Thread/Services/ThreadServices.swift`](/Users/zacellis/thread-game-site/native-ios/Thread/Services/ThreadServices.swift)

### If I update support, privacy, or terms, where do I edit?

Treat [`public/`](/Users/zacellis/thread-game-site/public) as the editable source and keep [`docs/`](/Users/zacellis/thread-game-site/docs) in sync for the live static site output.

Do not update only one of them and assume the live site is correct.

### If I change iOS build settings, where do I edit?

Edit:

- [`native-ios/project.yml`](/Users/zacellis/thread-game-site/native-ios/project.yml)

Do not hand-edit the generated `.xcodeproj` unless you are deliberately making a one-off local signing fix and understand it will be overwritten by `xcodegen generate`.

### Does the app share user progress with the website?

No.

- shared puzzle sequence: yes
- shared per-user progress: no
- app cross-device sync: private iCloud in `Release`
- website progress: website-local

### Why might local iOS CLI builds fail even when app code is fine?

This repo has repeatedly hit local Apple toolchain issues on this machine involving:

- `CoreSimulatorService`
- `actool`
- missing simulator runtimes during asset catalog compilation

That can fail a local CLI build even after Swift compilation succeeds.

If this happens, separate:

- app-code compile failures
- Apple local toolchain/runtime failures

## Agent operating guide

If another AI agent picks this repo up cold, it should work like this:

1. Orient first
- read this root README
- then read [`native-ios/README.md`](/Users/zacellis/thread-game-site/native-ios/README.md) if the task touches the app
- then read the smallest relevant contract/doc instead of guessing

2. Identify which product is actually being changed
- website
- native iPhone app
- backend
- App Store/release docs

3. Do not infer shared behavior where separation is intentional
- app and website are not one runtime
- app and website do not share user progress
- app and website do not share the same day boundary

4. Prefer the true source of truth for the thing being changed
- product/release flags: [`native-ios/project.yml`](/Users/zacellis/thread-game-site/native-ios/project.yml)
- app scheduling/runtime logic: native Swift sources
- web experience: `src/`
- public legal/support content: `public/`
- live static site output: `docs/`
- backend behavior: `api/` plus [`docs/thread-backend.md`](/Users/zacellis/thread-game-site/docs/thread-backend.md)

5. After any behavior or release change, update docs in the same commit
- do not leave the readmes for “later”
- stale handoff docs are one of the highest-risk failure modes in this repo

## Suggested prompt for future agents

Use this working prompt when handing the repo to another AI agent:

```text
You are working on Daily Thread. Treat the website, native iPhone app, and backend as related but operationally separate.

Before changing anything:
- read README.md
- if the task touches iOS, read native-ios/README.md
- if the task touches release/privacy/reminders/analytics, read native-ios/docs/app-store-launch.md
- if the task touches backend analytics/aggregates/support, read docs/thread-backend.md

Do not assume:
- website and app share a day boundary
- website and app share user progress
- the generated Xcode project is the source of truth
- bundled daily-round file order equals live daily schedule
- future app puzzle edits can ship without a new binary

When changing behavior, also update the relevant docs in the same patch.
When release state and repo state differ, call that out explicitly instead of guessing.
```

## README maintenance policy

### Why this matters

This repo is easy to misunderstand because the products are connected conceptually but intentionally separate operationally. If the docs drift, a future agent can make a “reasonable” change that is still wrong for release, privacy, scheduling, or sync behavior.

### Update the readmes when any of these change

- platform support
- day-boundary logic
- notification timing or copy
- analytics behavior or privacy posture
- CloudKit / sync behavior
- App Store share-link behavior
- support/privacy/legal URLs
- build flags or environment assumptions
- backend responsibilities or storage shape
- future-puzzle authoring workflow

### How to update them

1. Update the code/config first
2. Re-check the actual source of truth files
3. Update the smallest set of docs that define the changed behavior
4. Add an explicit note if live App Store state and repo state are not fully aligned yet

### Minimum doc update rule

For any meaningful behavior change, update at least one of:

- [`README.md`](/Users/zacellis/thread-game-site/README.md)
- [`native-ios/README.md`](/Users/zacellis/thread-game-site/native-ios/README.md)
- [`native-ios/docs/app-store-launch.md`](/Users/zacellis/thread-game-site/native-ios/docs/app-store-launch.md)
- [`docs/thread-backend.md`](/Users/zacellis/thread-game-site/docs/thread-backend.md)

### Release-state warning

Do not assume the repo version/build always matches the currently live App Store version.

If App Store Connect and repo config diverge:

- say so explicitly
- document which one is live
- do not silently normalize one to the other without confirmation
