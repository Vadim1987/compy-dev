# S27 — P0 evidence: the S0 items, checked against code and the PR base

Phase P0 of `../reviews/S27-triage-and-plan.md`. Every claim here was settled by
reading the tree or `git show 3256aac:<path>` (the PR base), not by inference.
Recorded before any fix, so the fixes can cite it.

---

## R033 / R171 — `handlers.userinput` is dead, and **this feature killed it**

**Verdict: CONFIRMED dead. It is our orphan, not a pre-existing one.**

`controller.lua:933` binds `local handlers = love.handlers`, so
`handlers.userinput` (`controller.lua:1143`) installs a handler for a
**custom, non-LÖVE event name**. It runs only if something pushes that event.

Nothing pushes it. At the PR base, something did:

```
3256aac:src/model/input/userInputModel.lua:815  love.harmony.utils.love_event('userinput')
3256aac:src/model/input/userInputModel.lua:819  love.event.push('userinput')
```

Both push sites are gone in the current tree (the "widget-owned callback
sequences" rework removed them — two surviving comments at
`userInputModel.lua:844` and `:875` still refer to "the old `push('userinput')`
block"). The handler at the other end was left installed.

This is the same failure mode as `wrap_handler` in session26: a consumer left
standing after its producer was deleted. **Action: delete the handler**, and
the two comments that describe the removed block by what it no longer does
(which `agents/rules/commenting.md` forbids independently).

**Severity: S2**, not S0 — dead code cannot misbehave. Recorded here because the
question was raised as one.

## R044 — `always_shown()` and the whole `shown` flag are this feature's

**Verdict: the owner's premise is CONFIRMED. It was not used pre-feature —
because none of it existed pre-feature.**

At the PR base, `userInputController.lua` (543 lines) has **no** `self.shown`,
no `is_shown()`, and no `always_shown()`. Its nearest concept is
`is_oneshot()` (`3256aac:src/controller/userInputController.lua:25`). Whether a
widget was live was decided by whether `love.state.user_input` was set at all,
not by a flag on the widget.

So `always_shown()` exists to paper over a distinction the feature introduced:
console and editor widgets are permanently mounted, a project's widget is
transient, and once shownness became a flag rather than an object's existence,
the permanent ones needed a way to say "always". Four real call sites:
`consoleController.lua:43`, `editorController.lua:12` and `:16`,
`tests/helpers/input_fixture.lua:258`.

The owner's second question — what stops something else resetting the flag —
stands: nothing does. `always_shown()` sets `self.shown = true` once
(`userInputController.lua:459`); any later `hide()` on that instance would clear
it.

**This is the same question R080 asks from the other end** (is the widget a
special chain tier, or an ordinary participant?). Both are about whether
"shown" is the right primitive. **Severity: S1, and they should be ruled on
together**, not separately as the triage currently has them (R044 in W7, R080 in
W6).

## R068 — the reconfigure row is green and blind. **Confirmed by mutation.**

**Verdict: CONFIRMED. The owner is right; the test proves nothing.**

`tests/input/input_reconfigure_spec.lua`, "re-shows from `after_submit` with the
same callbacks" asserts the widget is visible after a submit, with
`after_submit` re-showing it. Since submit no longer hides the widget, the
assertion holds whether or not `after_submit` ever runs.

Mutation check — replace the callback assignment with a comment:

```
input.callbacks.after_submit = function() input.show({}) end   →   -- MUTATED
```

`busted tests/input/input_reconfigure_spec.lua` → **15 successes / 0 failures**,
unchanged. (Mutation applied and verified as a 1-line diff, then reverted; the
working tree is clean.)

The row's own comment claims it asserts "(b) the widget is active again once
`after_submit` returns" — that is the part it cannot distinguish. **Action:**
replace it with the closure-on-submit shape the owner proposes (hide from
`after_submit`, assert it went away), which *is* discriminating, and check the
sibling row ("the re-armed session observes a second submit") the same way
before trusting it.

**Severity: S0.** A test that cannot fail is worse than no test, and this is the
fourth instance of the pattern on this feature.

---

## Still open in P0

The smoke-test findings SM1, SM3, SM4, SM5 are not reproduced yet — they need
the app under `xvfb-run love src`, not the suite.
