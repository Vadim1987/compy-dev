# Commission — cold revalidation of session66's own work

**Spawned 2026-09-02 by session66, at the owner's instruction**, after session66 had itself
revalidated session65. The work below was produced by **one reader and reviewed by nobody** — the
same condition that earned session65 its revalidation. The owner's framing: *"is any of your own
work worth cold revalidation? If so, run an agent to do it, then apply corrections in place so the
next session won't deviate from the primary mission."*

**Model:** Opus (judgment; the Fable oracle tier is retired). **Cold** — the reviewer has none of
session66's reasoning, which is the point.

---

## Your task

Revalidate **session66's own output** at the delivery level (`agents/rules/revalidation.md`): did
the outcome match the need, was anything overlooked, was anything unnecessary delivered. Five
subjects, below, and **no more**.

You are read-only over the repo except for **one deliverable file** (path at the end). Change no
code, no doc, no ledger. Report; session66 applies corrections.

### Read first

- `agents/validation.md` (the phase), `agents/rules/roadmap.md`, `agents/rules/ledgers.md`
- `doc/development/wip/77-new-input-api/ROADMAP.md` — the sequence and the `FIX-02` section
- Session66's findings: `validation/reviews/S66-session65-delivery-revalidation.md`
- Session66's handover: `implementation/sessions/session66/report.md`,
  `implementation/sessions/session67/prompt.md`
- Its eleven commits: `git log --oneline 9dfd2c3d..HEAD`, and `git show <sha>` as needed

### Subject 1 — the nine findings: are any wrong, overstated, or phantom?

`agents/validation.md`'s replanning checklist names the categories that matter here: **phantom
problems** (a problem in the analysis but not in the code), **self-inflicted constraints**, and
**unratified terminology**. Session65 had two findings refuted at their premise; assume the same
rate is possible here.

**Resolve each finding against the file it names**, not against the report's description of it. The
two worth the most attention:

- **F4** claims session65's replan reversed **two dated owner rulings without citing them**. Verify
  both existed and said what F4 says: `validation/plan.md`'s *"Why ACC runs before U, not after"*
  and the old `ACC-02-01`'s *"before the owner touches a keyboard"*. Check `git show 5f97485b`
  (the replan) for whether either was in fact cited. **If F4's premise is wrong, two owner rulings
  were collected on a false report** — that is the most expensive possible error in this session.
- **F3** claims five citations came to resolve to the **wrong** step after the acceptance renumber.
  Verify the old→new mapping from `ROADMAP.md`'s crosswalk and confirm each cited site really did
  point at a different pass, rather than merely at a renamed one.

### Subject 2 — the corrections as applied

`4ebc9dff` (crosswalk row + count), `aeab2a78` (`ledgers.md` §6), `cdf28968` (the test comment),
`58de1cf7` (the `T-NEVER-SHIPPED` provenance ruling). For each: **does the new text state something
true**, and does it contradict anything that already stood? `aeab2a78` rewrote a paragraph in a
**rule file that governs all future ledger work** — read the whole of `ledgers.md` and say whether
§6 now agrees with §2 and §3.

### Subject 3 — the deletion, which is the most destructive thing session66 did

`b365a42e` **deleted** `validation/plan.md`'s `ACC-02` row table rather than renumbering it, on
session66's own judgement that a duplicated schedule is `roadmap.md` §1's second-timeline failure.
The owner did not rule on this.

**Check for loss, concretely:** `git show b365a42e -- .../validation/plan.md` gives the deleted
rows. Does `ROADMAP.md`'s `ACC-02` + `ACC-03` carry **everything** they said — every step, and every
qualifier attached to it? Name anything that existed only in the deleted table. Also say whether the
deletion was **necessary** or whether renumbering would have served (over-delivery is a finding).

### Subject 4 — the `FIX-02` (a)/(b) assignment — the highest-consequence judgement

The owner ruled the *principle*: run the editorial rows whose prose a smoke pass reads **before**
`REC-01`/`MERGE-01`/`ACC-02`, because *"incorrect prose could confuse"* troubleshooting. **Session66
assigned the rows.** (a) = `-03 -04 -06 -17 -22 -23 -24 -25` + the `smoke_checklists.md` slice of
`-09`; (b) = `-05 -07 -08 -09 -10 -13 -14 -15 -16 -18 -19 -20`.

**Read each of the twenty open rows in `ROADMAP.md`'s `FIX-02` table — the full cell, not the
summary — and judge its half against two tests:**

1. **Could this row's defect mislead a device pass, or produce code work?** If yes it belongs in (a).
   Session66 made these calls partly from one-line summaries; a row whose own notes reveal more is
   exactly what this check is for.
2. **Could this row's work be invalidated by `MERGE-01`?** Its remaining scope touching `keyboard`
   or `maze` puts it in (b), or it gets swept twice.

Name every row you would move, with the sentence in its cell that decides it. **A row in the wrong
half defeats the ruling it implements** — that is the whole value of this subject.

Also check the two supporting claims: that the `smoke_checklists.md` slice of `-09` is safe to take
early because no remaining merge touches that file, and that `-25` belongs early because its test
can surface a behavioural defect.

### Subject 5 — the handover: would a fresh session deviate?

Read `session67/prompt.md` **as if you were booting on it**, with only `agents/*` and the repo.

- Does it state the current position **accurately** — sequence, what is done, what is next?
- Does anything in it point at a file, section, id or count that does not resolve? **Resolve the
  citations**, do not scan them.
- Would following it lead a session **away** from the roadmap — into re-analysis, into re-verifying
  the feature (`agents/validation.md` guardrail 1), or into re-doing work already done?
- Is anything the successor needs **missing**: an owner ruling from 2026-09-02 not carried, a
  constraint that only lives in session66's report, a trap it will walk into?

---

## Method constraints — these are not optional

- **Do not re-verify the feature** (`agents/validation.md`, hard guardrail 1). Do not re-check
  session65's 554 citation substitutions or its 68 reflowed comment blocks: both are proven by
  construction and re-deriving them is the recursion that guardrail exists to stop.
- **A line citation is verified by resolving the exact line, or not at all.**
- **An errored or unsupported query is not an empty result.** `mawk` here does not support `\<`/`\>`
  word boundaries — a sweep using them returns nothing and looks clean. This has produced a false
  "clean" result twice in this phase.
- **`lua-lsp` MCP server is available** — defs / refs / diagnostics / rename over a real AST of the
  `/repo` workspace. Use it for any Lua symbol question rather than inferring from grep; grep to
  find candidates, LSP to resolve them. `sleep 1` after any `.lua` edit before querying. **A
  `broken pipe` error means the language server is dead while `/mcp` still reports connected — that
  is an outage, not an empty result. Surface it; do not work around it silently.** You will likely
  not need it: this is a documents-and-judgement pass.
- **The suite is 1048 / 0 / 0 / 10** (`busted tests`, LuaJIT 2.1 in this container; the owner runs
  PUC Lua). You are not changing code, so you should not need to run it.
- **Verify every factual claim in the file it comes from.** Session66's report is a *claim*, not
  evidence, and so is this commission.

## Deliverable

Write to **`doc/development/wip/77-new-input-api/validation/outcomes/S66-cold-revalidation.md`**,
and write nothing else.

Structure it as: a one-paragraph verdict; then one section per subject; then a **findings table**
ranked by consequence, each row naming the file and line, what is wrong, and the correction you
would make. **Say plainly where session66 was right** — a revalidation that only lists complaints is
not calibrated, and "clean" is a result. If a finding of session66's is a phantom, say so and show
the evidence that kills it.
