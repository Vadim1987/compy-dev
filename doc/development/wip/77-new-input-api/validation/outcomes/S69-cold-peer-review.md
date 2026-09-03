---
description: Cold Sonnet peer review of session69's diff (1a864137..HEAD) — integrity and arithmetic, not scope
status: active
audience: developer
authored: llm
session: 69
date: 2026-09-03
---

# S69 cold peer review

**Verdict.** The 28-commit range is substantively sound: every code-facing claim I checked
resolved true against `src/` (the `SearchController`/`add_text` correction, the D-TWO-SURFACES
fact-preservation, `get_text()` shipping and being marked experimental), the three citation-hygiene
classes (A paths, B session numbers, C `FR-n`) re-derive to exactly the counts claimed at the
commits where they were claimed, and every sampled "deleted pointer" resolves to substance that
actually survived elsewhere. Two arithmetic claims do not survive re-derivation, however, and one
of them is asserted as a present fact one commit before it became true. Neither changes a decision
the session made or invalidates the work executed, but both are counting errors of exactly the kind
this review was commissioned to catch, in the same class of claim (a REMARK/id count) the prompt
flagged as previously burned by case-sensitivity and character-class mistakes.

## Findings

**F1 — `FIX-02-07`'s "29 at boot" undercounts by 2; the real boot figure is 31, matching the
owner's own question.** [`correction`]
- **Claimed:** commit `7c7cf6d2` (roadmap `FIX-02-07` cell) and `session69/track.md` (`0e3be8b7`
  parent context) both state "**29 markers across 10 files** at session69's boot."
