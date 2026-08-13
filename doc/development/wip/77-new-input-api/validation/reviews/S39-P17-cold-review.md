# P-17 cold review: maze and draw input migration

## Verdict

Changes requested: the migration has one player-visible, unstated shortcut narrowing in both
programs. The editor migration, teardown, Tab conversion, held-state removals, and repeat threading
otherwise agree with the intended migration on the evidence available here.

## Defects

### Medium — `Shift+Escape` no longer accepts additional held modifiers

**MEASURED.** At `dsent/dsent/dev`, both programs handle every Escape press themselves and call
`on_escape()` whenever either Shift key is down. Their `is_shift_down()` tests only `lshift` or
`rshift`; it does not exclude Ctrl or Alt. Thus Alt+Shift+Escape and Ctrl+Shift+Escape leave a
direct-control game level just as Shift+Escape does.

The migration registers only the exact `shift+escape` combo in `maze_main.lua` and `draw_main.lua`.
The platform canonicalises the complete modifier set and performs an exact combo lookup before an
optional modifier-class lookup. With Alt held, the event is `alt+shift+escape`, not
`shift+escape`; with Ctrl held it is `ctrl+shift+escape`. Neither program registers either form or
a class binding. Its `hooks.keypressed` then drops all Escape keys, so a hidden field leaves the
player in the level. This is reachable immediately in any direct-control maze level and in Draw
when its field is hidden.

With an active Draw/editor field, Alt+Shift+Escape also falls through to the widget. The widget's
plain-Escape cancel path clears the draft when Ctrl is not held, so the former gesture neither exits
nor preserves the text. This contradicts the migration's stated reason for consuming the exact
Shift+Escape shortcut. Register the omitted modifier variants if preserving the prior predicate is
intended, or obtain and record an explicit owner ruling for the narrowing.

## Observations

- **MEASURED.** The gateway reaches the project route independently of widget visibility, and the
  route orders consumers as shortcut, hook, then shown widget. The new combinations therefore can
  reach an editor field before its terminal widget.
- **MEASURED.** An active `show{}` is ignored without `force`; its force path only applies text.
  `configure{ prompt = ... }` followed by `set_text(...)` is the correct live-prompt path used by
  `core_editor.lua`.
- **MEASURED.** At platform base `3256aac`, a successful project-widget submit was oneshot and
  emitted `userinput`; the gateway cleared the widget for that event. HEAD's submit flow leaves the
  widget shown unless a project callback hides it. The migration's explicit re-arm sites therefore
  reproduce the relevant lifecycle change.
- **MEASURED.** Shortcut tables are created before the project executes. Activation seeds only
  missing hooks and does not replace shortcut tables, so the top-level registrations survive.
- **MEASURED.** The core-editor driver exercised arm, successful submit, completion re-arm,
  rejection-with-text, and a failed-run gate against a minimal `compy.input` stub. It observed the
  expected show/configure/set-text calls and no completion re-arm after `ctrl_update` was cleared.
  The driver is corroboration only: the runtime facts it models were checked separately above.
- **REASONED.** `side_run(ignore_repeat(tab_progression))` is the right Tab shape. It preserves the
  old poll's edge semantics while letting the event reach the hook/widget; the explicit eight
  combinations preserve the old modifier-insensitive poll. Direct and plan control handlers have
  no Tab action after a progression reset, so no second game action is apparent.
- **MEASURED.** The deleted `macro_state.shift_held`, `plan_held`, and `tab_was_down` have no
  remaining references. The retained Shift-release edge still closes a macro recording. The
  two-Shift widening is real and was disclosed; I found no further held-state widening.
- **MEASURED.** `isrepeat` is passed from the maze key hook through `game_key` to `ctrl_pressed`.
  `plan_key` rejects repeats; `handle_key` ignores the extra arguments, preserving repeated direct
  controls.
- **REASONED.** `to_menu()` and `toDrawMenu()` are the only menu-exit sinks reached by the added
  gesture and by the existing typed exits / last-level path. Both now call `hide()`, so I found no
  other migrated path that strands a shown field over a menu.
- **MEASURED.** I formed the findings above from `BUILD.md`, baseline sources, and the complete
  delta before reading P-17-03, P-17-04, P-17-00, or the commit messages. They agree with those
  documents except for the omitted modified Shift+Escape variants; the prior material does not
  state or assess that narrowing.

## What I measured and how

- **MEASURED.** Ran `PATH=/home/agent/.cache/p17-15-bin:$PATH ./verify.sh` with external LuaJIT
  `lua` and compile-only `luac` shims. It passed: build verified, 29 + 10 + 3 assertions.
- **MEASURED.** Built both programs to `/tmp/p17-15-build.bojTIp` and started each through the
  prescribed `timeout 25 xvfb-run -a stdbuf -oL -eL love src play ...` command. Both emitted
  projects reached `Project play opened`; no Compy/Lua exception was printed before the deliberate
  time limit. ALSA and X shutdown diagnostics are host-environment noise.
- **MEASURED.** Compared the seven-commit nested-repository delta with `dsent/dsent/dev`, and read
  the required platform paths at HEAD and at `3256aac`. I also ran `git diff --check` on the delta;
  it reported no whitespace errors.

## Limits

- **MEASURED.** This container cannot inject keystrokes or enter a game level. It cannot directly
  observe Shift+Escape, Tab, macro recording, plan buffering, or editor typing inside a live game.
  The human smoke checklist remains necessary.
- **MEASURED.** The Lua LSP MCP endpoint was not exposed to this review session, so symbol facts
  were cross-checked with complete local searches and direct call-path inspection instead.
- **MEASURED.** This was read-only: no Lua file, git state, nested-repository branch, staging area,
  or commit was changed.
