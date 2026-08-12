# S37 — cold revalidation of the landed P-18 work against mandate and intent

**Written:** 2026-08-12, session37, on commission (`../prompts/P-18-revalidation.md`). Read-only:
nothing outside this file was changed, and no git state in either repository was touched.

**What is judged:** five commits in the nested repo `/repo/src/examples/keyboard`, newest last —
`ca6d5df`, `c60b818`, `c1ee63c`, `c3388de`, `9a20433` — against the mandate
(`agents/validation.md`, "The strategic frame"), the governing constraint
(`P-18-00-keyboard-deepfix-design.md` §1.1: *the game's rules are never changed*), the design
reasoning (§7.1 R1–R5, §9), the step (`S27-triage-and-plan.md` §15.4, `P-18-00-triage-and-plan.md`),
the adoption checklist (`conventions/input_adoption.md`) and the ledger.

**Baseline for "player-visible".** Upstream, `origin/dsent/dev`, as §2.1 of the design document
requires. Everything below that says "upstream" was read at that ref, not remembered.

**Verification honestly stated.** Nothing was observed in a game scene. The container cannot inject
keystrokes; `xvfb-run love src` reaches the console and the intro. One fact was **measured** — see
F1 — in a standalone LÖVE 11.5 program; every other behavioural statement is traced through code.
The platform suite was run and is **946 / 0 / 0 / 10**, so the four commit messages that assert that
number are correct (they touch no platform code, so this was never in doubt).

---

## Verdict

**Sound in design; unsound as landed.**

The mechanism is right, and I would not change it: a key whose character has been delivered stays
claimed until the device says it is up. It is more predictable than what it replaces, not merely more
elaborate — it deletes a table, a tuned constant and a dependency on the debug frame counter, and it
removes the inter-channel read that made the game deaf. R2, R3 and R4 are satisfied by construction
and R5 structurally. Four of the five commits are what they claim to be, and `9a20433` and the
`isMod` half of `c3388de` are exactly behaviour-neutral, verified against the platform's own
`fold_mod`.

It is nevertheless **not safe to offer as a diff against upstream at `9a20433`**, for three reasons:

1. **F1 is a crash reachable with one keystroke** in the Words scene, and its cause is the single
   item of the design's own "diff, in full" (§9.5h) that did not land.
2. **F2 is a player-visible regression against upstream** that a commit message describes as a
   pre-existing leak being *closed*. That claim is false, and it hides the regression.
3. **F3 is a fourth narrowing** of the same kind as the three `c1ee63c` restored, not restored and
   not recorded, against a rule of restraint that says a narrowing must be said or not done.

None of the three needs a rule decision, a redesign or an owner ruling. F1 is the omitted helper;
F3 is one registration; F2 is a claim in the two remaining chord paths. The tree is close, and the
verdict is about the tree, not the thinking.

**Note on state.** HEAD is an *incomplete* step by the plan's own record: P-18-04 (`Ctrl+Alt+H` →
shortcut, "the handler claims its trigger"), P-18-05 and P-18-06 (comments, including the capslock
one) are explicitly left for a successor (`P-18-00-triage-and-plan.md` §6). F4 and part of F2 are
therefore **known** outstanding items, and I say so where they are; F1, F3, F5 and the false claim
inside F2 are not on any list I found.

---

## Findings, by severity

### F1 — CRITICAL: `inputTick` can raise, and the Words scene can reach it with one keystroke

`src/examples/keyboard/input.lua:169-175`, `src/examples/keyboard/words.lua:147-151`

```lua
function inputTick()
  for k in pairs(GLYPH_CLAIMED) do
    if not love.keyboard.isDown(k) then      -- <= raises on a non-KeyConstant
```

`love.keyboard.isDown` does not answer *false* for a string that is not a LÖVE KeyConstant; it
**raises**. Measured, LÖVE 11.5, standalone program, `pcall` per name:

| name | `love.keyboard.isDown` |
|---|---|
| `%` `_` `+` `:` `"` `<` `>` `?` `!` `@` `#` `$` `^` `&` `*` `(` `)` | returns false |
| **`~` `{` `}` `\|`** | **raises** `Invalid key constant: ~` etc. |
| **`é`** (any non-ASCII) | **raises** |

`wordsBaseKey` returns the character itself for anything that is neither `" "` nor alphabetic:

