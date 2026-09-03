---
description: can #77 be built on top of upstream PR #45 and ship with it — a trial merge, run and measured, with the collisions named
status: active
audience: developer
authored: llm
session: 70
date: 2026-09-03
---

# Building #77 on top of upstream PR #45

**The question, owner 2026-09-03:** *"We may build our PR on top of #45 so they ship
together. Difference between #45 and edge can be shipped afterwards but we should
ensure no fundamental conflicts."*

**Answer: no fundamental conflict.** Nothing in the input API's own machinery
collides. Everything that collides is the **editor route's key semantics**, where
#45 deliberately redefines what Enter, Escape, typing and Ctrl+S do — and our
specs pin the behaviour it replaces. That is a bounded set of behaviour decisions,
not an architectural disagreement, and every one of them has an owner who can
answer it in a sentence.

This is measured, not reasoned. A trial merge was performed, resolved, and **run**.

## How it was measured, so it can be redone

A **throwaway clone outside `/repo`** — never a worktree under it, so the `lua-lsp`
workspace was not polluted and the shared tree never held a merge:

```sh
git clone --no-hardlinks --local /repo trial && cd trial
cp -r /repo/src/util/string/. src/util/string/     # submodule, not cloned
cp -r /repo/src/lib/metalua/.  src/lib/metalua/     # submodule, not cloned
git fetch origin refs/remotes/upstream-pr/45:refs/heads/pr45
git merge --no-commit pr45
```

**Note for anyone repeating this:** `src/util/string` and `src/lib/metalua` are
**git submodules**. A fresh clone of `/repo` fails 38 specs with
*"module 'util.string.string' not found"* until they are populated. That is the
clone's problem, not the merge's.

Baselines, all three run in the same container (LuaJIT 2.1 — **the owner runs PUC
Lua**, so none of these is a their-machine claim):

| tree | suite |
|---|---|
| ours, `wip77/20260903/head` | **1055** / 0 / 0 / 10 |
| PR #45's own branch, `16eb33d7` | **753** / 0 / 0 / 0 |
| the trial merge, resolved as below | **1100 / 22 / 0 / 10** |

## The resolution taken, and what it deliberately did not decide

`git merge` conflicts in **4 files**. The resolution below is a *probe*, not a
proposal — it was chosen to make the tree runnable so the **failures** could be
read, and two of its four choices are exactly the decisions a real merge owes.

| file | resolved as | is this the real answer? |
|---|---|---|
| `tests/mock.lua` | both sides' exports kept | **yes** — a trivial union |
| `src/model/input/userInputModel.lua`, `set_text` | **ours**, with their `edit_history:reset()` prepended | **yes, and it is measured** — see below |
| `src/model/input/userInputModel.lua`, `new()` | ours plus their `editing` flag: `new(cfg, eval, custom_label, editing)`; their two positional call sites updated | **mechanical** — theirs is `new(cfg, eval, oneshot, custom_label, editing)`, and the `oneshot` it keeps is the **pre-existing** positional that is present at our PR base too, not the retired `auto_hide` predecessor |
| `src/controller/editorController.lua` | **theirs**, wholesale | **no** — a probe. It is their subsystem and their rewrite is a superset, but it drops our edits in that file |
| `src/controller/controller.lua` | **ours**, wholesale | **no** — a probe, and it is the direct cause of several failures below |

### The `set_text` choice is the one that was tested both ways

Ours keeps `normalized_lines`; theirs does its own `sanitize_utf8` + `string.lines`
and assigns `self.entered` **only when the string has exactly one line**.

- ours + their history reset → **1100 / 22**
- theirs + their history reset → **1094 / 28**, and the six extra failures are our
  own `input_cursor_text_spec`, `input_widget_control_spec` and
  `user_input_model_spec` cases — the `BUG-01`/`BUG-02` content contracts.

**The 16 editor failures are identical under both**, so `set_text` is not what
breaks the editor. Keep ours; add their one-line history reset.

## The 22 failures, read

### Six are ours, and all six are the editor route

