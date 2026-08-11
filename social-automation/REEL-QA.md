# Daily Thread Reel release gate

Every generated Reel must pass these checks before it can enter Buffer.

## Automated checks

- The canvas is 1080×1920 and the encoded video is H.264 High Profile, 30 fps, 30 seconds.
- Audio is AAC at 48 kHz; the two approved narration clips cannot overlap or run past the safe tail.
- `FIND THE CONNECTION` shares the rendered left edge of the active clue block.
- All five clue rows use one globally fitted font size; individual rows never shrink independently.
- Essential rows stay within the horizontal frame and the Reels vertical safe area.
- Rows cannot overlap. The final question and CTA remain centred, separate and above the bottom safe boundary.
- In join mode, all four edges of all five rows remain fixed within 0.1 px throughout the answer fill.
- In phrase mode, the standalone answer cannot collide with the resolved connections or final question.
- The media, captions, manifests and seven carousel slides are revalidated immediately before Buffer scheduling.
- The daily audit passes only when both that date's carousel and Reel are scheduled or sent.

## Format rules

- Join mode is allowed only when all five connections are exact clue+answer or answer+clue compounds.
- Phrase mode is used for every other round and shows the natural connection beneath each clue.
- The heading is always `FIND THE CONNECTION`; no operators, plus signs or redundant answer label are shown.
- Reusable narration is fixed: `Find the Thread that connects these words together. I'll give you a new word every five seconds.` and `How many clues did you need?`
- Only the daily Instagram Reel is scheduled; Trial Reel notifications remain disabled.

## Manual spot check after design changes

- Watch one join Reel and one phrase Reel from start to finish on a phone-sized preview.
- Inspect 0.5, 5, 10, 15, 20, 25.5, 27 and 29.5 seconds.
- Confirm the opening is immediately understandable, the countdown is calm, the voice is clean and the final answer has enough reading time.
- Confirm Instagram's right action rail and bottom caption controls do not cover essential content.
