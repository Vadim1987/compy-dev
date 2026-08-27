> REMARK: too shy for major changes done -- rewired dispatching, unblocked event-handling, new topology with shortcuts/hooks.... many documentation and technical debt added. And version is 1.0.0-rc...

# Changelog

Protocol: `CURRENT_SCOPE` holds everything not yet released. When a version
ships, this section is emptied and its content moves down into a new
section named for that version. Released versions are listed below it,
newest first.

## CURRENT_SCOPE

### Removed

- **Breaking: the legacy text-input globals are gone, with no
  compatibility shim.** `input_text`, `input_code`, `validated_input`,
  `user_input`, and `write_to_input` no longer exist in the project
  environment. Move their work to `compy.input.show{...}` and a
  callback — see "Migration from the legacy globals" in
  `doc/input_api.md` for the replacement of each. `compy.singleclick`
  and `compy.doubleclick` are also gone; use
  `compy.input.hooks.singleclick` / `.doubleclick` instead.

### Added

- A new `compy.input` API for showing an input prompt and reacting to
  input events. `show`/`hide`/`configure`/`clear` replace the old
  polling globals with one call plus a callback
  (`on_text_entered`); no more re-checking a variable every frame to
  notice a submission.

- Projects can now bind keyboard, mouse, and touch shortcuts directly
  — `compy.input.shortcuts.keypressed['ctrl+s'] = function() ... end`
  — instead of hand-testing modifiers inside a catch-all handler.
  Modifier classes (`'alt+*'`, every Alt chord) are supported too.
  `compy.input.hooks[event]` gives one fallback function per event;
  a project's existing `love.keypressed`-style handler keeps working
  unchanged, seeded into the matching hook automatically.

- `compy.input.fn.ignore_repeat`, `.stop_here`, and `.side_run` let a
  binding declare how it handles key repeats and event propagation at
  the registration site, instead of every handler having to end with
  `return true`.

- `compy.before_exit` gives a project one chance to restore global
  device state it changed (such as key-repeat) before its run ends.

- A new project-author guide, `doc/input_api.md`, covers the input
  widget, the submit lifecycle, shortcuts and hooks, held-key
  reading, and the migration table for every retired global.

### Changed

- **Keyboard and text input are no longer blocked while an input
  prompt is open.** Previously, showing an input widget stopped a
  project's own `love.keypressed`/`love.textinput`/`love.keyreleased`
  handlers from running at all. Now the project keeps receiving its
  own events throughout, so a hotkey can work *while* the user is
  typing into a prompt.

- Showing and hiding the input prompt no longer tears it down and
  rebuilds it. What the project set stays set: the prompt label, the
  highlighter, the validator and the callbacks all survive a `hide()`
  and are still in place at the next `show()`. The typed text does
  not — a fresh `show()` starts with an empty field unless you pass
  `text`.

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
