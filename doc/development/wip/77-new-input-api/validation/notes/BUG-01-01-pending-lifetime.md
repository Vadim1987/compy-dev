# BUG-01-01 — `state.pending` survives a project stop: evidence and disposition

**Session47, 2026-08-26.** Row **confirmed** and fixed (`bd2a5d49`), with the debt-ledger half
corrected separately (`abadf244`). This note records what was *established*, since the triage
registered the row with two open questions and a compounding claim.

## The defect, verified in code

`get_compy_input()` (`consoleController.lua`) builds a private `state` holding `shortcuts`, `hooks`,
`callbacks` and `pending`. It is reached only from `get_compy_namespace` → `prepare_project_env`,
and **`prepare_project_env` is called exactly once**, from `ConsoleController.new:80`. Verified by
grep across `src/` and `tests/`: the only other caller of `get_compy_namespace` is `prepare_env`,
which builds the *console* env and gets its own independent `state`.

**Env cloning does not separate instances.** `table.clone` is a deep clone, but `compy.input` is an
empty table whose metatable resolves everything (`build_frozen_view`), and `setmetatable(res,
getmetatable(obj))` preserves that metatable — which closes over the same `state`. So `base_env`,
`project_env`, and every `_reset_executor_env` re-clone share one store.

`stash_hidden_configure` writes `prompt`/`text`/`cursor` into `state.pending` when `configure()` is
called while hidden; `api_show` consumes it on the next `show()`. Nothing cleared it between runs.

## Question 1 — do `shortcuts` / `hooks` / `callbacks` share the hole?

**No.** Established, not assumed:

- `shortcuts` and `hooks` — `controller.lua`, `reset_compy_input` walks the `_bindable` channel list
  and wipes each one by name. Driven by the list rather than by `pairs`, because the surface is a
  proxy and `pairs` on it yields nothing.
- `callbacks` — `reset_widget_outputs` calls `ui:reset_callbacks()`, which wipes **in place** and
  re-seeds the stay-open defaults, so the reference the closure holds stays valid.

`pending` was the sole survivor. That is what made the fix small.

## Question 2 — is it reachable from a shipped example?

**Not demonstrably.** The two examples that call `configure` both avoid the hidden path:

- `balloons/terminal.lua:23` — `terminal_write` configures the prompt during a continuous session
  that is open for the whole run;
- `maze/core_editor.lua:67` — `set_prompt` guards with `compy.input.is_shown()` and falls back to
  `open_editor`.

So no shipped example leaks today. The path is nevertheless **public, documented API** — the
internals guide describes hidden-`configure` stashing as a feature — so this is a real defect in the
contract, not a theoretical one. Recorded as *fix on the merits, not on example evidence*.

## The compounding claim — confirmed

The debt entry *"`compy.input` is rebuilt per project environment"* asserted the opposite of the
call graph and accepted the debt on that premise. Corrected in `abadf244`; the entry now states the
fact, names what the arrangement costs, and carries a revisit trigger.

## Why the fix is not a deviation

Decision 11's teardown invariant already read *"no callback, combo entry, or widget configuration
survives the project that installed it."* An unapplied draft **is** widget configuration, so the fix
restores a stated contract rather than changing one. The invariant now names the draft explicitly,
because that is the case that slipped past it, and `internals/user_input.md` states the draft is
run-scoped.

## Design note — why the widget owns the draft

The alternative was a teardown handle threaded out of the closure to the framework. Rejected:
`callbacks` already lives on the widget for exactly this lifetime reason, and putting `pending`
beside it leaves the closure owning **no** application-lifetime state of its own — every store in
`state` is now either wiped by name at teardown or owned by the widget. No public surface was added,
which the strategic frame's "no moving parts beyond the ask" would have charged for.

## Owner attestation, 2026-08-26 — the defect class, named

> *"Hidden persistent mutable store which pretends to be ephemeral is a real design defect which you
> likely fixed."*

The owner endorsed the solution on that description, before the cold review returned. Their framing
is sharper than this note's original one and is the version to carry: the bug was never *"a table
was not cleared"* — it was **a store whose real lifetime and whose apparent lifetime disagreed**, in
a place where nothing forced them to be reconciled. The clearing was the remedy; the mismatch was
the defect.

Three properties have to hold at once for it to bite, which is why it survived review:

1. **hidden** — private to a closure, so no reader can see how long it lives;
2. **persistent** — built once for the application;
3. **pretending to be ephemeral** — every neighbouring store in the same table *was* run-scoped, and
   the guide describes the behaviour in per-run language ("retained and applied on the very next
   `show()`"), so the surrounding evidence actively argued for the wrong lifetime.

**Answered the same day.** The owner scoped the sweep to what could be inspected cheaply — the
`compy.input` hierarchy and the widget singleton, explicitly **not** every similarly-shaped closure
in the codebase — and it found **one more live instance**. Results below.

## The scoped sibling sweep, 2026-08-26

Scope as ruled: everything reachable under `compy.input`, plus the mutable state of the widget
singleton. Each candidate was checked against the question *"can this hold something a project put
there, after that project has stopped?"*

| store | verdict |
|---|---|
| `shortcuts` — 12 combo tables | **clean.** Teardown wipes each by name off `_bindable`; that list and the `EVENTS` list the tables are built from are the same 12 channels, in different order |
| `hooks` — 12 slots | **clean**, same walk |
| `callbacks` | **clean.** `reset_callbacks` wipes and re-seeds in place |
| `pending` | the original defect, fixed `bd2a5d49` |
| `fn` (the combinators) | **clean** — a fixed table of pure functions, nothing mutable |
| widget `shown` flag | **clean** — `hide()` at teardown |
| widget text content | **clean** — activation with no `text` calls `clear_input()` |
| `model.custom_status` | **clean** — cleared by `clear_input()` |
| `model.custom_label` (the prompt) | **DEFECT.** Fixed `8a9022ec` |
| input history | **clean at the seam** — probed: Up in project B after project A submitted returns empty |

**The one that bit: `model.custom_label`.** `apply_config` mirrors `cfg.prompt` onto it and writes it
**only when `cfg.prompt` is given**. Nothing cleared it — not `hide()`, not teardown, and notably not
`clear_input()`, which sits in the same function and *does* clear its neighbour `custom_status`. So
project A's `show{prompt = 'A> '}` labelled project B's field, and B could not overwrite it by
accident, because a bare `show()` leaves it untouched.

Proof it is the same class, not a coincidence: the breaking test failed **twice** — once on its own
assertion, and once in the *next spec in the file*, which had asserted the absence of that exact
string for unrelated reasons. Leaking across projects and leaking across test cases are one leak.

**Is it a class defect after all?** Two instances now, and the second was found by *looking* — so the
density argument from session46 (instances found by unrelated routes) still does not apply, and no
open-ended sweep is proposed. What the second instance does show is that the shape recurs inside one
subsystem, which is why the debt entry's revisit trigger stays.

**Byproduct — a new row.** `prompt` is on `PER_SHOW_KEYS`, documented *"spent by the show() that
reads them"*, and does not behave that way **within** a run either. Registered as `FIX-02-21`; the
cross-run half is what `8a9022ec` fixed and is not in question.

## Tooling note

The `lua-lsp` MCP bridge was **down for this row** (`broken pipe` on every call, including a bare
`references`). Symbol facts above were established with grep over `src/` and `tests/` instead, read
at each site rather than counted. Worth a retry next session before assuming it is gone.
