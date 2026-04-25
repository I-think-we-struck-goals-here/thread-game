# Daily Thread 1.0.2

Suggested App Store "What's New":

- Improved the first-play experience with gentle in-game guidance for players who skip the tutorial
- Refined the guess composer so typing feels clearer and more responsive
- Improved notification permission handling and reminder reliability
- Fixed a bug where some short answers could stop input too early
- Fixed an edge case where a completed daily thread could reopen after a stale sync state

Internal release scope:

- Added a subtle first-daily nudge card that only appears for players who skip straight to the daily puzzle and have not solved any practice rounds
- Replaced the old empty composer placeholder with a centered live caret treatment
- Tightened notification permission handling, debug diagnostics, and local reminder delivery behavior
- Switched guess-length handling to a shared policy with a `12` character floor so answer length is not leaked on short rounds
- Hardened daily completion against stale local or CloudKit snapshots for the same day
