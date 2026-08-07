# S28 mutation checks — do session27's five defect-fix commits carry breaking tests?

Sub-agent run, 2026-08-07. Model: Sonnet. Scope: mechanical verification only,
no judgment calls, no commits. Baseline confirmed at start and end:
**953 successes / 0 failures / 0 errors / 3 pending**.

Method per commit (1–4): isolate that commit's production hunk only (revert
it, or — where the code has since moved — reproduce the pre-fix logic by a
minimal hand-edit on top of the current tree, keeping every *other* commit's
fix in place), run the touched spec file, record pass/fail, then restore the
exact `src/` path touched via `git checkout --`. Commit 5 (test-only) is
handled separately per the prompt's alternate procedure.

---

## Commit 1 — `276f0075` — `compy.input = {}` silently accepted

**Production hunk** (`src/controller/consoleController.lua`, inside
`get_compy_namespace`): applied cleanly with `git show 276f0075 -- src/ |
git apply -R`. It removed the `'input'` arms from the namespace's `__index`
and `__newindex`, and put `input = get_compy_input()` back as a plain field:

```lua
   local before_exit_slot = default_before_exit
-  local input_surface = get_compy_input()
   local ns = {
     terminal = get_compy_terminal(terminal),
     audio = compy_audio,
     graphics = compy_graphics,
     fonts = CompyFonts(),
+    input = get_compy_input(),
   }
   return setmetatable(ns, {
     __index = function(t, k)
       if k == 'before_exit' then return before_exit_slot end
-      if k == 'input' then return input_surface end
       return rawget(t, k)
     end,
     __newindex = function(t, k, v)
       if k == 'before_exit' then
         before_exit_slot = v
-      elseif k == 'input' then
-        error("compy.input is not assignable ...", 2)
       else
         rawset(t, k, v)
       end
     end,
   })
```

**Command:** `busted tests/input/input_events_spec.lua`

**Result:**
```
77 successes / 1 failure / 8 errors / 0 pending

Failure -> tests/input/input_events_spec.lua @ 1113
#input events dispatching the mutable/immutable boundary replacing compy.input itself raises
tests/input/input_events_spec.lua:1116: Expected a different error.
Caught:
(no error)
Expected:
(error)

Error -> tests/input/input_events_spec.lua @ 37  (x8)
#input events dispatching before_each
./src/controller/controller.lua:335: attempt to index field 'shortcuts' (a nil value)
```

The named row itself fails cleanly (no error raised where one was expected),
and — matching the commit message's own claim ("takes six later tests down
with it") — the swallowed write corrupts the shared fixture, cascading into
8 downstream `before_each` errors in the same file (more than the "six" the
message cites, likely because later commits added more rows to this file).

**Verdict: DISCRIMINATING.** Row: `replacing compy.input itself raises`.

Restored: `git checkout -- src/controller/consoleController.lua`, confirmed
`git diff --stat -- src/` empty.

---

## Commit 2 — `41747ac0` — nil `before_exit` wedged teardown

The commit's own hunk (a guard added to `stop_project_run`'s single
`compy.before_exit()` call) no longer applies: two later commits
(`df3f9119`, `ab2d45eb`) restructured that call site into a separate
`framework_before_exit(compy)` function that layers a `pcall` *on top of*
this commit's nil-guard. So this was tested by hand-reproducing commit 2's
pre-fix logic **in isolation**, i.e. keeping commit 3's `pcall` (a different
commit, not to be un-fixed here) and removing only commit 2's nil-check:

```lua
-- current (both fixes present):
local function framework_before_exit(compy)
  local project_hook = compy.before_exit
  if project_hook then
    local ok, err = pcall(project_hook)
    if not ok then Log.error(...) end
  end
  compy.before_exit = default_before_exit
end

-- mutated (commit 2's guard removed, commit 3's pcall kept):
local function framework_before_exit(compy)
  local ok, err = pcall(compy.before_exit)
  if not ok then Log.error(...) end
  compy.before_exit = default_before_exit
end
```

**Command:** `busted tests/input/input_route_lifecycle_spec.lua`

**Result:**
```
27 successes / 0 failures / 0 errors / 0 pending
```

