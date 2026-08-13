# P-17-15 — prompt of record: a cold review of the maze/draw input migration

**Commissioned by:** the owner, 2026-08-13, session39. **Model: Opus, passed explicitly.**
**Deliverable (write it yourself):**
`doc/development/wip/77-new-input-api/validation/reviews/S39-P17-cold-review.md`

---

## What you are reviewing

`src/examples/maze` is a **nested repository** (its own remote, its own PR, **never pushed**), on
branch **`newinput-edge`**. It is a source root that emits **two** Compy programs, `maze` and `draw`
— read `BUILD.md` first, it explains the layout in a page.

Seven commits migrated its input onto the platform's `compy.input` API:

```
git -C src/examples/maze log --oneline dsent/dsent/dev..HEAD
```

**Review the delta as a whole — `dsent/dsent/dev..HEAD` — not commit by commit.** The upstream ref
`dsent/dsent/dev` (`b8cc436`) is the code as its authors wrote it, and is your baseline for every
"did this change behaviour?" question.

## Order of work — this matters, and it is why you were run separately

1. **Form your own view first.** Read `BUILD.md`, then the upstream at the baseline, then the diff.
   Decide for yourself what the migration did, what it changed for a player, and what looks wrong.
2. **Only then** read the step's own documents, to see what it *claims*:
   `validation/reviews/P-17-03-adoption-analysis.md`, `P-17-04-triage-and-substeps.md`,
   `validation/notes/P-17-00-platform-facts-for-the-editor-migration.md`, and the commit messages.
3. Report where your view and theirs differ. **A disagreement is the point of running you.**

## Measure, do not reason

Every previous cold pass in this sprint that merely inspected converged slower than the one that
built an instrument. You can run things:

- **The project's own suite and build check:**
  ```sh
  cd src/examples/maze && ./verify.sh          # expect: OK: build verified, 29 + 10 + 3 assertions
  ```
  This container has **`luajit` only** — no `lua`, no `luac`. `verify.sh` probes for them, so put a
  shim on `PATH` **somewhere executable** (`/tmp` here is `noexec`; `$HOME/.cache/…` works):
  `lua` → `exec luajit "$@"`; `luac` → `for f; do [ "$f" = -p ] && continue; luajit -e "assert(loadfile([[$f]]))" || exit 1; done`.
- **Build and run either program:**
  ```sh
  cd src/examples/maze && ./.compy/build /abs/out
  cd /repo && timeout 25 xvfb-run -a stdbuf -oL -eL love src play /abs/out/maze     # and /draw
  ```
  **The line buffering matters** — without `stdbuf` the timeout kill discards the output and a
  raising project looks healthy. Note the source root itself is **not** runnable; that is by
  upstream's design.
- **Write your own throwaway drivers.** `core_editor.lua` can be loaded head­less against a stub of
  `compy.input`; the game files cannot (they need `gfx`). Put scratch files outside the repo.
- **No keystroke can be injected and no game level can be reached in this container.** Say so where
  it limits you, rather than reasoning past it.

**Tag every finding `MEASURED` or `REASONED`.** A previous pass in this sprint wrote a design claim
from expectation, it reached shipped code, and one keystroke crashed the game.

## What you must NOT take on trust

The migration rests on four platform claims. **Check them in `/repo/src` yourself**, and at the PR
base `3256aac` where the claim is about what *changed*:

1. The gateway no longer gates on widget presence, so a project's shortcuts and hooks run while the
   input field is shown (the walk is shortcuts → hooks → widget).
2. `compy.input.show{}` over an already-shown field is ignored and **cannot** change the prompt even
   with `force`; `configure` + `set_text` is what changes a live field.
3. At the PR base the widget was **destroyed on every successful submit**, which is why the upstream
   code re-prompts the way it does.
4. A shortcut registered in top-level project code **survives** activation.

Also: the author's own harness claim. The editor flow was verified by a **stub of `compy.input`
written from reading the runtime** — so if that reading is wrong, the stub agrees with it. That is
the single weakest link in the step's evidence and you should attack it directly.

## Specific things to judge (not an exhaustive list — find what is not here)

- **The editor migration** (`core_editor.lua`, shared by both programs) — the largest change. Does
  every path a child can take still work: arm, submit, reject-and-correct, run-and-re-prompt,
  Tab-after-a-crash, entering a second level?
- **`Shift+Esc` as a combo, and `hide()` on the menu exits.** Is the teardown complete? Is anything
  else able to leave a field stranded?
- **The Tab family — eight registrations per program.** Is the set right? `side_run` rather than
  `stop_here` was deliberate, to keep the press reaching the field as before. `ignore_repeat` was
  deliberate too. Are both correct, and is anything now double-handled?
- **The three pieces of removed state** (`macro_state.shift_held`, `plan_held`, `tab_was_down`).
  Does any consumer still need what was removed? One stated widening exists — both Shift keys held,
  release one — judge whether it is acceptable, and whether there are others **not** stated.
- **`isrepeat` threading** through `love.keypressed` → `game_key` → `ctrl_pressed`. Direct-control
  levels are supposed to keep repeating; the plan buffer is not.

## The rules this work is judged against

- **The game's rules are not ours.** The test is *"would a player notice a difference?"* If yes it
  is out of scope, and should have been raised rather than done. Finding an unstated behaviour
  change is your highest-value output.
- **A narrowing is a change**: a binding that silently stops firing where a poll used to fire must
  be stated or not done.
- **Adoption is the point**, but a replacement must be justified on its own terms — renaming for its
  own sake is not a virtue, and neither is preserving old syntax where replacement is justified.
- **No comment in this repo may link to a platform doc** (`doc/…` paths, decision numbers). Naming
  the guide and a section is tolerated where it is really needed.
- **Comments are deliberately verbose right now** — compaction is a later pass, by owner ruling. Do
  not report verbosity as a defect; do report a comment that is *wrong*.

## Rules for you

- **Read-only. Touch no `.lua` file, and no git state anywhere** — no commits, no staging, and above
  all **no checkouts or branch switches** in `/repo` or any nested repo. `maze` is on
  `newinput-edge` deliberately and moving it destroys unpushed work. Building to an out-dir and
  running the app are fine; they do not modify the repo.
- **The `lua-lsp` MCP server is available** (definitions / references / diagnostics over a real AST
  of `/repo`). Grep to find candidates, then use it to resolve a symbol or prove who calls what —
  string search gives guesses, the LSP gives facts.
- Structure the deliverable as: **verdict** · **defects** (severity, each with what breaks and how
  it is reached) · **observations** · **what you measured and how** · **limits**. Plain Markdown,
  wrapped ~98 columns, no emoji.
- **Do not pad.** No finding is a legitimate result and should be said plainly if it is true.
