# S45 worker prompt of record — retire "overlay" from `src/` and `tests/`

Model: **Sonnet**, explicit. Spawned 2026-08-25 by session45 (parent: Opus).
Edits code comments and test-case names; **no git, ever**.

---

You are working in the LÖVE2D project at `/repo` (cwd), on feature #77's pre-PR
comment sweep (row P11).

## Absolute constraints

- **No git. Ever.** No `commit`, `add`, `stash`, `checkout`, `restore`,
  `reset`, `branch`, `clean`, `rm`. `git log` / `git show` reads only if you
  genuinely need history. The parent commits; you never do.
- **Do not change behaviour.** You are editing comment text and `it(...)` /
  `describe(...)` description strings. No logic, no control flow, no
  assertions, no renamed locals unless this prompt names the rename.
- **`busted tests` must report `968 successes / 0 failures / 0 errors /
  10 pending` when you finish.** Run it before you start, so you know the
  baseline is real, and again at the end. If the count moves, you changed
  something you should not have — find it and revert that edit.
- **Stay inside `src/` and `tests/`, and skip `src/examples/` and `src/lib/`.**
  The examples are separate repositories with their own authors and their own
  PRs; `src/lib/` is vendored. Their "overlay" uses are their own UI overlays,
  not this feature's vocabulary, and they are deliberately out of scope.

**Tooling:** a `lua-lsp` MCP server (defs / refs / diagnostics over a real AST
of `/repo`) is available. Use it to confirm what a symbol is before assuming,
and `sleep 1` after editing a `.lua` file before querying it again. `grep` is
the right opening move for finding candidate sites.

## The task

The word **"overlay"** is being retired from this feature's vocabulary in favour
of **"input widget"**. A doc-corpus pass already ran (session43, 96 of 130
occurrences changed, 34 kept with a stated reason each) — but its scope was
`doc/` only. **`src/` and `tests/` were never swept**, and about 72 occurrences
remain. That is your job.

### The rule, per site — this is a judgment call each time

Ask: **is this passage about the project-facing input widget, or about
something else that is genuinely an overlay?**

- **The project-facing input widget** (the text-solicitation surface a project
  opens with `compy.input.show`, the console's input line, the editor's input)
  → say **"input widget"**, or just **"widget"** where the sentence already has
  the context. This is the retirement.
- **Something else** → **leave it alone.** Three known cases, all verified, none
  of which you should touch:
  - `src/view/canvas/terminalView.lua` — the `overlay` **parameter** of
    `terminal_draw` is the console's own compositing layer. Not the widget.
  - `src/controller/controller.lua` — `reserved_overlay` and the `f10`
    reservation are the **FPS overlay**, a different thing entirely.
  - `tests/input/input_global_shortcuts_spec.lua` — "FPS overlay" for the same
    reason.
- **Where the console context genuinely needs the word** (a passage that is
  specifically about the widget being *drawn over* the console), the owner's
  ruling allows `input_widget_overlay` — but prefer saying it plainly. Use this
  sparingly and say in your report where you used it.

### What is in scope to edit

1. **Comment text** — the bulk of it.
2. **`it(...)` and `describe(...)` description strings** — e.g.
   `it('overlay: Ctrl+Enter submits')` → `it('input widget: Ctrl+Enter
   submits')`. These are prose that a reader of test output sees.
3. **Nothing else.** Do not rename functions, locals or fields. One rename was
   already done by the parent (`hide_overlay` → `hide_input_widget`); there are
   no others to do.

### While you are in there — two smaller things, same pass

- **A citation that no longer resolves is worse than none.** If a comment you
  touch cites a doc heading, check the heading still exists
  (`grep -n '^#' <the doc>`), and report any that do not. **Do not fix them
  yourself** — report them.
- **Do not compress or rewrite comments beyond the word change.** A separate
  compaction pass owns that, and the parent has already done the marked sites.
  Change what the vocabulary rule requires and nothing more.

## Deliverable

`doc/development/wip/77-new-input-api/validation/outcomes/S45-overlay-retirement-code.md`

1. **Numbers** — occurrences at start, changed, deliberately kept.
2. **The changed list** — `file:line`, before → after, grouped by file.
3. **The kept list** — every site you did not change, each with the one-line
   reason. This list is the part the parent will actually check, so make it
   complete: a site changed without a reason is a bug, and a site kept without
   a reason is worse.
4. **`input_widget_overlay` uses** — every one, with its justification.
5. **Anything you found but did not touch** — dangling citations, a comment
   whose claim looks false, a place where the word hides behind a synonym
   ("the overlay strip", "the floating input"). Report, do not act.

Finish by reporting: the three numbers, the suite line, and the deliverable path.
