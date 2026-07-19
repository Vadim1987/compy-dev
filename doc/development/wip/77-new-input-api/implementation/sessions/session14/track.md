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