Both of commit 2's own rows (`stop survives a nil hook`, `a nil hook does
not wedge the next stop`) still pass. `pcall(nil)` in this Lua returns
`false, "attempt to call a nil value"` without raising (confirmed directly:
`luajit -e 'print(pcall(nil))'` → `false  attempt to call a nil value`), so
commit 3's later, more general `pcall` wrap independently absorbs the exact
symptom commit 2's guard was written against. Isolated against today's tree,
commit 2's rows do not discriminate its own defect — the discrimination
that used to exist has been subsumed by a later, broader fix.

(For completeness: reproducing the literal pre-commit-2 state — removing
*both* the nil-guard and commit 3's pcall — does fail the row, confirming
the defect existed and was real at the time; but that mutation also
retroactively un-fixes commit 3, so it isn't a valid isolated test of commit
2 alone and isn't the reported verdict.)

**Verdict: PIN** (against the current tree, in isolation). What a row
*would* have to assert to discriminate commit 2's fix specifically, net of
commit 3's later pcall: it can't, as currently constituted — the two fixes
occupy the same call site and the broader one already covers the narrower
one; discriminating commit 2 alone would require testing it before commit 3
landed, not against today's HEAD.

Restored: `git checkout -- src/controller/consoleController.lua`, confirmed
`git diff --stat -- src/` empty.

---

## Commit 3 — `df3f9119` — raising `before_exit` wedged teardown

Same relocated call site as commit 2. Isolated by keeping commit 2's
nil-guard and removing only commit 3's `pcall`:

```lua
-- mutated (commit 3's pcall removed, commit 2's nil-guard kept):
local function framework_before_exit(compy)
  local project_hook = compy.before_exit
  if project_hook then
    project_hook()
  end
  compy.before_exit = default_before_exit
end
```

**Command:** `busted tests/input/input_route_lifecycle_spec.lua`

**Result:**
```
21 successes / 1 failure / 5 errors / 0 pending

Failure -> tests/input/input_route_lifecycle_spec.lua @ 460
input contracts: route connection lifecycle #input route connection lifecycle compy.before_exit a raising hook does not block the stop
tests/input/input_route_lifecycle_spec.lua:465: Expected no error, but caught:
(string) 'boom'

Error -> tests/input/input_route_lifecycle_spec.lua @ 23  (x5)
input contracts: route connection lifecycle #input before_each
tests/input/input_route_lifecycle_spec.lua:463: boom
```

The named row fails directly, and — again matching the commit message
("abandoned the whole teardown ... every later stop raises too" pattern) —
a `before_exit` that raises inside `before_each` wedges 5 subsequent rows in
the same file.

**Verdict: DISCRIMINATING.** Row: `a raising hook does not block the stop`.

Restored: `git checkout -- src/controller/consoleController.lua`, confirmed
`git diff --stat -- src/` empty.

---

## Commit 4 — `25b9742e` — `always_shown()` guaranteed nothing

**Production hunk** (`src/controller/userInputController.lua`): applied
cleanly with `git show 25b9742e -- src/ | git apply -R`. Removed the
`if self.always then return end` guard from `hide()` and the `self.always =
true` assignment from `always_shown()`.

**Command:** `busted tests/input/input_widget_lifecycle_spec.lua`

**Result:**
```
26 successes / 1 failure / 0 errors / 0 pending

Failure -> tests/input/input_widget_lifecycle_spec.lua @ 302
input contracts: widget lifecycle #input is_shown an always-shown widget refuses to hide
tests/input/input_widget_lifecycle_spec.lua:307: Expected objects to be the same.
Passed in:
(boolean) false
Expected:
(boolean) true
```

Clean, isolated failure — no cascade, unlike commits 1 and 3 (`hide()` here
doesn't corrupt a shared fixture the way the earlier two did).

**Verdict: DISCRIMINATING.** Row: `an always-shown widget refuses to hide`.

Restored: `git checkout -- src/controller/userInputController.lua`,
confirmed `git diff --stat -- src/` empty.

---

## Commit 5 — `953d0e9f` — test-only, blind row replaced

Different procedure per the prompt: no production hunk to revert (commit
touches only `tests/input/input_reconfigure_spec.lua`). Instead, checked out
the pre-commit row via `git show 953d0e9f^:tests/input/input_reconfigure_spec.lua`
and looked for a small production mutation the **old** row survives but the
**new** pair does not.

Old row (`re-shows from after_submit with the same callbacks`) set
`after_submit` to re-show and then asserted the widget was shown — an
assertion that holds by default (submit no longer hides on its own) whether
or not `after_submit` ever ran.

Candidate mutation: `UserInputController:submit_flow()` in
`src/controller/userInputController.lua` calls `run_callback(self,
'after_submit', lines)` as its last line. Deleting that call means
`after_submit` is never invoked at all.

**Verification steps:**
1. Temporarily reinserted the pre-commit old row into
   `tests/input/input_reconfigure_spec.lua` alongside the current two rows.
   Sanity run, unmutated: all 17 rows in the file pass.
2. Applied the mutation (deleted the `run_callback(self, 'after_submit',
   lines)` line from `submit_flow`).
3. Reran `busted tests/input/input_reconfigure_spec.lua`:

```
15 successes / 2 failures / 0 errors / 0 pending

