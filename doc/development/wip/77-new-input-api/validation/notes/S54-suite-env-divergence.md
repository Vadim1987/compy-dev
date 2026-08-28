# S54 — suite passes in the container, 107 failures in the owner's setup

**Status:** FIXED — root cause below, reproduced bit-for-bit, closed the
same day. Debt entry recorded and retired (`technical_debt/input.md`).
**Awaiting confirmation on the owner's machine.**
**Opened / diagnosed / fixed:** 2026-08-28 (session54, detour before the
commissioned task).

## The fix, as landed

Not the capability probe drafted below — the branch is **gone** instead.
`wrap` closes the arguments over a nullary function and calls
`xpcall(fn, on_error)`, which asks nothing of the runtime, so no platform
test remains to disagree with the capability. `select('#')` rather than
`#args`, so an explicit nil argument survives.

Guarded by two breaking cases in `input_route_lifecycle_spec.lua`, "the
boundary carries arguments on any runtime": they swap the global `xpcall`
for PUC 5.1's arity and drive a real keystroke, so they fail on LuaJIT too
without the fix. Suite **992 / 0 / 0 / 10**.

Verified end to end by running the whole suite with the global `xpcall`
replaced by PUC 5.1's arity: **883 / 109** before, **992 / 0** after. (109,
not 107, because the two new cases fail there too before the fix.)

## Root cause — `wrap` guards the `xpcall` extension on the wrong predicate

`src/controller/controller.lua`, `wrap` (`:122-153`). The non-web branch is

```lua
return xpcall(f, on_error, ...)
```

Passing arguments through `xpcall` to `f` is a **LuaJIT / Lua 5.2
extension**. PUC Lua 5.1 takes exactly two arguments and drops the rest, so
`f` runs with nil for every parameter. `wrap` already knows this — the
comment above the branch says so verbatim, and the `pcall` branch exists
precisely to avoid it — but the branch is selected on **`_G.web`**, set from
`OS.get_name() == 'Web'` in `main.lua`.

`_G.web` is a *platform* test standing in for a *runtime capability*. The two
came apart here:

| Runtime | `_G.web` | `xpcall` forwards args | Branch taken | Correct |
|---|---|---|---|---|
| LÖVE desktop (LuaJIT) | nil | yes | `xpcall` | yes |
| love.js Web build (PUC 5.1) | set | no | `pcall` | yes |
| **`busted` on PUC Lua 5.1** | **nil** | **no** | **`xpcall`** | **NO** |

The owner's `busted` runs `/usr/bin/lua5.1` — PUC Lua 5.1, no LuaJIT
installed at all. So `with_canvas_and_errors` enters every project route and
calls the chain with **no arguments**: hooks never see their key or
character, `combo_string` normalises against nothing, typed text never
arrives. Hence 107 failures, **all of them under `tests/input/`** and none
anywhere else — the rest of the suite does not cross that boundary.

The container never sees it because it has only LuaJIT (`jit=none` vs
`LuaJIT 2.1.1703358377` is the one env line that mattered).

**The upstream branch does not see it, but is not free of it** — a
distinction worth stating, because the first reading of this was "the
feature introduced it" and that is wrong. `master` carries the same
`_G.web`-guarded `xpcall` verbatim, reached through `error_wrapper` /
`set_handlers`, so on PUC 5.1 a project's adopted `love.keypressed` /
`textinput` / `keyreleased` and `love.update`'s `dt` were **already**
arriving nil there. What upstream lacks is not the defect but the
*coverage*: no test crosses that boundary. This feature inherited the bug
and widened it — `with_canvas_and_errors` routes every shortcut, hook and
the widget through it — and then had the tests to make it visible.

### Reproduced exactly

Forcing the arg-drop in the container — `xpcall(f, on_error, ...)` →
`xpcall(f, on_error)`, one character-level edit, reverted immediately after —
gives **883 / 107 / 0 / 10**, and the 107 failing rows `diff` **identical**
to the owner's report. Not "a similar cluster": the same set.

