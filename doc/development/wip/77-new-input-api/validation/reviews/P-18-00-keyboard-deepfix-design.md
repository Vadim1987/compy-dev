# P-18-00 — the keyboard deepfix: analysis and design

**Step:** P-18-00, the initial analysis/planning pass of P18 (`S27-triage-and-plan.md` §15.4).
**Opened:** 2026-08-11, session37, after the upstream merge landed (`keyboard` @ `ca6d5df`).
**Status: NOTHING HERE IS DECIDED.** §2–§7 are exposition — what the code does, read from the
merged tree. §8 lists the open questions. Decisions are the owner's and are recorded, one at a
time, as they are taken.

---

## 0. The agenda for this step

Stored here at the owner's instruction so it survives the chat. Order is a proposal; the owner cuts
and reorders it.

1. **The two `love.textinput` consumers** — how `alt.lua` and `words.lua` each use the event, what
   each requires from the shared layer, and what the merge changed about the heal's premise. §2–§7
   below. **This is where the step starts, because it decides whether the ratified design survives.**
2. **The heal proper** — `internals/examples/keyboard.md` re-read against two consumers: where the
   per-press state lives, whether the win-transition block generalises, what is subtracted.
3. **The `INPUT` table's dissolution and `INPUT.upRecent`'s fate** — both ride with item 2 and
   cannot be sequenced before it.
4. **`isMod` and the hand-written `k ~= "capslock"` test** — six call sites in five files, one
   decision.
5. **`alt.lua:214`'s hand-matched `Ctrl+Alt+H`** — `if k == "h" and INPUT.ctrl and INPUT.alt`.
6. **`bubble.lua`** — new from upstream; whether it is in scope at all, discussed rather than
   assumed.
7. **`love.mouse.setRelativeMode(true)` in `main.lua`** — whether the example-side half belongs in
   this step.
8. **Not reopened unless the owner says so:** `helpHeld`'s poll in `help.lua` (Decision 32 ruled it
   correct).

## 1. Terminology used here

The owner asked for unambiguous terms, so this document uses only:

- **LÖVE events and their payloads**: `love.keypressed(key, scancode, isrepeat)`,
  `love.keyreleased(key, scancode)`, `love.textinput(text)`. `key` is a LÖVE KeyConstant string
  (`"a"`, `"lshift"`, `"return"`); `text` is a UTF-8 string, normally one character.
- **Named functions, variables and fields** as they appear in the code.

Where the code's own identifiers contain the words *glyph* or *judge* (`spendGlyph`,
`GLYPH_CLAIMED`), they are used **as identifiers only**, never as concepts. No claim in this
document rests on either word.

## 1.1 The governing constraint (owner ruling, 2026-08-11) — the rules are not ours

> *"We are **never** changing game rules in `keyboard`. What we do is tweaking the
> **implementation** to use appropriate underlying mechanisms, trying to find an exact fit."*

**This governs every item on the agenda**, and it is a boundary rather than a preference: what the
player experiences is the author's, and the step's whole licence is to change *how* it is produced.

**The test it imposes**, and the one every proposal below is measured against: *would a player
notice a difference?* If yes, it is a rule change and it is out of scope, however well-motivated.
If no, it is an implementation fit and it is exactly what this step is for.

**What the authored rules are here, read from the code rather than assumed.** Both scenes were
written to accept **one character per physical press**, with OS key-repeat suppressed:

- `alt.lua`'s own comment states the intent directly — *"a held wrong key (its `textinput` repeats
  every frame) cannot knock continuously"*, and a held correct key must not bleed onto the next
  target.
- `words.lua`'s states it by reference — *"the `inputStale` guard drops a held/released or chord
  glyph, exactly as Alt does"*.
- Upstream's `inputStale` implements exactly that under the delivery order the author develops on
  (`love.textinput` first): the key is not yet held at its own first character, so that one is
  accepted, and the repeats arriving while it is held are dropped.

So **repeat-suppression is a rule, not an artifact**. What is an artifact — and therefore in scope
— is everything about *how* that rule is enforced: the dependence on delivery order (which is what
made the same code deaf on the device), the dependence on a release event arriving, and the frame
counter borrowed from the debug logger.

**Two proposals of mine are withdrawn under this ruling**, recorded because they were argued in the
session and someone reading only the outcome would wonder why they are absent:

1. **"Words could take the OS repeat as typing"** — that a held key types repeatedly, as it would
   in a text editor. It is a rule change: a player holding `l` would see `lll` where the authored
   game shows one `l`. Out of scope, whatever its merits as game design.
