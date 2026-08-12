---
description: Cold inventory of what the upstream keyboard example must change to adopt the Compy input API
status: draft
audience: developer
authored: llm
reviewed: none
---

# P-18-00 — Cold adoption inventory: `src/examples/keyboard` @ `origin/dsent/dev`

**Upstream ref read:** `origin/dsent/dev` = `025e858` *"keyboard: clear the sky with the notch,
and land the first burner"*, read exclusively through `git show` / `git grep` against the ref. No
working tree of any repository was touched, no branch moved, and no `.lua` file was edited.

**Method.** Every game claim below is verified at `<file>:<line>` **at that ref**; every platform
claim is verified in `/repo/src` at the working tree (which is the platform as it now stands).
Comments were treated as claims to check, not as facts — three of them turn out to be wrong
(§2 G1, G3, G5).

**Scope discipline.** The test applied throughout is *"would a player notice a difference?"* Where
the answer is yes, the item is in §4 (raised, not recommended) or is flagged in place as a
**narrowing** per `conventions/input_adoption.md`, "A narrowing is a change".

**Counts.** §1: 26 sites across 11 files · §2: 7 gaps · §3: 14 leave-alone entries ·
§4: 9 raised · §5: 5 waves.

---

## 0. The through-line

Almost every site in §1 is one of three consequences of a single upstream structure: **`INPUT`**
(`input.lua:31-34`) — a table mirroring what the keyboard is doing, maintained by the
`keypressed`/`keyreleased` channel and read from everywhere else, including `love.draw` and the
`textinput` channel.

`INPUT` carries three jobs, and the API now answers each separately:

| `INPUT` field | job | replacement |
|---|---|---|
| `held[k]` (as a repeat test) | "is this keypress a repeat" | `isrepeat`, LÖVE's own third argument, now threaded end to end (§2 G1) |
| `held[k]` (as a glyph test) | "did this character come from a key that is still down" | the settled claim fix (§1.10) |
| `held.h` | "is H physically down right now" | `Key.any_pressed('h')` |
| `shift` / `ctrl` / `alt` | "is this modifier down right now" | `Key.shift()` / `Key.ctrl()` / `Key.alt()` |
| `upRecent` + `INPUT_UP_GRACE` | a frame clock standing in for a device read | deleted by the settled fix |

When all of §1 is applied, `INPUT`, `INPUT_UP_GRACE`, `modHeld`, `inputUpdateMods` and
`inputStale` are gone, and `isMod` becomes `Key.is_mod`. That is the whole shape of the adoption:
**the mirror is deleted and each of its readers asks the right source directly** — checklist Q1,
Q2, Q3, Q5 (`doc/development/conventions/input_adoption.md`), Decision 30, Decision 32.5.

