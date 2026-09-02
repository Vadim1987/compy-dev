# session66 — track

## 2026-09-02 — boot

- Fresh start: `session66/` held only `prompt.md`, no `track.md`/`report.md`
  (`agents/sessions.md` §2 → fresh). Track opened here.
- HEAD `9dfd2c3d` (session65 wrap, "a scoped revalidation runs before the roadmap").
  Working tree: only the known untracked scratch (`broken-busted/`, `claude.sh`,
  `input-pr-slices.tar.gz`, `repos.txt`, `src/STEPS.md`, `worklog.md`, the three nested
  example repos). No unexpected diff.
- Baseline confirmed: **1048 / 0 / 0 / 10** — `busted tests`, **LuaJIT 2.1** in the
  container (owner runs PUC Lua).
- Read: `agents/validation.md`, `agents/sessions.md`, `agents/rules/revalidation.md`,
  session66 prompt, session65 report **and** track (end-to-end, per boot ritual §4).
- Task as booted: **part 1** a scoped delivery-level revalidation of session65 over four
  named subjects (+ one mechanical residual-id sweep); **part 2** the roadmap, row picked
  by the owner (prompt recommends `FIX-02`).
- Awaiting nothing to start part 1; part 2's row is an owner call.

## 2026-09-02 — owner adds a fifth subject, and starts the pass

**Owner:** *"I would add validating replan sanity and integrity to the revalidation — anything
omitted, lost, done in a way that undermines path to release?"* Then: *"start the revalidation now."*

So subject **5 = session65's replan** (the acceptance split + the reordering that moved the merges
ahead of the smoke): is anything omitted or lost from the old `ACC-02`, and does the new order
undermine the path to release. Integrity check in the `rules/revalidation.md` §4 sense, applied to a
plan rather than to prose.

Running the pass in the main session, not spawned: it revalidates hand-written *judgment*, which
`agents/validation.md`'s model-economy section puts in the parent tier.

## 2026-09-02 — the pass, closed

Deliverable: `validation/reviews/S66-session65-delivery-revalidation.md`. Nine findings, F1–F9;
subjects 1–3 clean on substance, the defects are in subject 4's leftovers and in the replan.

**The pass turned on where each session had been reading.** Session65 replanned from `ROADMAP.md`
(*what next*) and the rulings it reversed live in `validation/plan.md` (*why*) — the split
`agents/validation.md` names in as many words. Two dated owner rulings went with it: the pre-merge
smoke as the **control** for the post-merge one, and the cold review *"before any keyboard time"*.
Neither is cited in the replan, and the roadmap now calls the old order an unnoticed inversion.

**The owner's instruction was narrower than the change made.** *"Smoke and recon ahead of slicing
and docs finalisation"* orders `ACC-02` against the prose rows; putting the **merges** ahead of the
smoke was the session's own addition. Presented as a ruling to re-make, not a defect to fix.

**Method notes worth carrying:**

- **A `*"section"*` citation sweep is cheap and decisive.** Anchors = markdown headings **plus**
  bold lead-ins (this corpus names sections both ways; headings alone give ~40 false positives).
  Over `src/`, `tests/` and the persistent corpus it found exactly one real orphan — F1 — which
  three passes of reading had walked past.
- **The removal pass's grep scope was `src/` + `tests/`.** F1 is a doc citing a doc, so it was
  invisible to it. The rule in `agents/validation.md` names code; the hazard is not code-only.
- **A renumber's blast radius was measured as "no `ACC` id in `src/` or `tests/`".** True, and the
  wrong question: `roadmap.md` §2's cheap branch still says *sweep the planning documents*, and
  four live citations now resolve to a different smoke pass (F3).

## 2026-09-02 — the owner rules both halves of F4: the new order stands

**(a) Merges before smoke — confirmed, and the 2026-08-26 control argument is answered rather than
overruled.** *"We are accelerating now, so no point in having two separate sessions of smoke testing
and defect fixing just for ceremony. Recon will document what changed in upstreams before the merge;
this knowledge will assist troubleshooting."* So the control is **bought differently**: the old
ruling spent an extra owner sitting to separate two candidate causes; recon's written delta does the
same job at desk cost. That is the piece to record — not "the old ruling was wrong".

**(b) The cold read stays after keyboard time.** Owner's reasoning, and it generalises past this
row: *"It was supposed to de-risk by spotting bugs, but can also become wasted effort or misfire.
Smoke becomes more important in the same way as behavioural vs unit testing — cold review checks
internals, smoke validates the surface. When the planning horizon collapses to one day, postponing
smoke for the sake of additional peace of mind makes no sense."*

**The behavioural note:** both answers are the same move — a de-risking step whose cost is a *sitting*
loses to one that produces a result, once the horizon is short. Ceremony is the word for a step kept
for its shape. Neither ruling reverses the earlier reasoning on its merits; both change what the
reasoning is priced against.

**Consequence for the record:** `plan.md`'s *"Why ACC runs before U, not after"* is superseded in
place, and `ROADMAP.md`'s *"an inversion nobody had noticed"* framing must go — it is now known to be
false, and left standing it would mislead the next reader exactly as it misled session65.

