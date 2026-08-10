# S35 — revalidating the dissolution specification, read cold by the session that must test it

_2026-08-10, session35, Part 1. Mode: research + analysis. Nothing in the tree was changed._

Session34 wrote the specification of Decision 30 across five persistent documents. This is the
check of that spec by the first reader who has to **act** on it: the tests come next, and a test
can only assert what the documents let a reader work out. Every claim below was verified in code.

**Intent (checklist item 1).** Session34's docs step was to write, ahead of the code, what the
project-facing guide teaches about held keys, what the internals guide says the matcher's shape
is, and what the ledger and the debt register record — with a `PENDING` marker on every passage
describing behaviour the tree does not yet have.

**Verdict.** The spec is sound and mostly complete: the guide teaches the right thing, the
internals section is concrete enough to write most of the tests from, the markers are honest, and
the ledger's tombstones hold. Three things need an owner decision or a sentence of spec before
the tests are written (F1–F3), one document was missed by the sweep (F6), and one class of
pre-existing citation rot is reported without proposing to fix it here (F8).

---

## F1 — the `gui` row is not only a platform decision; it blocks a test case

`Key` exports `ctrl()`, `alt()`, `shift()` and no `gui()` (`src/util/key.lua`, the export table at
the foot). The ruled shape has the builder call those helpers per modifier row, and
`Key.mod_triples` has four rows.

The session prompt frames this as a decision the **platform** step takes. It arrives one step
earlier than that: `tests/input/keys_pressed_spec.lua`'s seventh combo case, *"all modifiers:
ctrl alt shift gui"*, asserts `'ctrl+alt+shift+gui+s'`. Those seven cases are being **rewritten**
against a patched `love.keyboard.isDown`, and that one cannot be rewritten until the row has an
answer.

The options, with what each costs:

- **Add `Key.gui()`** — three lines, exactly symmetric with the other three helpers. Keeps the
  serialisation contract whole, keeps Decision 8's four-name precedence list true, keeps the test
  case, and keeps shape (b) uniform across all four rows.
- **Read the `gui` pair directly inside the builder** — no new export, but the builder is then
  half shape (b) and half shape (a), which is the asymmetry the ruling rejected.
- **Drop `gui` from the serialisation** — smallest code, but it retracts a ratified contract:
  Decision 8 names the precedence order `ctrl < alt < shift < gui`, `Key.mod_triples` carries the
  row, and the internals section session34 just wrote states the four-name order. It would also
  have to be said out loud in the guide and the ledger.

**Recommendation: add `Key.gui()`.** Nothing registers a `gui` combo today, so this is a decision
about consistency, not about a defect — and the cheap consistent answer is the one that leaves
every document already written still true.

## F2 — the platform step breaks the keyboard example, and the internals guide already describes it fixed

`src/examples/keyboard/input.lua` reads the dissolved surface twice: `INPUT.held` (`:57`) and
`modHeld` (`:109-110`, `local held = compy.input.keys_pressed; if held[a] or held[b]`).

`compy.input` is a frozen view whose `__index` is `function(_, k) return resolve(k) end`
(`consoleController.lua:455-460`), and the resolver is `if k == 'keys_pressed' … return
resolve[k] or methods[k]` (`:539-542`). Remove the branch and the read returns **nil silently** —
so `modHeld` indexes nil and **crashes**, on every frame that draws a key cap.

Two further facts make this more than an ordering nuisance:

- The internals guide's §"Key state" already says *"(`examples/keyboard` draws shifted key labels
  this way)"* — i.e. by device read. That sentence sits inside the blanket `PENDING` marker, so
  when the platform step clears that marker the sentence becomes an **unmarked falsehood** unless
  the example moves too.
- The heal (P9b) is ruled to run **after** the platform code, and whether the examples step must
  precede it is deliberately unruled. So on the current ordering the example stays broken across
  at least one step, possibly two.

