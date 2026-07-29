# S20 — version-tag migration key (dissolve A/B/C/D buckets)

Resolves **RVW-094** (dissolve the A/B/C/D bucket taxonomy), **RVW-084/083** (rename the
"provisional / expected to change" group), **RVW-085** (the inspect carve-out), and folds
**ruling 8** (RVW-090, canonical-docs comment rule). Owner-ruled 2026-07-28. This is a
**docs/comments migration only — no production code changes.**

## The convention (owner, 2026-07-28)

LÖVE2D per-version availability style, mirroring `doc/input_api.md` (which already carries
`(supported since 1.0.0-rc20260712)` / `(deprecated, removed in …)`).

- **Version anchor:** `1.0.0-rc20260712`.
- **Fork = behaviour-availability** (not contract/documentation age). A behaviour is tagged
  `since 1.0.0-rc20260712` (or `changed in 1.0.0-rc20260712`) **only if it is new/altered by the
  feature — i.e. absent from / different in the `updev` baseline.** Behaviour that pre-existed the
  feature is **documented plainly with no tag attribution.**
- Retire the literal `Bucket A/B/C/D — NAME` banner labels. Keep the behaviour-named `describe`
  strings.

## Bucket → tag map

| Bucket | old label | owner semantics | tag |
|---|---|---|---|
| **A** | PRESERVE (routing) | pre-feature, justified, kept | **no tag** — pre-baseline; keep behaviour-named describes |
| **B** | IMPLEMENT (nfr) | forward contracts, not shipped | **"planned change"** (stays `pending` where already pending) |
| **C** | MECHANISM-GUARD (nfr) | NFR / mechanism, not behaviour | **no availability tag** — keep an "NFR / mechanism guard" label |
| **D** | CHARACTERIZE-PROVISIONAL (nfr) | pre-existing de-facto standard, undocumented-before, reverse-engineered, canonicalized now | **no tag** (behaviour is pre-baseline); document as current characterized behaviour — **except the RVW-085 carve-out** |

Net effect: almost nothing here earns a fresh `since` tag — the bucketed groups characterize
**preserved (A)**, **de-facto (D)**, **NFR (C)**, and **not-yet-shipped (B)** behaviour. The
genuinely feature-new public surface is already tagged in `input_api.md`. `input_events_spec.lua`
carries **no bucket banners** (already behaviour-named) and needs no migration.

## Per-file work

**`input_routing_spec.lua`**
- Line 36 `Bucket A — PRESERVE (stable-now contracts; green now)` → drop the bucket label; keep the
  rest of the block (exclusivity invariant + per-mode subgroup rationale) as plain description.
- Line 23 (RVW-094 suite-note) → **DROP**; the convention now lives here + in the migrated banners.
- Ruling 8 (RVW-090, lines 18-19) → **DROP** the two `REVIEW/DOC: all comments point to canonical
  docs …` lines; promote the rule into `doc/development/conventions/` (below). Keep the parked
  RVW-092/093/095 lines in the suite-note block intact.

**`input_nfr_forward_spec.lua`**
- Bucket D banner (31-40) + `describe('provisional — expected to change, no mandate')` (40) →
  drop the bucket label + "expected to change" framing; reword to
  `describe('current behaviour — characterized, no stakeholder mandate')` with a one-line note
  that these are **pre-baseline de-facto behaviours canonicalized here (no `since` tag)**. Resolves
  RVW-084 (rename) and RVW-083 ("forward" jargon dropped with the scheme).
- **RVW-085 carve-out** — `it('inspect: the console owns the surface')` (54): keep the behaviour;
  replace its `OWNER RULING PENDING / expected to change` header with a **contested/status-quo**
  note pointing to the new tech-debt entry (below). No `since` tag (inspect/suspend predates the
  redesign). No pending "proper" test (proper behaviour is undefined until the console/editor
  migration).
- Bucket C banner (77-85) → drop the bucket label; keep `describe('mechanism / NFR guards — not
  behaviour')` and the "these poke internals deliberately" rationale.