```lua
function wordsBaseKey(ch)
  if ch == " " then return "space" end
  if isAlphaChar(ch) then return string.lower(ch) end
  return ch                              -- "~" stays "~"
end
```

`isAlphaChar` is `#t == 1 and t:match("%a")` (`indicators.lua:13-15`), so a two-byte character also
falls through to `return ch`.

**The reachable path, traced.** Words scene → player presses `Shift+` `` ` `` (or `Shift+[`,
`Shift+]`, `Shift+\`) → `appTextinput("~")`: not paused, `Key.alt()` false, `Key.ctrl()` false, help
not shown, `isAlphaChar` false so no `capsReconcile` → `SCENES.words.textinput` (`words.lua:360-361`)
→ `wordsTextinput("~")` → `spendGlyph("~")` → `GLYPH_CLAIMED["~"] = true`. **The claim is set before
any of the scene's own guards**, so it happens on the level-over screen too. Next frame,
`main.lua:127` calls `inputTick()` → `love.keyboard.isDown("~")` → error.

**What the player sees.** `inputTick` runs in `love.update` *outside* the example's own `pcall`
(which only wraps `updateStep`, and only when `DEBUG`, which is `false` at `main.lua:16`). The error
propagates to the framework's `wrap` → `xpcall` → `user_error_handler` → `CC:suspend_run(...)`
(`src/controller/controller.lua:102-130, 589-595`). The game stops and the child is returned to an
error message.

**Cause: the one omitted item of the design's own diff.** §9.5h, "The diff, in full", lists three
things; two landed. The third did not:

> *"the shifted-symbol map moves down from `alt.lua` (where `ALT_BASE` inverts `SHIFT_MAP` at load)
> into `input.lua` … `wordsBaseKey` keeps its name and delegates, **which is also what fixes its
> missing shifted-symbol case**."*

`ALT_BASE` is still built in `alt.lua:46-49` and `wordsBaseKey` still does not consult it. With the
helper landed, `"~"` maps to `` "`" `` and there is no crash. `alt.lua` is therefore safe on a US
layout — `altBaseKey` (`alt.lua:68-74`) inverts `SHIFT_MAP`, and every value of `SHIFT_MAP`
(`config.lua:338-344`) has a base key — but **both** scenes crash on a character `textBaseKey` cannot
name at all: an IME composition, a dead key, an AltGr symbol, any non-US layout.

**The design document is wrong on this point too, and its error is the reason nobody looked.** §9.5f,
under "One behaviour both variants share, stated so it is not discovered later"
(`P-18-00-keyboard-deepfix-design.md:930-936`):

> *"the entry is then keyed by a name that no `love.keyreleased` will ever match; **the frame poll
> rescues it** (`Key.any_pressed("é")` is false, so it clears on the next frame)"*

It is not false. It raises — `Key.any_pressed` is `love.keyboard.isDown(...)` unchanged
(`src/util/key.lua:134-139`). The mechanism's stated safety net for un-nameable characters is the
crash. This sentence needs correcting wherever it is repeated, independently of the code fix.

**Not observed:** I did not drive the Words scene. What is measured is that `isDown` raises on those
four ASCII names and on non-ASCII; what is traced by reading is the path that hands it those names.

---

### F2 — HIGH: the chord claim covers only `alt+<key>`, and the commit's account of it is false

`src/examples/keyboard/input.lua:103-107`, `:217-228`; `alt.lua:213-216`

`c60b818` claims:

> *"The `alt+*` shortcut now CLAIMS the chord's trigger key, which closes a leak this game has
> always had: Alt+H, then letting go of Alt while H stays down, leaves H repeating, and those glyphs
> reached the scene as a typed answer."*

**Upstream did not have that leak.** `origin/dsent/dev:input.lua`, `appKeypressed`:

```lua
if inputStale(k) and k ~= "capslock" then return end
dbgLog("KP " .. k)
INPUT.held[k] = true ; inputUpdateMods()      -- <= BEFORE the swallow
if reservedChord(k) then return end
if appChord(k) then return end
```

`INPUT.held[k]` is set **before** `appChord` swallows the chord, so the trigger of *every* chord was
in the held set, and `inputStale` in the scenes' `textinput` dropped its characters — in either
delivery order, since the flag was set by the press that started the hold. The leak is **this
branch's**, created when the migration deleted the held set. Calling it a leak "this game has always
had" credits the fix with closing an upstream defect that did not exist, and it conceals that what
remains is a regression rather than inherited debt.

