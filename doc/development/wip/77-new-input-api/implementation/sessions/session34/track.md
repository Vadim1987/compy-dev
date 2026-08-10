# session34 — track

## 2026-08-10 — boot

- Booted per `agents/validation.md` → `agents/sessions.md`. **Fresh start**: session34 held
  only `prompt.md`; no `track.md` / `report.md` (sessions §2 row 1). Track opened now.
- HEAD `7437f2ab` "docs(session33): wrap — report, three closing instructions, session34
  prompt", branch `feature/77-newapi-analysis-s20260615`. Working tree: **no tracked
  modifications** — only the known untracked scratch (`claude.sh`, `src/STEPS.md`,
  `input-pr-slices.tar.gz`, `doc/tall_blocks.md`, `doc/development/wip/{clarification,
  personal-notes,pull-26}/`) and the three nested example repos.
- **Baseline confirmed: `busted tests` → 955 / 0 / 0 / 3.** Matches the prompt.
- Read in full: `agents/validation.md`, `agents/sessions.md`, this prompt, session33's
  `report.md` + `track.md`; plan `S27-triage-and-plan.md` §4 step table and §§11.4–11.6 for
  the four option rows.
- **Mode: not yet declared** — the session opens with a choice the owner makes. Options A–D
  presented; ruling pending. Execution mode begins only after the ruling.

## 2026-08-10 — owner ruling: A and B, plus an ordering change

- Owner took **A (docs) and B (the maze diagnostic)** for this session, and ruled
  additionally that **C precedes D**: *"otherwise will be fixing D against outdated platform
  logic (even if it not overlaps, doing so would be conceptually wrong)."* Sequencing is now
  docs → tests → platform code → the keyboard heal.
- Amendment written into P9b's step + new §13 reasoning (`115841cd`). **Left open and flagged,
  not extrapolated:** the examples step edits the same file the heal rewrites, so the argument
  applies there more directly than to the platform code — raise before the heal starts.
- **Mode: execution.**

## 2026-08-10 — A landed, five commits, and three things the step did not know

`fb81ecc0` guide · `90935e2c` internals · `8a879534` ledger · `8cae175f` debt · `70eb4842`
dispatch-layers. Suite 955/0/0/3 at each.

- **The guide teaches the device read and the flag shortcut**, the latter under a plain
  heading with no ledger reference (owner's naming ruling). **No obituary for the tracked
  set** — it appears nowhere at base `3256aac`, so for a reader of that guide it never
  existed, and "it is gone" would advertise a moving part the PR is not asking about.
- **Two statements were false about the tree TODAY**, not merely after the sprint — a hook
  does not receive the held table (Decision 26 landed long ago), and the widget/flow
  signatures in the internals doc were wrong. Corrected, not marked.
- **Three finds.** (1) `internals/event_dispatch_layers.md` documents the bookkeeping and was
  on nobody's list. (2) Decisions **25 and 26** still sent readers to the dissolved surface —
  26 while defining the rule that made the argument unnecessary. (3) **`Key` has no `gui()`**,
  so the ruled shape has no helper for the fourth row of `mod_triples`; nothing registers a
  gui combo so nothing is broken, but P14d must decide. The `gui_k` debt entry no longer
  reads "harmless".
- **PENDING markers** placed per passage; the five debt entries are marked rather than
  deleted, because deleting a live defect's record on the strength of a plan is how a defect
  goes unrecorded.
- Heading discipline: kept *"Held keys"* (two test comments cite it); renamed the internals
  heading and fixed its one citation in the same commit.

## 2026-08-10 — B: the SM3a hypothesis does not reproduce

`f4acdccf`. Note: `../../../validation/notes/S34-sm3a-runtime-check.md`.

- Harmony under `xvfb-run` is the only way to get two runs in one process. maze → other →
  maze: **same font pointer, same metrics, glyphs present, byte-identical screenshots** —
  including with `clock` in between, which sets a 172px font and never restores it.
- The hypothesis was structurally sound: the symbols are drawn with the **ambient**
  `gfx.getFont()`. What stabilises it is the **console drawing between runs** — the return
  path, not a stated guarantee. Session28 was right that nothing in stop resets it.
- **Not closed.** Owner saw it interactively; this drove the app synthetically; two
  intervening projects of several. Recorded as unreproduced precisely so it cannot authorise
  a state-reset fix.
- Two harness lessons, both cost a run: `hasGlyphs` on a string with newlines answers false,
  and harmony's `release_keys()` on the line after a combo clears the modifier **before** the
  queued keypress dispatches, so the shortcut silently never fires. Both carried into the
  note for P13.
- Tree restored: instrumentation reverted, scenario deleted, the four moved-aside scenarios
  moved back. `git status` clean but for the known scratch.

## 2026-08-10 — cold review of the docs step (owner-requested), three fixes

Sub-agent: **Sonnet, model passed explicitly**, read-only, briefed cold — given the diffs and
the tree, deliberately **not** given my reasoning or the plan. Prompt of record
`../../../validation/prompts/S34-docs-cold-review.md`, report
`../../../validation/outcomes/S34-docs-cold-review.md`. Fixes in `13f6df5b`.

- **It caught a real regression I introduced.** Two debt-register bullets asserted in the
  **present tense** that the builder asks the device. It does not — `controller.lua:395` still
  takes the table. Worse: the sentence one of them replaced was **true** before my edit. The
  docs-ahead-of-code discipline is exactly where this fails, and I failed it in the one file
  whose sibling entries all carry markers.
- **The key-files table** had silently lost `keys_pressed`/pressed-keys view from the gateway
  row while both are live exports — an omission with no marker reads as a description of today.
- **Marker scope** made explicit: a narrower marker inside a marked section could be read as
  ending the outer one's coverage.
- **Two declined, with reasons recorded in the commit:** the `gui` entry's placement under
  *"Anticipated — revisit at the named point"* is right, since naming the point is what that
  section is for; and its two non-findings (the nested repo's absent history, the mock's
  single-arg `isDown`) are known and already recorded elsewhere.
- **Clean bills worth having:** heading-rename citations all resolve, `../` links resolve, the
  new code example's API verified against real code and 5.1-safe, ledger tombstone discipline
  intact.

## 2026-08-10 — WRAPPED

Owner asked what the plan says is next and whether it wants warm or cold context. **Cold, and
for a substantive reason:** the tests are written against the spec this session wrote, so a
warm session would fill spec gaps from memory instead of noticing them — a cold reader who
cannot tell what to assert has found a defect in the spec. C also carries a decision (the `gui`
row) and is the largest unit left. Context space was not the constraint (22% used);
heterogeneity was — this session held docs, a runtime diagnostic and a review.

Wrapped per `agents/sessions.md` §5. Report distilled; successor commissioned as session35 and
the pointer repointed. **Successor shape: revalidation THEN execution** — this session was
cognitive-heavy, which the workflow answers with a revalidation handover, and the revalidation
target is exactly what the tests step needs first. Its gate is explicit: report and stop before
any code moves. The owner's instruction to situate the successor in the **plan**, not only its
step, is met by opening the prompt with the four-part order and what the sprint still owes.

Eleven commits, all docs. Suite **955 / 0 / 0 / 3** at every one. Nothing pushed. Track kept raw.