2. **"Guard the knock in `wordsBad` so a held wrong key does not knock per repeat"** — proposed
   only as a mitigation for (1). With repeat-suppression correctly implemented the knock already
   fires once per press, which is the authored behaviour, so the guard is unnecessary as well as
   forbidden.

**Precedent, same category:** `sapper`'s conversion in session36 was mechanically faithful and
still destroyed the feature's purpose, and was reverted. The lesson recorded then — *purpose beats
shape*, and *ask the author* — is this ruling's ancestor.

## 1.2 The order between the two channels is not guaranteed — attestation and principle

**Owner attestation, 2026-08-11.** Attested: **the game is deaf on desktop Linux — the nodejs
setup, run as `love src`.** Suspected, and labelled as such by the owner: it works as intended on
Android from an assembled `.apk`, on the grounds that **the author uses it there**. Recorded here
because it is first-hand evidence this session cannot reproduce: the container has no device and
cannot inject keystrokes.

**Owner principle, same message, and it is the stronger half:** *"relying on the order the library
does not guarantee is wrong anyway — any release of LÖVE2D could break both games,
irrecoverably."*

This is a **hard constraint on the mechanism, independent of which platform currently works**. A
mechanism that happens to produce the authored rule on one delivery order is not correct; it is
lucky, and the luck is held by a third party's release notes. "Irrecoverably" is precise: the
failure mode is total — nothing can be typed, and the player has no way around it.

**Both games are exposed today.** `alt.lua` and `words.lua` sit behind the same helper, so a flip
in delivery order does not degrade them, it silences them.

**The platform prose in the corpus is unsourced and is to be struck, not reconciled.** The design of
record (`internals/examples/keyboard.md`) asserts *"Desktop LÖVE sends `keypressed` first; the web
build sends `textinput` first"*, and the sprint's record elsewhere speaks of the Alt scene being
*"deaf on hardware"* while working in "the IDE". **Owner, 2026-08-11: those claims about what
"hardware" and "device" were are speculation of little value.** Only the attestation above is
evidence. When this step revises the design document, that sentence is **removed rather than
corrected** — R2 makes the platform question irrelevant to the mechanism, and an unsourced platform
claim in a persistent document is worse than no claim, because it reads as measurement.

**What the attestation does and does not change about the work.** It confirms the failure is real
and reachable in the environment we actually run in. It does **not** describe the tree as it now
stands: both scenes are already order-agnostic here — `alt.lua` since this branch's `3a9d48c`
(*"accept the first glyph of a press, whatever order it arrives in"*), and `words.lua` since
`ca6d5df`, which routed it to the same mechanism. **So R1 and R2 are satisfied in the merged tree
today, and what remains open is R3 and R4** — the trailing `love.textinput` after `love.keyreleased`,
and a `love.keyreleased` that never arrives. The deafness is the defect that motivated the heal; it
is not the defect the heal still has to fix.

## 2. The shared layer both scenes sit behind (`input.lua`)

All three events arrive as `compy.input.hooks.*`, registered in `inputInit`. The scene sees only
what these three functions pass on.

**`appKeypressed(k, _, isr)`** — the hook receives LÖVE's three arguments; the middle one
(`scancode`) is discarded.

1. `if isr and k ~= "capslock" then return end` — OS repeats are dropped here, at the source.
2. `if k == "capslock" then capsToggle() end`.
3. `if PAUSED then return end`; `if helpOverlayShown() then return end`.
4. `SCENES[ACTIVE].keypressed(k)` — **one argument**. `isrepeat` is *not* forwarded, so no scene
   can see it.

**`appKeyreleased(k)`** — writes `INPUT.upRecent[k] = DBG_FRAME`, clears `GLYPH_CLAIMED[k]`, then
calls `SCENES[ACTIVE].keyreleased(k)`.

**`appTextinput(t)`**

1. `if PAUSED then return end`.
2. `if INPUT.alt then return end`; `if INPUT.ctrl then return end` — a character produced while
   Alt or Ctrl is held never reaches a scene. Shift is deliberately not filtered.
3. `if helpOverlayShown() then return end`.
4. `if isAlphaChar(t) then capsReconcile(t, INPUT.shift) end` — the app-wide Caps estimate,
   updated before dispatch.
5. `SCENES[ACTIVE].textinput(t)`.

