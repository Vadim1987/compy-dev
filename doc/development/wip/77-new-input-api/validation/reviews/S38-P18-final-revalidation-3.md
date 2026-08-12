# S38 — third cold revalidation of the keyboard deepfix (`025e858..1033252`)

**Verdict: sound.** The acceptance mechanism is correct against LÖVE 11.5 in both delivery orders,
and the gesture set is now a **measured exact match** to upstream over the whole modifier space —
there is **no seventh dropped gesture**. I enumerated all eight modifier subsets against fifteen
triggers, ran the stimulus through upstream's `input.lua` and through the new one driven by the
*real* platform dispatcher, and diffed: **three differences, all bare-modifier presses, all
reachable only in the intro typewriter.** Two of the three are the delta the branch declined as
`O4`; the third is its mirror and is written down nowhere.

**Nothing I found changes what a player experiences in a game scene.** The remaining findings are one
comment that is now false, one stale number in a platform debt entry, one smoke gap carried over from
the second pass, and comment-economy observations. The work makes the system **more predictable, not
merely more elaborate** — the elaborateness that exists is the platform's combo model, already
recorded as debt.

**Written:** 2026-08-12, cold, read-only. Object of review: the complete diff
`git -C src/examples/keyboard diff 025e858..1033252`. No file in any repository was edited,
committed, staged or otherwise touched; this document is the only artifact. The two earlier reports
and the triage plan were read **after** the findings below were formed.

---

## Instruments — what was measured, and how

Everything under `/tmp/claude-1000/…/scratchpad/`, all throwaway.

1. **Real LÖVE 11.5, headless (`xvfb-run`)** — enumerated exactly which strings
   `love.keyboard.isDown` accepts and which raise, over every printable ASCII byte plus named keys
   and two non-ASCII characters.
2. **Load check in the real IDE** — `timeout 25 xvfb-run -a stdbuf -oL -eL love src play
   src/examples/keyboard` from `/repo`. Reached *"Project play opened / Running 'play'"* with no
   `Error:` line, i.e. the project's whole top-level chunk completed: `register_reserved` found the
   shortcut tables and `compy.input.fn`, `Key` resolved, `love.mouse.getRelativeMode()` exists in the
   sandbox, and `compy.before_exit` is assignable.
3. **A gesture-parity harness** — the **real** `src/util/key.lua` and the **real**
   `src/controller/projectInputController.lua` (so the real `find_shortcut`, the real
   `Key.new_handler_table` normalisation, the real `Key.is_mod` guard) driving the **real**
   `src/examples/keyboard/input.lua`, against a stubbed `isDown` whose raising behaviour is
   instrument 1's. `Controller.combo_string` / `any_mod` and the `INPUT_FN` combinators are copied
   **verbatim** from `controller.lua` and `consoleController.lua` — they are locals inside modules
   with heavy dependencies. The same stubs drive upstream's `input.lua` unmodified
   (`git show 025e858:input.lua`), with upstream's in-scene `Ctrl+Alt+H` match reproduced from
   `025e858:alt.lua:217`.
   - 105 fresh-press stimuli (8 modifier subsets × 15 triggers, self-presses excluded);
   - the same 105 as OS repeats;
   - 15 acceptance scenarios exercising `spendGlyph` / `inputTick` / `glyphBaseKey` exactly as the two
     judging scenes call them.

Findings are marked **measured** or **reasoned**.

---

## Defects

### D1 — `words.lua`'s `wordsBaseKey` comment describes the behaviour the fix removed *(low; measured)*

**What is wrong.** `words.lua:144-149`:

```lua
-- The physical key a target glyph is produced on: space for a
-- space, the lowercase key for a letter (incl. a capital), else
-- the glyph itself (an unshifted punctuation key).
function wordsBaseKey(ch)
  return glyphBaseKey(ch)
end
```

The body changed; the comment did not. `glyphBaseKey` (`input.lua:133-138`) has a fourth branch the
comment denies — the inverted `SHIFT_MAP` — so `"~"` returns `` "`" ``, not `"~"`, and `"!"` returns
`"1"`. **That branch is precisely what keeps smoke row C5 from crashing**: measured in real LÖVE,
`isDown("~")` raises *"Invalid key constant: ~"*, and `~ | { }` and every uppercase letter are the
only characters the game can produce that do. A reader following this comment concludes the claim is
taken on `"~"` itself and that the crash is still live.

For Words' *targets* the sentence is still true — the corpus punctuates with `,` and `.` only
(`words.lua:42-51`), and capitals go through the lowercase branch — so nothing behaves differently.
The defect is that the comment is the one a maintainer consults about the one behaviour that changed
in this function, and it is wrong there. In a repository with no tests that is the whole cost.

