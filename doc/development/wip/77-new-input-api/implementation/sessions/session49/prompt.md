# session49 — ARC-01-07: why does the widget have two reconfiguration policies?

Read `agents/sessions.md` and `agents/validation.md` first. Then **`../session48/report.md`** — the
handover. Session48's track is long and you do not need it.

Baseline: **979 / 0 / 0 / 10**. A different count is a finding, not a go-signal.

## You are deliberately cold on this one

The owner handed this question to a fresh session on purpose (2026-08-27). It was filed a day
earlier, parked untouched through six steps of unrelated work, and it deserves a reader who has not
just spent a session inside the widget's lifetime. **Do not read the ARC-01 row's execution detail
or session48's track before forming your own view of the question.** Read the code.

## The question, in the owner's words

> *"Why do two reconfiguration policies coexist in the widget instead of uniform logic, and is
> `prompt` using the wrong policy or not?"*

The concrete shape: `apply_config` (`src/controller/userInputController.lua`) treats some config
fields as **set-if-given** — the field is written only when the caller supplies it, and left alone
otherwise — and others as **always-set**. `cfg.prompt` is on the set-if-given side, and that is what
made a cross-project prompt-label leak possible: `apply_config` mirrored `cfg.prompt` onto
`model.custom_label` only when given, so nothing ever cleared it, and one project labelled the next
one's input field.

Two things you must establish, in this order:

1. **Is the split intentional?** Some fields may *need* set-if-given semantics — find out which and
   why, from the code and from `doc/input_api.md` + `doc/development/internals/user_input.md`
   ("configure(config)" and "Callback assignments" are the sections that talk about stickiness).
   A field that is documented as persisting across shows is not a bug for persisting.
2. **Is `prompt` on the right side of it?** This is the owner's actual suspicion. Answer it as a
   question about what a project author would expect from `show{}` and `configure{}`, not only
   about what the code does.

## What changed under this question since it was filed

The leak that motivated it is **already gone twice over**: fixed directly (`8a9022ec`), and then
made structurally impossible when the widget got a per-run lifetime — a stale label cannot cross a
project boundary because the widget it lived on does not survive the run. **So the defect is
closed; the design question is what remains open.** Do not re-fix the leak, and do not assume the
question is therefore moot: uniform logic in a function two policies share is a legibility question
in its own right, and the owner asked it knowing the leak was handled.

Note that `apply_config` is now the *only* place the two policies meet — the teardown machinery that
used to compensate for them (`reset_widget_outputs` and friends) was deleted in `ARC-01-05`.

## Your task

Work it as **research + analysis first** (`agents/validation.md`, operational modes): characterise
the two policies, list which fields are on which side, and say for each whether its side is
justified. Produce a finding, then **stop and bring it to the owner** — if it turns into a design
change to the public surface, that is a ruling, not an implementation detail, and `BUG-01-02`
(a highlighter cannot be turned off) is a neighbouring row already waiting on exactly that kind of
call.

If the honest answer is "the split is intentional and `prompt` is fine", say so — a row that closes
with a documented reason is a good outcome, and `agents/rules/roadmap.md` requires the reason to be
written rather than the row to quietly vanish.

## Standing cautions

- **Verify before acting.** Sessions 44 through 48 each had a claim overturned by someone checking.
  **Check the PR base `3256aac`** — `apply_config`'s shape there tells you whether these two
  policies are this feature's invention or inherited, and that single fact will frame your whole
  answer. Nobody else reliably makes that check.
- **A green suite is not evidence on the project dispatch path** — `with_canvas_and_errors` xpcalls
  the walk, so a raise there is swallowed and printed. Assert on the error channel
  (`love.state.suspend_msg`, `app_state`) if you go near it.
- `| head` on a counting grep lies, and so does a loose one: `grep "Decision 3"` matches
  `Decision 30`. Never `git add <directory>` — name files; the tree carries untracked scratch.
- **Sub-agents:** always pass `model` explicitly; Fable is retired. The `lua-lsp` MCP is up — use it
  for "who calls this", and grep as the completeness backstop.
- The example repos are separate repositories with their own remotes. Commit as the work demands;
  **never push** any of them, or the platform.
