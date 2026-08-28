# session54 — track

## 2026-08-28 boot

- HEAD `ad534984`, branch `feature/77-newapi-analysis-s20260615`.
- Tree: clean against HEAD; untracked = known scratch (`claude.sh`,
  `input-pr-slices.tar.gz`, `repos.txt`, `src/STEPS.md`, `worklog.md`,
  the three nested example repos).
- Baseline `busted tests` → **990 / 0 / 0 / 10**. Matches prompt.
- Fresh start (no prior `track.md`/`report.md` in session54).
- Prompt is a wait-for-human placeholder (session53 was a revalidation).

## Detour — owner-raised defect, ahead of any commissioned task

Owner: same branch, same command, **107 failures in their own dev setup**;
**0 failures on the upstream branch there**; green here. Asked for a way to
capture busted results machine-readably and hand the file over.

Mode: **research + analysis** (named per validation.md). No feature work.

- Built `tests/diag_output.lua` (busted output handler → report *file*, so
  the app's stdout logging cannot corrupt it) and `tests/diag_env.sh`
  (toolchain/git/submodule fingerprint). Both throwaway, both outside PR
  scope, deleted once the cause is known.
- Stock `json` handler is unusable on this suite: *"type 'function' is not
  supported by JSON"*, even on a fully green run. `TAP`/`junit` work but
  interleave with the app's stdout logging.
- Self-tested the handler against injected failure / error / file-load-error
  cases; temp specs removed, suite re-confirmed 990/0/0/10.
- Two hypotheses reproduced and **eliminated** in the container:
  metalua submodule rolled back to master's `0c4c30de` → 3 failures + 18
  tests not run (not 107); stringutils rolled back to `3662789` → no change.
  Pointers restored, suite green.
- Finding worth keeping regardless: this branch **does** bump
  `src/lib/metalua` (`0c4c30de` → `d0dbd0d9`) while `master` does not — a
  checkout that skips `git submodule update` diverges here and not upstream.
- Written up: `validation/notes/S54-suite-env-divergence.md`. OPEN, waiting
  on the owner's `busted-report.txt` + `busted-env.txt`.

### Owner delivered the reports (`broken-busted/`) — root cause found

- Their env: **PUC Lua 5.1, no LuaJIT installed**. That one line was it.
- All 107 failures under `tests/input/`, none elsewhere. 1000 tests
  collected either side, so nothing mis-collected — both submodule
  hypotheses dead on arrival.
- Cause: `controller.lua` `wrap` branches on **`_G.web`** to avoid PUC 5.1
  dropping `xpcall`'s trailing arguments. `_G.web` is a *platform* test
  standing in for a *runtime capability*; under busted-on-PUC-5.1 they come
  apart, so every project route is entered with nil arguments.
- The code comment at that branch already states the hazard verbatim. The
  guard, not the knowledge, is what was wrong.
- Reproduced **exactly**: forced the arg-drop in the container →
  883/107/0/10, and the 107 failing rows `diff` identical to the owner's.
  Reverted; suite re-confirmed 990/0/0/10.
- Fix drafted (capability predicate, one `select`/`xpcall` probe), **not
  applied** — src change in PR-prep, owner's ruling. Presented with the
  diff ready.
- Falsifies a premise in `technical_debt/input.md` ("the suite runs on
  LuaJIT"), and its proposed grep mitigation would not have caught this —
  the call is not bare, it is on the wrongly-guarded branch. Noted in the
  defect note; the debt entry itself is untouched pending the ruling.

### Owner ruled: record the debt entry first, then fix

- `4e828e6e` records `T-XPCALL-GUARD` as ACTIVE (minimal, owner's word),
  deliberately before the fix so there is an entry for the fix to close.
- `77845502` fix + two breaking tests. Chose to **delete the branch** rather
  than apply the drafted capability probe: closing the arguments over a
  nullary function asks nothing of the runtime, so the predicate that could
  be wrong stops existing. Simpler than the probe and strictly safer.
- `a69e81d2` retires the entry and corrects the falsified premise in "The
  Web build has no coverage" ("the suite runs on LuaJIT" — it does not).
- Whole suite re-run with the global `xpcall` at PUC 5.1's arity: 883/109
  before, 992/0 after. Plain run 992/0/0/10.
- **Baseline moves 990 → 992.** validation.md's fallback line + successor
  prompt take it at wrap.
- lua-lsp MCP was down (broken pipe, twice) — no AST check on the edit; the
  suite and the PUC-arity run are the evidence instead.

Behavioural note: the owner's instinct — "run it on my machine and hand you
the file" — was the whole diagnosis. The env fingerprint line settled in one
read what source analysis had been circling.