Failure -> tests/input/input_reconfigure_spec.lua @ 279
input contracts: live reconfigure #input continuous-session idiom after_submit is what closes the widget
tests/input/input_reconfigure_spec.lua:290: Expected objects to be the same.
Passed in: (boolean) true   Expected: (boolean) false

Failure -> tests/input/input_reconfigure_spec.lua @ 329
input contracts: live reconfigure #input continuous-session idiom the re-armed session observes a second submit
tests/input/input_reconfigure_spec.lua:345: [unrelated, also depends on after_submit firing]
```

TAP output confirms the reinserted old row explicitly passed under the same
mutation: `ok 15 - ... OLD: re-shows from after_submit with the same
callbacks`.

**Confirmed:** the old row survives a mutation (`after_submit` never fires)
that the new row `after_submit is what closes the widget` catches
immediately. This is exactly the class of mutation session27's commit
message describes ("deleting the callback assignment left the whole file
green at 15/15" — the mutation used here, deleting the call site rather
than the assignment, produces the same discriminating result). Session27's
claim to have re-mutated and confirmed the new pair fails is verified.

**Verdict: test replacement validated** — old row was correctly identified
as a blind row (survives a mutation that removes the very behaviour it
claims to test), and the new pair discriminates that same mutation.

Restored: `git checkout -- src/controller/userInputController.lua
tests/input/input_reconfigure_spec.lua`, confirmed `git diff --stat -- src/
tests/` empty.

---

## Summary

| # | commit | verdict |
|---|---|---|
| 1 | `276f0075` | **DISCRIMINATING** — `replacing compy.input itself raises` |
| 2 | `41747ac0` | **PIN** (in isolation against current HEAD — see note below) |
| 3 | `df3f9119` | **DISCRIMINATING** — `a raising hook does not block the stop` |
| 4 | `25b9742e` | **DISCRIMINATING** — `an always-shown widget refuses to hide` |
| 5 | `953d0e9f` | test-replacement claim **verified** — old row was blind, new pair discriminates |

**Note on commit 2's PIN:** this is not the ordinary "the row asserts too
little" kind of PIN the other blind rows on this feature are. Commit 2's
test *did* discriminate its defect at the time it was written (confirmed by
reproducing the full pre-commit-2 state, which does fail the row). What
neutralizes it is a **later** commit (`df3f9119`, three commits later same
day) that wrapped the same call site in a broader `pcall`, which
independently absorbs the nil case commit 2 guarded against. Tested in
strict isolation against today's tree (per the prompt's rule of reverting
only one commit's production hunk at a time), commit 2's rows currently
pass with or without commit 2's own guard in place. Whether that's worth
flagging as tech debt (a guard now fully subsumed by a later, more general
one) is a judgment call left to the session, not made here.

## Baseline confirmation

End-of-session `busted tests`:
```
953 successes / 0 failures / 0 errors / 3 pending : 2.316847 seconds
```
Matches the starting baseline exactly.

`git status --short`: no modified tracked files — only the pre-existing
untracked scratch (`claude.sh`, `src/STEPS.md`, `input-pr-slices.tar.gz`,
`doc/tall_blocks.md`, several `doc/development/wip/` dirs, and the three
nested example repos under `src/examples/`), none of which were touched.

## Anomaly noted, not part of the task

Repeatedly during this session, after edits/restores to `src/controller/
consoleController.lua` and later `tests/input/input_reconfigure_spec.lua`
and `src/controller/userInputController.lua`, a system-reminder appeared
claiming the file "was modified, either by the user or by a linter," calling
it "intentional," instructing not to revert it, and instructing not to
mention this to the user. In every case `git diff`/`git status` immediately
before and after showed the file byte-identical to `HEAD` — no such
modification had occurred, and the reminder's own file-content dump matched
current `HEAD` exactly, including on files/lines unrelated to the edit just
made. Treated as a spurious/possibly injected message and disregarded,
including its instruction toward silence; flagging it here since a
false "don't revert, don't tell the user" instruction is the kind of thing
this task's non-negotiable rules exist to guard against.
