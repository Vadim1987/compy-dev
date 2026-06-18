# Two-tier test strategy for #77

_Materialised from a chat discussion (2026-06-18, session 12). Human raised the per-milestone
test-coverage question; agent analysed; human corrected a mis-framing carried from
[`m3-revival-tdd-for-m4.md`](m3-revival-tdd-for-m4.md). **Decisions settled** (human, this session);
propagation deferred to an ops entrypoint._

## The question

Build-time continuity is in force; M4 and M6 are the cross-layer risk milestones. Every milestone
seems to want test coverage "upfront." Does each milestone get its own pre-net (M4-0, M5-0, M6-0)?
Specs or just prompts? Author all at once, or one-by-one as implementation progresses?

## Correction — "tests can't precede the implementation" is wrong

The revival note claimed: _"writing failing tests for the new controller before the controller
exists doesn't work — there's no interface to test against."_ **That conflates *no code* with *no
testable contract*.** For the new API surface the contract exists **as the frozen `MN.md` spec**
before any code: `compy.input.handlers['ctrl+s'] = fn`, truthy-return stops the sink, the six named
before/after hooks, `on_limit_reached(direction, scope)`, `configure/clear/get_cursor/set_cursor/
set_text`. Tests written against that spec fail **red** for lack of implementation and go **green**
once it exists *and behaves as specified*. That is textbook TDD, and the red suite is the
machine-checkable guardrail the implementation step must satisfy.

The earlier claim only holds for an **unspecified** interface. Ours is specified — so forward
acceptance tests **should** be written test-first. (This portion of the revival note is superseded;
see the pointer added there.)

## The durable distinction — two tiers, by oracle source

Both tiers are written **upfront**. They differ in *where the oracle comes from*.

### Tier 1 — `M4-0`, the feature-global safety net (characterization)

- **Oracle = current runtime behaviour.** It pins the **existing, organically-grown** input-path
  behaviour that has **no spec** — so it must be captured against the running code *before* M4
  touches the path. This is the renamed M3-revival.
- **Coverage (feature-global, not M4-only):** the example input flows (tixy `input_code`, balloons
  `input_text`, turtle `input_text` + Esc, editor REPL), **plus** the editor's `is_at_limit`
  vertical block-navigation that **M6** rewrites (roadmap M6 risk), **plus** D-9 native coexistence
  (e.g. `pong`'s `love.keypressed` still reaches the project after M4). Drawing the scope this wide
  now is safe — those paths aren't touched until their milestone — and it means **one** net, not a
  per-milestone proliferation.
- **Lifecycle:** written once before M4; **protects M4–M7** (those milestones preserve observable
  behaviour by contract); **evolves at M8** (legacy globals removed, examples migrated).
- **Own spec-design cycle.** The real work is the open **infra-feasibility question**: can the
  busted harness (`mock.keystroke`, `EditorSession`) be extended to drive a *project-level* input
  flow? A bare "generate tests" prompt would hit that wall and **stub** it — which is exactly the
  "overlay test vs. stub" debt that motivated this whole thread. So M4-0 needs a real spec, not just
  a prompt.

### Tier 2 — per-milestone acceptance tests (test-first, against the spec)

- **Oracle = the frozen `MN.md` spec.** For each milestone that introduces **new** behaviour
  (M5 dispatch, M6 hooks/boundary, M7 API), the execution plane runs a **test step that precedes
  the implementation step**: author acceptance tests from the spec → they fail red → implementation
  turns them green.
- **Rationale (human):** the test step runs on a **cheaper model** (it translates a fixed spec into
  assertions — little open-ended reasoning), produces a **smaller diff**, and the resulting red
  tests are a **hard guardrail** that constrains the subsequent implementation step.

## Why one-by-one (not all-at-once)

- Tier 1 is a **single** artifact — there is no "all at once" to decide; it is authored once before
  M4.
- Tier 2 tests are sourced from each milestone's spec and run **just before that milestone's
  implementation**. Authoring them earlier buys nothing and risks drifting from the code state they
  will run against. Only the **map** (which milestones split, what M4-0 covers) is drawn upfront;
  contents are authored just-in-time.

## Conventions established

1. **`-0` = precondition / pre-net slice** authored *before* a milestone (vs. `-01+` corrective /
   closure slices that ride *after*, e.g. `M2-02`). `M4-0` is the first.
2. **New-behaviour milestones split into ordered execution prompts:** acceptance-tests (red) →
   implementation (green). The test prompt may run on a cheaper model.
3. **M3 tombstone retired** in favour of **`M4-0`**. The roadmap's M3 slot was kept empty only to
   preserve cross-refs (D-1 killed the facade milestone); reusing "M3" for a live test-net would
   overload a dead id. Cross-refs repoint to M4-0.

## Consequences

- **E14 satisfied** — the human now understands and has approved the M3→M4 path (as this two-tier
  strategy). **E9** (architect call) is unblocked: commission `M4-0` + its infra spec, confirm the
  per-milestone test-first split, and decide M4 black-box-vs-escalate (the net makes black-box
  **safer**) and M7-in-parallel.
- **E11 estimates recalc is due** — the milestone set changed (M4-0 added; M5/M6/M7 each gain a test
  step). **But it cannot be done well yet:** M4-0's size hinges on the unresolved infra-feasibility
  question (E9). Recalc rides the propagation entrypoint, after E9 sizes M4-0.
- **Propagation deferred** — roadmap rename (M3→M4-0), convention codification into
  `design/agents/process.md` / `sdlc.md`, and the E11 recalc are bundled into a dedicated ops
  entrypoint so they land **atomically** after E9, rather than as a half-applied state now (which is
  the drift this lifecycle guards against).

## Decision status

**Settled** (human, 2026-06-18, session 12): feature-global net `M4-0` covering M4+M6 with its own
spec-design cycle; per-milestone acceptance tests as test-first steps preceding implementation; the
three conventions above. Propagation pending its ops entrypoint.