**Why this survived.** `1033252` is the commit that swept `words.lua`; it rewrote the
`wordsTextinput` block six lines below and left this one.

**What I would do.** Either delete `wordsBaseKey` and call `glyphBaseKey` at its two sites — the
alias carries no information the name `glyphBaseKey` does not, and the stale comment goes with it —
or reduce the comment to the one clause that is not derivable: *"a shifted symbol maps back to its
unshifted key; `isDown` raises on the symbol itself."* Recommendation only; the second pass declined
the alias on "minimise the change" grounds (`O6`) and I would not overturn that on its own — it is
the comment that makes it worth touching.

---

## Observations

### O1 — three bare-modifier deltas against upstream, and only two are written down *(measured)*

The parity diff over all 105 fresh-press stimuli is **three lines**:

| held | pressed | upstream | now |
|---|---|---|---|
| `Ctrl` | `Alt` | scene sees `lalt` | dropped |
| `Ctrl+Shift` | `Alt` | scene sees `lalt` | dropped |
| **`Alt`** | **`Shift`** | **swallowed** | **scene sees `lshift`** |

The first two are the triage's declined `O4`: `appKeypressed`'s `if Key.is_alt(k) then return end`
(`input.lua:204`) is unconditional, where upstream's `appChord` bailed out when Ctrl was held.

**The third is new and goes the other way.** Upstream's `appChord` swallowed *every* key while Alt
was held without Ctrl, modifiers included; the class `alt+*` cannot, because `find_shortcut` returns
early on `Key.is_mod(trigger)` (`projectInputController.lua:110`), so a Shift (or Ctrl) press with
Alt down now reaches the hook and the scene.

**Reachable by:** hold Alt, tap Shift while the intro typewriter is running — it now skips. Only
`intro.lua` can observe any of the three: every game scene guards with `not Key.is_mod(k)`
(`findkey.lua:132`, `alt.lua:194`, `astrocore.lua:145`, `bubble.lua:147`, `hide.lua:275`,
`train.lua:240`), `menu.lua:85` returns on `tonumber(k) == nil`, `words.lua:245` only reacts on its
end screen, and `fkDoneKey` matches named keys only (`findkey.lua:93-103`).

Two things make it worth a line. First, `intro.lua:58-62` — added by this branch — asserts *"The
Shift/Alt asymmetry is the game's own and is left as it is, not 'fixed' into a second difference."*
That is true for the **lone** presses it names and false for the modified ones, in both directions.
Second, smoke rows `A2`/`A3` test only the lone presses, so nothing would catch it.

**What I would do:** nothing to the code. By the same reasoning that declined `O4` — a keystroke the
player repeats, a gesture nobody has — this is below the bar. But `intro.lua`'s comment claims a
preserved boundary it does not preserve; one clause ("lone presses only") makes it true, or the
sentence should go. **Owner's to overturn**, as `O4` was.

### O2 — the debt entry undercounts the cost it was written to record *(measured)*

`doc/development/technical_debt/input.md:1505-1506` and `:1516`: *"`examples/keyboard` needs six such
tolerant gestures and pays **eleven** registrations"* … *"one file's **eleven** lines."* The code
registers **twelve** (`input.lua:67-87`, counted and exercised): the entry was written in the same
batch (`a05a3829`, P-18-17) as the twelfth registration (`7b0d542`, P-18-14), so it was stale on
arrival. Platform repo, one-word fix. The entry's history — four gestures caught by the first cold
review, the fifth by the second, the sixth by the third — checks out against the three prior reports.

### O3 — the smoke gap the second pass named as `O3(b)` is still open *(measured against the list)*

`Ctrl+Alt+H` is now a shortcut, so it is **swallowed in every scene**, where upstream let a bare `h`
reach Press / Find / Blow the bubble and knock there. The design of record states this as accepted
(`internals/examples/keyboard.md:103-109`); the checklist tests it nowhere. `B8`/`B11`/`B12` exercise
the chord in game 4 only, and `F2` ("play each for a few seconds") would not surface it. A regression
in either direction is invisible to the gate. One row in section D would close it.

Otherwise the list is **fit**: the four-commit anchor names **`1033252`** correctly, its platform id
(`a05a3829`) is this pin's parent as the table's own note says, and I found **no row testing a
mechanism the code no longer has** — I checked `A2`, `A3`, `B6`, `B7`, `C5`, `D3`, `E3` and `F2`
against the current behaviour and all are still meaningful. `B13` (the sixth gesture) and `D8b` are
present and correct.

