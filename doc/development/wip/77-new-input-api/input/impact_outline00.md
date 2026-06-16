# Round-2 Impact Outline (contour only — no chain edits yet)

*Input: `input/stakeholder2_structured.md`. This document marks what the
round-2 feedback touches across the solution chain (problem → requirements
→ decisions → design → spec → roadmap/estimates). It does not yet apply any
change; it scopes them. Application is tracked in `track00.md`.*

Legend: **CHANGE** = alters a settled resolution · **CLARIFY** = wording /
explanation only, no semantic change · **CONFIRM** = ratifies existing
resolution, no edit.

---

## C1 — D-2 / `show()` while active: block-by-default + `force` flag — **CHANGE**

Feedback: items 2 and the Spec `show()` remark.

Today the chain says a second `show()`/setup while active "reconfigures
in-place" silently (D-2 "dissolved"; `spec.md §2`, §7). Stakeholder wants
the default to be a **no-op block**, with an explicit `force` flag to
reconfigure.

Touches:
- `decisions.md` — D-2 resolution text; D-2 row in the glance table; the
  D-4 note that references `show()`/`hide()` activation is unaffected.
- `spec.md` — §2 `compy.input.show(config)` (add `force` field, change
  "reconfigures in-place" default to blocked); §2 `configure()` (does the
  block/force apply? — `configure()` is the live-update path, so the gate
  belongs to `show()`, not `configure()`); §7 edge case "`show()` while
  already active."
- `design.md` — §3 `compy.input.show` row; any prose asserting in-place
  reconfigure on re-show.
- `roadmap.md` / `summaries/roadmap.md` — M2 (`show`/`hide`) and/or M7
  (extended API) acquire the force-flag logic; small estimate touch.
- `summaries/decisions.md`, `summaries/spec.md` — D-2 line, show() line.

Coherence watch: FR-3/FR-4 (hide/show) and the "dynamic prompt change
mid-run" use case were cited as motivation for in-place reconfigure. With
block-by-default, the mid-run prompt change must go through `configure()`
(live-update path), not a second `show()`. Confirm that story still holds.

---

## C2 — D-5 boundary: add horizontal + line/whole-input granularity — **CHANGE**

Feedback: item 5.

Today `on_limit_reached(direction)` covers `'up'`/`'down'` at the
**whole-input** boundary only; the second arg is reserved/undefined
(`decisions.md` D-5, `spec.md §4`). Stakeholder expands to:
- horizontal boundaries: `'left'`/`'right'` at first/last character;
- a granularity distinction: boundary "for the whole input or the line."

This makes the currently-reserved second argument meaningful (line-level
vs input-level). Prior art: the editor's existing up/down block-navigation
boundary checks (`UserInputModel:is_at_limit`, vertical-only today;
`editorController.lua:511-512`).

Touches:
- `requirements.md` — FR-7 wording ("first or last valid position") already
  admits horizontal; note the multiline open-question in §5 is now answered
  more fully (line vs input granularity).
- `decisions.md` — D-5 resolution (directions set, granularity arg); D-5
  glance row.
