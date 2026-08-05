# Daily Thread social automation

This keeps nine Instagram carousels scheduled in Buffer. Each carousel publishes at **10:05 Europe/London** and shows the previous London day's Thread.

## How it works

1. `cli.mjs` reads `src/new-rounds.js` and reproduces the app's seeded daily schedule.
2. It renders seven 1080×1350 PNGs from `template.html` on a macOS GitHub runner, preserving the app's Didot/Avenir typography.
3. The workflow commits new, date-addressed images to `docs/social/YYYY-MM-DD/`.
4. Buffer receives those permanent public image URLs and schedules any missing dates.
5. The workflow runs twice daily. Buffer already holds nine future posts, so a temporary workflow failure does not create a missed day.

The Buffer API key is stored only as the repository secret `BUFFER_API_KEY`.

## Commands

```bash
npm ci --prefix social-automation
npx --prefix social-automation playwright install chromium
npm test --prefix social-automation
node social-automation/cli.mjs render --days 1
node social-automation/cli.mjs schedule \
  --days 9 \
  --media-root https://raw.githubusercontent.com/I-think-we-struck-goals-here/thread-game/main/docs/social
node social-automation/cli.mjs audit
```

`schedule` is idempotent: it queries Buffer's scheduled posts and will not create a second Daily Thread carousel for a covered London date. It stops at nine total queued posts, leaving one Free-plan slot available.

## Manual recovery

Open **Actions → Daily Thread social queue → Run workflow**. The job regenerates only missing/stale media and schedules only missing dates.

If a future puzzle pool or schedule seed changes, regenerate the affected queued dates before publishing the app change. Historical puzzle mappings must remain immutable.
