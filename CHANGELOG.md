# Changelog

Protocol: `CURRENT_SCOPE` holds everything not yet released. When a version
ships, this section is emptied and its content moves down into a new
section named for that version. Released versions are listed below it,
newest first.

## CURRENT_SCOPE

> **This release breaks projects written against the previous one**, in two places, both
> detailed below. The legacy text-input globals are **removed with no compatibility shim**
> (*Removed*), and **`on_text_entered` now receives one string** instead of a list of lines
> (*Changed*) — the second is the quiet one, because a callback that indexed the old payload
> keeps running and starts reading `nil`. This is still a `1.0.0-rc` release and nothing
> before 1.0.0 promises a stable surface, so the break is announced here rather than in the
> number.

### Removed

- **Breaking: the legacy text-input globals are gone, with no
  compatibility shim.** `input_text`, `input_code`, `validated_input`,
  `user_input`, and `write_to_input` no longer exist in the project
  environment — nor does `astv_input`, which was only ever present in
  a debug build. Move their work to `compy.input.show{...}` and a
  callback — see "Migration from the legacy globals" in
  `doc/input_api.md` for the replacement of each. `compy.singleclick`
  and `compy.doubleclick` are also gone; use
  `compy.input.hooks.singleclick` / `.doubleclick` instead.

- **The four evaluator objects are no longer reachable from a project.**
  `InputEvalText`, `InputEvalLua`, `ValidatedTextEval` and
  `LuaEditorEval` were never documented as project API, but they were
  *there* — a project environment starts as a copy of the framework's
  own globals, and they came along with it. They are now withheld
  deliberately. What a project needs from them is exported instead, and
  narrower: `LuaHighlighter`, `LuaSyntaxValidator` and `LineValidators`
  are in the project environment and go in the `highlighter` and
  `validator` keys of `compy.input.show`.

### Added

- **`auto_hide`** takes the input widget down after a successful
  submit, so a project that just needs one answer writes a single call
  with a prompt and a callback and installs nothing else. It is the
  `after_submit = function() compy.input.hide() end` you would
  otherwise write, as a key — and it is a **mode, not a one-off**:
  `show` and `configure` both set it, and it stays in force for every
  later submit until a call passes `auto_hide = false`. Escape still
  clears without closing; see "Asking one question" in
  `doc/input_api.md`.

- **`compy.input.get_text()` (experimental) reads the widget's current
  content** and may be withdrawn — see "Live changes" in
  `doc/input_api.md`. While it is here, a project no longer has to wait
  for a submit to find out what the user has typed — a timeout can take
  whatever has been entered so far, and a hotkey can act on the text in
  place. It answers one string with `\n` between lines: the spelling
  `on_text_entered` receives, and the one `set_text` takes back unchanged.
  An empty widget answers `''` and a hidden one answers `nil`, so the two
  never look alike. With `get_cursor()` it also makes saving and restoring
  content across a `hide()` two calls — see "hide()" in `doc/input_api.md`.

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

- **Breaking: `on_text_entered` now receives the submitted content as
  one string**, lines joined with `\n`, instead of a list of line
  strings. `after_submit` is unchanged and still receives the list, and
  that difference is now what tells the two callbacks apart — before,
  both were handed the same argument and nothing distinguished them.
  **Migrating:** a callback that joined the payload itself
  (`string.unlines(lines)` as its first statement) needs no change at
  all — joining a string returns it unchanged. A callback that indexed
  it (`lines[1]`) **must** drop the index, and will otherwise **fail
  silently**: indexing a string yields `nil` rather than raising.
  Dropping the index is not behaviour-preserving either, and the
  difference is also silent: `lines[1]` took the **first** line, while
  the new argument is **all** of them. A callback that parses what it
  receives — `tonumber(text)`, or a lookup keyed by it — now gets `nil`
  where a multi-line submission used to give it the first line. Prompts
  that only ever hold one line are unaffected; Shift+Enter is what makes
  any widget multi-line. A consumer that genuinely wants the lines has
  `after_submit`. See "Submit lifecycle" in `doc/input_api.md`.

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

- **Which behaviour you get is now yours to set, not implied by the
  call you made.** Colouring, the submit gate and what runs on a
  successful submit used to be bundled into the choice between
  `input_text`, `input_code` and `validated_input`; they are three
  independent, optional keys — `highlighter`, `validator` and
  `on_text_entered` — so a plain prompt with a filter, or a coloured
  one with no gate, is now expressible.

- `compy.input.show` and `compy.input.configure` raise on a key outside
  their config table, rather than ignoring it. This includes lifecycle
  callbacks such as `after_submit`
  that belong on `compy.input.callbacks`, and — at `configure` — `text`,
  `cursor` and `force`, which are `show`'s. Each raise names where the key
  belongs. Calls that are no-ops because of the current state — `show` on
  a widget that is already shown, mutations while hidden — still warn
  as before.

