# Thread Anonymous Aggregate Service

This app stays fully playable offline. The aggregate service is optional and only powers the future "how did I rank relative to everyone else?" chart.

## Goals

- Accept one anonymous daily result submission per installation per puzzle day.
- Return a lightweight histogram for a given daily round.
- Never require account creation, names, emails, or contacts.
- Fail silently from the app's perspective so gameplay never depends on service availability.

## Client configuration

The native app will automatically use the remote client when one of these is present:

- Environment variable: `THREAD_AGGREGATE_BASE_URL`
- Info.plist key: `ThreadAggregateBaseURL`

Optional auth:

- Environment variable: `THREAD_AGGREGATE_API_KEY`
- Info.plist key: `ThreadAggregateAPIKey`

## Submit daily result

`POST /v1/daily-results`

Request body:

```json
{
  "installationID": "uuid-string",
  "roundID": 184,
  "dateKey": "2026-04-04",
  "score": 3,
  "appVersion": "1.0-1",
  "platform": "ios"
}
```

Notes:

- `score` is `null` when the player missed the round.
- The server should dedupe by `installationID + roundID + dateKey`.
- Recommended response for accepted submissions: `202 Accepted`.

## Fetch histogram

`GET /v1/histograms/:roundID`

Successful response:

```json
{
  "roundID": 184,
  "totalSubmissions": 812,
  "buckets": [
    { "bucket": 1, "count": 82 },
    { "bucket": 2, "count": 194 },
    { "bucket": 3, "count": 243 },
    { "bucket": 4, "count": 173 },
    { "bucket": 5, "count": 91 },
    { "bucket": 0, "count": 29 }
  ]
}
```

Bucket meanings:

- `1...5`: solved in that many clues
- `0`: missed

## Privacy stance

- No personal identifiers beyond an anonymous installation ID.
- No raw guesses or clue-by-clue gameplay traces.
- The app should not block or nag if the user disables anonymous sharing.
- Analytics and aggregate scoring remain distinct concerns.

## Read models

The backend now also exposes:

- `GET /api/v1/histograms/:roundID`
- `GET /api/v1/admin/round-summary?roundID=47`

The public histogram endpoint is safe for the app. The admin summary endpoint should be protected with `THREAD_ADMIN_API_KEY`.