### Proposed fix (drafted, not applied — owner's call)

Select the branch on the capability, not the platform:

```lua
-- Does this runtime forward xpcall's trailing arguments to
-- `f`? The LuaJIT/5.2 extension; PUC Lua 5.1 takes exactly
-- two arguments and drops the rest. Asked of the runtime
-- once, because `_G.web` answers "is this the Web build",
-- which is a different question that only usually agrees.
local XPCALL_FORWARDS_ARGS = select(2, xpcall(
  function(...) return select('#', ...) end,
  function() end, 1)) == 1
```

and branch on `if not XPCALL_FORWARDS_ARGS then` — the `pcall` path, which
already exists and is already documented as the arity-safe one. `_G.web`
stops being load-bearing for correctness; the two branches and their
deliberately-unreconciled tails are otherwise untouched.

Cost: one predicate. It makes the suite interpreter-portable and removes a
latent trap for any future PUC-5.1 target.

### What this says about an existing debt entry

`technical_debt/input.md`, *"The Web build has no coverage, and carried a
feature-era regression unseen"*, states that **"the suite runs on LuaJIT,
where the desktop branch works"**, and concludes a PUC-5.1-only defect is
invisible to every check the project runs. That premise is now falsified:
the suite runs on whatever interpreter the developer's `busted` uses, and on
the owner's machine that is PUC Lua 5.1 — which is exactly why this surfaced.
The entry's proposed mitigation (a grep for bare `xpcall` with arguments)
would **not** have caught this one either: the offending call is not bare, it
is inside `wrap`, on the guarded-but-wrongly-guarded branch. Both points
belong in that entry whatever the ruling on the fix.

## The defect as reported

| Where | Branch | Result |
|---|---|---|
| Agent container (`/repo`, HEAD `ad534984`) | `feature/77-newapi-analysis-s20260615` | **990 / 0 / 0 / 10** |
| Owner's development setup | same branch | **107 failures** |
| Owner's development setup | upstream branch | **0 failures** |

Same command (`busted tests`), same branch, different machine. The upstream
branch being green in the owner's setup rules out a plain broken toolchain
there: whatever diverges is something *this branch* newly depends on, or
something in this branch's tree that the owner's checkout does not have in
the same state.

## Instrumentation added (this session)

Two throwaway diagnostic files, deliberately kept out of the PR scope
(`tests/` is not scanned for them — `.busted` collects `_spec.lua$` only):

- **`tests/diag_output.lua`** — a busted output handler that writes a
  machine-readable run report to a **file**, not stdout. Writing to a file
  matters: the app logs `INFO`/`WARN` lines to stdout during the run, which
  corrupts every stdout-based handler (the stock `json` handler additionally
  dies on this suite with *"type 'function' is not supported by JSON"*, so it
  is not an option at all).

  ```sh
  BUSTED_REPORT=busted-report.txt busted tests -o tests/diag_output.lua
  ```

  Report layout: `# env` fingerprint lines, a `# summary` line, one
  `# tests <status> <file>:<line>\t<full name>` row **per test** (all
  statuses, so the two runs can be diffed as sets), then a `# detail` block
  per failure/error carrying the message and traceback.

- **`tests/diag_env.sh`** — the fingerprint `busted` cannot see from inside
  Lua: interpreter/rock/`luarocks` versions, `git` HEAD + porcelain status,
  **submodule status**, locale, relevant environment variables.

  ```sh
  sh tests/diag_env.sh > busted-env.txt
  ```

**Zero-install fallback** if the diagnostic files cannot reach the failing
setup — the stock TAP handler, filtered clear of the app's log lines (those
start with an ANSI escape, TAP rows never do):

```sh
busted tests -o TAP 2>/dev/null \
  | grep -aE '^(ok |not ok |#|1\.\.)' > busted.tap
```

