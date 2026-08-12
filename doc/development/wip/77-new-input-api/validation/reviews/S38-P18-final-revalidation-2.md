# S38 — second cold revalidation of the keyboard deepfix (`025e858..1498f46`)

**Verdict: the mechanism is sound and the adoption is now nearly clean.** The claim/poll design is
correct against LÖVE 11.5 in both delivery orders — I measured it against the real dispatch chain —
and the three code defects the first cold pass named are genuinely fixed in the code, not only in
the commit messages. **One player-visible regression against upstream survives, unnamed anywhere:
`Ctrl+Alt+Shift+H` no longer re-arms the hint** — the sixth member of the shift-tolerant family that
this branch has now twice gone back to restore. Beyond that: one false rationale repeated in three
comments, and one comment block the dedicated sweep should have taken and did not. All are cheap.

**Written:** 2026-08-12, cold, read-only. Object of review: the complete diff
`git -C src/examples/keyboard diff 025e858..1498f46`. Nothing in any repository was edited,
committed or otherwise touched; this file is the only artifact. The first pass's report and the
triage plan were read **after** the findings below were formed.

---

## Instruments

Three, all throwaway, under `/tmp/claude-1000/-repo/6f512c55-e690-4ef3-9962-d6ea3490f5cb/scratchpad/`:

1. **Real LÖVE 11.5 headless** (`xvfb-run`) for library facts — `love.keyboard.isDown`'s raising
   set, `love.mouse.getRelativeMode`.
2. **A dispatch harness** driving the **real** `src/controller/projectInputController.lua` and the
   **real** `src/util/key.lua` over the **real** `src/examples/keyboard/input.lua`, with
   `Controller.combo_string` / `any_mod` and `INPUT_FN` copied verbatim from platform source, a
   stubbed `isDown` whose raising behaviour is instrument 1's, and scene stubs whose `textinput` is
   the first line of the real handlers. 16 scenarios.
3. **The live platform, with a probe.** A copy of the game under the scratchpad, run as
   `love src play <copy>`, printing from inside the real sandbox: which shortcut combos are actually
   registered, what `love.mouse.getRelativeMode()` answers before and after, and — by pushing
   `love.event` keyboard events — that the framework really delivers `keypressed(k, sc, isrepeat)`
   and `textinput(t)` into `compy.input.hooks.*`. **The `/repo` tree was not modified**; only the
   scratchpad copy.

Findings are marked **measured** or **reasoned**.

---

## Defects

### F1 — `Ctrl+Alt+Shift+H` stopped re-arming the hint, and can knock instead *(medium; measured)*

**What is wrong.** Upstream's teacher chord was matched by hand in the Alt scene, with **Shift
unconstrained**:

```lua
-- upstream alt.lua
if k == "h" and INPUT.ctrl and INPUT.alt then altHintReenable() return end
```

The migration converted it to a single shortcut, `sc["ctrl+alt+h"]` (`input.lua:82-85`). A combo is
its modifier set **exactly**, so `Ctrl+Alt+Shift+H` matches neither that binding nor any class
(`ctrl+alt+shift+*` is not registered). It falls through to `appKeypressed`, which claims `h` and
hands a plain `h` to the active scene (`input.lua:196, 205-206`). In `alt.lua` that reaches
`altPlayKey`: if the live target is a key-target (`backspace` / `tab` / `return`) and the gauge is
glowing, `h` is a wrong key → `altWrong()` — a knock and `ALT.fumbled` (`alt.lua:189-197`). If the
live target is printable, `altPlayKey` returns early and the gesture is simply inert. **Either way
the hint is not re-armed and no blip plays.**

**This is the exact class of finding the branch already accepted twice.** §5 RULE 1 of the triage
double-bound `shift+escape`/`alt+shift+escape` and `ctrl+alt+(shift+)up|down` precisely because
upstream left one modifier unconstrained; P-18-08 double-bound `alt+p`/`alt+shift+p` for the same
reason. `input.lua:45-46` states the rule in the file itself — *"A combo is its modifier set EXACTLY,
so a gesture that also tolerates Shift is bound twice"* — and then the next sentences describe
`ctrl+alt+h` without applying it. RULE 4's own recipe (§5 of the triage) specifies one registration.
So the plan, the code and the comment miss it together, which is why three passes did not catch it.

