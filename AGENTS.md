# AGENTS.md

This file defines working rules for future engineers and Codex sessions operating in this repo.

## Operating Goal

Leave the repo easier to understand than you found it.

Do not treat handoff docs as optional polish. In this repo, documentation is part of the engineering work because:

- the website, backend, and native app are related but intentionally separate
- release/debug behavior can diverge in meaningful ways
- product truths such as day boundaries, sync boundaries, and reminder behavior are easy to get wrong
- the working tree is often mixed across multiple surfaces

## First Steps For Any New Session

Before editing:

1. read `README.md`
2. read `CURRENT_STATE.md`
3. read this file
4. run `git status --short`
5. run `git diff --stat`
6. identify which product surface is actually in scope:
   - website
   - backend
   - native iPhone app
   - release/docs/support/legal

Do not assume the current dirty tree is one coherent task.

## Core Repo Truths

- Website and native app intentionally do **not** share user progress
- Website and native app intentionally share the same daily puzzle schedule: midnight `Europe/London`
- `native-ios/project.yml` is the source of truth for native build config
- `native-ios/ThreadApp.xcodeproj/project.pbxproj` is generated output
- `public/` is editable source for public static content
- `docs/` is committed site output and must stay aligned when public content changes

## Source-Of-Truth Precedence

When sources disagree, prefer this order:

1. current code/config
2. current git diff / current repo state
3. current handoff docs
4. older design/spec artifacts

If docs disagree with code:

- say so explicitly
- do not silently “fix” code to match stale docs
- update docs once the real behavior is confirmed

## Working Rules

- Main thread is the only writer
  - if sub-agents are used, they are critique-only by default
  - if a sub-agent is ever used for implementation, keep the write scope bounded and non-overlapping
- Specialist/sub-agents are critique-only unless explicitly given a bounded implementation task and there is no overlap risk
- Do not commit local Xcode user state such as:
  - `native-ios/ThreadApp.xcodeproj/project.xcworkspace/xcuserdata/`
- Do not hand-edit generated native Xcode config when `project.yml` is the real source of truth
- Do not sweep unrelated dirty-tree changes into a commit just because they are present
- If the tree is mixed, write down what you believe is in scope before you start editing
- Treat design mock HTML files under `native-ios/docs/` as context, not proof of shipped behavior
- Treat missing files as missing facts, not an invitation to invent them

## Code Quality Expectations

- Verify the runtime/data flow before changing behavior
- Trace the actual code path, not just filenames
- Separate facts, inferences, and unknowns in your own notes and in handoff updates
- Prefer small, explicit changes over broad speculative refactors
- For generated visual media, validate the exported geometry and colour values. Collision checks must measure the visible content (for example, a glyph-sized span), never a stretching block container, and should fail closed before unreadable media is scheduled.
- If a local environment/tooling issue is blocking verification, document it clearly and distinguish it from app-code failures
- If docs, code, and current diff disagree, record which one you trust and why

## Documentation Update Discipline

Documentation updates are required before a task is considered complete when the task changes understanding in a meaningful way.

### Update `README.md` when:

- architecture or repo navigation changes
- important file ownership or source-of-truth rules change
- core runtime/data flow changes
- build/test/debug workflow changes
- known repo-wide traps or operational risks change

### Update `CURRENT_STATE.md` when:

- a feature milestone materially changes current implementation state
- meaningful bug fixes change what is now true
- a release/debug workflow discovery affects how the repo should be operated
- the likely next task changes
- the dirty-tree/release-scope picture changes in a way a future engineer must understand
- you discover a new fragile area, blocker, or unresolved risk

### Update `AGENTS.md` when:

- repo working rules change
- doc maintenance expectations change
- multi-agent or handoff discipline changes
- a repeat failure mode suggests a new standing rule is needed

### Do not require doc updates for:

- trivial copy tweaks
- purely cosmetic refactors with no workflow or behavior impact
- isolated formatting fixes that do not change understanding

## Handoff Standard

If you finish a task that changes behavior, workflow, or what a future engineer needs to know, the docs should be good enough that a cold-start engineer can answer:

- what this repo is
- what surface is active right now
- what files matter first
- what is fragile
- what to verify before editing
- what the next sensible action is

If the docs do not support that, they are not done.
