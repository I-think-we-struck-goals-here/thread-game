# Daily Thread social automation

This maintains independent eight-slot Instagram and TikTok queues in Buffer.

Instagram receives two posts per London day:

- a seven-slide carousel at **10:05 Europe/London**
- a 30-second Reel at **18:30 Europe/London**

Both show the previous London day's Thread. Eight healthy queued items provide four days of cover while permanently reserving two slots under Buffer's ten-post Free-plan limit. Failed or currently-sending posts still count as occupied, so the scheduler pauses rather than exceeding that shared ceiling.

Instagram Trial Reel notifications are disabled. Before filling the queue, each run removes any scheduled, failed or sending post carrying the exact legacy `#DailyThreadTrial` marker. The historical video assets remain archived but are not scheduled.

TikTok receives two posts per London day:

- a growth post at **12:30 Europe/London**, rotating curated archive puzzles
- the previous day's Thread as a video at **18:30 Europe/London**

The growth slot is normally a 30-second archive video. On Tuesday and Friday it becomes a seven-image, 1080×1920 photo carousel. The midday archive puzzle is never the same answer as that evening's daily puzzle. TikTok captions ask for a 1–5 clue score and a follow; they do not promise a website link while the profile is below TikTok's link threshold.

## How it works

1. `cli.mjs` reads `src/new-rounds.js` and reproduces the app's seeded daily schedule.
2. It renders the Instagram carousel/Reel plus a TikTok-specific daily Reel and that date's archive growth asset.
3. Each Reel automatically selects either the join layout for exact before/after compounds or the phrase layout for more varied connections.
4. Carousel clue type starts at the approved 42px, measures the real glyph bounds, and scales the whole five-clue sequence only when the opening word would enter the onboarding safe area. A 22px emergency floor protects unusually long opening words; normal short clues stay at 42px. The renderer locks the approved `#f8f5f0` paper colour and rejects inconsistent or unreadable layouts.
5. The workflow commits immutable, date-addressed media to `docs/social/YYYY-MM-DD/`.
6. Buffer receives those public media URLs and independently schedules missing Instagram and TikTok slots.
7. The workflow runs at 06:17, 11:37 and 16:37 London time. The latter two are pre-publication repair checks for TikTok's 12:30 growth slot and both platforms' 18:30 video slot. Changes to the automation, workflow or puzzle pool also trigger an immediate deployment run; generated media commits are excluded to prevent loops.

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
  --queue-size 8 \
  --media-root https://raw.githubusercontent.com/I-think-we-struck-goals-here/thread-game/main/docs/social
node social-automation/cli.mjs audit
```

`schedule` is idempotent by London date and slot. It will not create a duplicate Instagram carousel/Reel or TikTok growth/daily post when that slot is already scheduled or sent. Each channel stops at eight occupied posts, counting `scheduled`, `error` and `sending` statuses so a failed publication cannot silently consume one of the two recovery slots. `audit` requires the automatic carousel/Reel and both TikTok slots.

TikTok videos are automatically marked as AI-generated because the reusable narration is synthetic. TikTok photo posts use Buffer's native photo-post title metadata. TikTok currently does not accept per-image alt text through Buffer's API.

Buffer fetches scheduled media from its source URL at publication time. Regenerating a future date at the same immutable queue URL therefore corrects its already-scheduled carousel without deleting or duplicating the Buffer post.

Buffer's API cannot upload a custom Reel cover. The automation selects the frame at 600 ms as the cover and shares the Reel to the Instagram feed.

## Manual recovery

Open **Actions → Daily Thread social queue → Run workflow**. The job regenerates only missing/stale media and schedules only missing dates.

If a future puzzle pool or schedule seed changes, regenerate the affected queued dates before publishing the app change. Historical puzzle mappings must remain immutable.
