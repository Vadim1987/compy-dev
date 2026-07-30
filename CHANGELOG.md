# Changelog

## Unreleased

### Changed

- Project input now uses separate `highlighter`, `validator`, and
  `on_text_entered` callbacks. Submissions are line arrays.

- `compy.input.show` and `compy.input.configure` raise on a key outside
  their config table, rather than ignoring it. This includes the retired
  `eval` and `result` keys, and lifecycle callbacks such as `after_submit`
  that belong on `compy.input.callbacks`. Calls that are no-ops because of
  the current state — `show` on an active overlay, mutations while hidden —
  still warn as before.

- While a project runs, keyboard and text input with no shortcut, hook,
  or shown input widget no longer accumulates in the hidden console.
  It stays in the project route and has no effect. An explicit future
  route participant could provide a different fallback if needed.
