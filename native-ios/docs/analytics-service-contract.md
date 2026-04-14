# Thread Analytics Service

Analytics in Thread should stay lightweight and anonymous. The native app works fully without it.

## Goals

- Capture the small set of product events needed to improve onboarding, retention, and friction points.
- Avoid names, emails, contacts, Apple IDs, advertising identifiers, or raw guess-by-guess gameplay traces.
- Keep analytics optional and easy to disable from Settings.
- Fall back to local logging when no remote endpoint is configured.
- Keep retention, installs, and session-duration reporting in App Store Connect Analytics rather than rebuilding those ourselves.

## Client configuration

The native app will automatically switch from local OS logging to the remote analytics client when one of these is present:

- Environment variable: `THREAD_ANALYTICS_BASE_URL`
- Info.plist key: `ThreadAnalyticsBaseURL`

Optional auth:

- Environment variable: `THREAD_ANALYTICS_API_KEY`
- Info.plist key: `ThreadAnalyticsAPIKey`

Admin read-only summary:

- `THREAD_ADMIN_API_KEY`

## Submit event

`POST /v1/events`

Request body:

```json
{
  "sessionID": "launch-session-uuid",
  "event": "round_finished",
  "properties": {
    "mode": "daily",
    "result": "solved",
    "round_id": "47",
    "round_number": "47",
    "date_key": "2026-04-07",
    "score": "3",
    "clues_used": "3",
    "wrong_guess_count": "2",
    "solve_duration_seconds": "94",
    "time_to_first_guess_seconds": "11",
    "current_streak_bucket": "4-6",
    "resumed_saved_progress": "false"
  },
  "occurredAt": "2026-04-04T16:00:00Z",
  "appVersion": "1.0-1",
  "platform": "ios",
  "deviceClass": "iphone"
}
```

## Event set

Launch-safe event names:

- `app_bootstrapped`
- `tutorial_started`
- `tutorial_skipped`
- `tutorial_completed`
- `round_started`
- `round_finished`
- `stats_opened`
- `settings_opened`
- `support_opened`
- `privacy_opened`
- `preference_changed`
- `result_shared`
- `notification_prompt_shown`
- `notification_permission_result`
- `notification_settings_opened`

## Important properties

- `mode`: `daily` or `practice`
- `result`: `solved` or `failed`
- `round_id`: canonical puzzle ID
- `round_number`: daily day number when relevant
- `date_key`: `YYYY-MM-DD` for daily puzzle events
- `practice_index`: 1-based practice tutorial round when relevant
- `score`: clue count for a solve
- `clues_used`
- `wrong_guess_count`
- `solve_duration_seconds`
- `time_to_first_guess_seconds`
- `current_streak_bucket`: one of `0`, `1`, `2-3`, `4-6`, `7-13`, `14+`
- `resumed_saved_progress`: `true` when the round resumed from saved local snapshot

## What the backend should do

- Accept the event payload and validate the property keys.
- Store raw event rows only as long as needed for product analysis.
- Derive aggregate tables daily so the product can answer questions like:
  - how many users started puzzle 47
  - how many completed it
  - average clue count
  - solve/fail distribution
  - share rate
  - reminder opt-in rate
- Treat `sessionID` as an ephemeral launch/session identifier, not a user profile key.
- Do not join analytics data with third-party data or ad systems.

## Admin read endpoints

The backend now includes two admin-only summary endpoints guarded by `THREAD_ADMIN_API_KEY`.

- `GET /api/v1/admin/round-summary?roundID=47`
- `GET /api/v1/admin/product-summary?days=30`

These are intended for internal dashboards or lightweight scripts, not for the app itself.

## Separate aggregate endpoint

The anonymous daily score distribution should remain a separate service from the analytics event stream.

- Analytics answers product questions.
- Aggregate submission powers the future public histogram.

## Privacy stance

- Session-scoped analytics only.
- No personal profiles or account creation.
- No raw guess history or clue-by-clue event stream.
- No Apple ID, iCloud identity, email, or contact data.
- No ad-tech identifiers.
- Aggregate ranking and analytics remain separate services.
