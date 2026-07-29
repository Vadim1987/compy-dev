# session21 — report

**Commissioned (per `session21/prompt.md`):** Part 1 — revalidate the S20 version-tag migration
(`rules/revalidation.md`); Part 2, on owner approval — resume the owner-gated marker mop-up at
B-F or B-COV.

**What it became:** both parts ran, the mop-up **finished** (B-F + B-COV — `tests/` is now swept),
the owner widened Part 1 mid-flight into a calibration check that changed a convention, and the
batch work uncovered and fixed a **live production bug**. Five commits, suite green throughout,
**841 → 854 / 0 / 0 / 4** (pendings unchanged at 4).

## Outcome

| Commit | What |
|---|---|
| `96d1c78` | S21 revalidation — 4 coherence gaps closed (F1/F2/F3/F5) |
| `c23fa82` | F4 ruling (ii): per-file `-- Availability:` lines across all 20 `tests/input/` files |
| `332eabb` | correction — the legacy-globals evidence I got backwards |
| `64e5af4` | B-F — structural mop-up, 14 markers |
| `5ad2ce2` | **fix(input)** — `highlight.hl` indexable on the non-parser branch |
| `401fd4c` | new standing rule — commit granularity (`agents/validation.md`) |
| `2b75f3a` | B-COV — 22 coverage markers |

## Part 1 — revalidation verdict

The migration was **substantively sound and correctly executed within the scope it took** — but
the scope was never ruled. Report: `validation/reviews/S21-revalidation-version-tag-migration.md`.

Clean: zero `Bucket` refs; the RVW-085 carve-out coherent; wip-citation discipline held (the two
`wip/` hits in persistent docs are the rule's own anti-pattern illustration and the debt item, not
citations); inventory + triage bookkeeping matched the tree. The architecture claim was
**verified in code**, not trusted — `controller.lua:21` (nil under inspect),
`consoleController.lua:1017` (suspend → `set_default_handlers` swap) — so "changing it reworks the
suspend/inspect spine" is true and the carve-out is right.

Corrected: residual lowercase `bucket` (F1); the nfr file head still in retired vocabulary,
contradicting its own `describe` (F2); the **G-1 ledger row stale** — it still proposed the
doc-first cross-check S20 had already performed, so the collapsed sitting would have ruled from a
weaker evidence base than the tree holds (F3); `SINK = last consumer` retired in one file and left
in five (F5). Two dangling spec cross-refs parked for later (F6).

## The two things that mattered most

**1. The owner's calibration hint was right, and it reshaped the convention (F4).** "Almost
nothing earns a `since` tag" was true *within the migrated files* and false as a suite-wide
signal: `grep "since 1.0.0" tests/` returned **nothing**, while `doc/input_api.md` tags the whole
`compy.input` surface feature-new and 13 of 20 input spec files are new vs `devupstream`. So
"untagged" meant *verified pre-baseline* in two files and *nobody looked* in eighteen —
indistinguishable to a reviewer. Owner ruled **(ii)**: every file in `tests/input/` now opens with
a one-line `-- Availability:` note, **classified by behaviour, not file age** (verified against
`devupstream`: `compy.input`/`keys_pressed`/`combo_string` absent pre-feature; `singleclick`/
`project_open` present; the `highlight.hl` fix in-feature). Hence `input_routing_spec` is new to
the repo yet **untagged**, while the pre-existing `user_input_model_spec` carries one feature-new
group. Rule + table: the S21 amendment in `S20-version-tag-migration-key.md`. Per-group and
per-test tags are written down as **prohibited**.

**2. A coverage marker found a real bug (`5ad2ce2`).** RVW-024 asked for a
`[lua || text] x [highlighter absent || returning nil]` matrix. The missing square was the failing
one: `1a2a9a3` taught the **parser** branch of `UserInputModel:highlight()` the `hl or {}`
invariant and left the **non-parser** branch building `{ hl = ev.highlighter(text) }`. Reachable
from the public API — the project widget is parser-less (`main.lua:374`, `InputEvalText`) and
`show({ highlighter = f })` assigns `f` straight onto that evaluator — so a highlighter returning
nil for some input (one that returns nothing for empty text is natural) produced `{ hl = nil }`.
Nothing crashed only because the *same* commit added a second guard in the view; that guard was
carrying the whole load while the model's contract went unmet. Breaking test first (failed with
the original `attempt to index local 'hl'`), one-line fix, own commit.

## Non-obvious points for a successor

- **Verify markers against the tree before acting on the plan.** B-F found **two** (RVW-048/051)
  whose `describe` wraps already existed — the plan's RESTRUCT recommendation was stale. B-COV
  then found **five more** (044/053/055/065/070) already answered by B-F's own new tests. A stale
  recommendation looks exactly like a live one.
- **Green is not proof a test bites.** Every test added this session that asserts new behaviour
  was negative-checked (flip an assertion, confirm exactly one failure, restore).
- **A comment can rot into a false claim.** The highlight test's rationale said it replicated "the
  view's access with NO `hl and` guard" — true before `1a2a9a3`, false after. That stale sentence
  was the thread that led to the bug.
- **A bare cross-branch symbol grep proves word presence, not API availability.** I stated the
  legacy-globals evidence backwards on that basis (`332eabb`); the globals live in the *baseline*
  and are gone in HEAD, which is what makes them *removed in*. Check where the hits land.
- **New standing rule (owner, 2026-07-29):** commit at the natural seam, one concern per commit, a
  production fix never rides along with the work that surfaced it, a batch is not a commit unit —
  `agents/validation.md`. No granularity rule existed anywhere before (format rules did).
- **Deviation to rule on:** RVW-020 was KEPT-for-TF2, but its subject (`view_access_ok`) ceased to
  exist when RVW-021/022 replaced the helper's semantics; renamed `assert_indexable_hl`, marker
  dropped as a consequence. Recorded RESOLVED-early; restorable if the owner wanted that name in
  front of them.
- **Two pendings now carry accurate reasons.** The editor-pointer cell is **config-gated off** in
  production (`cfg.editor.mouse_enabled = false`), not "unobservable" as previously written; the
  search cell is the one genuinely **un-designed** cell, where a test would invent the contract it
  verifies. Both remain `pending` deliberately — the 4-pending baseline is intact.
- Housekeeping done in the wrap: the stale **815/0/0/4** baseline in `agents/validation.md` and
  `validation/plan.md` (real: 854) corrected — flagged at boot, fixed at wrap.

## Where the successor resumes

The mop-up is **CLOSED**; `tests/` is swept. `src/` markers (RVW-115..138) stay parked pending the
owner's confirmation. The next move is **TF2**, and the owner set a precondition for it — see
`session22/prompt.md`: before any review, ask whether anything accumulated for the collapsed
sitting can be **ruled up-front**, so the code review happens once rather than twice.
