# S22 — G-1 upstream correction

This corrects `S22-G1-history-and-scope.md`, whose running-project
conclusion compared only the shipped tree.

## Upstream baseline

In `updev`, `set_handlers(userlove, CC)` replaced a keyboard/text
`love.<event>` callback only when the project defined a different
handler. A project with none therefore left the console default
callback installed. The raw `love.handlers.keypressed` and
`textinput` dispatcher sent events to a shown `user_input`, otherwise
called that installed callback. Thus during a running project with no
shown widget and no project handler, keyboard/text reached the hidden
console input; text accumulated and Enter could evaluate it.

## #77 behaviour

The current `set_handlers` unconditionally calls `occupy_keyboard`.
It installs `ProjectInputController` for all running projects, seeds
project handlers into hooks where present, and returns false/no-ops
when no shortcut, hook, or shown widget participates. There is no
fallback to the console. The current `no participant + hidden widget
mutates nothing` row tests this feature-new security change.

## Inspect

`inspect` was already the console debugger in `updev`: suspend set
`app_state='inspect'`, restored console callbacks, and evaluated in
the project environment. #77 preserves it. It is not the insecure
running-project fallback and does not require a future redesign to
resolve G-1's original concern.

## Recommended disposition

Close G-1 as resolved by #77: document the baseline→current routing
change, remove the misleading CONTESTED/deferred-redesign framing, and
keep the inspect test as characterized pre-feature debugger behaviour.