**`spendGlyph(k)`** — the shared per-press mechanism, in `input.lua`, called by both scenes:

```lua
function spendGlyph(k)
  if GLYPH_CLAIMED[k] then return true end       -- already accepted one this press
  local up = INPUT.upRecent[k]
  if up and DBG_FRAME - up <= INPUT_UP_GRACE then return true end
  GLYPH_CLAIMED[k] = true
  return false
end
```

It answers **"has a `love.textinput` for this key already been accepted since the key's last
`love.keyreleased`?"** — a question about the *physical press*, not about the character's content.
`GLYPH_CLAIMED[k]` is cleared in `appKeyreleased`; `INPUT_UP_GRACE` (= 1 frame, measured in
`DBG_FRAME`) additionally rejects a `love.textinput` arriving just after that key's
`love.keyreleased`.

## 3. `alt.lua` — what it does with the events

**Target:** `gaugeCurrent(ALT)` — **one item at a time**, either a single character (`"a"`, `"7"`,
`"!"`, `" "`) or a key name (`"backspace"`, `"tab"`, `"return"`). `altIsKeyTarget(item)` says
which. A correct answer advances to the next target immediately (`gaugeOnCorrect` → `gaugeNext`).

**On `love.textinput`** — `altTextinput(ch)`, in order:

```lua
if spendGlyph(altBaseKey(ch)) then return end   -- one accepted char per press
if fkDone(ALT) then return end                  -- end screen showing
if not gaugeGlowing(ALT) then return end        -- target not live
if altIsKeyTarget(gaugeCurrent(ALT)) then return end  -- key-name target: not this channel
if ch == gaugeCurrent(ALT) then altHit() else altWrong() end
```

`altBaseKey(ch)` maps the character to the key it is produced on (`"A"` → `"a"`, `" "` → `"space"`),
which is what `spendGlyph` is keyed by.

**On `love.keypressed`** — `altKeypressed(k)` handles `Ctrl+Alt+H` (§8.5), then the end screen,
then `altPlayKey(k)`, which acts **only** when the current target is a key name:

```lua
if k == gaugeCurrent(ALT) then altHit()
elseif not isMod(k) and k ~= "capslock" then altWrong() end
```

**On `love.keyreleased`** — `alt.lua` registers no handler. Nothing of Alt's depends on it directly;
the shared `appKeyreleased` clears `GLYPH_CLAIMED[k]` on its behalf.

**Wrong answers are idempotent per target:** `altWrong` plays a sound only when `ALT.fumbled` is
false, and `gaugeOnWrong` returns immediately once `st.fumbled` is set. Several wrong characters
read as one miss, by design.

## 4. `words.lua` — what it does with the events

**Target:** a **string**, not an item. `WORDS.line` is a generated line of words (order-2 Markov
over a bundled corpus); `WORDS.pos` indexes the character expected next;
`wordsExpected()` returns `WORDS.line:sub(WORDS.pos, WORDS.pos)`. Typing is strict left to right,
no backspace. A correct character advances `WORDS.pos` by one and can complete a word
(`wordsCheckWord` → `wordsScoreWord`) or the line (`wordsEndLine`).

**On `love.textinput`** — `wordsTextinput(ch)`:

```lua
if spendGlyph(wordsBaseKey(ch)) then return end  -- as corrected in ca6d5df
if wordsDone() then return end
local want = wordsExpected()
if want == "" then return end
if ch == want then wordsGood() else wordsBad() end
```

**On `love.keypressed`** — `wordsKeypressed(k)` acts **only when the level is over**
(`if wordsDone() then wordsEndKey(k) end`): `tab` climbs a rung, `return`/`kpenter` replays at the
top rung. **During play, `love.keypressed` does nothing in this scene** — there are no key-name
targets here; space is a target *character*, not the key name `"space"`.

**On `love.keyreleased`** — no handler, same as `alt.lua`.

**Wrong answers are NOT idempotent:** `wordsBad()` is

```lua
SOUND.reject()
WORDS.wordClean = false
```

— no `fumbled`-style guard. Every wrong `love.textinput` that reaches it plays a sound. Nothing
downstream deduplicates.

## 5. The differences that matter

