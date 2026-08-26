# session47 — start executing the roadmap

Read `agents/sessions.md` and `agents/validation.md` first, then
`../session46/report.md`. **Do not re-derive session46 from its track** — the report is the
handover, and the track is long.

Then read **`doc/development/wip/77-new-input-api/ROADMAP.md`**. It is new, it is the sequence, and
it is where you find what to do next. `validation/plan.md` is the reasoning and the record; go there
for *why*, not for *what next*. The rules governing the roadmap's shape are new too:
**`agents/rules/roadmap.md`**, referenced from `AGENTS.md`.

## Where the work is

Acceptance began and produced **26 defects**, ordered in the roadmap **by blast radius** — rows that
may reveal more defects, escalate into a design decision, or reach somewhere everything runs through
come first. Six sprints stand between here and the owner's keyboard:

```
ACC-01 ✅ → { BUG-01 · FIX-01 · FIX-02 · DEC-01 · CHG-01 } → FIX-03 → ACC-02 → REC-01 → MERGE-01 → PR-01
```

Baseline: **968 / 0 / 0 / 10**. A different count is a finding, not a go-signal.

## Your task — execute, starting at the top of the order

**This is an execution session** — the first in a while. Session46 was planning and judgment
throughout; the roadmap it produced is the mandate.

The workflow's default successor for a cognitive-heavy session is a revalidation
(`agents/rules/revalidation.md`). **The owner directed execution instead** (2026-08-26), so this
prompt commissions that — but the revalidation instinct is not discarded, it is **folded into the
first move**, which is also this phase's most-repeated lesson:

> **Verify before acting.** Session44's lesson, session45's, and session46's again: a handover's
> claims are a strong hint, not a fact. Several rows below are marked *"reviewer only"* — nobody has
> confirmed them in code. Confirm a row before you fix it, and if it turns out not to be a defect,
> **say so and close it** rather than fixing something that is not broken.

### Start here

**`BUG-01-01` — `state.pending` survives a project stop.** Leads because its blast radius is
*unknown*: reachability is untraced, `shortcuts`/`hooks`/`callbacks` may share the hole, and the
debt-ledger entry covering it rests on a premise the call graph contradicts. It ships with a test —
the `stop teardown` block checks handlers, hooks, visibility and callbacks, but not `pending`.

Then work down the order. Two rows carry a standing coupling: **`BUG-01-03` (turtle) fixes with
`FIX-02-11`** (the guide gap it is a symptom of), and **turtle may have siblings among the other
migrated examples** — check them, do not fix only turtle.

### Three rows need the owner, not you

- **`BUG-01-02`** (highlighter) — a design call: sentinel vs a new `clear_highlighter` member.
  Present the trade, do not pick.
- **`FIX-02-01`** (`on_text_entered` / `after_submit` are two ways to set one callback) — a
  public-surface question the owner raised twice. Same: present, do not decide.
- **`FIX-02-02`** (`tixy` may drop its legend on submit) — **verify against base `3256aac` first**.
  If it is a real change to pre-feature behaviour, it is ratify-or-revert, and that is the owner's.

## Standing cautions, earned this session

- **`| head` on a counting grep lies.** It undercounted the same defect twice — 10, then 14, when
  the answer was 37. So does `grep -h` piped to a path filter: with no path in the output, the
  filter matches nothing and silently passes everything.
- **Never `git add <directory>`.** Name files. The reassembly guide still says `git add -A` in one
  place; do not follow it there.
- **`agents/validation.md`'s marker gate covers `src/` and `tests/` only.** It does not reach `doc/`
  or the repo root, which is how 37 remarks survived a gate reported clean.
- **The example repos are separate repositories** with their own remotes and their own PRs. Commit
  in them as the work demands; **never push** any of them, or the platform.
