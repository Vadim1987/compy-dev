# Post-R replan hypothesis — for the next validation session to verify, not adopt on faith

**Status: NOT a ruling, NOT executed, NOT git-committed — a hypothesis on disk for a fresh
session to check against then-current reality.** Written 2026-07-20, while Phase R (session17,
Opus) was actively executing R4 (regrouped as units U1-U4 per
`R4-execution-decomposition.md`) — no code or spec was touched to produce this note; it is
pure analysis of already-existing, already-cited project documents.

**How to use this note.** Do not treat any claim below as settled. Re-derive the facts (LSP +
grep, per standing hygiene) against the tree as it exists when you read this — R4/R5 may have
surfaced something new during execution that isn't reflected here. If the facts still hold,
this note is a shortcut to a re-scoped Phase B–G. If they don't, discard it and run the plan
as written.

## The hypothesis

`plan.md`'s Phase B (convergence check) + Phase C (principle sheet + disposition table) +
Phase D (owner ruling sitting) exist to catch **two kinds of gap**: (a) known deviations
between shipped code and the design/spec corpus, and (b) design decisions that served
construction but now reduce clarity ("scaffolding-suspects"). The hypothesis is that **once
Phase R lands and gates closed, both categories are already fully enumerated** — B/C/D would
not discover new members, only formalize a set that is already on record — which means the
three phases can collapse to a short disposition-and-ruling pass over a known, short list
rather than running as designed (a ≲8-question owner sitting plus a full disposition table
merge).

**What would falsify this:** any new deviation or scaffolding-suspect surfacing during R4/R5
execution, in the final suite/LSP verification, or in a fresh read of the Pass-2 sheet that
isn't accounted for below. Check for that first.

## The known-deviations leg (category a) — already enumerated, not hypothetical

Source: `implementation/reviews/pass2-consolidated-ruling-sheet.md` rows R2/R4/R5/C1, each
independently confirmed with code citations in `reviews/owner-rulings-verified.md` (rulings
2, 4, 5). As of this writing none carry a final disposition (checkboxes unticked).

| Item | Finding (verified in code) | Disposition proposed here (unruled) |
|---|---|---|
| **R2** — `eval`/`result` config keys | `apply_config` (`userInputController.lua:212`, `:223`) accepts `cfg.eval`/`cfg.result`; shipped examples (`tixy`, `valid`, `guess`) already pass `eval=`. Neither key is in `design/spec.md` §3's config table. | Bless as public API: one row added to `doc/input_api.md`'s config table + one line in the PR's deviation table. No code change — the behavior already exists and examples depend on it. |
| **R4** — `multiline` flag | `design/spec.md` §3 lists a `multiline` config key; `userInputModel.lua:499` carries `-- TODO multiline`; no code path reads any such key; Shift+Enter newline is unconditional. Promised in spec, never implemented. | Strike the row from `design/spec.md`'s promotion target / `doc/input_api.md` (doc-only). Implementing it would be new scope, not a gap-closure — route to a separate backlog item if still wanted. |
| **R5** — silent config-key drop | `apply_config` has no `else`/warn branch for unrecognized keys in `show{}`. The same file family already has the opposite convention: `set_cursor`/`set_text` both call `Log.warn(... ignored — hidden)` (`consoleController.lua:495`, `:505`). | Add the matching `Log.warn` call to `apply_config` for consistency with the existing pattern. The one item on this list that is a real (small, mechanical) code change. |
| **C1** — `design/spec.md` disposition | Two of the three drifts above are spec-vs-code contradictions; `spec.md` predates the ratified/re-cut model (2026-07-06/07). | Archive `design/spec.md` as design-time history (already project convention — `design/` is frozen); `doc/input_api.md` is the one live surface stakeholders are pointed to. |

If a fresh read confirms these four rows are still the complete list (no additions from R4/R5
execution), then Phase C's "principle sheet" for this cluster degenerates to these four rows,
and Phase D's sitting is a short confirm-or-amend pass over four proposed dispositions — not
the ≲8-question, full-corpus exercise the plan was written for.

## The scaffolding-suspect leg (category b) — claim: R already absorbed the heaviest member

