---
description: Register of stakeholder inputs received after the initial session (SR1) — what each introduced + where it is absorbed. A traceability index so late inputs aren't lost during M4–M8 spec/test refinement and arch calls; NOT a requirements re-fit.
status: active
audience: design + implementation
---
# Feature #77 — Late-input register

**What this is.** A single index of stakeholder inputs that arrived **after the initial input session
(SR1)**, and **where each item is absorbed** (decision ledger / spec / milestone / arch-call). It exists
so nothing valuable from these rounds is lost while we refine specs/tests for **M4–M8** and resolve
outstanding architecture calls (e.g. **E9**).

**What this is NOT.** Not a requirements re-fit, and not a restatement of content. It **points at** the
authoritative records (the decision ledger in [`design/status.md`](../design/status.md), the per-decision
rationale in [`design/notes/decisions-record.md`](../design/notes/decisions-record.md), the specs, and
the E20 assessment) — it does not copy them. When an item's wording matters, read the linked source.
The validation-economics stance holds: lightweight inventory now; empirical revalidation rides on M4-0
against real code; full re-fit is the **E2 contingency** (only if stakeholders object after seeing
implementation).

**Baseline.** **SR1** ([`design/notes/input.md`](../design/notes/input.md), 2026-06-06) is the initial
input that seeded the design + the seven blocking decisions (D-1…D-7). It is the baseline this register
measures "late" against — not tracked here, just the reference point.

---

## SR2 — stakeholder round 2 (`design/notes/input/`, 2026-06-10) — **landed in design + specs**

Principal platform dev's pre-spec + post-spec responses. Structured form:
[`design/notes/input/stakeholder2_structured.md`](../design/notes/input/stakeholder2_structured.md).
E13 (session 12) walked how each landed; all are absorbed into the converged design + frozen specs.

| Item | Kind | Where absorbed | Status |
|---|---|---|---|
| **`ProjectInputController` rename** (not `ProjectController` — that reads like project create/delete) | naming requirement | `design/spec/M4.md`, `M5.md` (controller named throughout) | ✓ landed |
| **`show({force=true})`** — second setup call is a **no-op by default**; explicit `force` flag opts into in-place reconfigure (changed D-2 from "silent reconfigure") | requirement delta | `design/spec/M2.md §31/§49`, `M2-01-restore-mvc.md` (`force` path + F-5 debt) | ✓ landed |
| **D-5 boundary expansion** — add **horizontal (left/right, first/last char)** + **whole-input vs line** scope to `on_limit_reached`/`is_at_limit` (was up/down whole-input only) | requirement delta | `design/spec/M6.md §12/§36/§42/§50/§57` (extend `is_at_limit` to horizontal + line scope) | ✓ landed |
| **`keys_pressed` read-proxy** — permit read indexing (`proxy[k]`), block only writes (was iterator-only) | requirement delta | M1 outcome / `keys_pressed` proxy contract | ✓ landed |
| **D-4 named submit/cancel events** — "yes to dedicated named events; refine in implementation"; "framework's own teardown" phrasing was unclear → needs spelling out | confirmation + clarify | `design/spec/M6.md` (named submit/cancel chains) | ✓ landed (teardown phrasing folded into P4/A1 discussion, SR3) |
| **D-3 revised** — after reading the spec, accepts the combo/dispatch layer as an improvement over bare LÖVE pass-through (further helpers still out of scope) | scope confirmation | `design/spec/M5.md` (three-level dispatch) | ✓ landed |
| **D-1 / D-6 / D-7 confirmations**; touch = wording-only out-of-scope note | confirmations | decision ledger `design/status.md` | ✓ no change |

---

## SR3 — stakeholder round 3 (`notes/stakeholder-3-input/`, 2026-06-22) — **in-flight → E9**

Pre-feature **pain statements** + two working examples. Assessed by **E20** (verdict: design direction
holds — validated, not altered) and revalidated clean (session 19). Authoritative processing:
[`notes/stakeholder-3-input/assessment.md`](stakeholder-3-input/assessment.md) (§"Hand-off to E9").

| Item | Kind | Where absorbed | Status |
|---|---|---|---|
| **Combo-tier repeat semantics** — do `handlers[combo]`/`framework_handlers` fire on key-repeats or only fresh presses? (the one genuinely-open design Q) | open design question | **E9** (next to A6); human-provisional default = handler fires once / `on_key_pressed` sees repeats | ◐ carried to E9 |
| **`isrepeat` (+`scancode`) threading** — undo the incidental drop at `controller.lua:554` | regression-undo | **E9** + **M4-0 assert** | ◐ carried to E9 |
| **P1 event-order** — no runtime order guarantee owed; only M4-0 must not bake keypressed→textinput as an invariant | test-design constraint | **E9 / A8 / M4-0** | ◐ carried to E9 |
| **P3 modifier chords** — solved by combo dispatch (no fix needed) | validation | reinforces **A6** (decide before M5) | ✓ validated |
| **P4 exit/global-state** — real leak is T3 raw-`love.*` global state across run boundaries → framework snapshot/restore (not a project hook) | out-of-#77-scope sibling | **A1** (project-run-lifecycle); narrowed interrogation pending | ◐ carried to E9 |
| **Examples `keyboard` + `maze`** — new-style characterization + D-9/M8 migration surfaces | coverage anchors | **M4-0** characterization + migration targets | ◐ carried to E9/M4-0 |

---

## Maintenance (operational)

Update this register when **(a)** a new stakeholder/late input arrives (add a round + its items, status
`◐ in-flight`), or **(b)** a carried item lands in a spec/decision (flip to `✓ landed`, cite where).
It is a **traceability surface**, kept current like `entrypoints.md` — not a one-time summary. Tracked as
an operational entrypoint (estimates-class). See [`entrypoints.md`](../entrypoints.md).

## See also
- Decision ledger (authoritative): [`design/status.md`](../design/status.md);
  per-decision rationale: [`design/notes/decisions-record.md`](../design/notes/decisions-record.md).
- E13 briefing on SR1/SR2 landing: `sessions/.../session12/report.md`.
- E20 assessment (SR3 processing): [`notes/stakeholder-3-input/assessment.md`](stakeholder-3-input/assessment.md).

*— register opened by AI, 2026-06-22*