Verified here: 1001 lines out, zero polluted rows, failure diagnostics
carried on the `#` lines. It loses the env fingerprint and the tracebacks,
which is the only reason it is the fallback and not the first choice.

Container baselines for all of these are attached to this session's
investigation
(`baseline.txt`, `env-container.txt`); the container fingerprint is
LuaJIT 2.1.1703358377 / busted 2.3.0 / luassert 1.9.0-1 / penlight 1.15.0 /
luautf8 0.2.1, locale `POSIX`, `luarocks` tree at Lua 5.1.

## Hypotheses tested and eliminated in the container

Both were tested by checking the submodule out at the older commit, running
the full suite, and restoring the pointer (suite re-confirmed at 990/0/0/10
afterwards):

1. **Stale `src/lib/metalua` submodule.** This branch *does* bump it —
   `0c4c30de` on `master` → `d0dbd0d9` here (the `ast_to_src` comment/
   emptyline work) — so a checkout that never ran `git submodule update`
   after switching branches was the leading candidate. Reproducing it gives
   **3 failures, and 18 tests that never run**, not 107. Still a real
   divergence and worth ruling out in the owner's setup, but it is not this
   defect on its own.
2. **Stale `src/util/string` submodule** (`ff9be4b` — "use already present
   utf8"). The pointer is identical on both branches, so only a stale
   *working copy* could differ. Rolling back to `3662789` changes nothing
   here (**990/0/0/10**) — the container has the `luautf8` rock installed, so
   the older `require`-based path resolves anyway. **Not eliminated in the
   owner's setup**: if that rock is absent there, this path fails and the
   older-vs-newer submodule state becomes observable.

## What the divergence is not

The container tree is clean against HEAD (`git status --porcelain -- src
tests` empty), so no uncommitted source difference explains it from this
side. The only non-tracked things under `src/`/`tests/` are `src/STEPS.md`,
the three nested example repos (known non-anomalies), a stale vim swap file
from a July rename, and the two diagnostic files added above.

Neither hypothesis survived the owner's report anyway: their run shows
1000 collected tests, the same total as here, so nothing was mis-collected
and no submodule state affected which tests exist.

## Owner's environment, for the record

PUC Lua 5.1 (`/usr/bin/lua5.1`, `jit=none`, **no LuaJIT installed**), busted
2.2.0, luassert 1.9.0, penlight 1.14.0, lfs 1.8.0, luautf8 0.2.0, luarocks
3.8.0 with both a system and a `--local` rock tree carrying the same
versions. Container, for contrast: LuaJIT 2.1.1703358377, busted 2.3.0,
luassert 1.9.0, penlight 1.15.0, lfs 1.9.0, luautf8 0.2.1.

Only the first line matters. The rock-version spread is real but incidental:
forcing the arg-drop under the container's own rocks reproduces the failure
set exactly, so nothing is left for the version differences to explain.

## Disposition

**It is a feature defect, not merely an environment one**, though its blast
radius today is small:

- **Production, LÖVE desktop:** unaffected — LÖVE 11.5 ships LuaJIT.
- **Production, Web build:** unaffected — `_G.web` selects the `pcall` path,
  which is correct for the reason it was written.
- **Any PUC-5.1 host that is not the Web build:** every project input
  handler is called with nil arguments. Today that host is the test runner;
  it is latent for anything else.
- **The suite:** green is interpreter-dependent, which the PR's baseline
  claim does not survive. A suite that passes on the author's machine and
  fails on the reviewer's is a defect on its own terms, independent of the
  production reading.

Done: fix landed with its breaking tests, `T-XPCALL-GUARD` recorded and
retired, and the falsified premise in "The Web build has no coverage"
corrected in place.

Open: **the suite baseline moves 990 → 992**; `agents/validation.md`'s
fallback line and the successor prompt take the new number at wrap. The two
diagnostic files (`tests/diag_output.lua`, `tests/diag_env.sh`) stay
untracked until the owner's own machine reports green, then are deleted.