**What remains.** A claim is taken in exactly two places: a scene calling `spendGlyph` on a character
it was *handed*, and `claimChord` from `sc["alt+*"]` / `sc["alt+p"]`. Everything else that suppresses
a character takes no claim, so the trigger is free the moment the suppressor stops applying:

| gesture at HEAD | upstream | HEAD |
|---|---|---|
| **Ctrl+Alt+H**, release Ctrl+Alt with `h` still down | `h` held → every character dropped | no claim was ever taken → **one stray `h` is judged**, then the repeats are claimed |
| **Alt+Shift+`x`**, release the modifiers with `x` down | dropped (see F3: swallowed by `appChord`) | one stray `x` judged |
| **Ctrl+`x`**, release Ctrl with `x` down | dropped | one stray `x` judged |
| a key held while **paused** (`alt+p`), then unpaused | dropped | one stray character judged |
| a key held while the **help overlay** is up, then Alt released | dropped | one stray character judged |

In `alt.lua` a stray character is a miss on a target the player did not answer; in `words.lua` it is
a wrong character that costs `WORDS.wordClean` and knocks, with no idempotence guard
(`words.lua:210-215`). **A player would notice**, which is §1.1's test.

**It fails the design of record's own smoke item**, which names this exact case
(`doc/development/internals/examples/keyboard.md`, "Smoke checklist"):

> *"`Ctrl+Alt+H` **releasing the modifiers while `H` stays down** — no stray `h` reaches the target,
> and the target is not fumbled"*

Both `c60b818` and `P-18-00-triage-and-plan.md` §4/§6 list that item as *what a human still owes*.
It is not owed; it is decidable by reading, and the answer is that it does not hold.

**Coverage of the plan.** P-18-04 would close the `Ctrl+Alt+H` row ("the handler claims its
trigger"). Nothing on the list covers `Alt+Shift+*`, `Ctrl+*`, the pause row or the help row — and
the last two are structural: `appTextinput`'s guards (`input.lua:218-221`) return before the claim
is taken, and the design's own sketch (§9.5g) has the register below the guards, so the design
shares the hole and did not notice it.

Also, `alt.lua:178-181` now says the claim stops *"a chord key's trailing glyph (e.g. after Alt+H,
whose shortcut claims the trigger) fumbling the live target."* True of Alt+H, false of the game's
other chord, Ctrl+Alt+H, in the same file.

---

### F3 — HIGH: a fourth narrowing, of the same kind as the three restored, not restored and not said

`src/examples/keyboard/input.lua:81-86` (the comment), `:103` (the binding)

Upstream had **three** one-sided modifier predicates, not two. `appChord` is the third:

```lua
function appChord(k)
  if INPUT.ctrl then return false end
  if not INPUT.alt then return false end     -- says NOTHING about Shift
  if k == "p" then pauseToggle() end
  return true
end
```

So upstream swallowed **Alt+Shift+`k`** as well as Alt+`k`. A combo is its held modifier set exactly
— `combo_string` prepends every held modifier (`src/controller/controller.lua:402-411`) — so
Alt+Shift+`x` serialises as `alt+shift+x`, and the lookup tries `alt+shift+x` then the class
`alt+shift+*` (`src/controller/projectInputController.lua:104-114`). `alt+*` cannot match it. The
gesture now falls through to `appKeypressed` and reaches the scene.

**Player-visible:** every findkey-shaped scene treats it as a wrong key — `findkey.lua:129-134`,
and the same idiom in `astrocore.lua:139-147`, `hide.lua:270-277`, `train.lua:235-242`,
`bubble.lua:142-149`, `alt.lua:200-207` (their guards exclude modifiers and `capslock`, not a
trigger pressed *with* modifiers). And the intro typewriter finishes on any key, so Alt+Shift+
anything now skips it where upstream it did not. It also leaves F2's leak open for that gesture,
since no claim is taken.

**`c1ee63c` restored the two `reservedChord` narrowings and missed this one**, though it is the same
defect from the same cause; the comment it added enumerates *"'shift and not ctrl' also accepted Alt,
and 'ctrl and alt' also accepted Shift"* and reads as an exhaustive account. `P-18-00-triage-and-plan.md`
§5 RULE 1 is equally silent on it. The restoration is one registration —
`sc["alt+shift+*"] = fn.stop_here(claimChord)` — and `check_combo` accepts it (a class needs
modifiers, and this has two: `src/util/key.lua:86-99`).