The fix is two lines and is exactly what the new guide teaches — `love.keyboard.isDown(a, b)` —
which `src/examples/turtle/main.lua:34` and `src/examples/clock/main.lua:68` already do in-tree.

**Recommendation: the platform step carries it**, as its own commit in the nested repo. It is the
same concern (removing the surface), and it keeps the internals sentence true at the moment its
marker is cleared.

## F3 — spec gap: does a modifier's own press still serialise as `alt+lalt`?

Today the gateway writes `Controller.keys_pressed[k] = true` as its **first line**
(`controller.lua:788`), before anything dispatches — so when the triggering key *is* a modifier,
its own row is guaranteed to be in the string: pressing left Alt dispatches `'alt+lalt'`. Decision
21's class guard is built on that string existing: `find_shortcut` refuses to fall through to the
class key when `Key.is_mod(trigger)` (`projectInputController.lua:108-109`), precisely so that
holding Alt alone does not fire `'alt+*'`.

After the change the answer comes from the device instead. On real hardware the key is physically
down at press time, so the behaviour is preserved — but **no document says so**, and in tests it
is not automatic: the mock's `keystroke` sets modifier state *without* dispatching a keypress for
it (`tests/mock.lua:64-71`), so a test that wants `'alt+lalt'` must arrange both halves itself.

This is the one place where I could not tell what to assert from the documents. One sentence in
the internals section fixes it — that the trigger's own modifier row is answered by the device
like any other, so a modifier press still serialises with itself prepended.

## F4 — spec gap, smaller: what a project sees after `compy.input.keys_pressed` is removed

