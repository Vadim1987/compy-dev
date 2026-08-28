# session54 report — a defect found by the owner's machine, diagnosed and fixed

Session54 booted on a wait-for-human placeholder. The owner stepped it aside
before any commissioned task: `busted tests` gave **107 failures** in their
own development setup on this branch, **0** on the upstream branch there, and
**990 / 0 / 0 / 10** in the agent container. They asked for a way to capture
results machine-readably and hand the file over.

That is the whole session. No roadmap work was started.

## Outcome

**Root cause.** `src/controller/controller.lua`, `wrap` — the route-entry
error boundary — forwarded handler arguments through `xpcall`. That is a
LuaJIT/5.2 extension; PUC Lua 5.1 takes exactly two arguments and drops the
rest. The hazard was known and guarded, but on **`_G.web`**: a *platform*
test standing in for a *runtime capability*. The Web build is PUC 5.1, so the
guard held there. `busted` on PUC 5.1 is also PUC 5.1 and is *not* the Web
build, so it did not — and the owner's machine has no LuaJIT installed at
all. Every project route was entered with nil arguments: hooks never saw
their key or character, combos normalised against nothing, typed text never
arrived. Hence 107 failures, all under `tests/input/`, none elsewhere.

**Fix.** The branch was deleted, not re-guarded. `wrap` closes the arguments
over a nullary function and calls `xpcall(fn, on_error)`, which asks nothing
of the runtime — so the predicate that could be wrong stops existing. A
drafted capability-probe alternative was discarded in its favour as the
larger of the two. `select('#')` rather than `#args`, so an explicit nil
argument survives.

**Baseline moves 990 → 992** — two breaking tests, `input_route_lifecycle_
spec.lua`, "the boundary carries arguments on any runtime". They swap the
global `xpcall` for PUC 5.1's arity and drive a real keystroke, so they fail
on LuaJIT too without the fix.

**Confirmed on both machines.** Container: 992/0/0/10 on LuaJIT, and 992/0/0/10
with the global `xpcall` at PUC 5.1's arity for the whole run (883/109 there
before the fix). Owner's setup: 992 successes. The suite's green is now
interpreter-independent, which it had never been.

## Non-obvious points

- **The code comment at the defect stated the hazard verbatim.** What was
  wrong was the guard, not the knowledge. Reading the comment was what
  identified the bug in about a minute — after source analysis had spent
  much longer circling combo normalisation and `pairs` ordering.
- **The env fingerprint line settled it, not the failure list.** `jit=none`
  against `LuaJIT 2.1` was the whole diagnosis; the 107 names only confirmed
  the blast radius. The instrumentation that mattered was the cheap half.
- **`technical_debt/input.md` had asserted this was undetectable.** "The Web
  build has no coverage" claimed the suite runs on LuaJIT and concluded a
  PUC-5.1-only defect is invisible to every check the project runs. Both
  halves were wrong: the suite runs on whatever interpreter the developer's
  `busted` uses, and that entry's proposed lint (no bare `xpcall` with
  arguments) would not have caught this call, which sat on the guarded
  branch. Amended in place.
- **The first changelog entry framed the fix against the wrong baseline,
  and the owner caught it.** It described the change against this branch's
  recent state; a changelog is read against the last release. `master`
  carries the same `_G.web`-guarded `xpcall` verbatim — on PUC 5.1 an
  adopted `love.keypressed`/`textinput`/`keyreleased` and `love.update`'s
  `dt` already arrived nil there. So the feature **inherited** this defect,
  widened it to every shortcut/hook/widget, and supplied the first tests
  that could see it. Corrected in the changelog, the note and the retired
  debt entry. The general trap: a fix verified against the branch tip
  reads as a branch-introduced regression unless you check the base.
- **Two hypotheses died before the report arrived** — a stale `metalua`
  submodule (this branch does bump it; reproducing gives 3 failures, not
  107) and a stale `stringutils` one (no effect). Recorded because the
  metalua pointer divergence is real and will bite someone else.

## Artifacts

- `validation/notes/S54-suite-env-divergence.md` — the defect, opened,
  diagnosed and closed; carries the eliminated hypotheses and both
  environment fingerprints.
- `technical_debt/input.md` — `T-XPCALL-GUARD` recorded ACTIVE, then
  RETIRED; the falsified premise in "The Web build has no coverage"
  corrected.
- `CHANGELOG.md` — CURRENT_SCOPE had no `Fixed` section; this opened one.
- Commits: `dbb4ea8b`, `38a7a7ad` (diagnosis), `4e828e6e` (debt ACTIVE),
  `77845502` (fix + tests), `a69e81d2` (debt RETIRED), `08e70d6c` (note
  closed), `77111e11` (changelog), `28288d8c` (wrap), `19581cb4` (changelog
  correction, post-wrap).
- The two throwaway diagnostic files were deleted once the owner's machine
  reported green.

## Left open

- The commissioned thread: session53's carryover is untouched. Both of its
  revalidations passed clean, and the next validation/roadmap task is still
  the owner's to name.
- **Only one interpreter is ever exercised by any automated check.** This
  defect is the existing evidence for it. The debt entry stands.