Same family, one step smaller and mostly harmless: a **bare modifier pressed while Alt is held**
(hold Alt, then press Shift) was swallowed by `appChord` upstream and now reaches the scenes,
because a modifier trigger names no shortcut at all (`find_shortcut`, line 110) and
`Key.is_alt("lshift")` is false. The scenes' own guards absorb it; the intro does not.

`conventions/input_adoption.md`, Rules of restraint: *"**A narrowing is a change.** … Say it, or do
not do it."*

---

### F4 — MEDIUM: the capslock exemption's comment is still false, and it now cites a document that says the same false thing

`src/examples/keyboard/input.lua:177-185`

```lua
-- isr is the API's isrepeat (third hook argument): a held key
-- is filtered at the source instead of inferred from held
-- state. capslock is exempt because its release may not
-- arrive, so its next press can come in flagged as a repeat,
-- and dropping that would freeze the Caps estimate on a lock
-- the player did toggle (see the Caps Lock section of
-- doc/development/internals/examples/keyboard.md).
```

**The stated reason cannot happen under `isrepeat`.** A fresh press is never flagged as a repeat: the
OS knows the key is up regardless of which events reached the process. The reasoning is upstream's
and it was sound *there* — a lost release wedged `INPUT.held['capslock']` true for ever, so every
later press read stale and `capsToggle` never ran again. The new filter has no such set to wedge.
This is §9.5i of the design document, which says the comment *"is wrong and must be corrected
whatever else is decided"*, and it is carried as **P-18-06**, left for the successor. So the falsehood
is known.

**What is not recorded, and is a consequence of the disclosed stale note.** The comment sends the
reader to `doc/development/internals/examples/keyboard.md`, "Caps Lock", which states:

> *"**`keyreleased('capslock')`, reliably** — which is why `capslock` is exempt from the `isrepeat`
> filter in `keypressed`. With no release delivered, the next press can arrive flagged as a repeat,
> and dropping it would freeze the estimate on a lock the player has actually toggled."*

The stale note is not merely superseded on the judging mechanism (the disclosed gap) — **it is the
source of the false justification, it states it about the `isrepeat` filter specifically, and a live
code comment points at it for authority.** P-18-06 as written is a comment change; it would leave the
persistent document still teaching the error, and the next reader who checks the citation will find
it corroborated. The doc revision and the comment must move together.

Two further things the code says nowhere: that the exemption is **inherited from upstream and
preserved deliberately** (§5 RULE 3's ruling — the landed behaviour is identical to upstream's, which
I verified: upstream bypasses `inputStale` for `capslock` and reaches `capsToggle` on every repeat,
and so does this filter); and that the exemption's **effect has inverted** — it no longer protects a
toggle, it only decides what happens to capslock *repeats* (§9.5i).

---

### F5 — MEDIUM: a comment in the author's file was inverted, in a commit that names the call site

`src/examples/keyboard/indicators.lua:21-22`

```lua
-- Reconcile from one produced letter and the Shift state read
-- at the moment textinput fired (edge-tracked, not isDown).
function capsReconcile(letter, shift_held)
```

The parenthetical is now exactly backwards. `capsReconcile`'s only caller passes `Key.shift()`
(`input.lua:224`), and `Key.shift()` **is** `love.keyboard.isDown('lshift','rshift')`
(`src/util/key.lua:157-159`). `indicators.lua` is byte-identical to upstream
(`git diff origin/dsent/dev -- indicators.lua` is empty), where the comment was true —
`INPUT.shift` was maintained on press/release edges by `inputUpdateMods`.

**Attribution, stated precisely because the commit's own claim depends on it.** `c3388de` asserts
*"Behaviour is unchanged by construction: every call replaced was reaching the same function through
one more indirection"*, and that is correct — the `INPUT` proxy already resolved `shift` to
`Key.shift()`, so the edge-tracked → device-poll change belongs to the earlier migration commit that
built the proxy, not here. But `c3388de` enumerates *"its Caps reconciliation"* among the nine
readers it converted, so this is the commit that had the line open and left the author's comment
inverted three files away.

The substantive half is real and is on the human list (`P-18-00-triage-and-plan.md` §4.1): the poll
answers from SDL's post-pump state, so a Shift release delivered in the same event batch as the
character is already false at judgement time, where the mirror was not. Cheap to see, hard to see
*from the code*, which is what the comment was for.