**Reachable by.** In game 4 (Alt characters), press `Ctrl+Alt+Shift+H`. Upstream: hint re-arms,
finger sweep restarts, soft blip. Now: nothing, or a knock if the current target is `backspace`,
`tab` or `return`.

**Evidence.** Measured twice. Harness scenario *"Ctrl+Alt+Shift+H in alt scene"* dispatches
`alt KP h` where *"Ctrl+Alt+H in alt scene"* dispatches `alt onHint`. Live sandbox probe:
`sc[ctrl+alt+h]=true`, `sc[ctrl+alt+shift+h]=false`, every other family member present. The knock
half is **reasoned** from `altPlayKey` — I did not drive a gauge.

**What I would do.** Hoist the handler and bind it twice, exactly as `back`, `notch_up`, `notch_down`
and `pause` already are:

```lua
local hint = fn.stop_here(function(k, sk, isr)
  claimChord(k)
  rearm(k, sk, isr)
end)
sc["ctrl+alt+h"] = hint
sc["ctrl+alt+shift+h"] = hint
```

Then correct `input.lua:52-56` and `alt.lua:202-204` (see F3), and add a smoke row beside B8/B11.

### F2 — "so this file also runs standalone" is false, in three comments and one commit message *(low; measured)*

**What is wrong.** Three comments introduced by this branch justify a code choice by the game's
ability to run as a plain LÖVE program:

- `input.lua:8-10` — *"setTextInput(true) below is for running as a plain LOVE program"*;
- `input.lua:173-174` — *"Key.any_pressed(k) is the IDE's form of this call; the plain LOVE one is
  kept so this file also runs standalone"*;
- `help.lua:12-14` — the same sentence, about `love.keyboard.isDown("h")`.

**The game cannot run outside the IDE, and never could.** Measured:
`cd src/examples/keyboard && love .` dies at `config.lua:42`, *"attempt to index global 'Color'"* —
`Color` is a platform global (`src/util/color.lua:2`) and is defined nowhere in the example. The
game's own `main.lua` never reaches `inputInit`. Nor could it: `input.lua` itself calls
`compy.input.fn`, `compy.input.shortcuts`, `Key.ctrl`, `Key.alt`, `Key.shift` and `Key.is_alt`, and
`help.lua`'s very next expression is `Key.alt() and not Key.ctrl()` — so each file contradicts its
own standalone claim two lines below it. The rationale is also carried into `1498f46`'s commit
message (*"kept -- deliberately, so this file also runs standalone"*) and into P-18-11's execution
record (*"what makes the game correct as a standalone LÖVE program on a device"*).

The **code** is right and should not change: `setTextInput(true)` is upstream's own line and
"minimise the change" protects it; `isDown` and `Key.any_pressed` are the same function
(`src/util/key.lua:134-138`), so the choice is cosmetic. Only the stated reason is false — and in a
repository with no tests, the stated reason is all a future reader gets. This is the priority-3
category, and it is the *replacement* for the first pass's D3: the falsehood D3 named was removed and
a different one was put in its place.

**What I would do.** Say what is true and is enough: the line is upstream's own and the IDE makes
the same call at boot, so removing it would be a change with no effect (`input.lua`); and for
`helpHeld`, either drop the justification entirely or use `Key.any_pressed("h")` and say the file
asks the device for continuous state. Correct the commit-message claim in the step record, not by
rewriting history.

### F3 — `alt.lua`'s new comment asserts something F1 falsifies *(low; measured)*

`alt.lua:202-204`: *"Ctrl+Alt+H is not matched here any more: it is a shortcut (input.lua) that calls
onHint below, **so this scene sees no chord at all**."* Measured false: with Shift held the scene
sees `h` (harness, above). It is the same sentence that would have caught F1 had it been checked.
Fold the correction into F1's fix — once both combos are bound, the sentence becomes true.

---

## Observations