### O4 — `bubble.lua`'s new comment is review dialogue shipped into a third party's file *(reasoned against `agents/rules/commenting.md`)*

`bubble.lua:151-158`, eight comment lines over a four-line function. The last three — *"a release
lost to a focus change leaves `BUB.key` set … `bubbleGrow`'s timeout pops the bubble a moment
later"* — are a genuine payload (intent/constraint, and the caution lives where the handler is). The
first five are an answer to a challenge raised **in this review chain**: *"a frame poll could measure
the hold as well … so this is not something the platform cannot serve; the channel is the author's
choice."* That is a defence of a migration decision addressed to a reviewer, phrased as what the code
does **not** do — which the rules admit only when a reader could plausibly conclude otherwise. The
upstream author reading this as a diff has no idea a platform capability was ever in question. The
size rule ("a comment as long as the code it describes is a symptom") lands on it too. **I would keep
the caution and drop the first five lines**; the argument belongs in the platform's design of record,
where it already is (`internals/examples/keyboard.md:175-181`).

### O5 — `main.lua`'s trailing comment repeats its own header *(reasoned)*

`main.lua:176-180` explains, at the end of the file, that the keyboard handlers are hooks registered
in `inputInit`. `main.lua:3-5`, the file header, already says exactly that. The trailing block adds
one fact the header does not — that the framework would have captured `love.*` into the same hooks
anyway, so the explicit form costs nothing — but that is a justification of the migration, not
something a maintainer of the game needs. Two comments for one pointer, in the file the comment sweep
touched.

### O6 — small things in `input.lua` the sweep left *(measured)*

- **`input.lua:11` is 39 characters mid-paragraph** ("`-- on exit would be a no-op. Global key`"),
  a ragged wrap in the header the sweep re-wrapped. No line in the changed files exceeds 64 — checked
  across all nine.
- **The `setTextInput` rationale undercuts the call it justifies** (`input.lua:8-11`): *"below is for
  the device: the IDE makes the same call at its own boot … so here it is redundant."* Both halves
  are true — `src/main.lua:296` calls it unconditionally, under a header reading *"Android specific
  settings"* — but the sentence says the line is needed and then that it is not. Keeping upstream's
  call is right (there is no `compy` replacement for it in `input_api.md`, so this is not a `love.*`
  call the adoption ruling asks to convert); the reason should simply be *"upstream's own line; the
  IDE makes the same call at boot, so removing it would change nothing"*.
- **`GLYPH_CLAIMED` is initialised twice** — `input.lua:92` inside `inputInit` and `input.lua:122` at
  file scope. Harmless; the second is the one that carries the doc comment.

---

## Explicit verdict on the second pass's findings, judged from the current code

| | second pass | now | how judged |
|---|---|---|---|
| **F1** `Ctrl+Alt+Shift+H` no longer re-arms the hint | defect (medium) | **fixed** | `input.lua:82-87` hoists `hint` and binds `ctrl+alt+h` and `ctrl+alt+shift+h` to the same value. **Measured** through the real dispatcher: `lctrl+lalt \| h => onHint` and `lctrl+lalt+lshift \| h => onHint`, identical; both silent on an OS repeat; `h` claimed in both cases. Smoke row `B13` exists |
| **F2** "so this file also runs standalone" | defect (low) | **fixed** | The claim appears nowhere in the tree — `grep` for "standalone" in `src/examples/keyboard/*.lua` is empty. `d9ecdb0` moved all three polls to `Key.any_pressed` (`input.lua:152, 177`, `help.lua:14`), deleting the justification rather than rewording it, and `help.lua:10-12` now carries a true payload (a held chord is asked, not bound — which is what `input_api.md`, "Choosing the mechanism", tells a project to do). The replacement rationale in `input.lua:8-11` is not false, only self-undercutting — `O6` above |
| **F3** `alt.lua`'s "this scene sees no chord at all" | defect (low) | **fixed** | Now true of the chord it is about. **Measured**: with `Ctrl+Alt` or `Ctrl+Alt+Shift` held, `h` never reaches `altKeypressed`. Strictly read, the scene still sees *other* chords (`Ctrl+H` arrives as a plain `h`), so the sentence is broader than its subject — not worth a commit |
| **O1** `words.lua`'s history narration | observation | **fixed, one new** | `1033252` cut the block to three lines (`words.lua:215-217`) that name the mechanism and no history; `inputStale` appears nowhere in the repository. The **other** comment in the same file is now wrong — **D1** above |
| **O2** the release boundary is narrower than upstream's | observation | **fixed** | `internals/examples/keyboard.md:182-189` carries it in "Consequences, accepted", with the trade that justifies it, beside the opposite-direction residue |
| **O3** smoke coverage gaps | observation | **partly fixed** | (a) `B13` covers `Ctrl+Alt+Shift+H`. (b) **still open** — see `O3` above. (c) confirmed again: no stale rows, anchor correct |
| **O5** six gestures, eleven registrations | observation | **recorded, and now off by one** | Landed as a debt entry (`technical_debt/input.md:1497-1525`) rather than a code change, which is the right disposition — the cost is the platform's combo model, not the example's. The number is stale: `O2` above |

