# Build-time continuity vs. product backwards-compatibility (two different "BC"s)

_Materialised from a chat decision (2026-06-17, session 07). Owner: Hleb Rubanau. Orchestration
stance for the #77 incremental build — read before commissioning **M4** (overlay/dispatch rework)._

## The decision

Stakeholders **withdrew backwards-compatibility as a product requirement** for the new input API. That
withdrawal is real but **narrow** — it applies only to the *shipped end-state*. It does **not** license
breaking the running system between milestones. Two distinct notions were being conflated:

1. **Shipped / product BC — WITHDRAWN.** The *final* input API need **not** preserve the old public
   surface for external/project-author consumers. The end-state is free to drop, rename, or restructure
   old contracts where the design says so.
2. **Build-time continuity — IN FORCE (as a process rule, not a product requirement).** Each milestone
   must keep the *running system* working: the suite green, and the shipped examples (`turtle`,
   `tixy`, REPL, editor) not faulting, at **every** milestone boundary. We build #77 incrementally
   against a live codebase; a milestone that breaks the running system mid-build is a defect even if
   its end-state is correct.

These do not conflict. (1) constrains the destination; (2) constrains the path to it.

## Why it matters — `{ M, C, V }` is partly transitional scaffolding

This is exactly what the **M2 take-1 → M2-01** episode was about. Take-1 narrowed
`love.state.user_input` `{M,C,V}` → `{C}` on the theory that `M`/`V` were unused — a **product-BC**
judgement ("the final shape doesn't need them") applied at a point where **build-time continuity**
forbade it: the *current* running overlay (`controller.lua:401`) still reads `.V`, so it crashed
`turtle`/`tixy`. M2-01 restored the full triade to honour (2).

But the restoration is **not** a claim about the final API. Concretely, on this branch:

- **`.M`** has **no consumer outside tests** — carried purely for historical parity / build continuity.
- **`.V`** is the handle the **current** overlay uses; **M4 will legitimately rewire** the overlay so
  the controller owns dispatch and reaches the view itself.

So `{ M, C, V }` is, in part, **transitional scaffolding kept alive until M4 rewires its consumers** —
not a frozen end-state contract.

## Consequence for M4 (and any later milestone touching the overlay/dispatch)

- **M4 is *allowed* to drop `.M`/rework `.V`** — when it does, it must **migrate the consumer in the
  same slice** (build-time continuity), not narrow-then-hope. The lesson from take-1: an interface
  change is only safe when paired with a coordinated consumer sweep, proven by a test that drives the
  *real* path.
- **Do not mistake "M2-01 restored `{M,C,V}`" for "the shipped API is `{M,C,V}`."** The handle's shape
  is a build-state artifact; the design (`design/spec/M4.md`+) governs the destination.
- When M4 removes scaffolding, **strike the corresponding rows** here and in
  `implementation/technical_debt.md` and record the new shape in `internals/user_input.md`.

## Standing rule (going forward)

When a milestone is tempted to drop/narrow/rename something "the final design won't need," first ask:
**does the running system still depend on it at this milestone boundary?** If yes, either (a) keep it
until the consumer is migrated, or (b) migrate the consumer in the same slice. Never narrow ahead of
the sweep. Report — don't pre-emptively "tidy" — per `/agents/development.md`.
