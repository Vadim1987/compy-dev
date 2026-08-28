# S54 — suite passes in the container, 107 failures in the owner's setup

**Status:** OPEN — awaiting the owner's run report.
**Opened:** 2026-08-28 (session54, detour before the commissioned task).

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

## Next step (needs the owner)

Run both commands on the failing setup, on this branch, and hand over
`busted-report.txt` + `busted-env.txt`. The failing rows diff against the
container baseline directly, which turns "107 failures" into a named cluster
— and the cluster's shape (one spec file, one helper, or one assertion
idiom) is what identifies the cause.

Worth capturing at the same time, since it costs one more line each:

```sh
git submodule status            # expect the two pointers, no +/- prefix
git status --porcelain          # local edits masquerading as a defect
```

## Disposition

This is an **environment/reproducibility** defect, not a feature defect,
until the report says otherwise. It is nonetheless PR-relevant: a suite that
is green only on one machine is not a green suite, and the PR claims the
baseline. Both diagnostic files are deleted once the cause is found.
