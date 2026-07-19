# session14 — track

## Boot — 2026-07-19

- HEAD: `3c11c05` (session13 wrap: DI1 done, successor S14 = revalidate DI1 + DI2/DI3).
  Tree carries the known owner scratch + anomalies (`agents/validation.md` guardrail 3) — not swept.
- Suite baseline confirmed: **815 / 0 / 0 / 4**, pendings at lines 118/172/185/246 — exact match
  to the mandated baseline. Go-signal.
- Model: **Opus** (orchestrator). No prior `session14/track.md` — clean boot, no mid-flight death.
- Read in order: `agents/validation.md`, `session14/prompt.md`, `session13/report.md`,
  `session13/track.md`, `agents/rules/revalidation.md`, DI1 deliverable
  (`validation/outcomes/DI1-docA-fidelity.md`).
- **Mandate (S14):** (1) revalidate DI1 (`agents/rules/revalidation.md` checklist) — spot-check
  the verdict table against CODE (not suite — circularity guard), especially the four FALSE-claim
  findings + the `unique-no-home` rows DI3 will act on; confirm no doc-A section skipped. Report
  findings; **owner approval before DI2.** (2) DI2 owner ruling on promotion form (a/b/c),
  owner-gated. (3) DI3 mechanical execution (Sonnet) of the ruling.

## Revalidation of DI1 — CLEAN (2026-07-19)

Worked the `agents/rules/revalidation.md` checklist; spot-checked every load-bearing claim in
CODE myself (LSP path-resolved + grep backstop), not trusting the deliverable.

**Four FALSE-claim findings — all 4 re-confirmed in code:**
1. §6.1/§6.2 "zero consumers" → FALSE. `projectInputController.lua:198-207` `_dispatch` computes
   `combo_string(trigger, keys_pressed)` (l.199-200) as the live tier-1/2 lookup; all three
   channels thread `held_keys()` (l.259/265/273). ✓
2. §5.4 "not documented in internals; first record" → FALSE. `internals/user_input.md:168`
   documents inspect near-verbatim (get_user_input()→nil under inspect, REPL over project_env). ✓
3. §6.6 cursor "compy: nothing yet" → FALSE. `compy.input.get_cursor`/`set_cursor` exist at
   `consoleController.lua:520/527`. ✓
4. §6.6 auto-close "via pushed userinput event" → stale. `submit()` (`userInputController.lua:409-418`)
   delivers then `self:hide()` synchronously; grep confirms every `push('userinput')` hit in src is
   a comment saying the producer "is gone" — no live producer. ✓

**Two `unique-no-home` merge facts (DI3 targets) — both confirmed:**
- §9-3 sink-as-default silent-disable of `on_limit_reached`: structural. `_generic_callback` (tier
  3, maps keypressed→on_key_pressed) returns truthy → `_dispatch` short-circuits at l.205 before
  `_sink` (tier 4, where `on_limit_reached` fires). Real coupling. → `technical_debt/input.md`. ✓
- §9-2 'starting' never observed: `main.lua:272` love.load → `:286` 'starting' → `:319` 'ready',
  same synchronous call, before the event pump. → one line in `internals/user_input.md`. ✓

**Circularity guard held:** all Axis-1 fidelity witnesses are `src/**`; Axis-2 cites persistent
corpus docs; the tests.md fold-in is a doc-drift note, not a suite-as-fidelity-witness. ✓
**No section skipped:** verdict table covers §1,§2,§3(×N),§4,§5.1-5.9,§6.1-6.7,§7.1-7.4,§8,§9 —
matches doc-A's full header inventory. ✓
**tests.md drift target accurate:** `tests.md:69` says "808" + pendings 101/153/161/222; live is
815/0/0/4 pendings 118/172/185/246. DI3's refresh target is correct. ✓

Verdict: DI1 stands. No corrections needed. Awaiting owner approval before DI2.

## DI2 ruling + index — 2026-07-19
- Owner accepted revalidation. Ruled **(b) merge survivors, track destinations**; doc A frozen in place.
- Owner add-on: build resolution index (DI1 Axis-2 × A1 inventory) so DI3 follows mapped paths, no re-discovery.
- Recorded: `validation/notes/DI2-ruling-and-resolution-index.md` — ruling + survivor destinations + per-citation retarget table (all corpus headings grep-verified to exist).
- Survivors: §9-3 sink silent-disable → technical_debt/input.md; §9-2 'starting' one-liner → internals "Dispatch chain".
- DI3 next: Sonnet, mechanical — merge 2 facts, retarget ~30 doc-A refs per index, refresh tests.md (808→815, pendings→118/172/185/246). Non-doc-A refs untouched.
- Owner feedback: keep track raw/telegraphic (agents/sessions.md §3) — adopted here.

## DI3 done — 2026-07-19
- Spawned Sonnet (explicit model) vs DI3-prompt.md; serial shared tree; not-committed (I review+commit).
- Result reviewed: doc A untouched, design/ frozen, non-doc-A refs preserved, suite 815/0/0/4 (pendings 124/186/199/265).
- 2 Sonnet judgment calls, both accepted: dropped "doc A" definition comments (no sibling cites shorthand); dropped redundant design.md §4 ref (Decision 11 adjacent already states fact).
- pending line numbers came out 124/186/199/265 (not the prompt's stale 118/172/185/246 — Sonnet derived from live run, correct).
- Committed unit-sized: 62022fe (merges) / a89fbf4 (retargets) / a54558c (tests.md) / 7b7f2f2 (validation bookkeeping).
- DI track (DI1 reval + DI2 + DI3) COMPLETE. Next per plan: TF (test fidelity, other half of DI/TF gate) then Phase B convergence. Not this session's mandate — await owner.

## Ref stabilization (Phase-A tactical amendment) — 2026-07-19
- Owner review of DI3 → 2 asks: (1) paths ambiguous (bare `decisions/input.md` unresolvable from tests); (2) resolve/annotate remaining interim refs before TF. Owner: no TF yet, stabilize comment refs first.
- Owner rulings: root-relative ALL refs; interim refs KEPT as evidence (plan-consistent) but ANNOTATED (not resolved); {jargon} untouched (TF task); marker convention = badspecref is owner's ad-hoc bad-ref flag.
- Amendment recorded: `validation/reviews/ref-stabilization-2026-07-19.md` (tactical Phase-A, not strategic).
- RS1 (Sonnet): normalized 210 bare corpus refs → `doc/development/...` across 11 files. Reviewed clean (comment-only, LSP identical, suite green). Committed 47d92f0.
- RS2 (Sonnet): annotated ~20 opaque interim refs w/ meaning gloss + source-quote decode-map; kept every badspecref wrapper (25↔25 preserved); {jargon} untouched. Spot-checked A5/E30/C23/ratified-model/M8-01 glosses vs source — accurate. Suite 815/0/0/4.
- **2 items for owner:** (a) RS2 also edited 4 TRACKED example files (tixy/guess/valid/repl M8-01 refs) — OUTSIDE my inventory (I scoped to input suite); HELD aside pending scope ruling. (b) FLAGGED refs (empty badspecref = owner meta-comment; #77/'this feature' self-refs; 'm7 design session' unpinnable) — left for owner.
- Committing: core 5 files + bookkeeping. Examples held.
