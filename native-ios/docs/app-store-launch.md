# Daily Thread Launch Notes

This file is the source of truth for the launch build and App Store submission.

## Launch build currently assumed

- App Store name: `Daily Thread`
- In-app wordmark: `THREAD`
- Platforms: iPhone only
- Orientation: portrait only
- Remote push broadcasts: off
- Local reminders feature: on
- Private iCloud sync: on for `Release`
- First-party analytics endpoint: on in `Release`
- Anonymous aggregate endpoint: off unless `THREAD_AGGREGATE_BASE_URL` is set

## Release config from the project

From `native-ios/project.yml`:

- `THREAD_DISPLAY_NAME = Daily Thread`
- `THREAD_BUNDLE_IDENTIFIER = co.dailythread.threadapp`
- `THREAD_ENABLE_ICLOUD_SYNC = YES` in `Release`
- `THREAD_ENABLE_REMOTE_PUSH = NO`
- `THREAD_ANALYTICS_BASE_URL = "https://thread-game-site-zac-pools-projects.vercel.app"` in `Release`
- `THREAD_AGGREGATE_BASE_URL = ""`

That means the default release build currently ships with:

- local gameplay and local reminders
- private CloudKit sync for personal app data
- no remote push registration
- anonymous first-party analytics event upload
- no anonymous aggregate score upload

Important:

- the release build is now pointed at the stable Vercel backend host for analytics
- the Vercel project now has Postgres-backed analytics persistence configured
- release and debug analytics are separated by build channel
- the debug build now installs side by side as `Daily Thread Dev` with bundle identifier `co.dailythread.threadapp.dev`
- debug keeps iCloud sync off and should be used for first-run / reminder / onboarding QA when you do not want to overwrite the live app on a device

## App Privacy answers for the current default launch build

These answers are based on the release config above.

### Tracking

- Tracking: `No`

### Data collection

The current release build should be answered as collecting:

1. `Gameplay Content`
- Included because the app can sync puzzle history and in-progress game state through the user's private iCloud account using CloudKit.
- Linked to the user: `Yes`
- Used for tracking: `No`
- Purpose: `App Functionality`

2. `Other Data`
- Included because the app can sync app preferences such as haptics, reminder preference, analytics preference, and aggregate-sharing preference through private CloudKit.
- Linked to the user: `Yes`
- Used for tracking: `No`
- Purpose: `App Functionality`

### Also included in the default launch build

Because the release build now points at the anonymous analytics endpoint, also include:

1. `Product Interaction`
- Linked to the user: `No`
- Used for tracking: `No`
- Purpose: `Analytics`

2. `Other Usage Data`
- Linked to the user: `No`
- Used for tracking: `No`
- Purpose: `Analytics`

Reason:

- the analytics payload includes screen and gameplay event data such as tutorial completion, round started/finished, clue count, solve duration, share taps, reminder prompt outcomes, app version, and device class
- the analytics payload also includes anonymous session duration and exact streak/guess counts
- the event stream is session-scoped rather than account-based

### Not included in the default launch build

Do **not** include these unless you enable the corresponding backend before submission:

- `Identifiers`

Apple App Analytics and App Store infrastructure are separate from your own custom backend. This file only covers what the app itself sends or stores off-device.

## If you enable the anonymous aggregate endpoint before submission

If you set `THREAD_AGGREGATE_BASE_URL` for the release build before shipping, revisit App Privacy before publishing answers.

The current aggregate endpoint accepts:

- `installationID`
- `roundID`
- `dateKey`
- `score`
- `appVersion`
- `platform`

That almost certainly means the release build should then also disclose at least:

1. `Identifiers`
- because an app-scoped installation identifier is uploaded

2. `Gameplay Content` or `Usage Data`
- because puzzle result data is uploaded off-device

Treat this as a required privacy-answer update before launch if aggregate upload goes live.

## Submission checklist

Before TestFlight / App Review:

- Verify the app icon label shows `Daily Thread`
- Verify local reminders work at `9:00 AM` and `9:00 PM`
- Verify reminder permission ask timing:
  - first auto ask `15s` after first solved daily thread
  - second auto ask `15s` after third completed daily thread if still not granted
- Verify private iCloud sync on a signed release-capable build
- Confirm `https://daily-thread.co/privacy/` is live
- Confirm `https://daily-thread.co/support/` is live
- Confirm `https://daily-thread.co/terms/` is live
- Confirm App Store Connect category is `Games` with `Word` and `Puzzle`
- Confirm App Privacy answers match the exact release flags
- Confirm screenshots exist for iPhone
- Confirm support email and public copy are correct

## Device QA checklist

Run this on:

- one smaller iPhone
- one larger iPhone

Verify:

- tutorial flow
- skip tutorial flow
- daily round with 0, 1, and multiple wrong guesses
- no overlap in the composer / guesses band
- solved state fits on one screen
- stats screen distribution labels do not wrap incorrectly
- settings and stats icons sit at the same height across screens
- reminders prompt appears on the intended schedule
- app relaunch behavior matches the current build config

## Release-sensitive gotchas

These are the mistakes most likely to cause a bad release patch:

1. Assuming website and app use the same day boundary
- website: midnight `Europe/London`
- app: midnight in the device's local time zone

2. Assuming future app puzzle changes can ship without a new binary
- the app's future rounds are bundled locally
- changing them requires a new app build

3. Assuming the generated Xcode project is the source of truth
- edit `project.yml`
- regenerate the Xcode project

4. Assuming debug and release analytics are the same stream
- they can hit the same backend
- they are separated by build channel

5. Assuming reminder prompt behavior is generic app-open logic
- current release-intent behavior is milestone-based:
  - first ask after the first solved daily thread
  - second ask after the third completed daily thread if still not granted

6. Assuming repo version/build metadata is always identical to the currently live App Store build
- check App Store Connect before preparing the next patch release
- do not normalize version/build numbers blindly if the repo has not yet been reconciled
