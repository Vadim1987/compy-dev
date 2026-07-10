# Corrective take — M5c-02c: chunk-2 review findings

_Commissioned by the opus-sweeper PM (`agents/sweep.md`), session02, 2026-07-10, running
**autonomously** (per-chunk human gate lifted for this session; human reviews post-factum in git).
This is a **corrective take on the already-landed chunk 2** (`6a3215e` feat + `f280096` tests), not a
new chunk. Target executor: **Claude Sonnet**, dev charter (`agents/dev.md`), M0 image._

## You are

A one-shot implementation agent in the **compy** LÖVE2D repo (root = cwd). You apply a **small, exact
set of corrections** to the landed chunk-2 widget-output surface, keep the suite green, and commit
locally (Conventional Commits, no push). You do **not** re-open chunk 2's design or reach into chunk 3.
Record a short outcome ledger. If any correction turns out to be non-trivial or forces a design choice,
**STOP and report** — do not improvise.

## Context — what landed and why this take exists

Chunk 2 (widget outputs: `on_text_entered`/`on_limit_reached`/`validator`/`highlighter` as settable
slots, `on_limit_reached` firing, `highlighter` functional application) landed faithfully and the
suite is green (755/0/0/6). An independent review (`reviews/M5c-02.md`) raised a corrective-take; the
PM re-verified every finding against live code. **Four items, all confirmed real. Fix exactly these,
nothing else.**

## The corrections — do all four, test-first where a test is involved

1. **`is_at_limit` body exceeds the 14-line hard limit.**
   [`UserInputModel:is_at_limit`](../../../../../src/model/input/userInputModel.lua) (currently
   `userInputModel.lua:559-581`) has a **21-line body** (limit 14, `agents/rules.md`). Refactor it to
   ≤14 body lines **without changing behaviour**. Your choice of technique (extract a small
   private helper for the horizontal/line-scope branch, collapse the up/down guards, etc.) — the
   review sketched one 14-line rewrite you may adopt or improve on. **Hard requirement:** after the
   refactor, the full AC-15 boundary matrix (up/down/left/right × input/line, single-line collapse)
   must stay green — re-run `tests/input/input_contracts_spec.lua` and the full suite. Do not add or
   loosen any assertion; this is a pure body-length refactor.

2. **Over-length `-- REVIEW:` comment (implementor's own musing).**
   `userInputController.lua:322` is a **173-char** single-line `-- REVIEW:` comment (limit 64) musing
   that installing a noop-default `on_limit_reached` at config-apply time would let `emit_limit`
   collapse. **Disposition it, don't just truncate blindly:**
   - If installing that noop default is a **trivial, in-scope** cleanup (a default slot in the
     config-apply path, mirroring the AC-10/AC-26 default-callback shape chunk 1 established) that
     keeps every test green, do it and **delete** the marker. That is the cleaner resolution.
   - **Otherwise** (it's a real deferred refactor, or it would pull chunk-3 wiring in), replace the
     inline comment with a short (≤64-char/line) note **and log it in
     `implementation/technical_debt.md`** as an open item — do not leave an over-length marker, and do
     not silently drop the design thought. Pick the cheaper of the two; when in doubt, prefer the
     note+debt-log route (report-don't-fix).

3. **Over-length test declaration.**
   `input_contracts_spec.lua:1229` — `it('left at first-line start reports input scope', function()` —
   is **65 chars** (limit 64). Shorten the description string by ≥1 char (e.g. drop "reports",
   "at first-line start" → "first-line start") so the line is ≤64. Do not rename the behaviour it
   asserts. (Note: line 1245's sibling is 63 chars and already compliant — leave it.)

4. **Incomplete slot-sharing coverage (AC-16 / review-trap 1).**
   The slot-sharing test `show(config) and fields share one output slot`
   (`input_contracts_spec.lua:1121-1131`) proves config-key-**and**-field reach the same slot for only
   **`on_limit_reached` and `highlighter`**. Review-trap 1 requires that "one slot, two ergonomics"
   assertion for **all four** outputs. **Extend it** (or add sibling assertions) so `on_text_entered`
   **and** `validator` are also each proven to reach the same underlying slot through **both** a
   `show({<key> = fn})` config key **and** a direct `compy.input.<field> = fn` write. Follow the
   existing test's exact pattern; drive real production ingestion, not a stub. These two remain
   **settable-only** here — do **not** assert they *fire* or *gate* (that is chunk 3; keep the
   chunk-2/3 seam intact).

## Boundaries — do NOT

- Touch chunk-3 behaviour (submit/cancel, validator **gate**, `on_text_entered` **firing**),
  chunk-4 route lifecycle, or `src/examples/*`. This take is corrections to landed chunk-2 code only.
- Loosen, delete, or green any existing row beyond the length fix in (3) and the additions in (4).
- Widen the `INPUT_CALLBACKS` allowlist or change the config/field ingestion mechanism — (4) only
  *tests* the sharing that already exists; if it turns out the shared slot is **not** actually there
  for `on_text_entered`/`validator`, that is a real chunk-2 defect — **STOP and report it**, don't
  patch the mechanism under a "test" commission.

## Record + commit

- Write `implementation/outcomes/M5c-02c-corrective.md`: a short ledger — the four items, what you did
  for each (esp. the item-2 disposition path you chose and why), real busted counts before/after, and
  the `is_at_limit` refactor technique. Open with a one-line "surprise" note if anything deviated.
- Commit locally, Conventional Commits, independently revertible, pre-commit hook green, this repo
  only. Suggested: a `refactor(input):` for item 1, a `fix(input):`/`style(input):` for items 2–3,
  and a `test(input):` for item 4 — or fold sensibly; keep code and test changes legible in history.
- Full suite green at the end (`busted tests`): chunk-3+ rows still pending, nothing red.

## Then

Present a short summary and stop. The PM (not a human this session) will run the Opus reviewer on your
corrected diff and decide go/no-go before commissioning chunk 3.
