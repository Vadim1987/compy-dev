# M5c — chunk carve (PM planning artifact)

_Written by the opus-sweeper PM (`agents/sweep.md`), 2026-07-09, on resume after the session02
conversation was interrupted (laptop battery). The carve had only ever lived in the interrupted
session's context + implicitly in the chunk-1 prompt's `## Boundaries` section; this file promotes it
to a first-class, reviewable artifact and **validates it against the frozen
`design/spec/M5c-dispatch-chain.md` Scope 1–10**. This is a schedule, not a design — it makes no
architectural rulings; it only orders the architect's Scope items into independently-gated chunks._

## Scope of this carve — M5c ONLY

All five chunks below are **inside the M5c slice**. M7 and M8 are separate future milestones, each
carved into its own chunks when we reach them (M5c → M7 → M8, re-cut order). See "Milestone map" at
the foot for how M5c/M7/M8 divide the whole remaining feature — in particular why **turtle+maze
migrate in M5c** while **tixy+balloons migrate in M8**.

## The carve — 5 chunks along Scope 1–10

| Chunk | Slug | M5c Scope items | Status |
|-------|------|-----------------|--------|
| **1** | dispatch-chain | 1 (the chain), 2 (keyreleased unified), 6[native-mechanism], 7[incremental], 10[generic-callback rows] | ✅ **landed + gated** (LLM APPROVE + human; `b9bcc16`; suite 744/0/0/6) |
| **2** | widget-outputs | 4 (`on_text_entered`/`on_limit_reached`/`validator`/`highlighter` as config keys + assignable fields; functional application AC-42), 7[extend allowlist], 8/9 as resolved | ⬜ next |
| **3** | submit-cancel | 3 (tier-1 return/escape; before/after submit+cancel chains; validator gate; `on_text_entered` delivery; deactivate step; Escape dismiss; **delete `oneshot`**; **dissolve `push('userinput')` producer**) | ⬜ |
| **4** | route-lifecycle | 5 (slots occupied only while `'running'`; restore to console on `project_open`; **remove M4 ruling-1 forwarding**; stop = full teardown invariant) | ⬜ |
| **5** | example-migration | 6[examples] (turtle + maze migrated, hand-playable; maze = **uncommitted working-tree**, guardrail 7) | ⬜ |

Scope 8 (QUALITY corrective), 9 (`>> REVIEW` marker removal), and 10 (suite retro-reconciliation) are
**cross-cutting**: each remark / marker / row is dispositioned by the chunk that owns the machinery it
touches, cited per-remark in that chunk's outcome ledger — not a chunk of their own.

## Why this order (dependencies)

- **2 before 3** — the submit path (chunk 3) *fires* `on_text_entered` and *reads* the `validator`;
  chunk 2 first establishes those as settable widget-output slots (config keys + fields, allowlist
  extended). Submit wiring lands on top of surface that already exists.
- **3, 4 both touch deactivate — deliberate seam, watch it.** Chunk 3 owns the widget's *submit-time*
  deactivate step (Scope 3, project-route policy); chunk 4 owns *route-level* connect/teardown
  lifecycle (Scope 5, removing the M4 ruling-1 forwarding). Chunk 1 froze both as-is
  ("keep existing activate/deactivate"). Ordering 3→4 lands the submit deactivate first, then reworks
  route lifecycle around it. Not a blocker; flag for the chunk-3/4 commissions so neither silently
  re-scopes the other.
- **5 last** — migrating turtle+maze needs the *full* landed surface: submit/cancel (3) + widget
  outputs (2) + route lifecycle (4). Migrating earlier would exercise a half-built API.

## Validation against the frozen spec

Every Scope 1–10 item has a home; nothing in Scope 1–10 is unassigned, and no chunk reaches outside
M5c. Chunk 1's landing (outcome `M5c-01-dispatch-chain.md`, review `M5c-01.md`) already discharged
Scope 1, 2, 6[native-mechanism], 7[incremental AC-33], and the Scope-10 generic-callback rows
(AC-36/AC-38). Remaining: Scope 3, 4, 5, 6[examples], and the trailing 7/8/9/10 dispositions — the
four chunks above.

## Milestone map — M5c → M7 → M8 (the whole remaining feature)

Re-cut order after the E29 re-derivation (Gate 3, frozen 2026-07-07). **M5b no longer exists** — its
content folded into M5c.

- **M5c — the dispatch chain** (`spec/M5c-dispatch-chain.md`). The widest slice (~2× M4 by PERT). The
  four-tier chain on all three channels + everything the ratified model changed about M4's shape:
  submit/cancel, widget outputs, route-connection lifecycle, legacy-natives-as-tier-3, the
  mutable/immutable boundary, the QUALITY corrective, and the **turtle+maze migration**. Turtle+maze
  ride *here*, not M8, by an explicit sequencing constraint (design.md §5): their behaviour visibly
  changes with the new chain, so deferring them would ship an interim window with misbehaving
  examples. → the 5 chunks above.
- **M7 — extended widget-surface API** (`spec/M7-02-recut.md`). Purely additive, **no routing/dispatch
  change**: `configure()` (live prompt/validator/highlighter/callback update), `clear()`,
  `get_cursor`/`set_cursor` (2D `(line,col)`, D-8), `set_text`. Depends on M5c complete. This is the
  surface that makes validator-reject cursor-jump, history-nav from `on_limit_reached`, and draft
  restore possible.
- **M8 — legacy removal + remaining example migration** (`spec/M8-02-recut.md`). **Terminal
  milestone.** Deletes the five legacy globals (`user_input`, `input_text`, `input_code`,
  `validated_input`, `write_to_input`) and the poll-a-reftable idiom; migrates the *remaining* legacy
  consumers (**tixy + balloons**) onto `compy.input.*`. Depends on M5c **and** M7 (migration needs the
  full surface). Carries a **REVALIDATE-AT-COMMISSIONING** flag: authored before M5c/M7 landed, so its
  mechanics must be diffed against the M5c/M7 outcome ledgers at a gate round before it runs. The
  `push('userinput')` **producer** dies in M5c (chunk 3); the polling **consumer** idiom dies here.

Each of M7 and M8 will itself be carved into human-gated chunks at its milestone boundary — this file
only carves M5c.