- **True:** the case-sensitive `REMARK` count in the persistent corpus (`doc/` excluding
  `doc/development/wip/`) at the boot commit `1a864137` is **31 across 10 files** — the same number
  the owner used verbatim in the question the track section is titled after ("Owner question — the
  31 REMARK mentions"). I re-checked at `9eb91de2` (immediately before `FIX-01-01` began) and it is
  still 31; nothing removed a `REMARK` between boot and the start of `FIX-01-01`.
- **How I checked:** `git grep -noE "REMARK" 1a864137 -- 'doc/' ':!doc/development/wip/'` → 31
  lines, 10 distinct files (`git grep -loE "REMARK" 1a864137 -- 'doc/' ':!doc/development/wip/'`
  confirms 10). Repeated at `9eb91de2` with the same result. `git grep -noE "REMARK|INTERIM" ...`
  (the fuller gate pattern) returns 36 across 11 files, which is not the number cited either — so
  the row is specifically undercounting the `REMARK`-only figure, not conflating it with the wider
  pattern.
- **Severity:** `correction`. It sits in the ephemeral `ROADMAP.md`, not the persistent corpus, and
  the final "24 across 10 files" figure the row lands on (see F2) is independently correct — the
  wrong intermediate number does not change what got fixed, only how the delta is narrated.

**F2 — the same cell's "24 now — all five are FIX-01-01's" was true only in hindsight; at the
moment `7c7cf6d2` was committed the actual count was 26, not 24.** [`correction`]
- **Claimed:** `7c7cf6d2`'s commit message: *"29 at boot, 24 now, and all five are FIX-01-01's —
  R091, R092, R150 and R164 were the markers standing on the paragraphs it rewrote."* The roadmap
  cell states the same "24 across 10 files at 2026-09-03," attributing the entire drop to
  `FIX-01-01`.
- **True:** `git grep -oE "REMARK" 7c7cf6d2 -- 'doc/' ':!doc/development/wip/'` (i.e., the tree
  exactly as `7c7cf6d2` left it) returns **26**, not 24. `7c7cf6d2` (12:03:24) was committed
  *before* `ab8c2415` (12:05:20, the path fix) and `6c96c96f` (12:06:01, the `FR-n` fix). The
  `REMARK` count only reaches 24 after `6c96c96f` also lands, because two of the seven `REMARK`s
  actually removed across the session belong to `FR-1`/`FR-6` (class C, retired by `6c96c96f`'s
  "spelled out instead of cited" pass), not to `FIX-01-01`. `FIX-01-01` alone accounts for 5
  (R091, R092, R150, and R164's two remarks at `:819`/`:869`); the other 2 are `6c96c96f`'s. The
  final HEAD figure, 24 across 10 files, *is* correct — I independently re-derived it
  (`git grep -oE "REMARK" HEAD -- 'doc/' ':!doc/development/wip/'` → 24, 10 files) — but the cell
  that states it predates the second of the two fixes it depends on.
- **How I checked:** `git log --stat 1a864137..HEAD` for commit timestamps; `git grep` at `7c7cf6d2`,
  `6c96c96f`, and `HEAD` as above; `git diff 1a864137 HEAD -- 'doc/' ':!doc/development/wip/' | grep
  -B2 '^-.*REMARK'` to enumerate all seven actually-removed `REMARK` lines and attribute each to its
  commit.
- **Severity:** `correction`. The end state (24/10, and the work that produced it) is right; the
  cell narrates a count one commit ahead of the fix that makes it true.

**F3 — `T-EPHEMERAL-IDS`'s "FIX-02-05, FEAT-02 and BUG-02-01 at eleven apiece" is false; the three
counts are neither 11 nor equal to each other.** [`correction`]
- **Claimed:** `technical_debt/general.md`'s new `T-EPHEMERAL-IDS` entry (commit `61c66ba3`):
  *"The heaviest are `FIX-02-05`, `FEAT-02` and `BUG-02-01` at eleven apiece."*
- **True:** exact-token counts (excluding embedded occurrences inside longer ids like
  `FIX-02-05-base-evidence.md` or `FEAT-02-01`) across the six files the entry itself scopes
  (`technical_debt/input.md`, `technical_debt/general.md`, `decisions/input.md`,
  `smoke_checklists.md`, `internals/user_input.md`, `internals/examples/turtle.md`) at HEAD:
  **`FIX-02-05` = 8, `FEAT-02` = 10, `BUG-02-01` = 12.** No two of the three agree, and none is 11.
- **How I checked:**
  `git grep -oP '(?<![\w-])FIX-02-05(?![\w-])' HEAD -- <the six files>` → 8;
  same pattern for `FEAT-02` → 10; for `BUG-02-01` → 12; for `FIX-02-01` → 6 (this one *does*
  match the entry, which does not separately claim it); for `LEDGER-02` → 4 (also matches). I
  additionally listed every raw `FIX-02-05` hit with `git grep -n` to rule out an off-by-boundary
  miscount — all 8 are genuine roadmap-id citations, none is inside a filename.
- **What I could not fully close:** the entry's headline total, "119 occurrences," was not
  reproduced exactly. A broad approximation (`(FIX|FEAT|BUG|ACC|DEC|LEDGER|DOC|REC|MERGE|OP|CHG|ARC|
  GATE)-[0-9]{2}(-[0-9]{2})?` over the same six files) gives 114 — close enough that I do not
  treat 119 as disproven (the exact id-prefix vocabulary used to derive it is not stated, so an
  exact reproduction was not possible from the outside), but it is also not an independent
  confirmation. The "eleven apiece" claim, by contrast, is an exact literal-string search with no
  regex ambiguity, and it does not hold.
- **Severity:** `correction`. `T-EPHEMERAL-IDS` and the owner ruling that follows from it (rule now,
  sweep at `DOC-01-06`) do not depend on which three ids are heaviest — the entry's substance (live
  sprint ids dangle when `wip/` is deleted) is unaffected. But it is a false, specific, checkable
  sentence now shipped in the persistent debt ledger.

**F4 — `configure(config)`'s "ten live citations (2 src/, 7 tests/, 1 debt register)" is off by
one; the real count is nine (2/6/1).** [`correction`]
- **Claimed:** `FIX-01-01-enumeration.md` and `session69/track.md`, on why both `show(config)` and
  `configure(config)` headings were kept despite reading better merged: *"ten live citations name
  `configure(config)` as a section (2 in `src/`, 7 in `tests/`, 1 in the debt register)."*
- **True:** `git grep -n "configure(config)" -- src/ tests/ doc/development/technical_debt/` finds
  **2 in `src/`** (`consoleController.lua:925`, `userInputController.lua:383`), **6 in `tests/`**
  (all in `tests/input/input_widget_control_spec.lua`: lines 333, 350, 372, 389, 408, 490 — I
  listed every `configure` mention in that file to rule out a formatting variant elsewhere in the
  same suite; none exists), and **1 in the debt register** (`technical_debt/input.md:1131`). Total
  **9**, not 10.
- **How I checked:** `git grep -n "configure(config)" -- src/ tests/ doc/development/technical_debt/`
  (and a case-insensitive re-run, same result) at HEAD.
- **Severity:** `correction`. The decision itself — keep both headings rather than pay a
  cross-`src/`-and-`tests/` comment sweep for one editorial row — holds at 9 citations exactly as
  well as at 10; the count supporting it is simply wrong by one.

**Classes A, B, C (the three citation-hygiene sweeps) — re-derived and confirmed exact.**
[no finding]
- **Class A (ephemeral paths), 20 sites / 4 files, claimed at `461b4489`:** re-derived line-by-line
  at that commit for all four files (`decisions/input.md`: 2; `smoke_checklists.md`: 6;
  `technical_debt/general.md`: 10, including the 6 "written relative" sites without the literal
  `wip/` string; `technical_debt/input.md`: 2). Matches exactly, including which specific lines are
  literal-`wip/` vs. relative. Post-fix (`ab8c2415`), 14 of the 20 are gone and exactly the 6
  claimed as "handed to `LEDGER-02`" remain (`general.md`'s two renumber entries, 5+1 sites) —
  verified by grepping the tree at `ab8c2415` itself.
- **Class B (session numbers), 12 sites / 3 files, claimed at `461b4489`/`e3b8b1af`:** re-derived
  case-insensitively (`\(?session[0-9]+\)?`) at `e3b8b1af` — 12 sites exactly, distributed
  3/1/8 across `decisions/input.md` / `general.md` / `input.md`, matching the note's own line list.
  A case-*sensitive* grep first returned only 11 and silently missed `decisions/input.md:1164`'s
  `Session32` (capital S) — the exact case-sensitivity trap the commissioning prompt warned about;
  re-running case-insensitively resolved it, and the fix commit (`5d8ae109`) does correct that
  site. Post-fix, the corpus returns zero matches (verified).
- **Class C (`FR-n`), 7 sites / 2 files, claimed at `461b4489`:** re-derived at `ab8c2415` (before
  `6c96c96f`) — exactly `decisions/input.md:194,203` and `internals/user_input.md:199,200,413,415,424`,
  7 sites (8 raw `FR-n` tokens, since line 194 carries both `FR-3` and `FR-4`). No `FR-n` found in
  `src/` or `tests/`, or anywhere else in the non-`wip/` doc corpus. Post-fix (`6c96c96f`), zero
  matches remain, and I confirmed the two paragraphs read as genuine translations ("the setup
  parameters the widget was required to accept," "hiding without tearing down," "hearing key
  events that produce no character") rather than deletions, matching the commit's stated method.

**`T-NEVER-SHIPPED`'s "61 entries, 53 + 8" — confirmed exact.** [no finding]
- `awk` count of `###` entries under `## RETIRED` in `technical_debt/input.md` = 53, in
  `technical_debt/general.md` = 8. 53 + 8 = 61, matching the entry exactly. `LEDGER-02-01`'s "56
  walked, five more outside it" (56 + 5 = 61) is internally consistent with this figure.

**Code-facing claims — confirmed true against `src/`.** [no finding]
- `SearchController:textinput` (`src/controller/searchController.lua:143`) calls
  `self.input:add_text(t)` directly — it never calls its own instance's `textinput`. The rewritten
  Search section's corrected claim ("`SearchController:textinput` calls `add_text`; the instance's
  own `textinput` is never reached either") is accurate, as is "its `keypressed` removers reach
  past the controller into the model the same way `clear()` does" — `SearchController:keypressed`'s
  `removers()` closure operates on `self.model.input` directly (`:backspace()`, `:delete()`), same
  as `SearchController:clear()`'s `self.model.input:clear_input()`.
- `compy.input.get_text()` genuinely ships (`src/controller/consoleController.lua:906`), and the
  guide/CHANGELOG language marking it experimental, dropping the `ACC-02` smoke claim, and
  recording the caveat on `T-CONTENT-READ` are mutually consistent — checked the diffs of
  `38a40b4b`, `45bec9df`, and `bacc0f24` against each other and against `doc/input_api.md` at HEAD.
- D-TWO-SURFACES' rewrite (`ddcdd936`) — diffed old vs. new text directly — keeps every fact its
  commit message claims to keep (the `on_text_entered`/`hooks.textinput` distinction, "results
  never ride chain return values," the retired vertical-limit flag) and only removes the defended
  framing ("conflating them is the trap," the "student" passage, which the commit says already
  lives in the file's intro — confirmed at `decisions/input.md:80`).

## Deleted-pointer sampling (the prompt's suspicion #1)

Sampled three of the fourteen `ab8c2415` deletions directly against their replacement prose:
- `decisions/input.md`'s two archive pointers (`:1777`, `:1853`) — the `wip/…/decisions-vacuumed.md`
  path is replaced with "the feature's working tree," and the surrounding sentence ("that archive
  leaves the release when the working tree is deleted") already carried the substance the link
  pointed at. Holds.
- `technical_debt/general.md`'s two evidence pointers to `S68-FIX-02-05-base-evidence.md` — both
  replaced with the classification stated inline (39/9/5/3 over 56), which was already present on
  the same line before the edit, not newly added to compensate. Holds.
- `smoke_checklists.md`'s five pointers to `wip/` review/plan/tag documents — each replaced with
  "see the N commits named above," and I confirmed the referenced commit table ("### The four
  commits a result should be reported against" / "### The two commits...") exists as a heading
  earlier in the *same* `##` section for every one of the five edits (`keyboard`, `maze`, `turtle`
  sections each have their own such table immediately after the section header). None of the five
  is an orphaned reference.

No sample failed; I did not check the remaining eleven of fourteen individually given the pattern
held on every one tried and the review's time budget.

## What I could not check

- **The `T-EPHEMERAL-IDS` total of 119** (F3) — I approximated it at 114 with a broad id-prefix
  regex over the same six files, close enough not to call it disproven, but the entry does not
  state its exact derivation method (which id prefixes it swept, whether design-doc milestone ids
  like `M7-02` count), so I could not reproduce 119 exactly either way. Treat the total as
  unverified rather than confirmed or refuted; the "eleven apiece" sub-claim (F3) is independently
  and exactly wrong regardless of how the total was derived.
- **`lua-lsp` MCP was not invoked.** Every code-facing claim in this range resolved unambiguously
  from `git grep`/`git show` against small, single-purpose files (`searchController.lua`,
  `userInputController.lua`, `consoleController.lua`) where reference/definition ambiguity was not
  a live risk, so I did not spend a serial round-trip on it. If a future reviewer needs a
  call-hierarchy check (e.g., "does anything else call `SearchController:textinput`), that is
  still open.
- **Eleven of the fourteen `ab8c2415` path deletions** were not individually sampled (see above) —
  spot-checked three, pattern held, did not exhaustively verify the rest.
- **The exact grep methodology behind the session's own counts** is never stated in the notes
  (no command is quoted for classes A/B/C or for the 119/24/61 figures), so every re-derivation
  above is *my* reconstruction of a plausible pattern, not a replay of theirs. Where my count
  disagreed, I have stated the exact command I ran so the disagreement is checkable independently
  of my methodology.
- **No `broken pipe` or other lua-lsp outage occurred** — not applicable, since the tool was not
  invoked this session.