| | `alt.lua` | `words.lua` |
|---|---|---|
| target | one item at a time | a position in a string |
| target advances | to an item chosen by `gaugeCandidates`, which **excludes the current one** | to `WORDS.pos + 1` — **the next character of the line** |
| consecutive identical targets | prevented by the game (except a one-token notch) | **ordinary** — any doubled letter (`"all"`, `"been"`, `"little"`) |
| key-name targets | yes (`backspace`, `tab`, `return`), fed from `love.keypressed` | none during play |
| `love.keypressed` during play | judges key-name targets | unused |
| repeated wrong answers | idempotent (`ALT.fumbled`) | **not** idempotent — one sound each |
| per-press protection | `spendGlyph` | `spendGlyph` (was `inputStale` before `ca6d5df`) |

**The corpus makes the third row concrete:** 224 distinct words in `words_corpus.lua` contain a
doubled letter, and the generator is order-2 over that corpus, so lines containing `ll`, `ee`,
`tt`, `oo` are ordinary output, not a corner case.

## 6. What both scenes actually require from the shared layer

Stated as a property rather than a mechanism, because the mechanism is what is open:

**One `love.textinput` accepted per physical press of a key.**

Both need it, for the same reason and with the same consequence if it is missing:

- **`alt.lua`:** a held key emits repeated `love.textinput` events. Without the property, a held
  *wrong* key knocks repeatedly (its own guard covers the sound but not the principle), and a held
  *correct* key scores, advances the target, and then the trailing repeats are matched against the
  **new** target — bleeding a miss onto a target the player has not yet seen.
- **`words.lua`:** identical, and slightly worse. A held correct key advances `WORDS.pos`, and the
  next repeat is matched against `WORDS.line`'s next character — which may itself be a hit
  (typing `"ll"` with one press) or a miss that costs `WORDS.wordClean` and knocks per repeat,
  since `wordsBad` has no idempotence guard.

Neither scene needs anything else from the layer that it does not already have.

## 7. The ratified design, re-read against two consumers

`doc/development/internals/examples/keyboard.md` replaces the per-press mechanism with two fields
and three rules:

```
ALT_JUDGE = { lastText = nil, blocked = false }
1. if blocked, stop
2. if text == lastText, stop
3. otherwise match; set lastText = text
```

Rule 2 is a **content** test — *is this character the same as the last one accepted*. `spendGlyph`
is a **press-identity** test — *has this key already had one accepted since its last release*.
Under `alt.lua`'s conditions the two coincide, and the document says exactly why, in the section
titled *"The precondition this rests on: one target, one keystroke"*:

> **Every target is a single character or a single non-printing key.** The subgame never assembles
> a string. […] **If a later stage ever asks the player to type a word, this design must be
> revisited** — `lastText` would be deduplicating the letters of the answer against each other, and
> the block would need to span an entry rather than a keystroke. Stated here because it is the kind
> of premise that is invisible until it is violated.

**`words.lua` is that violation, and it is now in the tree.** Applied to Words as written, rule 2
drops the second `l` of `"all"`: the player presses `l`, releases, presses `l` again, and the
second `love.textinput("l")` carries the same `text` as the last accepted one, so it is discarded.
`WORDS.pos` does not advance. The player is not hard-stuck — typing any *other* character
overwrites `lastText`, and `l` then works — but that other character is a wrong answer, so it
knocks and clears `WORDS.wordClean`, costing the word its gauge unit.

This is a fact about the design, not a fault in it: the document predicted this precise failure and
asked for a revision if the premise was ever broken. The premise broke upstream, and the step is
explicitly permitted to revise the document.

**What else changes with a second consumer:**

- **`ALT_JUDGE` is named and scoped for one scene.** Two scenes needing the same property means
  either a shared mechanism in `input.lua` (where `spendGlyph` already lives) or one per scene,
  duplicated.
- **The `blocked` field exists for a transition Words does not have.** In Alt, a hit calls
  `gaugeOnCorrect` synchronously and the target changes underneath the event; `blocked` keeps the
  winning character from being written and re-judged across that change. In Words a hit advances
  `WORDS.pos` within the same line — a transition of the same shape but not the same code, and
  `wordsEndLine`/`wordsWin` are a second, coarser one.
- **The subtraction list is unchanged in kind but wider in reach.** `spendGlyph`, `GLYPH_CLAIMED`,
  `INPUT.upRecent`, `INPUT_UP_GRACE` now have two callers, and `INPUT.upRecent` is the last
  non-alias member of the `INPUT` table, which is why the table's dissolution is sequenced with
  this and not before it.

## 7.1 The requirements, as they now stand

Assembled from §1.1, §1.2 and §6 so the mechanism can be **derived** rather than chosen between two
candidates. Each is sourced; none is invented here.