| spec | what it pins | what #45 does instead |
|---|---|---|
| `input_routing_spec:105` — *editor mode routes text to the editor* | typing reaches the editor's widget | typing in **navigation** submode does not insert; the editor now has explicit nav/edit modes |
| `input_widget_callbacks_spec:990` — *editor Escape loads instead of cancelling* | Escape loads the selection and does not clear | Escape is `discard_edit` / `close_buffer` under the mode rules |
| `input_widget_callbacks_spec:1063` — *Alt+Enter, an unclaimed variant* | submits to nobody, leaves the text alone | Enter handling is rewritten around `force_accept`, `accept_block` and Ctrl+Enter / Ctrl+Shift+Enter |
| `input_widget_callbacks_spec:1084` — *Shift+Enter inserts a line-feed* | as stated | same rewrite |
| `input_global_shortcuts_spec:234` — *ctrl+shift+s finishes the edit* | `EditorController` handles it | #45 moves it **into the framework block** in `controller.lua`; our probe took `--ours` there, so nobody handles it |
| `input_global_shortcuts_spec:250` — *ctrl+s closes the buffer* | as stated | **a real disagreement**: #45 reserves bare Ctrl+S for the **checkpoint** (its spec 2.6), makes saving automatic and leaving `Shift+Esc` |

Only the last is a genuine two-answers-one-key conflict. The other five are our
specs asserting an editor that #45 replaces on purpose — they are **re-pinned, not
reconciled**, and by the author of the rework rather than by us.

**One convergence worth naming:** our `D-EXACT-RESERVE` work chose the
`ctrl+s` / `ctrl+shift+s` pair as its worked example of *a reservation claims its
combo exactly, not extensions of it*. #45 independently uses the same pair with
different meanings. The merge must decide both members, and our exactness rule is
what makes deciding them separately legal.

### Sixteen are theirs, and they are the probe's own fault, not a defect

All 16 are `editor_spec` navigation and wrap cases. Three things rule out the
obvious suspects: **PR #45's branch is green on its own** (753/0/0), the failures
are **identical** under either `set_text`, and adopting **their** `tests/mock.lua`
wholesale does not fix a single one of them (it adds 145 errors in our specs
instead — the two harnesses are not interchangeable, which is itself worth
knowing). What remains is the probe's `--ours` on `controller.lua`: their editor
work reaches into the framework's power-shortcut block, and taking our side
wholesale removes it.

**A real merge does not choose a side in `controller.lua`.** Ours restructured that
block into a `RESERVED` table (`D-RESERVE-TABLE`: a privileged table, consulted
before any route, which never consumes); theirs edited the old inline shape. The
work is to express #45's editor reservations **as entries in our table** — which is
what the table exists for, and is the one piece of real integration this merge
needs.

## What this means for the plan

- **Basing on #45 is viable and the cost is small and bounded**: one integration
  point (`controller.lua`'s reserved block), one mechanical signature merge, one
  key-meaning decision (bare Ctrl+S in the editor), and a re-pin of five editor-route
  specs that #45 is entitled to change.
- **The set_text question is settled by measurement**, and it settles in our
  favour — worth saying in the PR, because it is the only place where two
  implementations of the same function met and one is demonstrably more complete.
- **Nothing in `compy.input` moved.** The public surface, the routing grid, the
  hooks/shortcuts tables, the widget's configuration and every non-editor
  lifecycle case pass unchanged in the merged tree. The feature's own claim
  survives the merge intact, and that is the answer to *"no fundamental
  conflicts"*.
- **The edge minus #45 remains separable**, as the owner expected: the edge adds 19
  commits beyond #45 (71 − 52), and its extra conflicts in the dry merge were
  `.gitignore`, `consoleModel.lua` and an add/add on `examples/colors/main.lua` —
  none of them input-API surface.
- **What this did not test:** the merge was resolved by a probe, so the 22 failures
  are an upper bound on the reconciliation, not a defect list. Re-run the trial
  after the real `controller.lua` integration; the number to beat is **0 failures
  with both suites present**, which nothing observed here says is out of reach.

## Standing caveat

Nothing was merged, committed or pushed in `/repo` or in any nested repository.
The trial lives in the session scratchpad and is expected to be deleted; the
commands above rebuild it in about a minute.