---

### F6 — MEDIUM: R1 is not met for any character the game cannot name, and the file claims otherwise

`src/examples/keyboard/input.lua:156-168`, `words.lua:147-151`

The same omission as F1, in its non-crashing form. A claim keyed `"!"` is a valid KeyConstant, so no
error — but the physical key that is down is `"1"`, so `love.keyboard.isDown("!")` is false and the
poll clears the claim **every frame**. Holding `Shift+1` in Words therefore knocks once per frame
(`wordsBad` → `SOUND.reject()`, no `fumbled`-style guard, `words.lua:210-215`). Every shifted symbol
except the four that crash behaves this way; `alt.lua` is unaffected because `altBaseKey` inverts
`SHIFT_MAP`.

**Not a regression** — upstream's `inputStale("!")` never matched either, since `INPUT.held` was
keyed by real key names. It is the specific defect §9.5 identified, scheduled into the diff, and left
out. What makes it a finding rather than a note is the comment now above the poll:

> *"Claims are released by the DEVICE, once a frame, and by nothing else."*

Which is true only for keys the game can name. And R1 — *one `love.textinput` accepted per physical
press; OS repeats produce nothing* — is unmet on that set.

---

### F7 — LOW: the smoke evidence for `c60b818` does not reach the code it vouches for

`src/examples/keyboard/main.lua:125-135`; `c60b818`'s message and
`P-18-00-triage-and-plan.md` §6

> *"`inputTick` executes on every frame ahead of the debug `pcall`, so a fault in it would have
> crashed the run."*

Positionally accurate. But with no keystrokes injected, `GLYPH_CLAIMED` is empty for the whole run, so
what executed is the `for` statement and **nothing inside the loop**. The one fault that was there —
F1 — is a fault in the body. The sentence reads as coverage of `inputTick` and covers its first line.
Worth correcting because the same sentence is the execution record's justification too.

---

### F8 — LOW: four lines of the author's `love.update` were reformatted beyond the change

`src/examples/keyboard/main.lua:128-134`. `c60b818` stripped trailing whitespace and moved `then`
placement on lines it did not otherwise need to touch, in the author's file, inside a step whose
stated principle is minimisation (§9.5h, *"keep the names the original uses"*). Harmless; noted
because it enlarges the diff a reviewer of the upstream PR reads.

### F9 — LOW: `GLYPH_CLAIMED` is initialised twice

`src/examples/keyboard/input.lua:113` (in `inputInit`) and `:144` (top level). Both run — the file's
top level first at `dofile`, then `inputInit()` from `main.lua:85` — so one is dead. The comment block
at `:131-143` explains the mechanism above the redundant one. §9.5h's diff has it once.

---

## R1–R5 (§7.1), per requirement, with the code path

| # | requirement | verdict | path and reasoning |
|---|---|---|---|
| **R1** | one `textinput` accepted per physical press; OS repeats produce nothing | **partially met** | `appTextinput` (`input.lua:217-228`) → scene → `spendGlyph` (`:150-154`) sets `GLYPH_CLAIMED[k]`; released only when `love.keyboard.isDown(k)` is false at frame top (`:169-175`). Correct wherever the base key names the physical key — every letter, digit, `space`, and every Alt-scene symbol via `ALT_BASE`. **Fails** for a Words shifted symbol (F6) and **raises** for four of them (F1). |
| **R2** | no dependence on the relative order of `keypressed` and `textinput` | **met** | `spendGlyph` consults only `GLYPH_CLAIMED`; nothing in the accept decision reads state owned by the other channel. The release consults the device at frame time, after LÖVE has drained the whole batch, so no intra-batch order can reach it. The two schemes §2.2 rules out are both absent. *Residual, inherited from the migration and not from these commits:* `appTextinput`'s own guards are now device polls (`Key.alt()`, `Key.ctrl()`, `:219-220`) reading post-pump state, which is a cross-channel read at event time — same family, different question, and it decides suppression rather than repeat-identity. |
| **R3** | a character whose `textinput` arrives **after** its key's `keyreleased` must not be lost | **met** | `appKeyreleased` (`:207-211`) holds no judgement state at all — the two lines that maintained `upRecent`/`GLYPH_CLAIMED` are gone, and `INPUT_UP_GRACE` with them. Such a character is the *first* of its press, meets no claim, and is accepted. The acknowledged residue stands: release and re-press inside one event batch loses the second character (§9.5g, last row), which needs sub-16 ms human timing. |
| **R4** | a missed `keyreleased` must not silence the key | **met, with F1's caveat** | `keyreleased` is not consulted by the mechanism, so it cannot be missed: focus loss, `capslock`'s unreliable release, anything. The poll resolves on the next frame. The caveat is severe rather than partial — for a key whose name raises, the "rescue" is the crash (F1). |
| **R5** | both scenes served without either carrying the other's special cases | **met structurally, defeated in one detail** | `GLYPH_CLAIMED` / `spendGlyph` / `inputTick` are in `input.lua`; each scene calls it with its own base-key helper and neither knows about the other. But the shared helper §9.5h required did not land, so `wordsBaseKey` carries a defect `altBaseKey` does not — the exact asymmetry the shared helper existed to remove. |

