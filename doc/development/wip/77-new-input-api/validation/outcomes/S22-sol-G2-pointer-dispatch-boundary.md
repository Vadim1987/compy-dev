# S22 Sol consultation — G2 pointer-dispatch boundary

## Recommendation

Choose **1: alias-to-hook installation only**.

Seed `compy.singleclick` / `compy.doubleclick` into
`compy.input.hooks.singleclick` /
`compy.input.hooks.doubleclick` when the corresponding hook is
unset. Keep delayed delivery inside the existing pointer-local click
mechanism, reading the selected hook directly.

A tiny private local function may remove duplication between the
single- and double-click timer branches. It should remain an
implementation detail of click delivery, not become a reusable
dispatch abstraction and not live on `ProjectInputController`.

This gives G2 one structural registration location without pretending
that derived clicks share the keyboard/text route semantics.

## Why this is the right boundary

`ProjectInputController.dispatch` exists to walk three ordered
consumers:

1. a combo shortcut;
2. a per-event hook;
3. the shown text widget.

Derived clicks have only one of those consumers. The timer has already
decided which semantic notification exists, and there is no widget
fallback or second consumer after the project hook. A hook return value
therefore has nothing to consume.

Calling a one-function lookup a reusable "dispatch" helper would add a
name without adding policy. Putting it on `ProjectInputController`
would be actively misleading: that controller is connected and
disconnected with the keyboard/text route, while pointer handlers stay
live until project stop. Pointer-only projects rely on that different
lifecycle in `user_is_interactive()`.

The useful unification is discoverability and ownership:
`compy.input.hooks` is the one structural place to find project input
hooks. The delivery mechanisms need not be isomorphic.

## Why not the full three-consumer dispatch

Extending the full walk would invent three contracts that #77 does not
need:

- a combo token and normalization rule for a delayed semantic gesture;
- shortcut precedence for that gesture;
- a `singleclick` / `doubleclick` text-widget consumer.

The last is especially unsound. The widget already receives the raw
mouse press, move, and release synchronously for cursor placement and
drag selection. Sending it a derived click again after the delay would
either call a nonexistent method or require a new widget API with no
behavioural purpose.

The raw pointer gateway is intentionally a broadcast: the widget and
project `love.mouse*` handler both receive the event. Changing it to a
truthy-consume chain would alter selection and project pointer
behaviour. G2 has no reason to reopen that boundary.

## Buttons and modifiers

The current click detector increments its counter only when
`btn == 1`. Consequently:

- `singleclick` means a confirmed **primary-button** click;
- `doubleclick` means a confirmed **primary-button** double click;
- neither notification represents M2/right-button input.

The Paint example's `doubleclick` calling `point(..., 2)` is an
application choice: it maps a primary-button double-click gesture to
its secondary paint action. It is not evidence that the event carried
button 2. The hook should preserve the existing `(x, y)` signature.
Adding a constant `button = 1` would imply a general multi-button
gesture API that does not exist.

M2 and modifier-specific pointer actions belong on raw
`love.mousepressed` / `mousereleased`. Sapper already demonstrates
this split: unmodified delayed gestures use the `compy` aliases, while
Shift+M1 and Ctrl+M1 act through `love.mousepressed`.

The delayed callbacks currently inspect `Key.shift()` / `Key.alt()` /
`Key.ctrl()` at **delivery time**, not release time. Building
`alt+singleclick`-style shortcuts would make that timing ambiguity
part of a new public contract. Correct modifier chords would require
capturing a modifier snapshot at release, which is a separate
behaviour change. G2 should preserve current timing and leave
modifier-sensitive actions on the raw path.

## Timing, dragging, and touch

Preserve the existing click-accounting behaviour:

- primary-button release updates `click_count`, the 0.4-second timer,
  and `click_pos`;
- delivery occurs from `love.update`;
- the current drift check still decides whether to notify;
- the hook receives the same coordinates the alias receives today.

Do not move hook delivery to `mousereleased`; that would collapse the
single/double distinction and change latency.

Do not route mouse press/move/release through the new click hooks.
Those synchronous events drive input-widget cursor placement,
drag-selection, and release-selection, and independently reach the
project's raw LÖVE handler. Their broadcast and ordering stay intact.

Touch also stays unchanged. The raw touch gateway remains separate,
and the widget's touch methods remain the current stubs. The existing
mouse-release code does not filter the `touch` flag; G2 should neither
add nor remove touch-derived mouse-click behaviour incidentally.

## Concrete execution consequences

The bounded implementation should:

1. add the two click leaves to the existing hooks table;
2. seed aliases once, unset-only, after project installation;
3. make explicit hooks win over aliases;
4. let liveness recognize either resulting click hook;
5. let delayed pointer-local delivery fetch that hook and invoke it
   through the existing project error/canvas wrapper;
6. clear both click hooks at teardown with the other hook leaves;
7. preserve raw mouse, drag, selection, touch, timing, coordinates,
   and return-value behaviour.

Tests should prove direct-hook delivery, alias seeding, explicit-hook
precedence, primary-button-only accounting, delay, drift suppression,
teardown, and pointer-only liveness. A negative M2 assertion is useful
because it prevents the new structural name from being mistaken for a
general button abstraction. No shortcut or widget test should be
added for derived clicks.

## Judgment

G2 should stop at structural hook ownership plus alias installation.
That resolves the public-shape incoherence. Extending dispatch would
turn a small discoverability fix into a new general pointer model,
while the current code and both real consumers support a much narrower
contract.
