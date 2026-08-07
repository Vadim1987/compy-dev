# session27 — report

**Commissioned:** receive the owner's smoke-test verdict, then act on it.
It became the session that turned 187 inline review remarks into a triaged
plan and executed the architectural half of it — three ratified decisions,
five defects, and a suite from 923 to **953 / 0 / 0 / 3**, green and stated at
every commit. 41 commits here, 2 in `examples/keyboard`. Nothing pushed.

The commission is `validation/prompts/S27-human-commission.md`. It is **not
finished**: steps (d)–(9) — slice reassembly, the comment sweep, and two
revalidation rounds — remain, along with the smoke-test findings.

## Outcome

**The owner's review was the input, and reading it as questions rather than as
a task list was the whole method.** Of the 187 remarks, the ones that mattered
most were phrased as questions and had answers the code had to supply. Two
would have caused a wrong change if executed literally.

**Three ratified decisions, all new:**

- **Decision 26 — every consumer receives LÖVE's own argument list.** The chain
  had been handing keyboard/text consumers a `(k, keys_pressed, isrepeat)`
  triple of its own invention while pointer channels got LÖVE's arguments
  untouched, so "uniform" held within a subset and broke at its edge. Now
  `keypressed(key, scancode, isrepeat)` end to end. Decision 9 is **tombstoned
  in place**, superseded, number kept.
- **Decision 27 — one combo vocabulary, the button as a trigger.** Pointer
  channels gained the shortcuts tier the guide had argued was impossible;
  `combo_string('*', keys)` had built triggerless class keys all along.
  `shortcuts.mousepressed['mouse2']` is a right-click.
- **Decision 28 — stopping is the framework's.** The framework owns
  `framework_before_exit` and calls the project's hook from inside it, in a
  pcall, reading nothing. Structural, not a guard.

**Five defects, each with a breaking test first:**

| defect | how it was found |
|---|---|
| `compy.input = {}` silently accepted, corrupting framework state while the project holds a plain table | audit sub-agent, outside its brief |
| a nil `before_exit` wedged the console — teardown abandoned at its first statement, so every later stop failed too | the owner's remark on the call site |
| a **raising** `before_exit` did the same, still open after the nil case was fixed | a test the owner's remark asked for |
| `always_shown()` guaranteed nothing — any `hide()` would have cleared it | the owner asking what enforces it |
| a reconfigure row that could not fail | the owner suspecting it, mutation proving it |

**The architectural movement landed in five commits** — signature unification,
one bindable-channel list, the pointer shortcut tier, the `before_submit` veto,
and the dispatch/wiring collapse that removed 183 lines with the suite
unchanged.

## What the owner overturned, and why it matters

Three times a landed decision was challenged, and twice the reasoning failed:

- **scancode** — I dropped it with `keys_pressed`. Pointer channels already
  pass LÖVE's list verbatim including `istouch`/`presses`, so dropping it made
  `keypressed` the sole exception to a rule the system already had. Restoring it
  *deleted* the gateway's last special case.
- **the button in the combo** — I argued it was already in the payload. That
  argument applies verbatim to the keyboard, where the key is also in the
  payload and is a trigger anyway; taken seriously it abolishes the shortcuts
  tier and restores `if button == 2`.
- **the `before_exit` guard** — held as a fix, but the owner replaced the whole
  approach: remove the call site's discretion rather than guard it again.

**The generalisable lessons are in
`validation/notes/S27-observations.md`** and are worth carrying: an argument of
the form *"X is already available elsewhere, so it need not be here"* proves too
much; and when a guarantee has failed twice in the same place, stop guarding it.

## Non-obvious points

- **The four `project_env.X = nil` lines are a sandbox boundary, not an export
  list.** I probed before deleting them as no-ops: `pre_env` carries
  `InputEvalText` as a real table and `project_env` does not, *because of those
  lines*. This is also why the triage's R135 was wrong to call the doc's
  "projects cannot install evaluator objects" stale.
- **Decision numbering is load-bearing.** 179 comments in `src/` and `tests/`
  cite decisions by number, so the ledger is pruned by tombstoning in place,
  never renumbering. Decision 11 already precedented it.
- **Two wrappers that looked trivial were not.** Removing
  `build_shortcuts_surface`'s `__index` makes every `shortcuts[event]` read nil
  and crashes teardown on every project stop. The one that *was* inert
  (`build_leaf_surface`) was deleted. Verdicts came from experiment — probe,
  remove, re-probe, restore — not from reading.
- **`hook_pointer` was not a leftover.** It installs nothing but still computes
  the `user_pointer` liveness flag. Renamed, not deleted; the name was the lie.
- **The `lua-lsp` MCP server was down all session**, parent and all three
  sub-agents. Every reference claim rests on grep. `handlers.userinput`'s
  deletion is the one that turns on a completeness claim.

## State at wrap

- Suite **953 / 0 / 0 / 3**. App boots clean under `xvfb-run love src`.
- Working tree clean apart from the owner's known untracked scratch.
- `examples/keyboard` has 2 new commits; `balloons` and `maze` untouched by me.
- **Slices are stale** — regenerated last at `264e0c6c`, and the tree has moved
  far past it. Set 4 also needs cutting as `4a`/`4b`/`4c` under the new rules.
- **The PR description is stale** — written before Decisions 26/27/28 existed.

## Open, and the successor's business

Full detail in `validation/reviews/S27-triage-and-plan.md` §4 (phase table).

1. **P8 tail** — R057 (three-surface grouping), R074/R078/R079 (merge and
   dissolve), R047, R063, R064, R069, R075.
2. **P9** — the five smoke findings (SM1–SM5) and the nested repos. Needs the
   real app; the three nested repos have **no automated tests**, so committing
   is not verification.
3. **P10** — decision-ledger pruning and the doc/vocabulary batches.
4. **P11** — the commission's own tail: comment sweep, slice regeneration, two
   cold revalidation rounds.
5. **Close-out** — PR description refreshed, then the owner's ruling on deleting
   `wip/77`.
