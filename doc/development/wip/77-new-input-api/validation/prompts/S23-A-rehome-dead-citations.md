# S23-A sub-agent prompt — rehome dead contract citations (Sonnet)

**Materialized prompt of record** (validation.md hygiene c). Worker: Sonnet.
This is a **comment-only** pass. Owner-approved; the mapping below is decided —
do not re-derive it, do not extend it.

## Context you do not inherit

You are a sub-agent in the LÖVE2D project **compy** at `/repo` (cwd). You do
**not** inherit the repo's CLAUDE.md or the parent session's context, so:

- **MCP-LSP is available.** The `lua-lsp` MCP server (`definition`,
  `references`, `diagnostics`, `hover`) works over a real AST of the `/repo`
  workspace. After **any** `.lua` edit, `sleep 1` before calling refs / defs /
  diagnostics — the language server needs a beat to re-index.
- Local workspace commands (`git`, `grep`, `sed`, `awk`, …) are pre-approved.
  **Do NOT commit** — the parent session commits. Never push, never touch
  `.git` internals.
- Coding rules live in `/repo/agents/rules.md`. The ones that bite here: **line
  length ≤ 64 characters** (comments included — rewrap, don't overflow), and
  match the surrounding comment style.
- Tests run with `busted tests` (uses mock_love, no display needed). The
  expected result is **862 successes / 0 failures / 0 errors / 3 pending**.

## Why this work exists

The persistent documentation corpus is the authoritative contract for this
feature. `doc/input_api.md` was rewritten and its headings changed, but the
comments in `src/` and `tests/` that cite it were never updated. A revalidation
found **8 cited section names that no longer resolve**, across 22 sites. The
contract *content* still exists — every one of these is a rehoming, **not** a
contract change.

## The mapping — decided, apply exactly

`doc/input_api.md` current headings are: `Quick start`, `` `show(config)` ``,
`Submit lifecycle`, `Validation and highlighting`, `Live changes`,
`Event hooks and shortcuts`, `Callback assignments`, `Migration`, `See also`.
Verify this yourself with `grep -n '^#' doc/input_api.md` before you start.

| Dead citation | Replace with |
|---|---|
| `doc/input_api.md, "Sticky callbacks"` | `doc/input_api.md, "Callback assignments"` |
| `doc/input_api.md, "API reference"` | `doc/input_api.md, "Live changes"` |
| `doc/input_api.md, "Live reconfigure"` | `doc/input_api.md, "Live changes"` |
| `doc/input_api.md, "Live reconfigure: `configure`, `set_text`, `clear`, cursor"` | `doc/input_api.md, "Live changes"` |
| `doc/input_api.md, "Activating the widget: `show`"` | ``doc/input_api.md, "`show(config)`"`` |
| `internals/user_input.md, "Submit and cancel — the framework submit chain"` | `internals/user_input.md, "Submit and cancel — widget-owned callback sequences"` |
| `internals/user_input.md, "Submit and cancel — the framework tier-1 chains"` | same as the row above |
| `internals/user_input.md, "Cursor manipulation and 'reset'"` | `internals/user_input.md, "Cursor manipulation and "reset""` — i.e. **double** quotes, matching the real heading. If nesting double quotes reads badly in a given comment, rephrase to `internals/user_input.md, "Cursor manipulation and \"reset\""` or drop the quoted fragment to just the heading's first three words; use judgment, keep it greppable. |

**"Submit and cancel — the framework tier-1 chains" / "the framework submit
chain" are the priority.** They name a model this feature explicitly retired:
submit and cancel are **widget-owned callback flows, not a framework tier**
(`doc/development/decisions/input.md`, Decision 6 revised). Fix the surrounding
prose too where it repeats the "framework tier" framing — those comments should
not assert a superseded architecture.

Note some citations are **split across two comment lines** (e.g. `-- (doc/…md,
"Live reconfigure: \`configure\`,` / `-- \`set_text\`, \`clear\`, cursor")`).
Grep for the fragment, not the whole string.

## The sites (22, verified at HEAD — line numbers will drift as you edit)

- `src/controller/consoleController.lua`: 440, 575
- `src/model/input/userInputModel.lua`: 517
- `tests/input/input_cursor_text_spec.lua`: 6, 20, 115, 130, 144, 188
- `tests/input/input_reconfigure_spec.lua`: 258, 316, 320-321, 323
- `tests/input/input_widget_lifecycle_spec.lua`: 26, 105, 117
- `tests/input/input_widgets_callbacks_spec.lua`: 319, 334, 422, 526
- `tests/input/input_route_lifecycle_spec.lua`: 120
- `tests/input/user_input_model_spec.lua`: 151

Treat this list as a starting point, **not** as the completeness authority: after
your pass, re-grep for every dead name in the mapping table across tracked `src`
and `tests` and confirm zero remain.

## One narrative fix (not a citation)

`tests/input/input_reconfigure_spec.lua`, the `#m8` block header at ~257-267,
currently reads:

```
  -- doc/input_api.md, "The continuous-session idiom"
  -- (migration recipe):
  -- on_text_entered consumes; after_submit re-shows.
  -- Pins the pattern every example
  -- migration relies
  -- on, before any example is touched.
```

This is stale in substance: after the line-array/callback correction the overlay
**stays open by default** and the migrated examples **clear** rather than
re-show — the second test in this very block says so in its own comment. Replace
that fragment with (rewrap to ≤64 cols, keep the `=====` rules and the two
following lines about lifecycle callbacks being direct fields):

```
  -- doc/input_api.md, "Submit lifecycle": the overlay stays
  -- shown after a submit, so a continuous session needs no
  -- re-show — on_text_entered consumes and after_submit
  -- clears. A bare re-show from after_submit stays legal and
  -- is pinned here too, because the sticky-callback re-arm it
  -- relies on is contract.
```

Also at ~271-273, `-- The recipe: consume in on_text_entered, re-show …`
describes the first test accurately but frames it as *the* recipe. Change
`The recipe:` to `One shape:`. Do not touch any assertion or test body.

## Hard constraints

- **Comments and prose only.** Not one character of executable code changes — no
  assertion, expression, control-flow, or `it(...)` description edits. If you
  think a test is wrong, write it in your outcome file; do not act on it.
- Respect the ≤64-column line limit; rewrap comments you touch.
- Do not "improve" comments beyond the mapping and the one narrative fix above.
- Do not touch anything under `doc/development/wip/` except your outcome file.
- Do not commit.

## Verification before you finish

1. `busted tests` → must be **862 / 0 / 0 / 3**. Report the exact numbers.
2. Re-grep for all 8 dead names across tracked `src` and `tests`; report zero.
3. `git diff --stat` — confirm only expected files appear.
4. Sanity-check that every *replacement* section name actually exists, with
   `grep -n '^#'` on the two target docs.

## Deliverable

Write your report to
`/repo/doc/development/wip/77-new-input-api/validation/outcomes/S23-A-rehome-dead-citations.md`:
sites changed (file:line → old → new), the suite numbers, the re-grep result,
anything you deliberately left alone and why, and anything that surprised you.
State plainly if something did not go to plan — an accurate report of a partial
pass is worth more than a tidy one.
