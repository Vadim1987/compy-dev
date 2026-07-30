# S22 Terra outcome — R5 unknown `show` keys

## Result

Implemented the project-facing `compy.input.show(config)` boundary.
It now warns and removes every key outside this accepted table:

- `prompt`, `text`, `cursor`, `force`;
- `highlighter`, `validator`, `on_text_entered`, `on_limit_reached`.

The warning includes the rejected key and directs callers to the show
config table or `compy.input.callbacks`.  Thus retired `eval` and
`result` do not regain a compatibility path, and lifecycle callbacks
such as `after_submit` remain explicit callback-table assignments.

## Evidence

Added a public-lifecycle test that opens a real project overlay with
`eval`, `result`, and `after_submit` in `show`.  It asserts a warning
mentions each key and submits through the pre-existing direct
`after_submit` callback, proving the rejected callback was ignored.

The new test failed before implementation:

```
busted tests/input/input_widget_lifecycle_spec.lua
9 successes / 1 failure / 0 errors / 0 pending
```

It passed after the change:

```
busted tests/input/input_widget_lifecycle_spec.lua
10 successes / 0 failures / 0 errors / 0 pending
```

The complete input suite then passed:

```
busted tests/input
258 successes / 0 failures / 0 errors / 3 pending
```

The three pending rows are the established keyrelease, editor-pointer,
and project-touch routing rows in `input_routing_spec.lua`.

## Scope

Changed only `src/controller/consoleController.lua` and
`tests/input/input_widget_lifecycle_spec.lua`; no project docs were
edited because the queued API documentation migration owns that surface.