- `show` and `configure` are one configuration path, split by who owns the
  field. Your content (`text`, `cursor`) is `show`'s alone; everything the
  project sets (`prompt`, `highlighter`, `validator`, `on_text_entered`,
  `on_limit_reached`) is applied by both, only when named, and stays until
  replaced. `false` unsets any of them. There is no longer a key that one
  call applies and the other silently drops or defers.

- `show{force = true}` is now a full re-setup rather than a text-only
  patch: it applies every key you pass, and with no `text` it starts
  empty. It previously applied `text` alone, kept the content when `text`
  was absent, dropped `prompt`, and deferred `highlighter` to a later
  call. Pass the content if you want it kept.

- `configure` while the input prompt is hidden applies immediately and
  stays in force, instead of stashing `prompt`/`text`/`cursor` for the
  next `show` to spend once. `text` and `cursor` are no longer accepted
  there at all — pass them to the `show` that brings the widget up, which
  runs before anything is on screen.

- Assigning `compy.input.callbacks.highlighter` on a widget that is up now
  takes effect at once. It previously did nothing until an unrelated later
  `show`/`configure` happened to flush it.

- A malformed `cursor` is refused with a message naming the expected
  `{line, col}` shape, instead of failing with a raw Lua error from inside
  the framework. Out-of-range positions are unaffected and still clamp.

- A bad config key passed to `compy.input.show` now reports your own `show`
  line. It previously pointed inside the framework, which named the mistake
  but not the call that made it. `configure` was already correct.

- While a project runs, keyboard and text input with no shortcut, hook,
  or shown input widget no longer accumulates in the hidden console.
  It stays in the project route and has no effect. An explicit future
  route participant could provide a different fallback if needed.

### Fixed

- **Setting the widget's content to a string with newlines in it now
  works.** `text` is documented as "a string or list of line strings",
  and the string form was written only when it held a single line, so
  `show{text = "a\nb"}` or `set_text("a\nb")` silently wrote nothing
  and left the previous content standing. This is longstanding, not
  new — the same guard is in the release this one branches from — but
  this release is the one that documents the shape and puts it on the
  project-facing surface, so the silent case is fixed rather than
  described.

- **Content that is not text is refused with a message you can read.**
  `show{text = …}` and `set_text` take a string or a list of line
  strings — a list meaning a dense run of strings from `1`. Anything
  else raises `compy.input.set_text: text must be a string or a list
  of line strings`, naming the call that failed. Previously a list
  element that was not a string was stored as it came and corrupted the
  display from then on, with nothing said at the point of the mistake.
  Convert with `tostring` where you want
  a number shown: the widget reshapes how content is *spelled*, but it
  does not guess what a non-text value meant. This is the treatment
  `cursor` already gets. (`false` is not a malformed value — it is the
  unset, and `show{text = false}` opens an empty field.)

- **The two spellings of that shape now mean the same thing.** A list
  element containing a newline used to be stored verbatim, so
  `set_text{"a\nb"}` gave one line holding a line terminator the widget
  counted as an ordinary character, while `set_text("a\nb")` gave two
  lines. Both now give two. The reason is the cursor: it addresses
  content as `(line, col)`, and a newline kept inside a line leaves
  `col` unable to say where you are — the same reason the widget
  already dropped invalid UTF-8 from content you set. Blank elements
  are content and still survive. Also longstanding, and it only became
  visible once the string form above was fixed.

- **A crash in a project's `love.update` or in a pointer handler no
  longer vanishes.** The error boundary called its message handler with
  the wrong number of arguments, so the report was assembled from a
  `nil` and raised *inside* the handler, where it was swallowed: no
  error window, no console line, and the run carried on as though
  nothing had happened. Keyboard handlers went down a different path and
  reported correctly, which is what made the gap easy to miss — the same
  project would show you one crash and hide another. This is
  longstanding, not new.

- **Project callbacks no longer lose their arguments on Lua runtimes
  without LuaJIT's `xpcall` extension.** The framework runs your code
  behind an error boundary that forwarded arguments through `xpcall`;
  where that is unsupported — PUC Lua 5.1 — every argument was dropped
  before your function saw it. This is longstanding, not new: `love.update`
  already received a `nil` `dt` there, and so did an adopted
  `love.keypressed` / `love.textinput` / `love.keyreleased`. This release
  routes far more through that boundary — every shortcut, every hook and
  the input widget — so the same loss reached all of them until now. The
  boundary closes over the arguments instead of forwarding them, and
  behaves identically on every runtime. Desktop LÖVE runs LuaJIT and was
  never affected; the Web build was guarded separately and was not either.
