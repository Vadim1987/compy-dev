# P-18-00 part 2 — triage: the cold inventory against what landed, and the P-18 task list

**Written:** 2026-08-12, session37, after the cold inventory returned
(`../outcomes/P-18-00-adoption-inventory.md`, 26 sites). **Sequential by the owner's insistence:**
no triage was begun while the agent ran, because you cannot judge what landed without first knowing
what is minimally needed.

**Baselines.** The inventory is against **upstream** (`origin/dsent/dev`). "Landed" below means the
merged tree at `ca6d5df`, i.e. upstream plus this branch's 13 migration commits plus the merge's
correction. **Verdicts** are: **KEEP** (landed and right), **COMPLETE** (landed halfway, finish it),
**REVISE** (landed and wrong or superseded), **DO** (not landed), **RULE** (owner's, before the work).

---

## 0. Two owner calibrations applied throughout (2026-08-12)

**(a) Focus loss is not a catastrophe, and is not on its own a reason to change code.** *"Many
examples tolerate this risk. If the said risk is the only reason for some change, I'd rather not
enforce the change — just leave a comment with a warning."*

**(b) A risk cleared by repeating the chord is an inconvenience, not a harmful degradation.**

Applied, these move exactly one item and re-justify two:

- **1.26 (`bubble.lua`'s hold judge) is downgraded from "convert" to "comment only."** Its only
  failure is a release lost to focus change, and `bubbleGrow`'s timeout pops the bubble by itself —
  a child who let go inside the band gets a pop, which is an inconvenience cleared by trying again.
  **Do not convert it**; leave a comment naming the risk. This also keeps `bubble.lua` — the owner's
  "let bubble drive on its own channels" — untouched, and preserves the game's only `keyreleased`
  consumer.
- **1.17 (`helpHeld`) keeps its change but loses that justification.** The wedge the inventory calls
  the highest-value line is focus-shaped, and it is cleared by pressing and releasing `h` again — an
  inconvenience by (b). **The change stands on a different ground and would stand without the
  wedge:** `INPUT.held` is deleted by the adoption, so this reader must ask something else, and a
  poll is the sanctioned answer for continuous state (Decision 32).
- **The settled claim fix does NOT rest on focus loss and must not be argued that way.** Its
  load-bearing case is ordinary typing: clearing a claim on `love.keyreleased` admits a trailing
  repeat character as a fresh one — **a wrong answer the player did not type**, in normal play, and
  precisely what upstream's `INPUT_UP_GRACE` was built to prevent. The device poll is what lets that
  window go without admitting the phantom. Focus loss is a bonus, not the case.

## 0.1 The scene-scoping blocker dissolves — the owner named the technique, and this game already uses it

The inventory blocked `Ctrl+Alt+H` as a shortcut (§1.21, §4.3) because `compy.input.shortcuts` is
project-global while the binding is scene-local, and `scene.lua` has `enter` but no `leave`.

**The owner's pointer is right and the precedent is closer than either of us said.** `balloons`
registers once and dispatches through a state-indexed table (`game_state_router`, `main.lua:71-78`:
`map[game_state](...)`); `pong` does the same with `key_actions[S.state][k]` (`main.lua:315-320`).
**And this very file already does it:** `notchAdjust` (`input.lua`) is a globally-registered
`ctrl+alt+up/down` shortcut whose action is looked up on the active scene —
`local s = SCENES[ACTIVE]; if s and s.onNotch then s.onNotch(delta) end`.

So nothing needs unregistering and no `leave` hook is required: **register globally, dispatch
per-scene through the descriptor**, exactly as `onNotch` does. `Ctrl+Alt+H` becomes a shortcut whose
handler calls an `onHint` entry that only `alt.lua` defines. §4.3's restructuring objection does not
apply, and the same answer is available to every other scene-scoped binding the inventory listed.

---

## 1. The triage, site by site

### Already landed and right — KEEP (7)

| site | what landed | note |
|---|---|---|
| **1.5** `modHeld` | deleted | P14e |
| **1.7** `inputUpdateMods` | deleted | P14e |
| **1.8** `reservedChord` → three shortcuts | landed **exactly** as the cold pass specifies, `fn.stop_here(fn.ignore_repeat(...))` and all | independent confirmation: the wrapper is **mandatory**, not decoration — shortcuts see every repeat |
| **1.11** repeat filter | `if isr and k ~= "capslock" then return end` | the cold pass reaches the same minimal edit, exemption verbatim |
| **1.11** mirror lines | `INPUT.held`, `inputUpdateMods`, `reservedChord`, `appChord` calls deleted | |
| **1.19 / 1.24** the two `textinput` guards | both call the claim check | mechanism still changes under them (P-18-01); the **sites** are right |
| **1.9** Alt class | `alt+*` + exact `alt+p`, both `stop_here` | the cold pass calls the split "legitimate"; it is what landed |

### Landed halfway — COMPLETE (5)

| site | landed | what is missing |
|---|---|---|
| **1.2** the `INPUT` table | became a **metatable proxy** returning `Key.shift/ctrl/alt` | the table itself, and its 8 remaining read sites, still exist. The proxy is a halfway house — it was always meant to be dissolved (P18's own material) |
| **1.10 / 1.3 / 1.4 / 1.12** the claim machinery | `GLYPH_CLAIMED` + `spendGlyph` exist and are called from both scenes | **the release rule is still the old one**: `INPUT.upRecent`, `INPUT_UP_GRACE`, the frame stamp and the release-handler bookkeeping are all still there. This is the heal |
| **1.13** `appTextinput` | reads go through the proxy | direct `Key.alt()/ctrl()/shift()` when the proxy dies |
| **1.17** `helpHeld` | polls `love.keyboard.isDown("h")` | its two modifier reads still go through the proxy |
| **1.1** the header | rewritten once for the migration | must be rewritten **again** for the settled fix, which contradicts parts of it |

### Not landed — DO (6)

| site | edit |
|---|---|
| **1.6** `isMod` | replace the body with `Key.is_mod(k)`; the game keeps its own name and the five other call sites (1.25) do not move |
| **1.9** the chord claim | `alt+*` must **claim its trigger key** — this is the Alt+H leak, live today |
| **1.14** `setRelativeMode` | add `compy.before_exit` restoring it; the comment claiming the runner does it is **false** |
| **1.16** the release poll | once per frame — and see the correction in §2 |
| **1.18 / 1.22 / 1.23** three draw-time `INPUT.shift` reads | `Key.shift()` — rides with the proxy dissolution |
| **1.21** `Ctrl+Alt+H` | now a real shortcut, per §0.1 |

### Landed differently, or superseded — REVISE (2)

- **1.15 — `main.lua`'s three `love.*` wrappers.** The cold pass recommends **keeping** them (they
  are auto-seeded as hooks; smallest edit; keeps the game plain-LÖVE). This branch **deleted** them
  and registers the hooks explicitly in `input.lua`. Both work. The landed form is more explicit and
  is already documented in the file header; the cold form is smaller and preserves the soft
  standalone preference the owner has since demoted. **Recommendation: keep what landed**, and note
  that the choice was made — no revert. *(Listed as REVISE only because the two passes disagree.)*
- **1.26 — `bubble.lua`.** The cold pass recommends a polling conversion; **§0(a) overrides it.**
  Comment only.

### Owner rulings needed before the work — RULE (4) — **all four RESOLVED, see §5**

1. **The two narrowings that already landed and were never ruled** (inventory 1.8, §4.5). Combos are
   exact modifier sets, so **Alt+Shift+Esc no longer goes back** and **Ctrl+Alt+Shift+Up no longer
   notches**. Upstream both worked. Neither gesture is documented anywhere in the game. *My
   recommendation: accept, and state it in the file — a narrowing is a change; say it or do not do
   it.*
2. **The bare-Alt delta** (inventory 1.9, §4.4). `'alt+*'` cannot swallow a lone Alt press, so Alt
   alone now finishes the intro typewriter — as lone Shift already did upstream. Preserving it would
   need a hand-written `k == "lalt" or k == "ralt"` test, which re-implements the fold and hard-codes
   the modifier set. *Recommendation: accept and state it; do not write the test.*
3. **The capslock exemption** (inventory §4.2). Its stated reason dies with the held set, and it now
   lets every repeat reach `capsToggle`, so a **held** capslock flickers the estimate. Settled by one
   observation a human can make in a minute: hold `capslock` and watch the decal. *Recommendation:
   drop the exemption if the observation shows repeats; otherwise drop it as vestigial anyway — but
   it is player-visible in a pathological case, so it is yours.*
4. **`Ctrl+Alt+H` as a shortcut, now that §0.1 unblocks it** — versus the minimal `Key.ctrl()/alt()`
   edit that keeps the hand-match. *Recommendation: the shortcut with an `onHint` descriptor entry,
   mirroring `onNotch`, because it removes the last hand-matched combo in the game and uses the
   game's own pattern.*

---

## 2. One correction to my own earlier recommendation

§9.5h of the design document put the claim-release poll in `updateStep`, "beside `pastelTick`". **The
cold pass is right that it belongs in `love.update` instead** (inventory 1.10, 1.16): `updateStep`
returns early on `not DREW_ONCE`, on `PAUSED` and on `helpOverlayShown()`, and a claim that is not
released while the help overlay is up would outlive its key — the overlay is *held* Alt+H, so this
is not a corner case, it is the ordinary way that overlay is used.

---

## 3. The plan: P-18-01 … P-18-06

Ordering is dependency-driven, not preference. Each is one commit unless it says otherwise; the suite
is not affected (no platform code), and the gate for every one of them is a human smoke pass, because
this repository has no tests.

| id | task | depends on | notes |
|---|---|---|---|
| ~~**P-18-01**~~ **DONE `c60b818`** | **The heal.** `spendGlyph` loses its grace branch; `INPUT.upRecent`, `INPUT_UP_GRACE` and the release-handler bookkeeping go; a once-per-frame release poll lands in `love.update`; `alt+*` claims its trigger; the header is rewritten to describe the adopted model | — | the sprint-blocking defect. **The chord claim is part of it**, not a follow-up: it is the same mechanism |
| ~~**P-18-02**~~ **DONE `c3388de`** | **Dissolve the `INPUT` proxy.** The table goes; its 8 readers ask `Key` directly — `appTextinput` ×3, `helpHeld` ×2, `keyboard_view` ×1, `alt.lua` ×2 | P-18-01 (which deletes `upRecent`, the proxy's only non-alias member) | mechanical once the heal has landed |
| ~~**P-18-03**~~ **DONE `c3388de`, same concern** | **`isMod` gains `Key.is_mod`'s body.** One line; five other files unaffected | — | independent |
| ~~**P-18-01b**~~ **DONE `c1ee63c`** | **The three restorations (§5).** The two extra combo bindings, and `Key.is_alt(k)` in the hook for the bare-Alt press | — | separable from the heal; one concern, one commit — behaviour restored, not changed |
| **P-18-04** | **`Ctrl+Alt+H` becomes a shortcut** with an `onHint` scene-descriptor entry (§0.1) — **RULED (A), owner 2026-08-12**. `fn.ignore_repeat` is mandatory; the handler claims its trigger | — | independent once ruled: the `Key` form it replaces is no longer on the table, so it no longer waits on P-18-02 |
| **P-18-05** | **`compy.before_exit` restores relative mode**, and the false comment goes | — | independent; the platform-side question stays promoted, not answered here |
| **P-18-06** | **Comments only.** `bubble.lua`'s focus caution (§0(a)); the capslock comment, whose stated reason no longer holds (RULE 3); the Shift-vs-Alt asymmetry the intro guard deliberately leaves (RULE 2) | — | the "deviation lives in the workspace" rule, discharged. **Shrunk by §5:** the two narrowings and the bare-Alt delta are now *restored* rather than documented |

**Not in P-18, recorded so it is not lost:** disabling global key repeat now that `before_exit`
exists (inventory §4.1 — it changes *which events arrive* and would confound the smoke pass);
`Key.is_mod` being undocumented in `doc/input_api.md` (§4.6 — **P10's**, a platform doc gap); and
`main.lua`'s own `TODO(root-access)`, which is the author's.

## 4. What the smoke pass owes a human

The cold pass named four; with §0's calibration the list is three, and one of them is new:

1. **Caps reconciliation after the source change** (inventory 1.13). `capsReconcile` will read the
   device *now* where the mirror read the edge; press and release Shift quickly while typing letters
   and watch whether the decal and the keycap case ever disagree with what was typed.
2. **Hold `capslock`** and watch the decal (RULE 3) — settles the exemption.
3. **The Alt scene end to end**: a fast tap of the target character registers (the case the shipped
   code drops); `Ctrl+Alt+H` then typing the hinted letter; and `Ctrl+Alt+H` **releasing the
   modifiers while H stays down** — no stray `h` reaches the target. That last one is the chord
   claim, and it is the only case in the game where the new mechanism is directly visible.

---

## 5. The four rulings, answered (owner, 2026-08-12) — three dissolve, one is a choice

### RULE 1 — the two narrowings: **just register the extra combos.** No blocker exists.

The owner asked whether the combos can simply be bound, and what it would take if not. **Nothing is
in the way**, verified rather than assumed:

- **There is no trigger blacklist.** `find_shortcut`
  (`src/controller/projectInputController.lua:104-114`) refuses exactly one thing — a trigger that is
  itself a modifier (`Key.is_mod(trigger)`, line 110). `escape` and `up` are ordinary triggers.
- **`combo_string`** (`src/controller/controller.lua:402-411`) prepends whatever modifiers are held,
  in `Key.mod_triples` order — **ctrl < alt < shift** (Decision 8). So the strings are
  `'alt+shift+escape'` and `'ctrl+alt+shift+up'` / `'…+down'`, and `Key.normalize_combo` is exported,
  so order and case are normalised on assignment anyway.
- **The framework claims neither.** `escape` handling in `editorController`/`userInputController`
  belongs to those routes, not to a running project; the game already binds `shift+escape` and it
  works.

**The exact restoration of upstream's two predicates is three more registrations:**

```lua
sc['shift+escape']      = back        -- } upstream: shift and NOT ctrl,
sc['alt+shift+escape']  = back        -- } alt unconstrained
sc['ctrl+alt+up']       = notch_up    -- } upstream: ctrl and alt,
sc['ctrl+alt+shift+up'] = notch_up    -- } shift unconstrained
sc['ctrl+alt+down']     = notch_down
sc['ctrl+alt+shift+down'] = notch_down
```

(the handlers are the same values, bound twice — no new code, and `fn.stop_here(fn.ignore_repeat(…))`
wraps each as before). **Resolved: bind them; the narrowings disappear rather than being accepted.**
The cost is three lines of registration table; the gain is that no player-visible gesture changes.

### RULE 2 — the bare-Alt delta: **restorable exactly, in one line, with no hand-rolled fold**

*What it is, since the owner had not met it:* `intro.lua`'s typewriter animation finishes early on
**any** keypress (`intro.lua:58-66`). Upstream, `appChord` swallowed a **bare Alt press** before the
scene saw it, so Alt alone did not skip the intro. A combo class cannot swallow it — a modifier's own
press names no combo (Decision 21, and `find_shortcut:110` is where it returns) — so after the
conversion Alt alone skips the intro. Lone **Shift** already did, upstream and now.

The cold pass said preserving it needs a hand-written `k == "lalt" or k == "ralt"`, which
re-implements the fold. **That is out of date: `Key.is_alt(k)` exists and is exported**
(`src/util/key.lua:171-173`, `:198`). So the guard is one line in `appKeypressed`, using the
platform's own l/r fold:

```lua
if Key.is_alt(k) then return end   -- upstream's appChord swallowed a bare Alt press
```

**Resolved: restore it.** It is a regression, it is one line, and the line hard-codes nothing.
Note what it deliberately does **not** do: it leaves lone Shift skipping the intro, because that is
what upstream does — the asymmetry is the author's, not ours, and a comment says so rather than a
second delta "fixing" it.

### RULE 3 — capslock: **keep the current behaviour; only the comment is wrong**

The owner asked to keep it, and that turns out to cost nothing at all: **the landed behaviour is
identical to upstream's.** Upstream exempts `capslock` from its stale filter
(`input.lua:124`), so every repeat already reaches `capsToggle` (`:130`); this branch exempts it from
the `isrepeat` filter, so every repeat still reaches it. **There is no deviation to accept** — the
flicker, if a platform repeats lock keys at all, is an upstream property that this feature neither
introduces nor removes.

**What must change is the comment**, which now states a reason that does not hold (§9.5i of the
design document): the held set it protected is gone. The replacement says what is true — the
exemption is inherited from upstream and preserved deliberately, and the estimate is corrected from
`textinput` anyway (`capsReconcile`). **No observation is owed any more**; it moves from a blocking
question to a curiosity.

### RULE 4 — `Ctrl+Alt+H`, and the owner's help-overlay proposal (two different chords)

**First, a distinction that the answer turns on**, because the two are easy to merge:

| chord | what it does | where it lives |
|---|---|---|
| **Alt+H** | shows the **help overlay** while held | `help.lua`'s `helpHeld`, polled |
| **Ctrl+Alt+H** | re-arms the **hint** in the Alt-keys scene | `alt.lua`'s hand-matched `if k == "h" and …` |

RULE 4 was about the second. The owner's *"display on shortcut, closure on polling"* answers the
first. Both are worth answering.

**Ctrl+Alt+H — the two options.**

- **(A) A real shortcut, dispatched per scene** — now unblocked by §0.1:
  ```lua
  sc['ctrl+alt+h'] = fn.stop_here(fn.ignore_repeat(function(k)
    claim(k)                                   -- a chord owns its trigger
    local s = SCENES[ACTIVE]
    if s and s.onHint then s.onHint() end
  end))
  ```
  plus `onHint = altHintReenable` in `alt.lua`'s descriptor — **exactly the shape `onNotch` already
  has in this file**. It removes the game's last hand-matched combo (checklist Q8) and needs no
  `leave` hook.
- **(B) The minimal edit** — keep the hand-match in `altKeypressed`, and change only its two modifier
  reads to `Key.ctrl()` / `Key.alt()`. Three characters of behaviour change, none of shape.

**RULED (A), owner, 2026-08-12:** *"I see no reason to lean to B. The existing code is clear
boilerplate, nothing unique to preserve — and exactly the type of construction we want to get rid
of."*

So `Ctrl+Alt+H` becomes `sc['ctrl+alt+h']`, dispatched through an `onHint` descriptor entry that only
`alt.lua` defines, and `altKeypressed` loses its first four lines. **The one thing this must not get
wrong:** `fn.ignore_repeat` is required. Shortcuts see every repeat, where the hand-match inherited
the hook's `isrepeat` filter for free — an unwrapped binding would re-arm the hint on every repeat
frame, which is a rule change hiding inside a mechanical conversion (the same trap the cold pass
found in the reserved chords).

**Alt+H — the owner's flag/state-machine proposal, assessed.** *"Display on shortcut, closure on
polling… a feature flag `showHelp` set by the shortcut, checked and set to false by polling;
`textinput` also checks it, rejecting `h` while active and maybe a few frames later."*

The proposal is sound and cannot wedge (the poll always closes it). **But the claim mechanism from
P-18-01 already delivers its every effect, with no flag, no states and no frame count:**

- *"reject `h` while help is active"* — while the overlay is up, `appTextinput` already drops
  **everything** (`helpOverlayShown()` gate). Nothing to add.
- *"…and maybe a few frames later"* — this is the real problem: Alt released first, `H` still down,
  its repeats now arriving as plain `h`. **The claim covers it exactly**: the `alt+*` handler claims
  `h` when the chord is pressed, and the claim is released **when the device says `h` is up** — not
  after *n* frames. A frame count here would be `INPUT_UP_GRACE` rebuilt, which is what P-18-01
  deletes.
- *"display on shortcut"* — the shortcut would fire (Alt+H is an Alt chord, so `alt+*` catches it),
  but the display itself is **continuous state**, which Decision 32 answers with a poll; the landed
  `helpHeld` is one line, holds no state, and self-heals.

**Recommendation: keep the poll for display, and let P-18-01's chord claim do the rest** — the
proposal's `shown / closing / invisible` machine collapses into "the key is down" and "the key is
up", asked of the device. Recorded because the reasoning matters more than the outcome: the flag
version is not wrong, it is the same behaviour with a state machine standing where a device read
does.

---

## 6. Execution record (session37, 2026-08-12)

**Four of the six children landed**, in the nested repo, nothing pushed. Suite untouched throughout at
**946 / 0 / 0 / 10** (no platform code); the app loads and runs under `love src play` after each.

| step | commit | note |
|---|---|---|
| **P-18-01** the heal | `c60b818` | claim released by `inputTick`'s device poll in `love.update`; `upRecent`, `INPUT_UP_GRACE` and the release bookkeeping gone; `alt+*` and `alt+p` claim their trigger; header rewritten; two stale comments in `alt.lua`/`words.lua` corrected with the mechanism they describe |
| **P-18-01b** the restorations | `c1ee63c` | `alt+shift+escape`, `ctrl+alt+shift+up/down` bound to the same hoisted handlers; `Key.is_alt(k)` restores the bare-Alt swallow. **No new behaviour — all three work as before the conversion** |
| **P-18-02 + P-18-03** | `c3388de` | nine reads call `Key` directly, the proxy and its `REMARK` are gone, `isMod` gains `Key.is_mod`'s body. Delegated to a supervised Sonnet worker against `../prompts/P-18-02-03-proxy-and-ismod.md`; diff reviewed site by site here, its report in `../outcomes/P-18-02-03-execution.md` |

**Left for the successor:** **P-18-04** (`Ctrl+Alt+H` → shortcut + `onHint`; `fn.ignore_repeat`
mandatory; the handler claims its trigger), **P-18-05** (`compy.before_exit` restores relative mode,
false comment goes), **P-18-06** (comments: `bubble.lua`'s focus caution, the capslock comment whose
reason no longer holds, the Shift/Alt asymmetry the intro guard leaves).

**Verification honestly stated:** every commit was smoked for load, and `inputTick` runs ahead of the
debug `pcall` so a fault in it would crash the run. **No game scene was reached** — the container
cannot inject keystrokes — so §4's three human items still stand, and the two most valuable are the
fast tap of a target character and `Ctrl+Alt+H` with the modifiers released while `H` stays down.

---

## 7. Cold revalidation, and what it cost (2026-08-12)

Commissioned by the owner before handover: Opus, explicit, read-only, judging the landed commits
against mandate and intent. Prompt `../prompts/P-18-revalidation.md`, report
`S37-P18-revalidation.md`. **Verdict: sound in design, unsound as landed** — 9 findings, and the
three that mattered were all mine.

**F1, critical — the poll could raise, and one keystroke in Words crashed the game.**
`love.keyboard.isDown` raises on a string that is not a LÖVE key constant, which I had asserted the
opposite of in the design document (§9.5f, now corrected in place). `wordsBaseKey` returned the
produced character itself, so a shifted symbol claimed `"~"` and the next `love.update` errored
outside any `pcall`. Fixed in **`52a8d69`**: `glyphBaseKey` moves into `input.lua` — the one item of
§9.5h's "diff, in full" that had not landed — and a claim that cannot be polled is never taken.
**Measured in real LÖVE, both the fault and the fix.**

**F2, high — a false claim in `c60b818`'s message.** It said the chord claim closes a leak the game
"has always had". Upstream had no such leak: `appKeypressed` marked the trigger held *before*
`appChord` swallowed it, so the held set suppressed the trailing characters for **every** chord. The
leak is this branch's, introduced when the held set went. And the claim only covered the swallowed
Alt class. Fixed in **`42d1a8b`**, which claims the trigger whenever Ctrl or Alt is down.

**F3, high — a fourth narrowing of the same family as the three `c1ee63c` restored.** `alt+*` cannot
match `alt+shift+key`, where the hand-written test said only "Alt and not Ctrl" — so Alt+Shift+key
had started counting as a wrong key in six scenes. `alt+shift+*` registered in **`42d1a8b`**.

**Also acted on:** the `capslock` comment was still false *and* cited the design note, whose Caps Lock
section taught the same false reason — both corrected, the note in its rewrite. And
`indicators.lua`'s comment said the Shift state is *"edge-tracked, not isDown"* when its caller now
passes `Key.shift()`, i.e. exactly `isDown` (**`ece2c1b`**).

**The design of record is rewritten** (`doc/development/internals/examples/keyboard.md`), which
§15.4 required *before* the code and which I had not done — disclosed to the revalidator rather than
left for it to find. It now describes the shipped mechanism, covers both consumers, drops the
unsourced platform sentence, states the unpollable-character residue, and carries a smoke checklist
naming the cases only a human can reach.

**The lesson worth carrying, because it is the session's second instance:** a claim about a
library's behaviour, written from expectation rather than measurement, propagated from a design
document into code and cost a crash. The earlier instance was the platform sentence this same
document had to strike. **Measuring took one throwaway LÖVE script and 20 seconds.**

---

## 8. Execution record (session38, 2026-08-12)

| step | commit | note |
|---|---|---|
| **P-18-04** `Ctrl+Alt+H` | `e6c8f97` | `sc["ctrl+alt+h"]` dispatched through a new `onHint` descriptor entry (only `alt.lua` defines one), the shape `onNotch` already has; `fn.ignore_repeat` wraps the action, `claimChord` sits outside it; the hand match leaves `altKeypressed` |

**Two behaviour changes accepted with P-18-04**, both written into
`doc/development/internals/examples/keyboard.md` ("A chord owns its trigger key") and the code
comments, not only into the commit message:

- **A shortcut is swallowed in every scene.** The hand match let a bare `h` reach the games that
  judge key targets (Press, Find, Blow the bubble), where the teacher chord knocked as a wrong key.
  Incidental, and the other reserved chords behave this way already. It is the one item in this step
  that touches §1.1's *"would a player notice a difference?"* test, which is why it is stated rather
  than absorbed.
- **The dispatcher keeps the pause gate** the scene handler gave it for free (`hintReenable` returns
  while `PAUSED`), so the chord stays inert behind the pause screen. The notch deliberately does not
  — upstream ran `reservedChord` above its own `PAUSED` check, so that exemption is the author's.

**Smoke rows added in the same change set:** `B11` (hold the chord — it must re-arm once, not once
per repeat frame) and `B12` (press it while paused — nothing). Both `[new]`; the platform-side doc
commit carries them.
