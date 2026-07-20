# Input-API redesign — evaluation + resurfacing tensions (orchestrator, S15)

Companion to [`input-api-redesign-proposal.md`](input-api-redesign-proposal.md). My (Opus
orchestrator) architect assessment, plus the catalogue of tensions/contradictions the TF2
review notes surfaced — the *evidence* the proposal claims to dissolve. Written as input for
the next-session **Fable** analysis; Fable boots cold, so this is self-contained. Grounded in
`decisions/input.md` and a read of `src/controller/projectInputController.lua` (the live
4-tier chain) — not doc-only.

---

## A. The resurfacing tensions (harvested from the inline TF2 notes)

The owner's sense that "the same tensions keep resurfacing" is borne out — the notes cluster
into seven recurring themes, not scattered nitpicks:

1. **Terminology collisions.** `sink`/`widget`/`singleton` name one thing three ways; "consumer"
   is used for *both* a route (controller) and a sink (last chain element); `tier-3` /
   `generic callback` / `native` are opaque jargon; `on_text_entered` vs `on_text_input` is the
   costly confusion Decision 5 itself concedes; `proxy` names a mechanism, not a contract.
2. **Behaviour-vs-internals testing smell.** Many rows poke `singleton` internals or combo-table
   internals instead of the observable `compy.input` surface. The owner repeatedly asks: is this
   test-specific patching masquerading as configuration? Suggests a `F.mock_widget(...)` helper
   to make boundary-patching *explicit* where it's genuinely needed.
3. **Symmetry / coverage gaps.** Tests exercise `keypressed` but not `keyreleased`/`textinput`;
   `on_text_input` but not `on_key_pressed`; missing symmetric cases ("truthy hook return
   prevents reaching widget", "*missing* handler doesn't block hook", "missing hook doesn't
   block widget"); held-keys *content* vs *delivery* split across distant rows.
4. **API-shape question.** `.on_*` fields vs a `hooks[event]` table — the pivot's structural core.
5. **Framework-tier questioning.** "native" is misleading; is `activate_project` installing hooks
   via the legacy `love.*` path, and does that *mask* the explicit-hook path from the suite?
6. **Immutable-boundary friction.** The strict per-field write-prohibition (Decision 7) reads as
   heavy; owner now prefers "freeze the container, keys stay writable."
7. **Bucket/label staleness.** A/B/C/D buckets and "forward"/"provisional"/"expected to change"
   prose are outdated now the feature is implemented; "expected to change" actually names
   *de-facto standard* behaviour (a candidate to cite from decision docs, not a volatile group).

Themes 1, 4, 5, 6 are exactly what the proposal targets. Themes 2, 3, 7 are **test-quality**
work that is largely independent of whether the redesign happens — worth separating, because
they should proceed regardless.

---

## B. Assessment

**On the vocabulary (proposal §1) — do it, unconditionally, and now.** Highest value-per-risk
item on the table. The public surface carries the names (`compy.input.on_*` → `hooks[...]`),
so they leak into every example and doc and freeze at 1.0 — cheapest to fix before external
adopters exist. Even if the chain structure were left at four tiers, tightening the words pays
for itself. The one non-trivial piece: `hooks[event]` *table* vs three `on_*` *fields* is an
API-shape change (touches Decision 7's enumerated boundary), but it's a strictly better shape
(symmetric with `handlers[event]`) and bounded.

**On the structure (proposal §2–§4) — genuinely better; reopens three ratified decisions, so
treat it as a deliberate, scoped, tests-first move.** The strong parts:
- **Non-consumption-when-hidden as the propagation engine** is the best idea here. It generalises
  D1 (route-centric) + D11 (connect-while-running) into one uniform bubble-to-parent story and
  *dissolves* the reserved-keys special case rather than relocating it.
- It **preserves Decision 5's two-directions insight** while shedding the tier-1/tier-4 asymmetry
  — the right kind of refinement (keep the load-bearing idea, drop the scaffolding).
- The **Decision-6 trap is resolved, not regressed** — *provided* "widget owns Enter/Esc" means
  the **UIC (controller)** owns detect-and-propagate while the parent context owns lifecycle
  (owner's §4 clarification: widget detects + does its job + communicates the event; context can
  capture text in `before_cancel` and restore, show/hide). This hinges entirely on that layering
  staying precise — the notes themselves show the wobble (`sink → widget hook, widget?`). Fable
  should pressure-test exactly this seam.

**Risks / watch-items for Fable:**
- **Layering discipline (D6).** If "widget" blurs from controller to model, the old
  dismiss-limitation returns. This is the single highest-stakes correctness question.
- **Call-order semantics (D6).** Moving submit/cancel into a `callbacks` table must keep
  order-by-position (not consume-by-return); don't let the table shape re-import a return-value
  convention.
- **Precedence collision (D10 unify).** Folding explicit hooks and sandboxed-love seeds into one
  `hooks[event]` slot needs the precedence spelled out (explicit > seed > no-op) and the
  "read native once at activation" rule preserved.
- **Loosened guard (D7).** "Freeze container, keys writable" must still forbid swapping a whole
  sub-table (`handlers = {}`) or the tamper-resistance Decision 7 bought is lost — clarify the
  exact frozen set.
- **Scope & phase.** This exceeds the validation mandate (`plan.md` = validation-*for-delivery*).
  It maps cleanly onto Phase B's **scaffolding-suspect** bucket and Phase C's **design-tweak
  proposals**, so the process has a home for it — but it must be a *conscious* scope decision,
  not comment-sprawl seeping into code. Cheapest-ever moment (tests just split+nested, examples
  migrated, zero external adopters), which argues *for* doing it pre-1.0 — as its own framed step.

**Recommendation.** Yes to redesign-before-delivery: (A) vocabulary with no reservations; (B)
structure as a bounded design-refinement pass, gated on the owner's explicit go, driven by a
delta-spec first (an addendum to `decisions/input.md`; frozen `design/` untouched), then a
breaking test, then the reshape. Keep test-quality themes (2, 3, 7) on a parallel track — they
land regardless of the B decision.

---

## C. Process disposition (owner ruling, S15)

- **TF1** — complete (see session15 report).
- **TF2** — in progress; must still be completed against the **current** implementation. The
  *plan after* TF2 may change in light of these ideas.
- **This redesign** — a side-product feeding **Phase B**. Not smuggled into TF2.
- **Next session (S16)** — preliminary analysis + plan review, led by **Fable**: pressure-test
  the proposal (esp. the D6 layering seam), and re-shape the post-TF2 plan if the pivot is
  adopted. This supersedes the sessions.md default successor table for S16, by owner direction.