Verified: a **silent nil**, not a raised error (F2's mechanism). The guide says the field is
removed; nothing says what a project that still reads it gets. Worth one sentence and one test
case, because "returns nil, then the caller indexes it" is exactly how the keyboard example
fails.

## F5 — the `PENDING` markers, checked in both directions

Eleven markers: five debt entries, the project guide's §"Held keys", three in the internals guide,
one in the dispatch-layers guide.

**Every one names a claim that is genuinely not true yet** — the builder still takes the table
(`controller.lua:395`), the gateway still writes and clears it (`:788`, `:906`), the field still
exists (`:498`), the read-only view is still built (`:420-443`), and the sandbox still resolves it
(`consoleController.lua:539-540`). No noise markers.

One deliberate over-claim, in the safe direction: the §"Key state" marker covers *"this whole
section, every paragraph of it"*, and some paragraphs are already true today — the one describing
`dispatch` as the consumer, and Decision 26's argument-list statement. Session34 chose blanket
scope so a narrower inner marker could not read as ending it, which is right. The consequence for
the step that clears it: **re-read the section, do not assume the whole of it became true.**

## F6 — the sweep missed a fourth persistent document, and it is the heal's design of record

`doc/development/internals/examples/keyboard.md` names the dissolved surface in four places, and
carries no marker:

- `:19` and `:31` — "held-key state", "the held set" as a named framework surface;
- `:240` — a missing release "would otherwise leave it stuck in the held set, with nothing to
  clear it", which is a statement about the tracked set's failure mode and stops being true when
  the device answers instead;
- `:266-269` — the sharp one. A *suggested* design says confirming a win from `love.update`
  *"does read the held set, and that is legitimate: the rule's own question is 'is the player
  still holding the key', which the held set answers directly."* Under Decision 30 that
  recommendation points at a surface that will not exist, and the answer it wants is
  `love.keyboard.isDown` — which answers that question **better**, since it is the frame-time
  question the device is correct for.

This is the same class of find session34 made with the dispatch-layers guide, and it matters more:
this file is P9b's design of record, P9b now runs **after** the platform code, so it will be read
as guidance at a point when the surface it names is already gone. It is on no plan list.

## F7 — one more unmarked passage this sprint falsifies

`doc/development/tests.md:73` describes the mechanism/NFR guards as *"identity, allocation and
**held-key-table** checks"*. The tests step deletes exactly those. The plan already tracks the two
places naming `keys_pressed_spec` by filename (`tests.md:45`, `event_dispatch_layers.md:53`); this
third one is untracked.

## F8 — pre-existing citation rot, reported not fixed

Not session34's — `git log -S` puts every one of these in earlier doc commits — but the tests and
platform steps will be editing beside them, so they should not be trusted or extended:

| Citation | Where it actually is |
|---|---|
| `event_dispatch_layers.md` item 1: `controller.lua:873`, `:876`, `:877`, `:995` | `:785`, `:787`, `:788`, `:906` — off by ~88 |
| `user_input.md`: `controller.lua:1165-1166` (`user_is_interactive`) | `:1034`; the file is 1089 lines |
| `user_input.md`: `projectInputController.lua:74-86` (`dispatch`) | `:132-147` |
| `user_input.md`: `projectInputController.lua:203-213` | out of range; the file is 193 lines |
| `user_input.md`: `consoleController.lua:919-936` (`suspend`) | `:1240` |
| `user_input.md`: `consoleController.lua:1276-1289` (`stop_project_run`) | `:1349` |
| `technical_debt/input.md`: `controller.lua:1112-1113`, `examples/maze/main.lua:497` | both out of range |

Also: the internals guide claims an in-code `DEFERRED` marker above
`ProjectInputController:keypressed`. **`DEFERRED` appears nowhere in `src/` or `tests/`** — the
owner's own in-file REMARK beside that paragraph already suspects as much.

The plan's own citations, by contrast, check out: `find_shortcut` at
`projectInputController.lua:103-110` ✓, the sandbox plumbing at `consoleController.lua:829-830` ✓,
the write sites and the field ✓.

---

## Clean bills

- **The flag-shortcut teaching is true today.** `fn.side_run` exists (`consoleController.lua:503-509`)
  and returns `false`, so the binding runs and the event carries on — which is exactly what the
  new guide's worked example depends on.
- **"Ask the keyboard" is proven in-tree, not aspirational.** The project sandbox's `love` is the
  real table (the project env is a clone of the application env), and
  `examples/turtle/main.lua:34` and `examples/clock/main.lua:68` already call
  `love.keyboard.isDown('lshift', 'rshift')` with two arguments.
- **Ledger tombstones hold.** Decisions 13, 20 and 29 each carry *"— SUPERSEDED by Decision 30"*
  in the heading; 8, 21, 26 and 27 stand, as Decision 30 says they do. Decision 21's amendment
  note is accurate on both counts it corrects.
- **The mock's stated defect is real.** `isDown = function(k) return held[k] end`
  (`tests/mock.lua:30`) reads one argument, so `Key.ctrl()` — which calls
  `isDown('lctrl', 'rctrl')` — sees only the left key; and the `mods` token map (`:17-21`) has
  `C`/`S`/`M` mapping to left keys only. **No test can exercise a right-hand modifier today**,
  and the existing case *"ctrl+s from rctrl held"* would silently stop proving anything. The
  variadic fix is a genuine prerequisite, and the token map needs right-hand entries whose
  spelling is the tests step's own call (self-named tokens — `rctrl`, `rshift`, `ralt` — read
  best against `keystroke`'s split-on-`-` grammar).
- **The project guide has no other reference to the dissolved field** — the only occurrence in
  `doc/input_api.md` is inside the marker itself.

## Minor, no action asked

The debt entry *"The held-key surface is a table that cannot be iterated"* still says
*"`doc/input_api.md` states the limitation, so a reader is warned rather than surprised."* The
guide rewrite removed that statement, so the sentence is stale — inside an entry the platform step
**deletes** rather than edits, so it self-resolves.

## What the tests step needs before it can start

1. The `gui` ruling (F1) — it blocks a test case, not just the builder.
2. A decision on whether the platform step carries the keyboard example's two reads (F2).
3. One sentence of spec on the modifier-own-press string (F3), and optionally one on the
   post-removal read (F4).

F6 and F7 are doc work that can ride with the platform step; F8 belongs to the late comment/doc
sweep.
