# session23 — report

**Commissioned:** revalidate session22's pre-TF2 gate work as a delta check —
C1 authority integration, J1 plain-vocabulary cleanup, the persistent contract
corpus, code/test alignment, and the TF2 navigation slices — then stop for the
human before TF2.

## Outcome

Verdict **NOT CLEAN (accept with corrections)**: 5 findings, written to
`validation/reviews/S23-revalidation-pre-TF2-gates.md`. The owner accepted every
disposition, added one new ruling, and authorized execution. All corrections are
now landed in 9 commits (`20c9e45`..`b148f4f`); suite **867 / 0 / 0 / 3**.

The through-line behind the findings: session22 made the persistent corpus
authoritative **in status** but never reconciled the layer that *points at* it.
The contract text was accurate — `SHOW_KEYS`, the submit order, and the helpers
all matched the code. What was broken was every citation of it.

| Finding | Result |
| --- | --- |
| F1 · dead contract citations | 8 non-existent section names, cited from 31 sites in 8 files; two of them re-asserted the framework-tier model Decision 6 revised retired. Rehomed (`4c42f68`). |
| F2 · wip-tree citations | 13 comment blocks in 7 tracked files (incl. 4 shipped examples) cited the deletion-gated tree; the corpus recorded this as "two comments". Rehomed, ledger corrected (`adbe98c`, `14fb73c`). |
| F3 · corpus self-resolution | `decisions/input.md` rested a withdrawn stakeholder guarantee on wip-only `design/requirements.md`; `technical_debt/input.md` cited a non-existent `overlay_spec.lua`. Both repaired without losing substance (`14fb73c`). |
| F4 · tracked swap artifact | `tests/input/.input_nfr_forward_spec.lua.swp` — untracked, `.gitignore` extended (`e3af2a1`). |
| F5 · construction markers | Residual `RESOLVED-BY-REDESIGN` / `S21/B-F` / `TF1` / `M8-03` labels removed (`adbe98c`, `14fb73c`). |

**New owner ruling, executed in-flight:** `show`/`configure` now **raise** on an
unrecognised key instead of warning and ignoring. Recorded as Decision 15
**revised**, status `in-flight`, rationale "DevX: strict contract enforcement,
explicit failure mode" (`c8c4204` + `e57a481`).

## Verification and handoff facts

- Baseline was exactly the prompt's **862 / 0 / 0 / 3**. Final is
  **867 / 0 / 0 / 3** (−1 replaced warn test, +6 new contract tests). The three
  pendings are unchanged: console key release, editor pointer, touch routing.
- Test-first held: the 5 new contract tests failed against warn-and-ignore
  before the implementation landed.
- **Two refinements the owner's ruling implied but did not state**, both now
  pinned by tests: (1) scope is **contract violations, not runtime states** —
  `show` on an active overlay and mutations while hidden still *warn*, so
  strictness cannot creep; (2) the error path was verified **first** — project
  top-level code runs under `pcall` in `run_user_code`, project `love.*`
  handlers under `xpcall` → `user_error_handler` → `suspend_run`. Raising
  surfaces as a project error, never a framework takedown.
- Precedent that made the ruling a *uniformity* fix rather than a new mode:
  `frozen_error` already raises for the sibling violation
  `compy.input.shortcuts = {}` (Decision 7 revised).
- Slices were regenerated (`550bf1e`) and are **materially better than
  session22's**: that batch's `3d-tests.patch` carried the `.swp` as a
  payload-less "Binary files … differ" hunk, so `git apply` refused the whole
  slice — session22 verified name lists but never ran `apply --check`. The
  regenerated partition came up **88 of 89** (`.gitignore` matched no pathspec);
  it was added to slice `3d` **and to `pr-assembly-guide.md`**, the re-runnable
  source of truth. Now 89/89, disjoint, all 8 apply cleanly against `BASE`.
- The guide's §3 dangler list is resolved as a side effect of F1/F2.
- **Overruled one sub-agent framing:** 23 bare `#77` citations in persistent
  docs are legitimate permanent GitHub issue references, not construction
  residue.
- Sub-agent legs (Sonnet, prompts of record under `validation/prompts/`):
  `S23-marker-corpus-sweep`, `S23-slice-partition-verify`,
  `S23-A-rehome-dead-citations` — outcomes under `validation/outcomes/`.
- **Process error, disclosed:** directory-wide staging (`git add src tests`)
  swept the owner's untracked scratch into a commit; caught after the fact,
  soft-reset and recommitted clean as `adbe98c`. In this tree, stage explicit
  paths only.

## Successor task

Session24 is a **wait-for-human placeholder**. The tree is ready for TF2, which
the owner opens from `implementation/pr-slices/`. The successor's live
expectation is **inbound TF2 review feedback**: receive it, triage it against
the standing ledgers, and act only on the human's instruction. It must not
launch TF2 or pre-empt its findings.
