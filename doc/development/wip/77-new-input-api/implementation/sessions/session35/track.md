# session35 — track

## 2026-08-10 — boot

- Booted per `agents/validation.md` → `agents/sessions.md`. **Fresh start**: session35 held only
  `prompt.md`; no `track.md` / `report.md` (sessions §2 row 1). Track opened now.
- HEAD `5c405575` "docs(session34): wrap — report, session35 prompt, repointed pointer", branch
  `feature/77-newapi-analysis-s20260615`. Working tree: **no tracked modifications** — only the
  known untracked scratch (`claude.sh`, `src/STEPS.md`, `input-pr-slices.tar.gz`,
  `doc/tall_blocks.md`, `doc/development/wip/{clarification,personal-notes,pull-26}/`) and the
  three nested example repos.
- **Baseline confirmed: `busted tests` → 955 / 0 / 0 / 3.** Matches the prompt.
- Read in full: `agents/validation.md`, `agents/sessions.md`, this prompt, session34's
  `report.md` + `prompt.md` + `track.md`, `agents/rules/revalidation.md`.
- Task restated to the owner before any work, at their request. **Mode: research + analysis
  (revalidation)** — Part 1 only; Part 2 (tests, then platform code) is execution and is gated
  on the owner's go after the findings report.

## 2026-08-10 — Part 1 done: the spec revalidation

Report: `../../../validation/reviews/S35-spec-revalidation.md`. Done inline, no sub-agent —
the briefing would have cost more than the work, and every claim needed verifying in code by
the same reader who has to write the tests. Tree untouched.

- **Spec verdict: sound.** Markers honest in both directions (all 11 name something genuinely
  not true yet), guide accurate today, ledger tombstones hold, the mock's stated defect is real
  in code.
- **Three things gate the tests.** (1) The `gui` row is not only a platform decision — the
  seventh combo test case asserts `'ctrl+alt+shift+gui+s'` and cannot be rewritten without the
  ruling; recommend adding `Key.gui()` since every already-written document stays true.
  (2) Removing the field **crashes** the keyboard example — the frozen view returns nil silently,
  `modHeld` indexes it — and the internals guide already claims that example reads the device,
  inside the marker the platform step clears. (3) Nothing says whether a modifier's own press
  still serialises as `alt+lalt`; today the gateway's first line guarantees it, after the change
  the device does, and the mock does not do it for free.
- **The docs sweep missed a fourth persistent document**: `internals/examples/keyboard.md`, which
  is P9b's design of record and *recommends* reading the dissolved set. P9b now runs after the
  platform code, so it would be read after the surface is gone.
- **Citation rot is broad but pre-existing** (`git log -S` on each): the layers guide is off by
  ~88 lines on the gateway, the internals guide cites two ranges past end-of-file, and the
  in-code `DEFERRED` marker it names exists nowhere in `src/` or `tests/`.
- **Reported and stopped** per the prompt's gate. No code moved.

## 2026-08-10 — owner pivots the session: the spec is wrong in two places, fix it

Corrections written to `../../../validation/reviews/S35-spec-corrections.md`. The session's task
is no longer "tests then platform code" — it is **fix the spec first**. Mode stays
research/evaluation until the corrections are agreed; execution after.

- **(1) `Key`, not `love.keyboard`, is what a project consults.** A ladder, not a binary:
  shortcuts/combos first; `Key.*` inside project code is *permitted but a symptom of possible
  tech debt*; `love.keyboard` is the *method of last resort*, legitimate only where `Key` has no
  answer (keycap visualisation). The guide teaches the last rung as the recommendation — my F2
  inherited the error, and my "clean bill" citing turtle/clock as proof is **withdrawn**: they
  are work items, not evidence.
- Verified: `Key` is a global required at boot and **already the project idiom** (sapper ×4,
  tixy, paint). **Harmony is safe** — its `patch_isDown` is variadic (`init.lua:242-253`),
  unlike the test mock. To update: turtle (**two** sites, not one), clock, and the keyboard
  example's `modHeld`.
- **(2) `gui` goes** — never requested, added for symmetry with the shape now dissolved. Out of
  code, tests and docs; one debt-register line saying it is supportable in principle and
  purposefully unsupported. **This supersedes my F1** (add `Key.gui()`) and dissolves the
  question instead of answering it — the same argument Decision 30 applies to the tracked set.
- Enumerated traces incl. two nobody had listed: **harmony's `Super`/`Hyper`/`H` token map**
  (dead — no scenario uses it) and **Decision 8 names `gui` in its precedence list** (`:392`),
  so the ledger needs an in-place amendment, session34's Decision-21 precedent.
- Two behavioural consequences recorded rather than hidden: registering `'gui+s'` starts failing
  loudly (`gui` reads as a second trigger), and a Super press stops being modifier-shaped, so a
  registered `'ctrl+*'` class would now catch it.
