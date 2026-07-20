# S16 plan revision — finishing TF2, phasing the redesign (DRAFT, pending owner gate)

_Fable, session16, 2026-07-20. Companion to the pressure-test verdict
(`../outcomes/S16-fable-redesign-pressure-test.md`, referenced as F1–F7 below).
Status: **proposal** — plan.md is amended only after the owner ratifies; phase
letters stay untouched (labels are load-bearing across frozen prompts/tracks)._

## 1. TF2 — finish against the current implementation, unchanged in method

TF2 (owner human review of the split suite) continues exactly as mandated: against
the **shipped** form, redesign not smuggled in (the S15 separation ruling stands —
review of what is built must not be contaminated by proposals to change it).
Remaining surface: the owner's pass was mid-flight in `input_nfr_forward_spec`
(open `.swp` at the TF2-wip commit); the other five split files carry notes already.

One mechanical addition for note-taking (no method change): where a TF2 remark is
*about* something the redesign would abolish (a `sink`/`singleton` term, the
framework tier, `on_*` field shape), tagging it `{redesign}` inline keeps TF3 cheap.

## 2. TF3 — triage gains ONE new bucket

TF3 stays hint-scoped as planned (mechanical fixes land; judgment pools with A2's
standing fixture questions). Amendment: a fourth disposition bucket —

> **absorbed-by-redesign** — the hint is real but its fix is subsumed by a redesign
> item; park it against the delta-spec instead of patching twice.

Guard on the bucket: it may only absorb hints that map to a *named* proposal/verdict
item (F1–F7 or a proposal § — cite which); anything else is triaged normally. This is
the anti-smuggling valve: without it, TF3 would either double-fix (churn) or
hand-wave ("the redesign will handle it" with no receipt).

Test-quality themes 2/3/7 from the evaluation (internals-poking tests, symmetry gaps,
stale bucket labels) proceed **regardless** of the redesign decision — they are about
the suite, not the API shape.

## 3. The redesign — in-scope pre-PR, executed through the EXISTING phase machinery

**Recommendation: do it before the PR, not as a fast-follow.** Grounds: the
stakeholder ask *is* "simpler and more robust input API"; shipping names and tiers we
already assess as scaffolding contradicts the ask and freezes them into the 1.0
public surface (the PR's justification table would have to defend `sink`/`singleton`/
tier-1 rows we intend to delete). This is also the cheapest moment ever: tests just
split+nested, examples migrated, zero external adopters (evaluation §B). The cost —
PR delay of roughly one delta-spec + one bounded execution pass — buys a strictly
smaller, more defensible PR.

No new phases; the plan absorbs it:

| plan slot | redesign content |
|---|---|
| **Phase B** (convergence check) | records the redesign as THE scaffolding-suspect cluster, citing proposal + verdict — B does not re-derive it |
| **pre-D artifact** | **delta-spec authored** as an addendum to `decisions/input.md` (frozen `design/` untouched), carrying the five F-obligations: F2 reading (i) + gateway retention, F1 layering precisions, F3(a) consumption rule, F4 named ruling, F5 seed choice + F6 frozen-set/callbacks membership |
| **Phase C** | principle sheet gains the redesign principles (F4 trade; F5 choice; F6 membership); disposition table maps the absorbed TF2/TF3 hints + the affected Pass-2 rows to them |
| **Phase D** (owner sitting) | ratifies the delta-spec one principle at a time — the anti-rubber-stamp contract applies to our own proposal too |
| **Phase E** (execution) | the reshape runs as the FIRST E-units, tests-first, in this order: **(E-r1)** widget-default Enter/Esc via UIC `submit()`/`cancel()` + chain-step shownness consumption (F1+F3; breaking test = the Escape clear-AND-hide regression + the Ctrl+Q escape-hatch test) → **(E-r2)** `hooks[event]` unification per F5 choice → **(E-r3)** `callbacks` table + D7 guard simplification (F6; guard change LAST, after the leaves exist) → **(E-r4)** rename/prose sweep (widget/hook/callback vocabulary; LSP + grep backstop, complete or not at all — F7) |
| **Phase F/G** | unchanged; slice regeneration stays LAST |

Jargon postponement (owner decision 1 in plan.md) is **unaffected in letter,
resolved in practice**: the vocabulary ruling lands at the same Phase-D sitting,
once, exactly as decision 1 required — the redesign supplies the taxonomy it was
waiting for.

## 4. Sequence from here (the concrete next steps)

1. **S16 (this session):** owner ⇄ Fable iterate on the pressure-test verdict; the
   five obligations are either accepted, amended, or struck — recorded in this file
   as they resolve.
2. **TF2 finish** (owner-paced, interactive) + **TF3 triage** with the
   absorbed-by-redesign bucket.
3. **Phase B** convergence check (consumes DI1 + the redesign disposition).
4. **Delta-spec authoring** (drafted by the orchestrator tier, Fable-reviewed —
   consult-in-main-session, not a spawn).
5. **Phase D sitting** → **Phase E** with E-r1..E-r4 first, then the already-planned
   E order (ruling-driven changes → simplifications → `internals/user_input.md`
   rewrite → doc incorporation → ledger sweeps).

## 5. What this revision does NOT change

- DI phase outcomes, guardrails 1–3, the suite-baseline discipline (815/0/0/4).
- The Pass-2-sheet disposition contract (every row still lands in the C-table).
- Phase letters, artifact locations, sub-agent hygiene, model economy.
- The frozen status of `design/` and the ratified-glossary owner-gate.

## Owner rulings pending (the gate for this document)

- [ ] TF2/TF3 amendments (§1–§2) — accept / amend
- [ ] Redesign in-scope pre-PR vs fast-follow (§3 header call)
- [ ] The five delta-spec obligations (F-summary) — accept as the delta-spec skeleton
- [ ] E-r1..E-r4 ordering — accept / reorder