**O1 — `words.lua:219-228` is a ten-line history narration on an eleven-line function** *(measured
against the rule)*. `agents/rules/commenting.md` bans exactly this — *"Narrate history — 'this used
to…', 'we removed…' … Git holds history"* — and the size rule calls a comment as long as the code it
describes *"a symptom, not a style."* The block explains `inputStale`, a symbol that no longer
exists in the repository, the reasoning behind its removal, and what made the Alt scene deaf. It is
also the one place the branch names its own defect in a file the upstream author will read as a
diff. This block **survived the dedicated comment sweep** (`1498f46` did not touch `words.lua`),
which is worth noting because the sweep is the gate that was supposed to take it. The durable
argument already lives in `doc/development/internals/examples/keyboard.md`. Two lines here would do:
*"one glyph per press; the claim is released by the device (inputTick)."*

**O2 — the release boundary is now narrower than upstream's, in the direction upstream guarded**
*(measured)*. Upstream held a key "stale" for `INPUT_UP_GRACE = 1` frame after its release. A claim
is cleared by the first `inputTick` that sees the key up — i.e. inside the same frame's
`love.update`. Harness scenario 1: a `textinput` delivered in the *pump after* that tick is
**accepted**, where upstream dropped it. Reachability is low — the OS delivers a final repeat
character and the keyup in the same batch, so both land in one frame — but this is the phantom the
design of record says the poll exists to prevent (*"clearing at the release would let that character
through as a fresh one"*), and the poll narrows it rather than closing it. The design's "Consequences,
accepted" names the **opposite-direction** residue (a re-press inside one frame loses its character)
and not this one. One sentence there completes the pair; no code change.

**O3 — smoke coverage gaps that follow from the above.** (a) No row for `Ctrl+Alt+Shift+H` — F1 would
pass the gate unseen. (b) No row for the accepted change that `Ctrl+Alt+H` is now **swallowed in every
scene**, where upstream let a bare `h` knock in Press / Find / Blow the bubble; the design of record
states it as accepted, the checklist tests it nowhere, so a future regression in either direction is
invisible. B8/B11/B12 exercise the chord only in game 4. (c) Otherwise the list is fit: I found **no
row testing a mechanism the code no longer has**, and the four-commit anchor names `1498f46` and
`025e858` correctly. Its platform id (`8a22ed24`) is now two docs-only commits behind `ccd184c4`; the
table's note explains one of them, and the list's own "refresh before you run" instruction covers the
rest.

**O4 — an unstated micro-delta in the intro** *(measured)*. `appKeypressed` now returns on
`Key.is_alt(k)` before dispatching, unconditionally. Upstream's `appChord` bailed out when Ctrl was
held, so **Ctrl held + Alt pressed** reached the scene and skipped the intro typewriter. It no longer
does. This is inside the family RULE 2 restored "exactly", it is not written down anywhere, and it is
about as small as a player-visible difference can be. Mentioned only because the ruling asks for
completeness; I would not spend a commit on it.

**O5 — six gestures cost eleven registrations, and that is where F1 came from** *(the strategic
frame)*. `register_reserved` binds 11 combo strings for 6 gestures, purely because a combo is its
modifier set exactly and four of the gestures tolerate Shift. The enumeration is mechanical, it is
not checkable by anything, and the one member that was not enumerated is F1. The mechanism the work
*built* (claim + poll) is a clear win on predictability — one table, one per-frame poll, no clock, no
held set, no `DBG_FRAME` coupling in acceptance. The apparatus it *adopted* is where the elaborateness
sits, and it is the platform's, not the game's. Worth carrying back to the input API as feedback — a
way to say "these modifiers are don't-care" — rather than fixing here.

**O6 — aliases.** `claimChord` (`input.lua:33-35`) is `spendGlyph` with the return dropped, and
`wordsBaseKey` (`words.lua:145-149`) is now a bare forward to `glyphBaseKey`. The triage already
declined the first (§9, "Declined") and I agree the finding is weak — both name intent in the game's
own vocabulary, which "minimise the change" protects. Recorded so the next pass does not re-raise it.

---

## Verdict on the first pass's four defects, judged from the current code

| | first pass | now | how judged |
|---|---|---|---|
| **D1** the menu digit is judged by the game it opens | defect | **fixed** | `menu.lua:93` claims the digit before `gotoScene`. **Measured** in both delivery orders: keypress-first, the digit's `textinput` reaches the new scene and is dropped; textinput-first, it reaches the menu, which has no `textinput` handler. I also checked the *other* transition sites for the same leak — `intro.lua:69` (`return`/`kpenter` only) and `goBack` (`escape`) are non-printing, so the menu was the only one. Smoke row A4 exists |
| **D2** `Alt+Shift+P` no longer pauses | defect | **fixed** | `input.lua:75-80` binds one hoisted handler to `alt+p` and `alt+shift+p`. **Measured**: both toggle once per fresh press, neither on a repeat, both claim `p`. Live probe confirms both are registered. Smoke row D8b exists |
| **D3** `help.lua`'s comment states the opposite of the API | defect | **partly fixed** | The specific falsehood is gone — `help.lua:12-13` now says `Key.any_pressed` *does* answer for a non-modifier key, which is true. Its replacement justification is false instead: see **F2**. Code unchanged, as ruled |
| **D4** smoke rows D9/G1 unrunnable under the stated launch | defect | **fixed** | `smoke_checklists.md:44-47` gives the exit rows their own IDE launch and says why, and D9/G1 both point at it |

The first pass's observations: **O2** (64 columns) is fixed — measured, the only line over 64 in the
whole example is upstream's own `scene.lua:16`. **O4** (the stray `REMARK:`) is fixed —
`grep -rn 'REMARK:\|INTERIM:'` is empty across the example. **O1** and **O6** landed in platform docs.
**O3** is largely addressed (`input.lua` 306 → 232 lines) except for O1 above. **O5** and **O7** were
judgement calls; O7's clause is now in `main.lua:93-95`.

---

## What I checked and found correct

**The mechanism, in both delivery orders** — measured. One character accepted per physical press;
OS repeats dropped; identical outcome whether `keypressed` or `textinput` arrives first; a doubled
letter typed press/release/press registers twice; a claim survives the key's own repeats and is
released only when the device reports the key up.

**No path into `love.keyboard.isDown` can raise.** Measured in real LÖVE: `isDown` raises on `~`,
`|`, `A`, `é` and accepts every other name the game can produce, including every unshifted
punctuation key and `kp1`. `glyphBaseKey` maps every raising *character* the game can see to a
pollable key (`~`→`` ` ``, `|`→`\`, uppercase→lowercase, `" "`→`space`) through the inverted
`SHIFT_MAP`, and `pollable`'s memoised `pcall` closes the rest; `inputTick` iterates only names that
passed that gate, so the per-frame loop cannot raise. The C5 crash is closed twice over.

**Every reserved binding, and each exactly once per press** — measured: `shift+escape` and
`alt+shift+escape` go back; `ctrl+alt+up/down` and both `+shift` variants notch once and are inert on
repeats; `alt+p`/`alt+shift+p` toggle once; `ctrl+alt+h` re-arms once and is silent while paused;
`alt+*` / `alt+shift+*` swallow with no knock; a bare Alt press reaches the hook (a class never takes
its own modifier) and is filtered there; a bare Shift press still skips the intro, as upstream.
`capslock` repeats still reach `capsToggle`, byte-identical in effect to upstream's exemption.

**The chord-owns-its-trigger rule holds where it matters** — measured: `Alt+H`, then releasing Alt
while `H` stays down, puts nothing into the scene; the same for `Ctrl+Alt+H`. Pressing `H` again
after a release types an `h`, as ruled.

**The platform claims in the comments are true** — checked in source and, where noted, measured:
`compy.input` shortcut tables are provisioned before the project's top-level chunk (so registration
in `inputInit` survives) and `seed_hooks` runs after it and only fills nils (so the explicit hooks
are preserved) — **live probe: all eleven combos and both hooks present inside the running sandbox**;
the framework delivers LÖVE's own argument list including `isrepeat` (**measured end-to-end** by
pushing events into the real run); `stop_here` consumes regardless of the handler's return and
`ignore_repeat` reads argument three; the platform sets `setTextInput(true)` and `setKeyRepeat(true)`
at boot (`src/main.lua:296-297`); nothing in the runner restores relative mode (the only
`setRelativeMode` outside the example is LÖVE's own error handler, `lib/error_explorer.lua:303`);
`compy.before_exit` fires from `stop_project_run` and is uninstalled-but-not-fired on a top-level
raise (`consoleController.lua:317-323, 1338-1342`); `love.mouse.getRelativeMode()` exists in the
sandbox and answered `false` before and `true` after the game's own call (**measured in the live
run**).

**The comment sweep's own headline claims hold** — measured: no comment cites a platform doc or a
decision number any more (the two remaining `docs/…` references, `help.lua:5` and
`keyboard_view.lua:195`, are the author's and predate the branch); exactly one line over 64 columns
remains and it is upstream's; `input.lua` is 232 lines.

**Nothing dangles.** `INPUT`, `inputStale`, `isMod`, `modHeld`, `inputUpdateMods`, `reservedChord`,
`appChord`, `ALT_BASE`, `INPUT_UP_GRACE`, `upRecent` appear nowhere except the one `words.lua`
comment that names `inputStale` (O1). `bubble.lua` really is the only remaining `keyreleased`
consumer.

**The design of record matches the shipped code**, claim by claim, including the menu rule and the
`Ctrl+Alt+H`-is-swallowed-everywhere concession. Its one gap is O2 above; F1 is not in it either,
because F1 is not in the code.

**A pre-existing property that is *not* a finding:** on a layout where a printable character needs
AltGr, that character cannot be typed as a target — `alt+*` swallows the press and `appTextinput`
drops the glyph. Upstream's `appChord` did the same thing. Unchanged by this work.

**The game loads in the real platform** — `timeout 25 xvfb-run -a stdbuf -oL -eL love src play
src/examples/keyboard` from `/repo`, no `Error:` line, no raise.

---

## Limits — what I could not verify

- **Nothing in this work has ever been run in a game scene.** Not by the implementing sessions, not
  by the first cold pass, not by me. This container has no display device and cannot inject
  keystrokes into a real key-repeat stream. Every behavioural claim here is a library measurement, a
  dispatch-layer simulation, or a probe of a boot-time state.
- **The harness is not LÖVE.** It reproduces the platform's dispatch chain over the real
  `input.lua`, but not LÖVE's event ordering and batching, OS repeat timing, the real
  `gauge`/`sound` state machines, or the window/focus lifecycle. Where I say "measured", read
  *measured against a faithful model of the dispatch layer and a measured model of `isDown`* — except
  where I say "live probe", which was the real sandbox.
- **The live probe injected only unmodified keys.** Combo dispatch reads held modifiers from the
  device, which cannot be faked from inside the project, so every combo result above comes from
  instrument 2, not from the running game.
- **F1's knock is reasoned, not measured.** That `altPlayKey` reaches `altWrong` for `h` against a
  key-target comes from reading `alt.lua` and `gauge.lua`; the *loss of the re-arm* is measured.
- **The pointer restore is verified up to the hook, not through it.** The hook is installed, the
  slot is writable, `getRelativeMode` answers, the call path to `framework_before_exit` is in source.
  Whether the console's pointer behaves afterwards needs a pointer and a human — smoke G1.
- **I did not measure which delivery order any build uses.** The mechanism is order-independent by
  construction and I measured both, so nothing here depends on the answer.
- **Android / the assembled `.apk` was not exercised in any form.**
- **E3 (held capslock flicker) remains open**, unchanged and unanswerable here.

---

## Recommendation

**One code fix: F1** — bind `ctrl+alt+shift+h` to the same handler value as `ctrl+alt+h`, correct the
two comments that describe the binding (`input.lua:52-56`, `alt.lua:202-204`), and add a smoke row.
It is three lines and it is the same edit the branch has made four times already.

**Two comment fixes, no behaviour: F2** (drop the false standalone rationale in `input.lua` ×2 and
`help.lua`) and **O1** (cut `words.lua`'s history block to two lines).

**Two documentation lines: O2** (the trailing-glyph residue into the design of record's accepted
consequences) and **O3(b)** (a smoke row for `Ctrl+Alt+H` in a non-teaching game).

With F1 fixed I would call the adoption clean and the work ready for the human gate. Without it, a
teacher gesture that worked upstream is silently dead in the one scene the whole step exists for, and
no row on the checklist would catch it.