- `spec.md` — §4 `on_limit_reached` (direction domain now up/down/left/
  right; define the second arg as granularity instead of "reserved, do
  not use").
- `design.md` — §7 FR-11/FR-12 walkthrough rows that map Up/Down-at-
  boundary to `on_limit_reached` (now also left/right).
- Implementation note: `UserInputModel:is_at_limit` is vertical-only; a
  horizontal/line-level variant is new work — surfaces in the roadmap
  (M6, where `on_limit_reached` fires) + model work.
- `roadmap.md` / summaries — M6 scope + estimate touch; test coverage line.
- `summaries/decisions.md` — D-5 line.

Coherence watch: keep "the hook always propagates" property; confirm the
granularity arg has a defined v1 meaning now (it was explicitly "undefined
in v1" before).

---

## C3 — Rename `ProjectController` → `ProjectInputController` — **CHANGE** (mechanical, wide)

Feedback: the first `*` item.

Pure rename, but the identifier appears across the whole chain and in the
new-file plan. No semantic change.

Touches (every mention of `ProjectController`):
- `decisions.md` (D-3, D-4, D-7, D-9, approach prose),
- `design.md` (§2, §3 component, §4 dispatch, §5, §6),
- `spec.md` (§6 header + body, §1 dispatch examples),
- `roadmap.md` (M4, M5, M6 descriptions and file list:
  `src/projectController.lua` → `src/projectInputController.lua`),
- `summaries/decisions.md`, `summaries/design.md`, `summaries/roadmap.md`,
  `summaries/spec.md`,
- `README.md` TL;DR (does not name it — check),
- supporting `notes/` (routing_unification, solution_sketch, etc.) — these
  are analysis notes; update for consistency but they are not the
  authoritative chain.

Coherence watch: ensure the new name does not collide with `ProjectService`
(the existing project-create/delete service the stakeholder referenced) —
it does not; the distinction is exactly the stakeholder's point.

---

## C4 — `keys_pressed` proxy: allow read indexing, block writes — **CHANGE**

Feedback: Spec `keys_pressed` remark.

Today the proxy is iterator-only ("direct indexing not supported";
`spec.md §1`, `design.md §3`). Stakeholder wants `proxy[k]` read access,
with writes blocked.

Touches:
- `spec.md` — §1 "Ownership and passing" (drop "direct indexing not
  supported"; describe a read-only proxy: `__index` reads through,
  `__newindex` raises/ignores).
- `design.md` — §3 `keys_pressed` table ("read-only proxy (iterator only)"
  → "read-only proxy: read-indexable, write-blocked").
- `roadmap.md` — M1 (combo_string / keys_pressed) proxy construction note;
  negligible estimate change (a metatable instead of an iterator wrapper).
- `summaries/spec.md` if it mentions the proxy.

Coherence watch: combo serialisation and the read-only contract are
unaffected; this only widens read access. Confirm no consumer relied on
indexing being absent.

---

## C5 — D-4 "framework's own teardown": clarify the phrase — **CLARIFY**

Feedback: item 4.

The before/after named-chain design is accepted. Only the phrase "the
framework's own teardown" in the D-4 question is unclear. Add an inline
gloss: it refers to the framework-owned middle step of the chain — the
structural close on cancel (`model:cancel()` → push `'userinput'` → hide)
and evaluate+store on submit — which always runs and which projects cannot
suppress.

Touches:
- `decisions.md` — D-4 question text (add a parenthetical gloss).
- No semantic change to the resolution.
- `summaries/decisions.md` D-4 line — optional gloss.

---

## C6 — D-3 scope framing: pass-through + accepted improvement — **CLARIFY**

Feedback: items 3 (before) and 3 (after).

Stakeholder ratifies the combo/dispatch layer as an acceptable improvement
over raw LÖVE pass-through, while bounding scope: "further helpers … not as
part of this effort." The chain already builds the combo layer; this needs
only a scope-boundary note (no new helpers beyond what the spec already
describes; the overloadable-matcher / `mods`-string ideas stay flagged as
future seams, not built).

Touches:
- `decisions.md` — D-3 (add a one-line scope-boundary note tying to the
  stakeholder ratification); the existing "future seam" annotations in D-6
  already match this stance.
- No structural change.

---

## C7 — D-1, D-6, D-7, lifecycle — **CONFIRM** (no edit beyond optional ack)

- D-1 (no backward compat): confirmed.
- D-6 (two independent channels): confirmed ("same as 3").
- D-7 (project-first): confirmed, with the forward-looking note that the
  REPL run path is expected to converge on the project path. Worth a
  one-line forward note in D-7, optional.
- Persistent-singleton lifecycle: approved ("very sensible").
- Touch scope: wording correction only to `requirements.md §4` /
  `design.md §1` out-of-scope phrasing — optional.

---

## Estimate-impact contour (refined in `summary00.md`)

| Item | Direction | Rough size |
|---|---|---|
| C1 force flag | + | small (M2/M7 logic + a config field) |
| C2 boundary expansion | + | small–moderate (model `is_at_limit` horizontal/line variant; M6 + tests) |
| C3 rename | + | negligible (mechanical; one file rename) |
| C4 proxy read-index | ± | negligible (metatable shape) |
| C5 / C6 clarifications | 0 | doc-only |

Net expected: a small upward nudge concentrated in C2; the rest is
negligible or doc-only. No milestone is removed or reordered; no decision
is reversed. Full restated estimates in `summary00.md`.