The **settled** design decision handed to this inventory (do not re-derive): a character claims
its key when it is delivered to a scene; the claim is released by polling the device once per
frame — any claimed key that `love.keyboard.isDown` reports up is unclaimed. `INPUT.upRecent`,
`INPUT_UP_GRACE` and the release-handler's bookkeeping all go; nothing consults the other channel
and nothing consults a clock. Its two consequences are applied, not questioned: whoever consumes a
chord claims its trigger key, and `love.keyboard.isDown` stays in the game rather than
`Key.any_pressed` (owner's call, for minimising the change, with a comment pointing at the
platform's form).

> **Note on names.** `GLYPH_CLAIMED` and `spendGlyph` **do not exist at `origin/dsent/dev`** —
> verified: `git grep -n "GLYPH_CLAIMED\|spendGlyph" origin/dsent/dev -- '*.lua'` returns nothing.
> The upstream machinery they replace is `inputStale` (`input.lua:112-117`) plus `INPUT.held` /
> `INPUT.upRecent`. This inventory therefore names the *sites*, and refers to the claim table and
> its claim/release calls by the settled fix's names without assuming their upstream shape.

---

## 1. Per-site inventory, ordered by file

Mechanism key: **[hook]** `compy.input.hooks.*` · **[shortcut]** `compy.input.shortcuts.*[combo]`
· **[class]** a modifier-class combo · **[fn]** a `compy.input.fn.*` combinator · **[Key]** a `Key`
query · **[poll]** a device poll · **[settled]** the settled claim fix · **[none]** delete only.

### `input.lua`

**1.1 — `input.lua:1-30` (header comment).** Documents the event model. Three of its load-bearing
claims are false against the platform as it now stands: that the IDE *"strips the isrepeat flag"*,
that it *"delivers textinput BEFORE the matching keypress"*, and that no project-exit cleanup hook
exists. See §2 G1, G3, G2.
→ **[none]** Rewrite the header to describe the adopted model. *Rationale:* a deviation is stated
in the workspace, not only in a commit message (`input_adoption.md`, Rules of restraint). This is
the one comment edit that is not optional — the file's whole design story is told here, and the
settled fix contradicts it.

**1.2 — `input.lua:31-34`, `INPUT = { held = {}, upRecent = {}, shift, ctrl, alt }`.** A table of
keys currently down plus three booleans mirroring modifier state, written on every press and
release.
→ **[none] / [Key] / [poll]** Delete the table. Each reader is converted at its own site (1.5,
1.6, 1.7, 1.10, 1.11, 1.12, 1.13, and help/keyboard_view/alt below). *Rationale:* checklist **Q1**
— "Delete it; ask at the point of use"; a mirror has no reconciliation path. Decision 32.5.

**1.3 — `input.lua:36-38`, `INPUT_UP_GRACE = 1` (and its comment).** A frame budget during which a
just-released key still counts as held, so a trailing key-repeat glyph is swallowed.
→ **[settled]** Delete. *Rationale:* a clock standing in for a device read; the settled fix
releases claims by polling `love.keyboard.isDown`, which needs no grace window.

**1.4 — `input.lua:40-47`, `inputInit()`.** `love.keyboard.setTextInput(true)` plus five resets of
`INPUT`.
→ **[none]** Drop the five resets; keep line 41 (see §3.11). If the settled fix's claim table
needs a reset, it belongs here. *Rationale:* minimal edit; the function survives with one line.

**1.5 — `input.lua:49-54`, `modHeld(a, b)`.** `INPUT.held[a] or INPUT.held[b]` — a local
re-implementation of the left/right fold, over the mirror rather than the device.
→ **[Key]** Delete; its three call sites become `Key.ctrl()`, `Key.alt()`, `Key.shift()`.
*Rationale:* checklist **Q2** — "the fold ships already, and a local copy also hard-codes *which
keys are modifiers*". Verified equivalent: `src/util/key.lua:5-7` names exactly the same six key
names.

**1.6 — `input.lua:56-60`, `isMod(k)`.** Hard-codes the six modifier key names.
→ **[Key]** Replace the body with `return Key.is_mod(k)`, or delete and convert the six call sites
(1.20 and the five at 1.25). Verified equivalent: `Key.is_mod`
(`src/util/key.lua:147-149`) tests membership of the same `fold_mod` table built from the same six
names, and is exported at `src/util/key.lua:186`+.
*Rationale:* checklist **Q2** — a local copy hard-codes the modifier set, "a set that has changed
once" (Decision 31). **Caveat, raised in §4.6:** `Key.is_mod` is real and exported but is **not**
named in `doc/input_api.md` — the guide documents only `shift/ctrl/alt/any_pressed`. Replacing the
body (keeping the game's own name `isMod`) is the lower-risk of the two forms and is what this
inventory recommends: one line changes, five files do not.

**1.7 — `input.lua:62-66`, `inputUpdateMods()`.** Copies three device facts into `INPUT` on every
press and release.
→ **[none]** Delete, with its three call sites (`input.lua:127`, `:141`, and its own body).
*Rationale:* **Q1**. Nothing needs the copy once each reader polls.

**1.8 — `input.lua:82-100`, `reservedChord(k)` (+ `goBack()` at `:68-72`).** One function
demultiplexing three orthogonal combos by hand: `shift+escape and not ctrl` → `goBack()`;
`ctrl+alt+up` → `notchAdjust(1)`; `ctrl+alt+down` → `notchAdjust(-1)`. Consumes by returning true
(`input.lua:128`).
→ **[shortcut] + [fn]** Three registrations:

```lua
local fn = compy.input.fn
local sc = compy.input.shortcuts.keypressed
sc['shift+escape']  = fn.stop_here(fn.ignore_repeat(goBack))
sc['ctrl+alt+up']   = fn.stop_here(fn.ignore_repeat(function() notchAdjust(1) end))
sc['ctrl+alt+down'] = fn.stop_here(fn.ignore_repeat(function() notchAdjust(-1) end))
```

*Rationale:* checklist **Q8** — "Split into shortcuts, one per combo. That is what they are for".
`goBack`, `notchAdjust` and their guards are kept verbatim.

Three things this edit must get right, all verified:

- **`fn.ignore_repeat` is mandatory, not decoration.** Upstream these run *after* the repeat filter
  at `input.lua:124`, so a held Ctrl+Alt+Up notches once. Shortcuts dispatch does **not** gate on
  `isrepeat` (`internals/user_input.md:64`; `projectInputController.lua`'s `dispatch` has no
  `isr` test), so without the wrapper a held chord would notch every frame. That would be a rule
  change.
- **Ordering is preserved for free.** Upstream, `reservedChord` runs *before* the `PAUSED` and
  `helpOverlayShown()` gates (`input.lua:128` vs `:131-132`), so Shift+Esc and the notch chords
  work while paused and while help is up. Shortcuts run before the hook, so this survives
  unchanged.
- **Two narrowings, stated.** Upstream tests `INPUT.shift and not INPUT.ctrl` — it does **not**
  exclude Alt, so Alt+Shift+Esc goes back today and will not after. Likewise upstream tests ctrl
  and alt without excluding Shift, so Ctrl+Alt+Shift+Up notches today and will not after. A combo
  is its modifier set *exactly*. Neither gesture is documented anywhere in the game
  (`STR.back_hint` shows Shift+Esc; `git grep` finds no other mention), so this is judged
  acceptable — but it is a narrowing and is named here rather than hidden in a diff.

**1.9 — `input.lua:102-107`, `appChord(k)`.** "Alt+key without Ctrl is a chord, never a typed
target, so swallow it here"; Alt+P toggles pause, everything else is swallowed silently.
→ **[class] + [fn] + [settled]** One registration that is a near-verbatim transcription:

```lua
compy.input.shortcuts.keypressed['alt+*'] = fn.stop_here(function(k, _, isr)
  claim(k)                                   -- the chord owns its trigger key
  if k == "p" and not isr then pauseToggle() end
end)
```

*Rationale:* checklist **Q8**/**Q10** and Decision 21, which cites *this example by name*: "which
`examples/keyboard` did, and which needed an explicit *and not Ctrl* clause to keep `ctrl+alt+h`
out of the Alt class. A class gets that exclusion for free". Line 103's `if INPUT.ctrl then return
false end` deletes itself: `'alt+*'` is the Alt class *exactly*, so Ctrl+Alt+H still reaches the
scene (1.22) with no clause to maintain.

- `claim(k)` is the settled fix's first consequence — the consumer of a chord claims its trigger,
  so a trigger still held after its modifier is released does not start typing into the scene. It
  must sit **outside** any `ignore_repeat`, because a held chord's glyph repeats too.
- The Q8-purist split (`'alt+p'` exact + `'alt+*'` class, exact wins per Decision 21) is
  legitimate and costs one duplicated `claim(k)`. Either is defensible; the single binding is the
  smaller edit and is what is recommended.
- **One behaviour delta, raised in §4.4.** Upstream `appChord('lalt')` returns true — a bare Alt
  press is swallowed from the scene. Under the class form it is not: `find_shortcut`
  (`src/controller/projectInputController.lua:107`) returns early when the trigger is itself a
  modifier, so a bare Alt press names no shortcut and reaches the hook. Every game scene ignores
  modifiers explicitly (`not isMod(k)` guards, 1.20/1.22/1.24/1.25/1.26), and `menuKeypressed`
  no-ops on a non-numeric key — but **`introKeypressed` (`intro.lua:58-66`) finishes the
  typewriter on any key**, so pressing Alt alone during the intro would now snap it complete.
  Upstream, pressing Shift alone already does exactly that, so the delta is a consistency gain as
  much as a change; it is still a change and belongs to the owner.

**1.10 — `input.lua:109-117`, `inputStale(k)`.** THE settled site. Reads `INPUT.held[k]` (state
owned by the `keypressed` channel) and `INPUT.upRecent[k]` against `DBG_FRAME` (a frame counter),
and is consulted from inside `textinput` handlers (1.19, 1.23).
→ **[settled]** Replace with the claim check. `INPUT.upRecent`, `INPUT_UP_GRACE` and the
release-handler bookkeeping (1.12) go. The release poll runs once per frame over the claim table
against `love.keyboard.isDown`.
*Rationale:* settled; not re-derived here. The class of fault it fixes — one channel's state read
from another — is the class this inventory was asked to sweep for, and §1.19/§1.23 are its only
other instances.
**Placement, verified:** the per-frame release poll must run in `love.update`
(`main.lua:120-129`), **not** inside `updateStep` — `updateStep` returns early on
`not DREW_ONCE` (`:105`), on `PAUSED` (`:111`) and on `helpOverlayShown()` (`:114`), and a claim
that is not released while paused or while help is held would outlive its key.

**1.11 — `input.lua:123-135`, `appKeypressed(k)`.** Six of its thirteen lines are the mirror:

- `:124` `if inputStale(k) and k ~= "capslock" then return end` — the repeat filter.
  → **[hook] + [fn]** `isrepeat` is now LÖVE's own third argument, delivered unchanged to every
  consumer (verified: `src/controller/controller.lua:766` `handlers.keypressed = function(k, sc,
  isr)` and `:868` `return love.keypressed(k, sc, isr)`; `projectInputController.lua`'s `dispatch`
  forwards the varargs to shortcut, hook and widget alike; Decisions 9 and 26). The minimal
  behaviour-preserving edit keeps the capslock exemption verbatim:
  `if isrepeat and k ~= "capslock" then return end`. `fn.ignore_repeat` is the alternative but
  cannot express the exemption, so it does not fit here. Dropping the exemption is raised in §4.2.
  *Rationale:* checklist **Q4** — "did this just happen" is an event; the poll and its companion
  both go.
- `:126` `INPUT.held[k] = true` → **[none]** delete (**Q1**).
- `:127` `inputUpdateMods()` → **[none]** delete (1.7).
- `:128` `if reservedChord(k) then return end` → **[none]** delete (1.8).
- `:129` `if appChord(k) then return end` → **[none]** delete (1.9).
- `:130` `if k == "capslock" then capsToggle() end` → **[shortcut] + [fn]**
  `compy.input.shortcuts.keypressed['capslock'] = fn.side_run(capsToggle)`. `side_run`, not
  `stop_here`: upstream continues to the scene dispatch after toggling. **Q8**, lowest-value item
  in this section — leaving it in the hook is also defensible and is a smaller edit. If it is
  split, note that a shortcut fires on repeats where the hook (now `isrepeat`-filtered) does not,
  which reproduces upstream's capslock exemption exactly and lets `:124` become a plain
  `if isrepeat then return end`.
- `:131-134` `PAUSED` / `helpOverlayShown()` gates and the scene dispatch → **[none]**, see §3.4.

**1.12 — `input.lua:137-144`, `appKeyreleased(k)`.** `INPUT.held[k] = nil` (`:139`),
`INPUT.upRecent[k] = DBG_FRAME` (`:140`), `inputUpdateMods()` (`:141`).
→ **[none]** Delete all three; the function keeps `dbgLog` and the scene dispatch (`:143`), whose
only consumer is `bubble.lua:152`. *Rationale:* **Q1** plus the settled fix ("the release-handler's
claim bookkeeping … goes"). This is where the mirror's staleness was born: nothing here can
observe a release lost to focus change.

**1.13 — `input.lua:150-160`, `appTextinput(t)`.** Three mirror reads:

- `:152-153` `if INPUT.alt then return end` / `if INPUT.ctrl then return end` — drop a chord glyph.
  → **[Key]** `Key.alt()` / `Key.ctrl()`. *Rationale:* checklist **Q10**, second half — "For a
  query, spell the exclusion out and accept that it hard-codes the modifier set". A shortcut form
  is **not** available here: the condition is *alt or ctrl held*, which is six distinct modifier
  classes (`alt+*`, `ctrl+*`, `alt+shift+*`, `ctrl+shift+*`, `ctrl+alt+*`, `ctrl+alt+shift+*`);
  six registrations to express one predicate is worse than the predicate. Keep it a query, change
  only the source (**Q3**: route both through one surface).
- `:155` `dbgLog(... tostring(INPUT.shift))` → **[Key]** `Key.shift()`.
- `:157` `capsReconcile(t, INPUT.shift)` → **[Key]** `Key.shift()`. *Rationale:* **Q5** — "is this
  held right now" is the correct shape; only the source changes.
  **Flagged for the smoke pass:** `indicators.lua:22` claims the Shift state here is "edge-tracked,
  not isDown", i.e. the mirror's value at press time. `Key.shift()` answers about the device *now*.
  Decision 30 names and accepts the resulting error ("the clock this answers on"): with a press and
  a release queued in the same frame's batch, the poll can already see the modifier released. Caps
  reconciliation is the one place in this game where that error would be *visible* (the Caps decal
  and every letter keycap's case flip together), so this is the item most worth a human at a real
  keyboard — see §5.

### `main.lua`

**1.14 — `main.lua:92`, `love.mouse.setRelativeMode(true)`.** Suppresses the system pointer. The
comment claims *"the runner restores it on exit"*.
→ **[none]** + `compy.before_exit`. **The comment is false**, verified: the only
`setRelativeMode(false)` anywhere in `/repo/src` is `src/lib/error_explorer.lua:303`, a crash
path. `ConsoleController:stop_project_run` (`src/controller/consoleController.lua:1339-1350`)
calls `framework_before_exit(compy)` and never touches the mouse. The gap is now closable by the
project itself:

```lua
compy.before_exit = function()
  love.mouse.setRelativeMode(false)
end
```

*Rationale:* `doc/input_api.md`, "Stop hook — `compy.before_exit`": "It exists so a project can put
back global device state it changed imperatively". Verified to fire on Ctrl+Esc:
`controller.lua:883-890` (`keyreleased` → `love.event.quit()`) → `love.quit`
(`controller.lua:653-683`) → `CC:stop_project_run()` → `framework_before_exit`. This is a change to
what the *platform* is left holding, not to what the player of this game sees, so it is in scope.

**1.15 — `main.lua:160-170`, `love.keypressed` / `love.keyreleased` / `love.textinput`.**
→ **[hook]** **Keep them as `love.*` definitions.** They are auto-seeded as
`compy.input.hooks.keypressed/keyreleased/textinput` at activation (Decision 10;
`projectInputController.lua`'s `seed_hooks`, which runs *after* the project's top-level code, so
the shortcut registrations in 1.8/1.9/1.11 are already in place and are not disturbed). The only
edit is the signature, so the repeat filter of 1.11 can be fed:

```lua
function love.keypressed(k, sc, isrepeat)
  appKeypressed(k, isrepeat)
end
```

*Rationale:* "Every shortcut, hook and callback receives exactly the arguments LÖVE delivers …
A handler you already wrote as `love.keypressed` works unchanged when it becomes a hook"
(`doc/input_api.md`). Smallest possible edit, and it is the adoption that also keeps the game a
plain LÖVE program (the soft preference, at its recorded weight).

**1.16 — `main.lua:120-129`, `love.update` (and `DBG_FRAME` at `:18`, `:121`).** After 1.3 and
1.10, `DBG_FRAME`'s only remaining consumer is `dbgLog`'s line prefix (`main.lua:25`).
→ **[poll]** Add the settled fix's once-per-frame claim release here, outside `updateStep` — see
1.10's placement note. `DBG_FRAME` itself stays, as a log counter. *Rationale:* the release must
not be gated by `DREW_ONCE`, `PAUSED` or the help overlay.

### `help.lua`

**1.17 — `help.lua:10-12`, `helpHeld()`.** `return INPUT.held.h and INPUT.alt and not INPUT.ctrl`
— reads the mirror for a non-modifier key **and** two modifiers, in one expression, and is called
from `love.draw` (`help.lua:55` via `drawHelpLayer`), from `updateStep` (`main.lua:114`) and from
the keypressed/textinput gates.
→ **[Key]** One line:

```lua
return Key.any_pressed('h') and Key.alt() and not Key.ctrl()
```

*Rationale:* this is the canonical example in `doc/input_api.md`, "Choosing the mechanism"
(`peeking()`), down to the `not Key.ctrl()` clause — and the canonical *counter*-example
immediately above it is the mirrored `alt+h` press/release pair this game correctly did **not**
write. Checklist **Q1** + **Q2** + **Q3** + **Q5**: continuous state, polled, but from the wrong
source. Ctrl+Alt+H must keep missing this predicate (it is `alt.lua`'s hint re-arm, 1.22), which
the `not Key.ctrl()` clause preserves verbatim.
**Highest-value single line in the inventory:** a lost `keyreleased` for `h` (focus change,
notification, the Alt+Tab-shaped case) leaves `INPUT.held.h` true forever, and the help overlay
freezes the game behind it (`main.lua:114`, `input.lua:151/154`) with no way out but a fresh `h`
press-and-release. Polling cannot wedge.

### `keyboard_view.lua`

**1.18 — `keyboard_view.lua:284-288`, `capsEffectiveUpper()`.** `if INPUT.shift then return not
CAPS_STATE.on end` — decides the case every letter keycap is drawn in; called from `love.draw` and
from `alt.lua:243`.
→ **[Key]** `if Key.shift() then …`. *Rationale:* **Q5** — the correct shape (a draw-time question
about continuous state), wrong source. `doc/input_api.md`, "Held keys", rung 2, uses exactly this
shape (`draw_keycaps(Key.shift())`) and `internals/user_input.md:291` names *this example* as the
reason a project that renders held state has to poll.

### `alt.lua`

**1.19 — `alt.lua:186-187`, `altTextinput(ch)` → `if inputStale(altBaseKey(ch)) then return end`.**
The second cross-channel read: a `textinput` handler judging a glyph by `keypressed`-owned state.
→ **[settled]** The claim check. *Rationale:* settled (1.10). The comment at `alt.lua:178-185`
explains the behaviour it buys — a held wrong key not knocking every frame, a held right key not
bleeding a miss onto the next target, a chord's trailing glyph not fumbling the live target — and
**all three must survive**; they are rules a player experiences. The claim mechanism is what
preserves them.

**1.20 — `alt.lua:207`, `elseif not isMod(k) and k ~= "capslock" then`.**
→ **[Key]** Via 1.6 (`isMod` keeps its name, gains `Key.is_mod`'s body) — no edit at this site.

**1.21 — `alt.lua:216-220`, `altKeypressed`: `if k == "h" and INPUT.ctrl and INPUT.alt then`.** The
teacher chord Ctrl+Alt+H, hand-tested inside a scene handler.
→ **[Key]** Minimal edit: `Key.ctrl()` and `Key.alt()`. *Rationale:* **Q2**/**Q3** — route the
modifier questions through `Key`; the shape stays.
**Why not a `'ctrl+alt+h'` shortcut, which is what Q8 would want:** shortcuts are registered on
`compy.input.shortcuts`, which is **project-global**, while this binding is **scene-scoped** — it
must exist only in the `alt` scene. The scene registry (`scene.lua:31-58`) has an `enter` but no
`leave`, so scoping a shortcut would mean either registering it with an `ACTIVE == "alt"` guard
inside (which puts the demultiplexing back, just in a smaller place) or adding a `leave` hook to
the registry (a restructuring, out of scope). Raised in §4.3. Repeat behaviour is unaffected by
the minimal edit: the chord is still filtered by 1.11's `isrepeat` gate, as it was by the stale
filter.

**1.22 — `alt.lua:242-245`, `altHintReady`: `return INPUT.shift`.** → **[Key]** `Key.shift()`.
**Q5**, draw-time.

**1.23 — `alt.lua:252-264`, `altHintDeco`: `if INPUT.shift then`.** → **[Key]** `Key.shift()`.
**Q5**, draw-time. (Together with 1.18 and 1.22 these are the three "light the caps that are
held" reads — rung 2/3 of "Held keys", and correct as written once the source is right.)

### `words.lua`

**1.24 — `words.lua:220-221`, `wordsTextinput(ch)` → `if inputStale(wordsBaseKey(ch)) then
return end`.** The third cross-channel read, same shape as 1.19.
→ **[settled]** The claim check.

### `findkey.lua`, `bubble.lua`, `hide.lua`, `train.lua`, `astrocore.lua`

**1.25 — `findkey.lua:132`, `bubble.lua:147`, `hide.lua:275`, `train.lua:240`,
`astrocore.lua:145`** — all five are the same line, `elseif not isMod(k) and k ~= "capslock" then`.
→ **[Key]** No edit at these sites if 1.6 replaces `isMod`'s body. They are listed because they are
what makes 1.6 worth doing centrally rather than five times.

**1.26 — `bubble.lua:137-155`, `bubbleKeypressed` / `bubbleKeyreleased`.** `BUB.key` is set on
`keypressed` (`:144-145`) and the bubble is judged on `keyreleased` for the same key (`:152-154`).
→ **[poll]** *Considered and recommended with a caution, not asserted.* This is checklist **Q6**'s
shape — a state opened on one channel and closed on the mirrored one — but it is a **bare** key,
which Q9/Decision 32.3 explicitly legitimate ("prefer the release channel for bare keys"), and the
hold-and-release *is* the game's rule.
The failure Q6 names is real here and bounded: a release lost to focus change leaves `BUB.key` set
and the bubble inflates past the window until `bubbleGrow` (`:116-121`) pops it — so the child who
let go inside the band gets a pop. The self-limiting pop is why this is a caution rather than the
help-overlay wedge of 1.17.
The behaviour-preserving conversion is to keep the **press** as the event (the inflation's start
instant is genuinely an event) and detect the release by polling at the top of `bubbleUpdate`:
`if BUB.key and not love.keyboard.isDown(BUB.key) then bubbleRelease() end`, before `bubbleGrow`
increments `BUB.t`. LÖVE pumps events before `update` in the same frame, so the release is seen in
the same frame it arrives and `BUB.t` carries the same value the handler would have read.
`bubbleKeyreleased` and the `keyreleased` entry in the scene table (`bubble.lua:258`) then go, and with them
the game's only `keyreleased` consumer.
**This is the one §1 item that could change what a player experiences** (only in the lost-release
case, where it corrects a fault) and it is the second smoke-pass item in §5. If the owner prefers
strict shape-preservation, leaving it exactly as written is defensible under "Purpose beats shape"
— record the decision rather than the silence (Decision 32.5).

---

## 2. Platform gaps the example worked around

Each is a claim the upstream code makes about the platform, checked against `/repo/src`.

**G1 — "The IDE … strips the isrepeat flag before calling the game"** (`input.lua:3-4`), which is
why repeats are filtered by edge tracking (`input.lua:5-7`).
**Verdict: was true once, is false now — gap CLOSED.** `src/controller/controller.lua:766`
receives `(k, sc, isr)` and `:868` forwards all three to the active route;
`src/controller/projectInputController.lua`'s `dispatch` forwards the varargs to shortcut, hook
and widget alike. Decisions 9 and 26; `internals/user_input.md:60`. **Closed by:** LÖVE's own
`isrepeat` argument, plus `compy.input.fn.ignore_repeat`
(`src/controller/consoleController.lua:486-492`) where a wrapper is wanted instead of a test.
Consumed at 1.11.

**G2 — "the runner exposes no project-exit cleanup hook to restore [key repeat] on Ctrl+Esc
force-exit; see Beads compy-keyboard-exit-hook"** (`input.lua:6-9`), which is why the game does not
disable global key repeat at all.
**Verdict: CLOSED.** `compy.before_exit` exists (`doc/input_api.md`, "Stop hook";
`src/controller/consoleController.lua:140-177`, `:1342`), fires on every framework-invoked stop,
and the Ctrl+Esc path is one of them — verified end to end: `controller.lua:883-890` →
`love.event.quit()` → `love.quit` (`controller.lua:653-683`) → `stop_project_run` →
`framework_before_exit`. **Note the documented limit:** it does *not* fire when the project's own
code raises (`doc/input_api.md`), so it is not a guarantee, just a hook. What the game should
*do* with it is split: restoring relative mouse mode is recommended (1.14); actually disabling key
repeat is raised, not recommended (§4.1).

**G3 — "the IDE delivers textinput BEFORE the matching keypress (the reverse of desktop LOVE)"**
(`input.lua:12-13`), the premise the whole `inputStale` design rests on.
**Verdict: NOT a platform behaviour, and not one the platform can close.** The gateway does not
reorder: `handlers.textinput` (`controller.lua:877-881`) forwards straight to `love.textinput`,
`handlers.keypressed` (`:766`, `:868`) straight to `love.keypressed`; the order is LÖVE's own, and
`internals/user_input.md:56` states plainly that "LÖVE2D does not guarantee the relative *order*
the two arrive in for the same physical key". This is the fault the settled fix exists for
(1.10/1.19/1.24), and it is the only item in this inventory where the upstream comment describes a
platform that never promised what it says.

**G4 — "LOVE 11.5 has no lock-state API, so effective Caps is an estimate"**
(`indicators.lua:2-5`).
**Verdict: NOT closed.** `Key` (`src/util/key.lua:180-193`) exports `shift/ctrl/alt/any_pressed/
is_mod/is_enter/…` and nothing lock-related; nothing in `/repo/src` reads a lock state. The
estimate machinery (`capsToggle` + `capsReconcile`) stays — §3.5.

**G5 — "the runner restores [relative mouse mode] on exit"** (`main.lua:89`).
**Verdict: false, and now the project's own job — CLOSED by `compy.before_exit`.** See 1.14 for
the verification.

**G6 — the Alt-chord class needed a hand-written "and not Ctrl" clause** (`input.lua:103`, and the
comment at `:100-101` explaining why Ctrl+Alt+H must stay unconsumed).
**Verdict: CLOSED by modifier classes.** Decision 21 cites this exact workaround as its
motivation. `'alt+*'` is the Alt class *exactly*; Ctrl+Alt+H is a different class and is not
caught. Consumed at 1.9.

**G7 — `love.keyboard.setTextInput(true)` "to match the IDE default"** (`input.lua:41`, `:9-10`).
**Verdict: no gap — the claim is correct and the call is redundant.** `src/main.lua:296` already
enables text input at boot. The call is harmless and is what keeps the file honest as a plain
LÖVE program; §3.11 leaves it.

---

## 3. Leave alone, and why

This list is load-bearing: a previous conversion of another example was mechanically faithful and
destroyed the feature's purpose.

**3.1 — `menu.lua:82-90`, `menuKeypressed(k)`.** `tonumber(k)` → `MENU_ORDER[n]` →
`sceneAvailable(id)`. It looks like ten missing shortcuts.
**Leave.** The whole point of the menu is stated at `menu.lua:1-6`: the list is "derived
structurally from the scenes registered in this build … so omit-not-disable is guaranteed **by
construction**". Ten `shortcuts.keypressed['1'] … ['0']` registrations would be a second,
hand-maintained copy of `MENU_ORDER` that can drift from the one `menuItems()` draws — converting
the one thing the file exists to prevent. This is the shape of the mistake the rule of restraint
was bought with.

**3.2 — `intro.lua:58-66`, `introKeypressed(k)`.** "Any key snaps the welcome complete."
**Leave.** That is *every key on the channel*, which is what a hook is (Decision 21: a bare `'*'`
raises, and names the hook as the alternative). It is already reached through the hook.

**3.3 — `findkey.lua:93-103` `fkDoneKey`, `words.lua:237-245` `wordsEndKey`, `alt.lua:221-224`,
`astrocore.lua:129-137`.** Tab / Enter on the end screens.
**Leave.** These are conditional on scene *phase* (`fkDone`, `fkAtEnd`, `streamAtLevel`), not on a
combo. A shortcut is "a one-off transition of your own state" (Decision 32.1) that stands on its
own once made; these do not — the same Tab means "climb a rung", "nothing", or "advance a
platform" depending on where the game is. They are also scene-scoped, which shortcuts are not
(see 1.21).

**3.4 — `input.lua:131-132` and `:151/:154`, the `PAUSED` / `helpOverlayShown()` gates; and
`main.lua:111-116`.** Game policy expressed as early returns.
**Leave.** Nothing about them is input mechanism; they read the game's own state. Their *ordering*
relative to the reserved chords is preserved for free (1.8).

**3.5 — `indicators.lua:7-26`, `CAPS_STATE` / `capsToggle` / `capsReconcile`.**
**Leave the machinery.** It looks like a mirror (Q1) and is not: it estimates a **device lock
state the platform cannot answer** (G4), reconciled from observable evidence rather than
accumulated from events. It is precisely the "deliberate, project-specific decision taken in
awareness of the trap" Decision 32.5 carves out — and the awareness is written down at
`indicators.lua:1-5`. Only the *source* of its `shift_held` argument changes (1.13), and its
comment at `:22` must be corrected with it.

**3.6 — `alt.lua:40-44` `ALT_KEYTARGET` and the keypressed-vs-textinput acceptance split
(`alt.lua:6-11`, `:174-176`, `:198-201`).**
**Leave.** This is the game's *rule* — the "plastic-screwdriver rule": a printable target is
accepted by the glyph it produced, however produced; the three non-printing targets are accepted
by key name because they emit no glyph. It is not a mechanism to be unified.

**3.7 — `scene.lua` in whole, and the `SCENES[ACTIVE].keypressed` dispatch (`input.lua:133-134`,
`:142-143`, `:159-160`).**
**Leave.** A registry of scene handler tables is the game's architecture, not an input mechanism,
and it is not string-tag dispatch in the sense the rules forbid — the string is a scene id, the
handlers are functions in a table.

**3.8 — `bubble.lua`'s hold-and-release rule, `findkey.lua`'s first-try gauge, `alt.lua`'s
hint ladder, `hide.lua` / `train.lua` / `astrocore.lua` acceptance logic.**
**Leave.** All rules. The only mechanism question in any of them is 1.26.

**3.9 — `press.lua:28-30`, `find.lua:28-30`, and every other scene's one-line delegation to
`fk*`.**
**Leave.** Nothing to adopt; they name no key and read no device.

**3.10 — `main.lua:160-170`, the three `love.*` handler definitions.**
**Leave as `love.*`** (edit the signature only, 1.15). Converting them to explicit
`compy.input.hooks.* = …` assignments is behaviourally identical (Decision 10: an explicit hook
wins over the seed, but the seed *is* these functions), gains nothing, and costs the game its
ability to run as a plain LÖVE program. That last point is the soft preference at its recorded
weight, and here it costs nothing to honour.

**3.11 — `input.lua:41`, `love.keyboard.setTextInput(true)`.**
**Leave.** Redundant under Compy (G7) and correct standalone. Removing it would be tidying, which
"Minimise the change" forbids.

**3.12 — `main.lua:104-158`, the `DEBUG` pcall wrapping of `update`/`draw`, `dbgLog`, `dbgBoot`.**
**Leave.** Not input. Note only that `compy.before_exit` does **not** fire on a project raise
(`doc/input_api.md`), so the pcall recovery and the 1.14 hook are complementary, not overlapping.

**3.13 — `love.keyboard.isDown` in the settled fix's release poll.**
**Leave as `love.keyboard.isDown`**, not `Key.any_pressed`. Owner's call, recorded in the
commission, for minimising the change; a comment points at `Key.any_pressed` as the platform's
recommended form. Note this leaves the game with two spellings of one question (checklist **Q3**
would say route both through `Key`) — the deviation is the owner's and belongs in a comment at the
site.

**3.14 — no pointer adoption at all.** `git grep` finds exactly one mouse call in the whole game
(`main.lua:92`, 1.14) and no `love.mousepressed`/`mousemoved`/`wheelmoved`/touch handler. The
pointer half of the API (`hooks.mousepressed`, `singleclick`/`doubleclick`, `mouseN` triggers) has
nothing to adopt here. Stated because its absence from §1 would otherwise look like an oversight.

---

## 4. Raised, not recommended

**4.1 — Disable global key repeat now that `compy.before_exit` exists.** G2's gap is closed, so
`love.keyboard.setKeyRepeat(false)` + a restoring `before_exit` is now writable — it is literally
the example in `doc/input_api.md`'s Stop-hook section. **Not recommended here:** it changes
*which events arrive*, not how they are handled, and the settled claim fix is designed around
repeats arriving (a held key's glyph stream is what the claim suppresses). Adopting both at once
would make a smoke pass unable to tell which mechanism was doing the work. If it is wanted, it is
a separate change after §5 wave 5, with its own pass.

**4.2 — Drop the capslock exemption from the repeat filter** (`input.lua:124`,
`and k ~= "capslock"`). Its stated reason (`input.lua:119-121`) is that capslock's release may not
arrive and would wedge the held set — and the held set is exactly what this adoption deletes. With
the reason gone the exemption is vestigial, and a *held* capslock currently toggles `CAPS_STATE` on
every repeat (`input.lua:130`), which is a flicker. **Not recommended as sweep work** because it
is a player-visible difference in a pathological case, and "behaviour-preserving, or recorded and
deferred". Recorded here.

**4.3 — Make Ctrl+Alt+H a real `shortcuts.keypressed['ctrl+alt+h']`** (1.21), which is what Q8
asks for. **Blocked by scoping:** `compy.input.shortcuts` is project-global and the binding is
scene-local; `scene.lua`'s registry (`:31-58`) has `enter` but no `leave`, so there is nowhere to
unregister. Adding a `leave` hook is a restructuring — out of scope under "Do not restructure",
and worth its own ruling because *every* scene-scoped binding in this game (3.3) would then become
convertible. The same question governs whether Alt+P's pause should be scene-scoped rather than a
`pauseToggle()` that no-ops on untimed scenes (`pause.lua:11-17`).

**4.4 — The bare-Alt-press delta in the intro** (1.9). Upstream swallows a lone Alt press; the
`'alt+*'` class cannot (a modifier's own press names no combo, Decision 21), so Alt alone would
finish the intro typewriter — which lone Shift already does upstream. Preserving it exactly would
need a `k == "lalt" or k == "ralt"` test in the hook, which re-implements the fold Q2 forbids and
hard-codes the modifier set Decision 31 changed once. **Recommendation: accept the delta and say
so; do not write the preserving test.** Owner's word.

**4.5 — The two narrowings in 1.8**: Alt+Shift+Esc and Ctrl+Alt+Shift+Up stop working. Stated at
the site, repeated here because "A narrowing is a change … Say it, or do not do it".

**4.6 — `Key.is_mod` is not documented as project surface.** It exists and is exported
(`src/util/key.lua:147-149`, `:186`+) and is exactly what 1.6 wants, but `doc/input_api.md`
documents only `Key.shift/ctrl/alt/any_pressed`. This is a **platform doc gap**, raised against
the platform rather than the game: either name `is_mod` in the guide's "Held keys" section, or
tell projects to spell the exclusion out. Until then 1.6 uses an undocumented member — which the
recommended form (replace `isMod`'s body, keep the game's name) confines to one line.

**4.7 — Standalone-ness.** Every shortcut registration (1.8, 1.9, 1.11) touches `compy.input`,
which does not exist outside Compy, so after this adoption the game no longer runs as a plain LÖVE
program without a guard. Recorded at the weight the commission gives it: nobody asked for
standalone-ness, it did not shape any call above, and 1.15/3.10/3.11 honour it only where it was
free. If the owner wants it kept, the cost is one `if compy then … end` around the registration
block plus a fallback path in `appKeypressed` — a real cost, raised, not recommended.

**4.8 — `main.lua:90`'s `TODO(root-access)`** ("replace with trackpad disable on entry"). Untouched
by this adoption; noted so the author's own pending item is not read as something this pass
declined.

**4.9 — The `dbgLog` calls on every key event** (`input.lua:125`, `:138`, `:155`). Under `DEBUG =
false` they are a function call and an early return per event; not an input concern, not touched,
mentioned because they sit in the middle of every handler this pass rewrites and a reviewer will
see them move.

---

## 5. Ordering proposal

**Wave 1 — independent, mechanical, no behaviour change (do first, in any order).**
1.6 (`isMod` → `Key.is_mod` body; 1.20/1.25 follow for free), 1.17 (`helpHeld`), 1.18
(`capsEffectiveUpper`), 1.21 (`altKeypressed`'s modifier tests), 1.22, 1.23, 1.13's `Key.shift()`
and `Key.alt()`/`Key.ctrl()` substitutions, 1.14 (`before_exit`). Each is a same-meaning source
swap at one site. **After this wave `INPUT.shift/ctrl/alt` and `INPUT.held.h` have no readers
left.**

**Wave 2 — the repeat filter.** 1.15 (signature) then 1.11's `:124`. Must follow nothing, must
precede wave 3 (the shortcuts in wave 3 rely on `isrepeat` being available for `fn.ignore_repeat`
and on the hook no longer running the stale filter first).

**Wave 3 — the shortcuts.** 1.8 (three reserved chords), 1.9 (`alt+*`), optionally 1.11's
`capslock` split. **Depends on wave 2.** 1.9 additionally **depends on wave 4** for its `claim(k)`
call, so either land 1.9 after wave 4 or land it in two steps (swallow first, claim second) — the
one-step form is cleaner.

**Wave 4 — the settled claim fix.** 1.3, 1.10, 1.12, 1.16 (the per-frame release poll), and the
call-site updates at 1.19 and 1.24. This is the only wave that is a design change rather than a
substitution, and it must land as one commit: `inputStale`'s three callers and the release
bookkeeping are a single mechanism.

**Wave 5 — deletions and the record.** 1.2 (`INPUT` itself), 1.4, 1.5, 1.7, then 1.1
(rewrite the header) and `indicators.lua:22`'s comment. Deletions last, so each earlier wave can
be reverted independently; the comment rewrite last because only then is it true.

**1.26 (bubble) is independent of all five waves** and should land alone, so a smoke pass can
attribute anything it finds.

**Wants a human at a real keyboard, before or instead of trusting the diff:**
1. **Wave 4 in whole** — the settled fix is the only thing standing between a held key and a flood
   of glyphs into `alt`/`words` scoring. Test: hold a correct target key; hold a wrong one; press
   Alt+H and release Alt before H; press Ctrl+Alt+H then type.
2. **1.13's `capsReconcile(t, Key.shift())`** — the one place Decision 30's accepted one-frame poll
   error would be *visible* (the Caps decal and every letter keycap flip together). Test: type
   capitals fast with Shift; toggle Caps Lock and type; type a shifted symbol.
3. **1.26 (bubble)**, if adopted — the release judge is the game's entire rule. Test: release
   early, inside the band, and past it, at two notches.
4. **1.9's `alt+*`** — confirm Alt+P still pauses only timed scenes, that no Alt chord types into a
   scene, and (the delta) what Alt alone does during the intro.

---

## 6. Confidence and limits

**High confidence** (verified in code at both ends, upstream ref and platform):
the `INPUT` mirror and every one of its readers; `isrepeat` availability (G1); `compy.before_exit`
existence and its Ctrl+Esc path (G2); the gateway not reordering channels (G3); no lock-state API
(G4); relative mouse mode never restored on the stop path (G5); `Key.is_mod`'s exact equivalence to
`isMod`; the two narrowings in 1.8; the modifier-trigger early return that produces the delta in
4.4; `dispatch` not gating on `isrepeat`, which is what makes `fn.ignore_repeat` mandatory in 1.8.

**Medium confidence — reasoned, not executed:**

- **1.26's frame-timing equivalence.** The claim that polling at the top of `bubbleUpdate` sees
  the release in the same frame the handler would rests on LÖVE pumping its event queue before
  `love.update`. That is LÖVE's documented loop, but it was not measured here.
- **The `capsReconcile` poll error's practical size** (1.13). Decision 30 bounds it to one frame's
  event batch; whether a real child's Shift-and-letter ever lands in one batch is a keyboard
  question, not a code one.
- **The exact `claim` / release call shape** in 1.9 and 1.10. The settled fix's names
  (`GLYPH_CLAIMED`, `spendGlyph`) do not exist at the upstream ref, so this inventory names the
  sites and the required property (claim outside `ignore_repeat`; release outside `updateStep`)
  rather than the calls.

**Could not be determined in this container — owed to a human, not guessed:**

1. **Nothing here was run.** No keystroke can be injected and there is no device;
   `love.keyboard.isDown` cannot be exercised. Every behavioural statement above is derived from
   reading two codebases, and every §5 smoke item is owed.
2. **Whether Alt+Shift+Esc or Ctrl+Alt+Shift+Up are used by anyone** (4.5). The code accepts them;
   no string, comment or on-screen hint mentions them. Only the author knows.
3. **Whether the intro's Alt delta matters** (4.4). It is a four-to-six-year-old pressing keys
   during a five-second animation; the author's judgement, not a reader's.
4. **What the platform actually delivered when the upstream comments were written** (G1, G3, G5).
   Two of the three are false *now*; whether they were true then was not investigated — this repo's
   history was deliberately not read, per the commission.
5. **Whether upstream has moved.** `origin/dsent/dev` was read at `025e858`; if the example's
   author has pushed since, line numbers shift, though the structure this inventory describes is
   the whole file and would survive.
6. **`Key`'s reachability from a project environment** was taken from `doc/input_api.md` ("`Key` is
   available to every project, like `compy`") plus `src/util/key.lua`'s global assignment and the
   project env being a clone of the app env (`consoleController.lua:40-42`, `:1008-1014`). It was
   confirmed by three shipped examples using it (`src/examples/turtle/main.lua:34`,
   `sapper/main.lua:672`, `maze/main.lua:568`) — but not by running this game.
