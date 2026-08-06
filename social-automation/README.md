# Daily Thread social automation

This maintains a nine-slot Instagram queue in Buffer with two Daily Thread posts per London day:

- a seven-slide carousel at **10:05 Europe/London**
- a 30-second Reel at **18:30 Europe/London**

Both show the previous London day's Thread. Nine queued posts provide more than four days of cover while leaving one slot free on Buffer's ten-post Free-plan limit.

## How it works

1. `cli.mjs` reads `src/new-rounds.js` and reproduces the app's seeded daily schedule.
2. It renders seven 1080×1350 PNGs and one 1080×1920, 30-second H.264/AAC Reel for each date.
3. Each Reel automatically selects either the join layout for exact before/after compounds or the phrase layout for more varied connections.
4. The workflow commits immutable, date-addressed media to `docs/social/YYYY-MM-DD/`.
5. Buffer receives those public media URLs and schedules any missing carousel or Reel.
6. The workflow runs at 06:17 and 16:37 London time, giving the evening run time to recover before the Reel slot. Changes to the automation, workflow or puzzle pool also trigger an immediate deployment run; generated media commits are excluded to prevent loops.

The Buffer API key is stored only as the repository secret `BUFFER_API_KEY`.

## Commands

```bash
npm ci --prefix social-automation
npx --prefix social-automation playwright install chromium
npm test --prefix social-automation
node social-automation/cli.mjs render --days 1
node social-automation/cli.mjs plan --days 1 \
  --media-root https://raw.githubusercontent.com/I-think-we-struck-goals-here/thread-game/main/docs/social
node social-automation/cli.mjs schedule \
  --days 5 \
  --queue-size 9 \
  --media-root https://raw.githubusercontent.com/I-think-we-struck-goals-here/thread-game/main/docs/social
node social-automation/cli.mjs audit
```

`schedule` is idempotent by London date and format: it will not create a second carousel or Reel when that format is already scheduled or sent. It stops at nine total queued posts. `audit` passes only when both formats for today are scheduled or sent.

Buffer's API cannot upload a custom Reel cover. The automation selects the frame at 600 ms as the cover and shares the Reel to the Instagram feed.

## Manual recovery

Open **Actions → Daily Thread social queue → Run workflow**. The job regenerates only missing/stale media and schedules only missing dates.

If a future puzzle pool or schedule seed changes, regenerate the affected queued dates before publishing the app change. Historical puzzle mappings must remain immutable.
