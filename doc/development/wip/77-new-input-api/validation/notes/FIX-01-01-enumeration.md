---
description: FIX-01-01 re-derivation — P11's deferred editorial list, named as 8, never listed
status: active
audience: developer
authored: llm
session: 69
date: 2026-09-03
---

# FIX-01-01 — the eight, re-derived at HEAD

**Source of the count.** Session45's W10-batch-3 re-derivation
(`validation/outcomes/S45-W10-batch3-rederivation.md`) and
`S45-P11-inventory.md` §5: *8 editorial remainder* =
4 in `decisions/input.md` + 4 in `internals/user_input.md`. Plan.md still
says "8" and "must be re-derived"; this is that derivation. Line numbers
below are HEAD 2026-09-03; the 2026-08-25 numbers are in the source tables.

| id | 2026-08-25 site | ask | HEAD |
|---|---|---|---|
| R085 | `decisions/input.md:159` | drop the "consuming is not removing" defence | **gone** — the heading and paragraph are not in the file |
| R091 | `decisions/input.md:234` | drop "conflating them is a trap"; just distinguish | **live** — `D-TWO-SURFACES` Why, remark at `:262` |
| R092 | `decisions/input.md:235` | trim the same Why (incl. "student") | **live** — same block, remark at `:263`; "student" itself moved to the file intro `:80`; the Why still over-explains |
| R100 | `decisions/input.md:410` | the "no X, no Y, no Z" list defends unasked alternatives | **gone as a list.** The matching archaeology remark is gone. `D-HOOKS-SEEDED` Why still has *"never asked for"* — that is `DEC-02`'s interim-prose rule, not this row |
| R143 | `internals/user_input.md:211` | paragraph too big; compress or dissolve | **gone** — the prose-size remark is gone (the archaeology half of the same paragraph was the strip that took it) |
| R150 | `internals/user_input.md:462` | heavy Search-widget paragraph; rewrite | **live** — remark at `:524`, paragraph `:526`–`:548` |
| R162 | `internals/user_input.md:725` | drop the `love.handlers.userinput` vestige | **gone** — no `userinput` vestige remains in this file |
| R164 | `internals/user_input.md:744` | do not restate the public API; say what the table is and where | **live** — remarks at `:819` (the method inventory) and `:869` (`show`/`configure` subsections that duplicate `doc/input_api.md`) |

**Size after derivation: three live sites**, not eight. Four already paid by
later passes that never ticked this row. R100's residue is `DEC-02`.

**Not this row** (live remarks in the same files, other owners):
`FR-1`/`FR-6` → `FIX-01-02`; overlay/callbacks vocabulary → `FIX-02` (b);
`T-ARGUES-INTERIM` marker on `D-ROUTE-LIFETIME` → `DEC-02`; remaining
`REMARK:`s → `FIX-02-07`.