**The traces §9's cases ask for**, all read rather than run:

- **A held key.** First character claims; each repeat meets the claim and is dropped; `isDown` is
  true every frame so the claim stands. ✓
- **A trailing repeat after the release.** The release changes nothing; the trailing character in the
  same batch meets the still-set claim and is dropped; the poll clears it next frame. ✓ This is what
  the grace window bought, obtained from the frame boundary instead of a constant.
- **A fast tap.** No window exists to reject it. ✓ (Two taps inside one batch lose the second.)
- **A chord whose modifier is released while the trigger stays down.** ✓ for `alt+<key>` — the class
  claims the trigger and the claim outlives the modifier. ✗ for Ctrl+Alt+H, Alt+Shift+`k`, Ctrl+`k`
  (F2).
- **The help overlay held while the poll runs.** ✓ and this is the commits' best call.
  `helpOverlayShown` → `helpHeld` polls `isDown("h")` (`help.lua:16-19`), and `updateStep` returns
  early while the overlay is up (`main.lua:114-116`) — so `inputTick` had to go in `love.update`
  instead, which is a **deliberate divergence from §9.5h's letter** ("one call to `inputTick()` in
  `updateStep`") for a reason §9.5h missed: `updateStep` also returns before `DREW_ONCE` and while
  paused, and the overlay *is* held Alt+H, whose trigger is claimed. Placed as §9.5h said, a claim
  would outlive its key in ordinary use. The commit states this and it checks out.

---

## Verified sound — what I tried to break and could not

Recorded so the parent knows which claims survived, not only which failed.

- **`9a20433` is exactly behaviour-neutral.** `Key.is_mod(k)` is `fold_mod[k] ~= nil`, and `fold_mod`
  is built from `mod_triples` = `{lctrl,rctrl},{lalt,ralt},{lshift,rshift}` (`src/util/key.lua:15-32`)
  — the same six names, no more, as upstream's hand-written `isMod`. `gui`/`mode` are not in it. All
  six call sites are `not Key.is_mod(k) and k ~= "capslock"` wrong-key guards and read identically.
- **`Key.is_alt(k)` restores the bare-Alt swallow exactly.** `table.is_member(alt_k, k)` with
  `alt_k = { "lalt", "ralt" }` (`src/util/key.lua:7, 172-174, 193`). Its placement *after* the `capslock`,
  `PAUSED` and help lines is behaviourally identical to upstream's placement before them, since the
  only line with a side effect is gated on `k == "capslock"`.
- **The two restored gesture sets are complete for their predicates.** `escape and shift and not
  ctrl` = {shift+esc, alt+shift+esc}; `ctrl and alt and up` = {ctrl+alt+up, ctrl+alt+shift+up}. Both
  bound, to hoisted handler values so the second binding is a reference (`input.lua:90-102`).
- **`alt+p` pauses once per press.** Shortcuts receive LÖVE's raw payload — `dispatch` forwards `...`
  (`projectInputController.lua:135-145`) and `stop_here` forwards `...`
  (`consoleController.lua:494-500`) — so `(k, _, isr)` binds `(key, scancode, isrepeat)` per
  `doc/input_api.md`, and `if not isr then pauseToggle() end` fires on the fresh press only. The
  claim sits outside the repeat gate, as the comment says and as the mechanism needs.