- Bucket B banner (173-181) + `describe('forward contracts (pending until implemented)')` (183) →
  drop the bucket label; reword to **planned change** vocabulary; bodies stay `pending`.
- Inline "is the Bucket B forward" (96-99) → "is a **planned change** (not yet landed)".

**`input_events_spec.lua`** — no banners; leave as-is.

## Ruling 8 — canonical-docs comment rule

- Promote into a new/updated `doc/development/conventions/` note: *"Comments cite canonical docs
  (`doc/…`), never the feature's ephemeral working tree (`doc/development/wip/…`)."*
- **Live follow-up (tech-debt):** 2 src violations cite wip paths —
  `src/controller/consoleController.lua:511`, `src/controller/userInputController.lua:8`. Logged in
  `technical_debt/input.md`, not fixed in this comments pass.

## S21 amendment — per-file availability lines (owner ruling, 2026-07-29)

**Why.** S20 applied the convention only where A/B/C/D banners happened to exist (routing, nfr).
Everywhere else in `tests/input/` nothing was said — so "untagged" meant *"verified pre-baseline"*
in two files and *"nobody looked"* in the other eighteen, indistinguishable to a reader. The
owner ruled option **(ii)**: make silence mean something.

**Rule.** **Every** file in `tests/input/` opens with a one-line `-- Availability:` note stating
which side of the baseline its behaviour sits on. Grep-anchored on `^-- Availability:`. Per-group
and per-test tags remain **prohibited** — that is the elaboration this convention exists to avoid.

**Classification is by behaviour, not by file age** — several files are new to the repo yet assert
pre-baseline behaviour (`input_routing_spec`), and one pre-existing file gained feature-new
coverage (`user_input_model_spec`). Verified against the `devupstream` baseline
(`git grep -l <symbol> devupstream -- src/`), S21:

| Availability | Files |
|---|---|
| **feature-new** (`since 1.0.0-rc20260712`) | `input_cursor_text`, `input_reconfigure`, `input_widget_lifecycle`, `input_events`, `input_lifecycle_unfork`, `input_route_lifecycle`, `keys_pressed` (mechanism) |
| **since / changed in** | `input_redesign_ac` (the ACs), `input_widgets_callbacks` (outputs new, submit/cancel defaults altered) |
| **changed in** | `project_open_liveness` (input-only projects stay live — ruling a) |
| **pre-baseline, untagged** | `input_routing`, `input_nfr_forward`, `cursor`, `history`, `input`, `input_text`, `user_input_view` |
| **mixed / qualified** | `user_input_model` (pre-baseline + the `set_text keep_cursor` addition), `input_shortcuts_click` (pre-baseline shortcuts/click, feature-new combo normalisation, legacy globals **removed in** 1.0.0-rc20260712), `highlight_regression` (pre-baseline machinery, guards a crash fixed in this feature) |

Baseline evidence for the non-obvious calls: `compy.input`, `keys_pressed`, `combo_string` and the
legacy `solicit*` surface return **zero** hits in `devupstream -- src/`; `singleclick` and
`project_open` are present pre-feature; the `highlight.hl` indexability fix landed in-feature
(`1a2a9a3`).

## RVW-085 tech-debt entry (technical_debt/input.md)

*Inspect-mode console-owns-surface is characterized status quo, not a ratified contract.* Under
`inspect` the console REPL owns every input channel and a shown project widget is not honoured
(`get_user_input()`→nil under inspect, `ConsoleController:suspend()`→`set_default_handlers`, REPL
runs in the paused project's env). RVW-111 questions whether an active route should own the
fall-through instead of a hidden/paused console. **Not a stakeholder ask; changing it reworks the
suspend/inspect spine (architecturally significant), so left as-is.** During a real *run* a hidden
widget already falls through (no silent console consumption) — the contested behaviour is only the
inspect-mode debugger. Revisit under a future console/editor migration.