Phase B's third bucket is "design decisions that served construction but now reduce clarity/
stability." The input-API redesign ratified in `reviews/delta-design-input-api.md` and
`reviews/delta-spec-input-api.md` (session16, R1/R2) targeted exactly that: an asymmetric,
hard-to-review dispatch shape, a consumption-signal overload, vocabulary drift (`handlers`
colliding with `love.handlers`), and a promised-but-never-delivered shared `dispatch()`. If R4/
R5 land as specified, the single heaviest scaffolding-suspect this feature has produced is
already dispositioned and executed, not merely flagged for a future owner sitting.

**What's explicitly NOT covered by R and would still need Phase B/C/D's normal treatment if
found:** jargon outside R's scope (`overlay`, `callback slots`, tier-N prose — `plan.md`'s
"Owner decisions already made" #1), any scaffolding-suspect unrelated to the dispatch/vocab
cluster, and anything Phase A's spec-reference sweep flagged as "no persistent home" (rolled
to Phase C evidence, not yet reviewed here).

## Background rationale (generic, project-level — not a status report)

- **Feature importance.** `design/requirements.md` documents concrete, real limitations of the
  prior polling API (no events while a prompt is shown, can't hide/show without teardown,
  hotkeys/dynamic prompts/text-adventure patterns "awkward or impossible") for the actual
  target users. This is a genuine, stakeholder-sourced need, not internally-generated scope.
- **Genuine complexity, not just process overhead.** The input subsystem sits at the
  intersection of several organically-grown layers (the `love.handlers` gateway pre-tap,
  per-mode controllers — project/console/editor — and the shared widget model) that predate
  this feature. Some of what surfaced during validation reflects real inherited structure, not
  avoidable planning failure.
- **Pivot 1 (mid-implementation, ~2026-07-03–07).** A design corpus that had never been
  formally ratified (`Approved by human?: NOT YET` on every governing file) was nonetheless
  bound "strictly" during implementation; a review pass (`reviews/m4-architect-pushback.md`)
  found the resulting drift was real but traced to that process gap, not to semantic errors —
  resolved by re-deriving the corpus from a ratified model and re-cutting the milestone set
  (Gate 3 closed 2026-07-07, `design/roadmap.md`).
- **Pivot 2 (post-implementation, ~mid-July).** The shipped API shape had been accepted
  earlier as a deliberate scope tradeoff ("stop theorizing, start building") — asymmetric and
  hard to review, but functionally complete and green by 2026-07-12 (`#77 new-input-API sweep
  COMPLETE`). Closer PR-readiness review surfaced that the tradeoff needed paying down before
  the PR could be reviewed from documentation alone — this is Phase R's origin.
- **General principle for re-scoping gates:** a multi-phase gate structure is worth its
  overhead while genuine unknowns remain; once a category of gap is fully enumerated (as
  category (a) above claims to be) or already substantively resolved by other work (as
  category (b) claims for the dispatch/vocab cluster), running the full gate again re-derives
  a conclusion rather than reaching a new one. That is the condition worth checking before
  deciding whether to run Phase B–D as originally scoped or as the shortcut this note proposes.

## What a fresh session should actually do with this

1. Confirm Phase R's own gate closed as specified (suite green, ten ACs pass, rename sweep
   LSP-zero, REVIEW-inventory resolved items gone) — do not take this note's word for it.
2. Re-grep/re-check the four rows above against the post-R tree; confirm no new deviation or
   scaffolding-suspect emerged during R4/R5 that isn't listed here.
3. Re-read `plan.md` Phase A's "no persistent home" inventory and Phase TF3's leftover triage
   list — those are the two places a fifth item could legitimately be hiding.
4. If 1-3 hold: propose to the owner a collapsed B→C→D pass scoped to the four rows above
   (each with a proposed disposition already drafted here) plus the explicitly-excluded jargon
   cluster, rather than the full plan as written. Record whatever the owner actually rules —
   this note's proposed dispositions are drafts, not pre-approved.
5. If 1-3 don't hold: this note's premise is wrong for the current state; run Phase B/C/D as
   `plan.md` specifies and note why the shortcut didn't apply.