The second pass's `O4` (Ctrl held + Alt pressed) was **explicitly declined** by the triage
(§10, "Owner's to overturn"). It is still live, and it has acquired the mirror case in `O1` above,
which the decline did not consider.

The first pass's four defects are all still fixed: `menu.lua:93` claims the digit (**measured**: the
digit's own `textinput` is dropped by the game it opens), `alt+p`/`alt+shift+p` both toggle once
(**measured**), `help.lua`'s comment is true, and `smoke_checklists.md:45-48` gives `D9`/`G1` their
own IDE launch.

---

## What I checked and found correct

**Gesture parity with upstream, exhaustively** — measured. 105 fresh presses across every modifier
subset: three differences, all in `O1`, none reachable in a game scene. All six shift-tolerant
gestures reproduce exactly — `shift+escape` / `alt+shift+escape`, `ctrl+alt+(shift+)up`,
`ctrl+alt+(shift+)down`, `alt+p` / `alt+shift+p`, `ctrl+alt+h` / `ctrl+alt+shift+h`, and the
`alt+*` / `alt+shift+*` swallow. **There is no seventh member of that class.**

**No reserved action re-fires on an OS key repeat** — measured over the same 105 stimuli delivered
with `isrepeat` true: the *only* effect any of them produces is `capsToggle` for `capslock`, which is
byte-identical to upstream's exemption from the staleness test. `B11`, `D6` and `D8` are backed.

**The acceptance mechanism, in both delivery orders** — measured, 15 scenarios:

| scenario | result |
|---|---|
| keypress→glyph, and glyph→keypress | accepted exactly once, either way |
| fast tap (glyph after the key is already up) | accepted — the case every earlier version dropped |
| held key, three repeat glyphs | one accept, then drops |
| release, frame, re-press | two accepts |
| release + re-press with no frame between | second dropped — the documented ~16 ms residue |
| `Ctrl+Alt+H`, modifiers released, `H` still down | every trailing glyph dropped |
| `Alt+H` via the class, Alt released, `H` down | dropped |
| menu digit | dropped by the game it opened |
| `~` (base `` ` ``), `!` (base `1`), `A` (base `a`), space | accepted once, no raise |
| non-ASCII (IME/dead key) | accepted every time, no raise — the stated residue |

Every one matches what `internals/examples/keyboard.md` claims, including the two residues it names.

**No path into the device poll can raise** — measured in real LÖVE. `isDown` raises on exactly
`A`-`Z`, `{`, `|`, `}`, `~`, a literal `" "` and non-ASCII, and accepts every other printable ASCII
byte plus the named keys. `glyphBaseKey` maps every raising *character* the game can produce to a
pollable name; `pollable`'s memoised `pcall` (`input.lua:148-156`) covers the rest; `inputTick`
iterates only names that passed that gate, so the per-frame loop is raise-free by construction. `C5`
is closed twice over.

**Nothing dangles.** `INPUT`, `isMod`, `modHeld`, `inputUpdateMods`, `inputStale`, `reservedChord`,
`appChord`, `INPUT_UP_GRACE`, `upRecent`, `ALT_BASE` appear nowhere in the tree. The only remaining
`love.*` input calls are `love.keyboard.setTextInput` (no `compy` equivalent exists) and the two
`love.mouse` relative-mode calls (the `before_exit` fix's whole subject) — nothing was renamed for
its own sake, and nothing that had a justified replacement was left behind.

**The comment rules hold** on the sweep's headline claims: no line over 64 columns in any changed
file; no `INTERIM:` or `REMARK:` anywhere; no comment cites a platform doc, a `doc/…` path, a
decision number or a Beads id — the two `docs/…` references (`help.lua:5`, `keyboard_view.lua:195`)
are the author's own and predate the branch, and upstream's *"see Beads compy-keyboard-exit-hook"*
was correctly removed rather than repointed.

**The platform claims in the comments are true**, checked in source: `stop_here` consumes regardless
of the handler's return and `ignore_repeat` reads argument three (`consoleController.lua:482-509`);
shortcuts run ahead of hooks and an exact combo beats a class (`projectInputController.lua:104-114`);
a class never takes its own modifier's press (`Key.is_mod` guard, `key.lua:147-149`);
`compy.before_exit` is invoked from exactly one place on the stop path and is *uninstalled but not
fired* on a top-level raise (`consoleController.lua:168-178, 317-323, 1338-1342`) — so `main.lua:93-95`
is accurate, and the smoke list's `G1` names the crash residue as platform debt rather than hiding it.

**The design of record matches the shipped code**, claim by claim — the claim/poll paradigm, the
`inputTick`-in-`love.update` placement and its reason, the character→key inference and its limit, the
chord-owns-its-trigger rule and its extension to the menu, the `Ctrl+Alt+H`-everywhere concession, the
Caps Lock exemption, and both accepted residues. I found nothing in it that the code does not do.

**Is it more predictable, or merely more elaborate?** More predictable, clearly. Upstream's
acceptance needed a held set, a just-released set, a one-frame grace window measured off the debug
logger's frame counter, an edge-tracked mirror of the modifier state, and an assumption about which
channel arrives first — and the assumption was wrong, which is why the Alt scene was deaf. What
replaces it is one table, one per-frame device poll, and no clock, and it is correct in either
order — measured. The elaborateness that remains is twelve registrations for six gestures, which is
the platform's combo grammar and is already in the debt register. The one place the game itself pays
is that a chord's trigger is claimed in three separate places (the two classes, the four exact
bindings, and `appKeypressed`); that is forced by `stop_here` cutting the chain before the hook, not
gratuitous.

---

## Limits — what I could not verify

**Nothing in this work has ever been run in a game scene.** Not once, by anyone, at any head of this
branch. No gauge has advanced, no knock has sounded, no burst has been drawn, no hint has re-armed on
a real keypress. Everything above about *what a player sees* is inference from code paths that I drove
with synthetic events against stubs.

Specifically:

- **No keystroke has entered this game.** The container has no display device and cannot inject
  input. My harness calls the dispatcher directly; it does not go through SDL, LÖVE's event pump, or
  the framework's own `love.keypressed`.
- **The order in which LÖVE delivers `keypressed` and `textinput` on this build is unmeasured.** I
  measured that the mechanism gives the same answer in *both* orders, which is the point of the
  design — but which order actually occurs on desktop Linux or on the Android `.apk` is untested here.
- **`Controller.combo_string`, `any_mod` and the three `fn` combinators are verbatim copies** in my
  harness, not the loaded originals — they are locals inside modules I cannot load without the whole
  application. I re-read all five against source; a divergence would be a transcription error of mine.
- **The knock half of any judging path is reasoned, not measured.** I never drove `gauge.lua`,
  `ALT.fumbled`, `SOUND.*` or `keyRect`.
- **`compy.before_exit` was not observed firing.** Its wiring is read from source; the second pass
  measured `getRelativeMode()` before and after in a live sandbox copy, and I did not repeat that.
- **The device build is entirely untested.** No `.apk` was assembled and nothing here says anything
  about Android behaviour, key repeat on that platform, or whether lock keys repeat there (`E3`).
- **Untouched scenes were read, not run.** `astro`, `press`, `find`, `hide`, `train` receive only the
  `isMod` → `Key.is_mod` substitution, which I verified is behaviourally identical
  (`key.lua:147-149` folds exactly upstream's six names) but did not exercise.

The smoke checklist remains the only instrument that can close any of this, and it is owed by a human.

---

## Recommendation

**Pass.** The one defect (`D1`) is a comment; the rest are observations. If anything is spent on this
branch before the human smoke pass, spend it in this order:

1. **D1** — fix or delete `words.lua`'s `wordsBaseKey` comment. It misdescribes the one behaviour in
   that function that changed, and it is the behaviour smoke row `C5` exists to test.
2. **O3** — one smoke row for `Ctrl+Alt+H` in a non-teaching scene, the accepted change nothing tests.
3. **O2** — eleven → twelve in the debt entry (platform repo).
4. **O1** — one clause in `intro.lua`'s comment, or drop the sentence. **Owner's call**, as `O4` was.
5. **O4, O5, O6** — comment economy. Cheap, and none of it is load-bearing.

None of these blocks the smoke pass, and none of them should hold the PR if the owner would rather
run the checklist first.