- **Alt+CapsLock still does not toggle the estimate**, as upstream. `capslock` is not a modifier by
  `Key.is_mod`, so it is an ordinary trigger, so `alt+*` matches and `stop_here` consumes before
  `appKeypressed`'s `capsToggle` — which is exactly where upstream's `appChord` swallowed it.
  Ctrl+CapsLock reaches `capsToggle` in both.
- **Markers.** Exactly one retired: the `INPUT`-proxy `REMARK`, in `c3388de`, answered by the
  deletion it asks about — legitimate. The `setTextInput` `REMARK` (`input.lua:111`) is untouched and
  unanswered. Upstream carries no markers at all; the repo has no `INTERIM:`. Verified marker-by-
  marker across all five commits. The claim *"no other marker in the repository is touched"* is true.
- **Scope: `bubble.lua` was honoured.** One line, the wrong-key guard
  (`git diff origin/dsent/dev HEAD -- bubble.lua` is a single hunk), the ruling in §0(a) / §1.26. The
  game's only `keyreleased` consumer still gets its dispatch (`input.lua:207-211`). `astrocore.lua`,
  `findkey.lua`, `hide.lua`, `train.lua`: one line each, same guard. Nothing of the author's is
  damaged.
- **The whole branch is 11 files / 232 insertions against upstream**, of which `input.lua` is 283
  changed lines and everything else is small. No moving part beyond the ask, F8 aside.
- **`inputTick`'s traversal is legal**: assigning `nil` to the current key inside `pairs` is
  explicitly permitted in Lua.
- **`claimChord` cannot crash**: its argument comes from LÖVE's own `keypressed`, so it is always a
  real KeyConstant. F1's exposure is only through the character→key inference.
- **Suite:** 946 / 0 / 0 / 10, unchanged, as four commit messages claim.

---

## Raised, not recommended

Rule opinions, kept out of the findings deliberately.

1. **The stale design of record wants F2's stray character *counted* in one case.** Its smoke
   checklist asks for both *"no stray `h` reaches the target"* and, next line, *"the same, **while the
   target is `h`** — the trailing `h` counts as a win rather than being swallowed."* Upstream swallows
   it either way. Closing F2 by claiming every chord's trigger matches upstream and contradicts that
   second item. I judged against upstream, because §1.1 does; if the ratified note's preference is
   the intended rule, that is the author's call, not a validator's, and it should be settled before
   P-18-04 lands rather than discovered by it.
2. **`wordsBad` has no idempotence guard where `alt.lua` has `ALT.fumbled`.** Under F6 that is
   audible — a knock per frame while a shifted symbol is held. Fixing the base-key map removes the
   symptom without touching the rule. Adding a guard would be a rule change, and the design already
   withdrew that proposal (§1.1, withdrawn proposal 2). No recommendation.
3. **`Key.any_pressed(k)` for a single key still reads oddly** (§9.5e's recorded wart), and the code
   sidesteps it by calling `love.keyboard.isDown` with a comment. That is the owner's ruling and is
   right for portability to the upstream standalone program. Only noted because F1 means the comment
   recommending `Key.any_pressed` recommends a call with the same defect.

---

## What I could not determine

- **Nothing was observed in a game scene.** No keystroke injection, no device. Every behavioural
  statement above is traced through code except the one measurement named in F1.
- **Specifically not observed:** F1's crash firing inside the running game; the fast tap of a target
  character registering; Ctrl+Alt+H with the modifiers released while H stays down; any Alt+Shift
  gesture; the Caps decal under the poll (the §4.1 human item); whether the OS repeats `capslock`
  at all (§4.2 — and by RULE 3 that observation is no longer owed).
- **`harmony` cannot settle F1 and is not evidence either way.** It can inject keys
  (`h.love_key` / `h.love_text`), but it patches `love.keyboard.isDown` and in lock mode never
  reaches the real call (`src/harmony/init.lua:242-254`) — so it would **mask** the raise rather than
  reproduce it, and its faked held-set is not the mechanism under test.
- **Whether a doubled letter types correctly in Words** (`"all"` — the case that killed the ratified
  content-scoped rule) is sound by reading under press-identity, and unobserved.
- **The android/`.apk` half of §1.2's attestation** is outside anything this container can reach; I
  neither confirmed nor disturbed it.
- **F5's practical frequency** — how often a Shift release shares an event batch with the character
  it modified — is a timing question about SDL and the OS that needs measurement on a device, not
  reasoning.
