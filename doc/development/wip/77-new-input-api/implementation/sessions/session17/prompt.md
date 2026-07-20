# session17 — prompt

Read and strictly respect `agents/sessions.md`. You're working inside
`agents/validation.md`'s flow. Read `../../../validation/plan.md`, particularly the
2026-07-20 revision block and the new **Phase R** section it inserted.

Your predecessor (session16, run with **Fable** in the main seat by owner direction —
see below) completed the **redesign pressure-test, three rounds of owner iteration,
and R1–R3** (delta-design, delta-spec, owner confirm-gate — both documents
**APPROVED**). Read `../session16/report.md` for the full account; don't re-derive it.

## Process note — why session16 deviates from your default table, and why session17
## reverts to normal

`agents/sessions.md` §5's table would normally send a cognitive-heavy predecessor
into a **revalidation** successor (`rules/revalidation.md`). Session16 explicitly
overrode that (owner directive, mid-session) because the redesign judgment needed
live back-and-forth, so the owner ran Fable as the main seat instead of the usual
Opus orchestrator. **That was the deviation, not the norm.** Now that R1–R3 are
approved, this session reverts to the standard shape this framework is built around:
**you (Opus) orchestrate; Fable is available as an on-call subagent oracle**, per
`agents/validation.md`'s standing model-economy directive — *sparingly*, for
genuinely hard judgment calls, always with `model: fable` set explicitly on the
`Agent` call (the "prefer consulting in the main session over spawning" caveat in
that directive was written for a Fable-run session consulting itself; it doesn't
apply here — you are not Fable, so a Fable consult is necessarily a spawn).

**When to summon Fable this session:** a genuinely hard judgment call surfaces during
R4 execution — an ambiguity in the delta-spec that a test reveals, a design-intent
question Sonnet's mechanical work can't resolve on its own, anything where being
wrong is costly. **Not** for routine execution, mechanical fixes, or anything the
delta-spec already answers explicitly — that's Sonnet's lane. When in doubt about
whether something is "genuinely hard," it usually isn't; escalate only the real ones.

## Your task — Phase R execution (R4/R5)

Read `../../../validation/reviews/delta-design-input-api.md` (the *why*, decision-level)
and `../../../validation/reviews/delta-spec-input-api.md` (the *how* — table shapes,
signatures, ten tests-first acceptance criteria) in full; both are approved and
ready to drive execution directly. `plan.md`'s Phase R section lists R4's eight
sub-steps and R5's extraction obligations in recommended order. Start with:

1. **R4 step 1 — REVIEW-remarks reconnaissance** (Sonnet, `model: sonnet` explicit;
   tell it the `lua-lsp` MCP server exists and to `sleep 1` after any `.lua` edit
   before querying refs/diagnostics, per standing hygiene (a)). Inventory every
   `REVIEW:`/`REVIEW/` remark in `src/` (33+ counted in `src/controller/*.lua` alone
   at session16's count — re-verify, don't trust the stale number) and tag each
   resolved-by-redesign / still-open / out-of-scope against the delta-design's
   obligations. Materialize the prompt and the inventory on disk
   (`validation/prompts/`, `validation/outcomes/`), per hygiene (c).
2. Then R4 steps 2–7 in the delta-spec's own order (tier-1 removal → submit/cancel
   default-flip → `hooks[event]` unification → `callbacks`/D7 guard → console patch →
   vocabulary rename sweep), tests-first per the ten acceptance criteria, suite green
   after every unit, each unit committed per the standing per-unit discipline.
   Sequence sub-agents serially in the shared tree — do not parallelize via worktree
   isolation (hygiene (d)).
3. R5 (dispatch/widget-API extraction) can ride inside R4's units or land as its own
   Sonnet unit — either way, same suite-green-per-unit discipline.
4. Confirm Phase R's own gate (suite green, all ten ACs passing as tests, the rename
   sweep verified complete via LSP `references` — zero hits on retired terms — plus
   grep as the completeness backstop, per standing charter rule) before considering R
   done.

Once R is gated closed, **TF2 resumes** (owner-paced, interactive — never start it
unprompted) over the now-settled post-redesign suite, per `plan.md`'s reordering.
That is explicitly **not** this session's task unless the owner redirects — R4/R5
execution is.

Gate discipline unchanged: iterate until explicitly approved; do not wrap early.
