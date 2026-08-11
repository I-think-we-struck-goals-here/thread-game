# Daily Thread TikTok release gate

Every generated TikTok asset must pass this gate before Buffer can schedule it.

## Automated checks

- Daily and archive videos are exactly 1080×1920, 30 fps and 30 seconds, encoded as H.264/AAC at 48 kHz.
- The approved narration clips cannot overlap or run beyond the safe audio tail.
- Video clue rows share one globally fitted size, remain fixed through the answer reveal, and stay clear of TikTok's action rail and bottom controls.
- Photo posts contain exactly seven 1080×1920 images.
- All five photo clues use one shared size of at least 74px and stay within the 90–880px essential horizontal safe area.
- Photo instructions end at or above y=1605; the final title and follow CTA remain within the essential safe frame.
- The locked paper colour is `#f8f5f0` in every exported format.
- Tuesday and Friday select photo posts; other midday slots select archive videos.
- The archive answer cannot match that evening's daily answer.
- Captions contain a stable daily or archive marker so retries cannot create duplicate Buffer posts.
- Buffer validation checks the returned asset count and media type before considering a post scheduled.
- The daily audit requires both the growth and daily TikTok slots to be scheduled or sent.

## Publishing rules

- Growth slot: 12:30 Europe/London.
- Daily slot: 18:30 Europe/London.
- Keep at most eight occupied posts and two spare Buffer Free slots; failed and sending posts count as occupied.
- Videos set TikTok's AI-generated disclosure because narration is synthetic.
- Do not promise a website link until the TikTok profile can actually show one.

## Manual spot check after a design change

- Inspect all seven photo slides at phone size.
- Watch one join-mode and one phrase-mode video from start to finish.
- Check 0.5, 5, 10, 15, 20, 25.5, 27 and 29.5 seconds.
- Confirm clues are legible without pausing, the answer has enough reading time, and the final follow CTA is not covered by TikTok controls.
