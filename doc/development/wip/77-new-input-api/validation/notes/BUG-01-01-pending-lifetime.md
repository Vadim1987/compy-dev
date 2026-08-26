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

## Tooling note

The `lua-lsp` MCP bridge was **down for this row** (`broken pipe` on every call, including a bare
`references`). Symbol facts above were established with grep over `src/` and `tests/` instead, read
at each site rather than counted. Worth a retry next session before assuming it is gone.
