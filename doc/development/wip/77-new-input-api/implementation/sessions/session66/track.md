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