| # | requirement | source |
|---|---|---|
| **R1** | One `love.textinput` accepted per **physical press** of a key; OS repeats produce nothing | authored rule, §1.1 — stated in both scenes' own comments |
| **R2** | The mechanism must not depend on the **relative order** of `love.keypressed` and `love.textinput` | owner principle, §1.2 — the order is not guaranteed and a LÖVE release could flip it |
| **R3** | A character produced by a press must not be lost when its `love.textinput` arrives **after that key's `love.keyreleased`** | §1.1's fit test — the press produced a character and the player does not get it; named in the design note's smoke checklist |
| **R4** | A **missed** `love.keyreleased` (focus loss mid-hold; `capslock`, whose release is unreliable) must not silence the key afterwards | robustness; `capslock` is already exempted by hand in `appKeypressed`, which is the same problem met once already |
| **R5** | Both scenes are served without either one carrying the other's special cases | §5, §7 — two consumers with different target models |

**How the two candidates score.** `inputStale` fails R1 and R2 outright (it is the order dependence).
`spendGlyph` satisfies R1, R2 and R5; it fails R3 (the `INPUT_UP_GRACE` window rejects exactly that
character) and R4 (a claim that is never cleared silences the key). The ratified `lastText` rule
satisfies R2, R3 and R4 but fails R1 in Words, where it is a rule change (§8.1).

**No candidate on the table satisfies all five**, which is the honest state of the design and the
reason §8.2 is a real question rather than a formality.

## 8. Open questions — to be decided with the owner, one at a time

**8.1 Which property does the shared layer provide: press-identity or content-identity?**
Press-identity (`spendGlyph`) serves both scenes today and costs what the design document names: a
`love.textinput` arriving after its own `love.keyreleased` is rejected, so a very fast tap is lost.
Content-identity (`lastText`) removes that cost and the frame counter with it, but is only sound
where consecutive targets cannot repeat — which Words breaks.

**[2026-08-11] §1.1's ruling narrows this to one answer, pending the owner's confirmation.**
Content-identity is not a trade-off here, it is a **rule change**: under `lastText`, typing `"all"`
loses its second `l` and the player cannot enter a word the game is showing them without first
typing something wrong. A player would notice, so it fails the test §1.1 imposes — **unless the
rule is revised to key on something other than the character's content**, which is what the design
document itself asked for when its precondition broke.

That leaves two live directions rather than one, and they are not the same:

- **Keep press-identity, fix its two artifacts.** `spendGlyph` already produces the authored
  behaviour in both scenes; what it costs is the fast tap (it consults `INPUT.upRecent`, a frame
  stamp read from the debug counter) and its dependence on `love.keyreleased` arriving. Both are
  implementation, so both are in scope.
- **Revise the ratified design so its rule is press-scoped rather than content-scoped**, keeping
  its virtue — no frame counter, no grace window, no claim table — if a formulation exists that
  does not consult held state or delivery order. Whether one exists is §8.2, and it is not yet
  answered.

The fast tap is worth naming precisely, because it is the one place where the current
implementation **fails to deliver the authored rule**: a press produces a character, and the
implementation drops it. Fixing that is not a rule change; it is the fit this step is for.

**8.2 Is there a third mechanism that has neither cost?** `love.keypressed` carries `isrepeat` and
`love.textinput` does not; the two channels have no guaranteed order, which is what rules out
"a fresh keypress arms a gate that its `love.textinput` consumes". Whether an order-agnostic
variant exists — and whether it is worth more than either simple answer — is an open design
question, not a settled one.

**8.3 Where does the state live?** `input.lua` (shared, as now) or per scene (as `ALT_JUDGE` was
drawn). Also: does `SCENES[ACTIVE].keypressed` start receiving `isrepeat`, which the shared hook
currently discards?

**8.4 What does the design document become?** It is scoped to the Alt-keys subgame in its title and
its first line. A second consumer either widens it or splits it.

**8.5 The remaining items** are 4–7 of the agenda and are not touched by the above:
`isMod`/`capslock` (six sites), `Ctrl+Alt+H` as a hand-matched combo, `bubble.lua`'s scope, and
`love.mouse.setRelativeMode`.

**Not verified by running anything.** This repository has no test suite, and the container cannot
inject keystrokes; every statement above is read from the code in the merged tree. The doubled-letter
claim in §5 is measured from `words_corpus.lua`; the behaviour it implies in §7 is reasoned.