## 2026-09-02 — the fix set lands; part 1 closed

Six commits, `d5362b06`..`b365a42e`, suite 1048 at each, none pushed. F1/F2/F5/F7 fixed, F3 swept,
F4 recorded, F8 closed. **Open: F9** (does §2's stakeholder carve-out reach §3 — owed before
`LEDGER-02`) and **F6's section-order move**, deliberately not taken: a large diff in a file the
owner reads, and the sequence line is already right.

**Three judgement calls inside the fixes, worth their own line:**

- **`plan.md`'s `ACC-02` table was deleted, not renumbered.** It duplicated the roadmap's schedule,
  which is `roadmap.md` §1's second-timeline failure arriving by the side door, and it is why seven
  ids drifted in one edit. Renumbering it would have preserved the defect in working order. The
  plan keeps the *why* the roadmap does not carry, and the roadmap's `maze` row gained the Track-2
  obligation that lived only in the plan.
- **Dated records keep their text.** The turtle peer review and the `FEAT-02` revalidation get a
  bracketed note rather than an edit — rewriting a finding to match today falsifies the record it is.
- **`REC-01`'s delta document is written onto the row as a condition**, not as an outcome. The order
  now in force rests on it: without that document the merges precede the smoke with nothing standing
  in for the control the old order bought.

**The class F1 and F3 share, for whoever sweeps next.** Both were measured against `src/` and
`tests/` and both live outside it — a doc citing a doc, and a plan citing a plan. **The scope of a
citation sweep is where the citations are, not where the code is.**

## 2026-09-02 — F9 ruled, and the shape of the ruling is the point

**Owner:** *"Let's rule for this specific case, no time and need to generalize. 'Why oneshot is gone
and what replaces it' will be the answer, which should be answered by decisions. It's not a debt
because the contradiction did not exist at base (there was `oneshot` and nothing replaced it). So
it's swept from debt but stands in decisions and changelog."*

So the two entries go, and **§3's test is not amended** — I had offered a one-line general clause
and it was declined on cost. The ruling landed on `T-NEVER-SHIPPED`, where `LEDGER-02` reads its
input, not in the rule file.

**Two things to carry.** The owner's ground is sharper than the one I proposed: I argued the outside
request is *preserved elsewhere*, they argued the entry **was never debt** — at `3256aac` there was
`oneshot` and nothing replacing it, so *"ruled in and nothing implements it"* is a contradiction this
branch created and closed. Provenance never had to be weighed. And **generalising has a price**: a
rule earns its place by the passes it saves, and a rule written to close one instance is a rule the
next reader must interpret. Record where it is consumed.

Checked while recording, since the ruling asserts it: `CHANGELOG.md` `CURRENT_SCOPE` *Added* carries
`auto_hide` at user-facing altitude and correctly never mentions `oneshot` — no project could write
it — and `D-AUTO-HIDE` names the outside request and the old name for the grep.

## 2026-09-02 — the `FIX-02` split (the entry it should have had at the time)

**Owner:** *"Makes sense to run RECON+MERGE+SMOKE before this huge bundle of editorial fixes? If
anything arises, verbose prose could help troubleshooting, but incorrect prose could confuse it. So
I would lean to run editorial bundle first to reduce possible noise and confusion."* Then, on the
proposal: *"I agree with reordering. Do it and put a remark saying we temporarily skip crosswalk
renumbering so the roadmap order prevails."*

Ruled as a **split**, not a move — moving the bundle whole would have swept `keyboard` and `maze`
immediately before merging upstream into them, which is the inversion the acceptance reorder had
just removed. Landed `4582678d`.

**The strongest form of the owner's argument was not in their sentence:** the document read *during*
the sitting is `smoke_checklists.md`, and it carries the banned widget-sense idiom. Prose that
misleads is worst in the file open on the desk.

## 2026-09-02 — the cold read of this session's own work

Owner: *"Is any of your own work worth cold revalidation? If so, run an agent to do it, then apply
corrections in place so the next session won't deviate from the primary mission."* Commissioned
(Opus, cold): `validation/prompts/S66-cold-revalidation-commission.md` →
`validation/outcomes/S66-cold-revalidation.md`.

**Judgement cleared, execution caught.** Nine findings hold, F4's premise verified on both halves,
four corrections all true — and **two of twenty rows were in the wrong half of the split**, the
deletion lost a status fact while promoting the instruction that fact refuted, and my own citation
sweep skipped `ROADMAP.md`.

**The line worth keeping:** *the pass that names a defect class is not thereby immune to it.* F3's
finding was "the blast radius was measured in the wrong place"; its own sweep was measured in the
wrong place, one file over. **And a scoping assumption is the thing to state out loud** — the sweep
assumed the renumbering pass had cleaned the document it was performed in, and that assumption was
never written down anywhere it could be checked.

Six correction commits: `7150d15b` (the split's two rows + four overstatements), `cce77919` (the
Track-2 fact), `1e052c7d` (the roadmap's own `ACC-` citations), `2a486215` (five pre-existing
`FIX-02-01` citations and two fired triggers), `cb159e39` (the stale sizings), and the wrap
correction.
