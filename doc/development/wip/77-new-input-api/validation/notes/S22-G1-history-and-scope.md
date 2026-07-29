# S22 — G-1 history and scope

## Confirmed current behaviour

`inspect` is the console route bound to the paused project's
environment. `ConsoleController:suspend()` sets `app_state='inspect'`
and reinstalls the default console handlers. `get_user_input()` then
returns nil, so the project widget is unhonoured. The REPL is therefore
live debugging input, not hidden console capture.

While a project is `running`, keyboard/text handlers belong to
`ProjectInputController`, not the console. Its chain is shortcuts →
hooks → widget. A hidden widget reports not consumed; it does not
transfer the event to the console. The current test
`no participant + hidden widget mutates nothing` records that outcome.

When a non-blocking project returns to `project_open`, keyboard/text
are deliberately restored to the visible console route. That is not
eavesdropping during a running project.

## Consequence for the ruling

The historic concern that a hidden running-project widget silently
accumulated console input was investigated and narrowed away. It is
not a deprecated current behaviour with a pending replacement test.
The only live G-1 question is whether #77 should retain the
inspect-mode debugger status quo or commission a separate redesign of
the suspend/inspect route.

Sources: `src/controller/controller.lua` (`get_user_input`, project
route installation); `src/controller/consoleController.lua`
(`suspend`); `doc/development/internals/user_input.md` (Dispatch
chain); `doc/development/decisions/input.md` (Decisions 11–12).
