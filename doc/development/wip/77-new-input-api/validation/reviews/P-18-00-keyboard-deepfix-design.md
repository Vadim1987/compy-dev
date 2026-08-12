# P-18-00 — the keyboard deepfix: analysis and design

**Step:** P-18-00, the initial analysis/planning pass of P18 (`S27-triage-and-plan.md` §15.4).
**Opened:** 2026-08-11, session37, after the upstream merge landed (`keyboard` @ `ca6d5df`).
**Status: NOTHING HERE IS DECIDED.** §2–§7 are exposition — what the code does, read from the
merged tree; **§2.1 states the same layer at UPSTREAM**, which is the baseline the eventual patch is
measured against, and every claim about *authored* behaviour is checked there. §7.1 states the requirements, §8 the open questions, §9 the derivation from those
requirements and the options it leaves. Decisions are the owner's and are recorded, one at a time,
as they are taken.

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

## 2.1 The same layer at UPSTREAM, and why this document must say which baseline it means

**Owner, 2026-08-12:** *"Are you judging against the current patched form or the upstream form? I am
not interested in analysing our half-done machinery applied before we saw updated upstream. I am
analysing how a clean patch towards upstream would look."*

**The correction is accepted and it applies to this whole document.** §2 above describes the **merged
tree** — upstream plus this branch's migration — which is the tree P18 edits. But the deliverable is
a **diff against upstream**, so every claim about *authored behaviour* has to hold at
`origin/dsent/dev`, not merely here. Where the two differ, both are now stated.

**Upstream's shared layer**, read at `origin/dsent/dev:input.lua`:

```lua
INPUT = { held = { }, upRecent = { }, shift = false, ctrl = false, alt = false }

function inputStale(k)                       -- held, OR released within GRACE frames
  if INPUT.held[k] then return true end
  local up = INPUT.upRecent[k]
  if not up then return false end
  return DBG_FRAME - up <= INPUT_UP_GRACE
end

function appKeypressed(k)                    -- love.keypressed(k) forwarded from main.lua
  if inputStale(k) and k ~= "capslock" then return end   -- (a) OS-repeat filter
  INPUT.held[k] = true ; inputUpdateMods()
  if reservedChord(k) then return end
  if appChord(k) then return end
  ...capslock / PAUSED / help... ; dispatch to SCENES[ACTIVE].keypressed(k)
end

function appKeyreleased(k)
  INPUT.held[k] = nil ; INPUT.upRecent[k] = DBG_FRAME ; inputUpdateMods()
  dispatch to SCENES[ACTIVE].keyreleased(k)
end

function appTextinput(t)                     -- identical in shape to the merged tree's
  ...PAUSED / INPUT.alt / INPUT.ctrl / help...
  if isAlphaChar(t) then capsReconcile(t, INPUT.shift) end
  dispatch to SCENES[ACTIVE].textinput(t)    -- the scenes call inputStale themselves
end
```

**`inputStale` has two callers upstream, and only one of them is broken.**

- **(a) inside `appKeypressed`** — filtering OS repeats. **This one is sound.** A repeat
  `love.keypressed` always arrives while its key is genuinely held, and a fresh press always arrives
  after the release cleared `INPUT.held`, so no delivery order can confuse it. Its only flaw is the
  `upRecent` tail, which can drop a fresh press within one frame of a release.
- **(b) inside `altTextinput` and `wordsTextinput`** — this is the defect, and it is the *only*
  place the inter-channel assumption lives.

That matters for the shape of the patch: **the fix is confined to (b)**, and it does not depend on
the migration. Upstream's repeat filtering for `love.keypressed` is replaced by the API's `isrepeat`
as part of feature #77's migration, not as part of this heal — two changes that happen to touch the
same file.

**Upstream's `alt.lua` registers `keypressed` and `textinput` only** — verified at
`origin/dsent/dev:alt.lua:308-317`, the same as the merged tree. `bubble.lua` remains the game's only
scene with a `keyreleased` handler, in both baselines. Every other claim in §3–§7 is about files this
branch never touched (`words.lua`, `bubble.lua`, `findkey.lua`, `gauge.lua`, `config.lua`), where the
merged tree **is** upstream.

**The mechanism as an upstream-relative delta**, which is the form the eventual patch takes:

| | upstream | after |
|---|---|---|
| removed | `INPUT.held`, `inputUpdateMods`, `inputStale`, `INPUT.upRecent`, `INPUT_UP_GRACE` | — |
| added | — | `GLYPH_CLAIMED`, `spendGlyph`, `inputTick` and its call in `updateStep` |
| the two scenes | `if inputStale(baseKey(ch)) then return end` | `if spendGlyph(baseKey(ch)) then return end` |
| the release handler | maintains `held`, `upRecent`, mods; dispatches | dispatches only |

Two tables and a tuned constant become one table cleared by the device. The rest of the delta at
those lines — `isrepeat` in place of the stale test, `Key.*` in place of `INPUT.shift/ctrl/alt`,
shortcuts in place of `reservedChord`/`appChord`, a poll in place of `help.lua`'s `INPUT.held.h` — is
feature #77's migration and is reviewed as such.

## 2.2 The inter-channel assumption, stated exactly

**Owner, 2026-08-12:** *"What exactly was the inter-channel assumption in upstream?"*

**The assumption is one line of `inputStale`, read from the wrong channel:**

```lua
function inputStale(k)
  if INPUT.held[k] then return true end        -- <= THIS
  ...
end
```

`INPUT.held` is owned by the **`love.keypressed` channel** — set in `appKeypressed`, cleared in
`appKeyreleased`. The two scenes call `inputStale` from their **`love.textinput`** handler. So a
decision about a character is taken from state maintained by a different channel, and it is only
correct if that channel has already run for *this* press.

Written as the proposition the code needs to be true:

> **At the moment `love.textinput(t)` arrives, `INPUT.held[baseKey(t)]` is false if this is the
> first character of a press and true if it is a repeat.**

That holds **iff `love.textinput` is delivered before its own `love.keypressed`**, which LÖVE does
not define. Under the other order every press marks the key held first, so the very first character
of every press reads as stale and is dropped — **nothing is ever accepted, the game is deaf**, which
is the state the owner attested on desktop Linux (§1.2).

**There is a second, smaller assumption in the same function, and it is about timing rather than
order:**

```lua
  local up = INPUT.upRecent[k]
  if not up then return false end
  return DBG_FRAME - up <= INPUT_UP_GRACE      -- <= AND THIS
```

> **A repeat character trailing a release arrives within `INPUT_UP_GRACE` (1) frames of it, and
> nothing the player does deliberately arrives that fast.**

The first half is a guess about the OS's timing; the second is what makes it a defect in the other
direction — a genuine press whose character lands inside that window is discarded (R3).

**Both are removed by the same change, and neither is replaced by another assumption.** A claim is
taken by the character itself, on its own channel, and released when the **device** reports the key
up. Nothing reads state owned by another channel, and nothing is compared against a duration.

**One place the same read is legitimate, for contrast** — `appKeypressed`'s own use of `inputStale`
to filter OS repeats. There the reader and the state are on the *same* channel: a repeat
`love.keypressed` necessarily arrives while its key is held, and a fresh one necessarily follows the
release that cleared the flag. No ordering between channels is involved, so that call is sound
(§2.1).

## 2.3 What the example built because the platform withheld it — and what the feature gives back

**Owner, 2026-08-12:** *"The receiving side in the upstream game does not expect `isr` to be
delivered, right? If we deliver it now, would it remove any machinery built exclusively to work
around the lack of the flag?"*

**Yes — and the author says so in the file's own header, which is the best evidence this step has
found.** Upstream `input.lua`, first lines:

> *"The IDE keeps key-repeat enabled and **strips the isrepeat flag before calling the game**, so
> repeats are filtered here by **edge tracking**: a key already in `INPUT.held` is a repeat and is
> ignored completely."*
>
> *"Ordering: the IDE delivers `textinput` BEFORE the matching keypress (the reverse of desktop
> LOVE). So a 'fresh keypress arms a gate, its textinput consumes it' scheme cannot work […] So
> textinput is judged directly, with no gate. […] A held key emits textinput; since textinput
> precedes the fresh keypress, the producing key is in `INPUT.held` when a repeat arrives, so the
> scene drops it."*

**Verified at the PR base rather than taken on trust:** `3256aac:src/controller/controller.lua:162`
defines `local function keypressed(k)` — **one parameter**. The platform discarded `scancode` and
`isrepeat` before any project handler ran. The author's account is exact.

**This changes how §2.2 should be read.** The inter-channel assumption was **not an oversight**: it
was a documented dependency on a platform behaviour, reasoned about in writing, with the alternative
(a gate armed by the keypress) explicitly considered and rejected for the same reason this document
re-derived later. What made it a defect is that **the behaviour it depends on was never guaranteed**
— and the platform it was true of is the one this feature is changing.

**Attribution of each piece, since "what the flag removes" is narrower than "what the feature
removes":**

| upstream machinery | exists because | retired by |
|---|---|---|
| `INPUT.held` **as a repeat detector**, via `inputStale` inside `appKeypressed` | the platform stripped `isrepeat` | **the flag** — `if isr` replaces the edge tracking outright |
| `INPUT.held` **as modifier state**, via `modHeld` + `inputUpdateMods` | no held-modifier query existed for a project | the feature's `Key.shift/ctrl/alt` |
| `reservedChord`, `appChord` | no combo mechanism existed | the feature's `shortcuts` + `alt+*` class |
| `isMod` | no `Key.is_mod` existed | the feature's `Key.is_mod` (P18's onboarding half) |
| `help.lua`'s `INPUT.held.h` | no held-key query existed | a poll — Decision 32 ruled it correct |
| *"does NOT disable global key-repeat (the runner exposes no project-exit cleanup hook…)"* | no exit hook existed | the feature's `compy.before_exit` |
| `INPUT.upRecent` + `INPUT_UP_GRACE` | **`love.textinput` carries no repeat flag — in any LÖVE version** | **nothing the platform can give** — only the new mechanism (§9.5) |

**The last row is the point, and it is why this step exists at all.** Delivering `isrepeat` retires
the *keypressed*-side workaround completely and cleanly. It does **nothing** for the textinput side,
because that channel has no such flag to deliver and never has: a character carries no indication of
whether the key that produced it was repeating. That is why the heal needs a mechanism of its own,
and why it is separable from the migration (§2.1).

**Read together, the example's header is a list of gaps in the pre-feature platform**, written by
someone who worked around each one deliberately and said so. Four of the six are closed by this
feature. That is a stronger sentence for the PR description than anything the sprint has written for
itself, and it is the author's testimony rather than ours.

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

## 9. Derivation from R1–R5 (2026-08-11, at the owner's instruction)

### 9.1 What the three channels can and cannot tell us

- **`isrepeat` is the only authoritative per-press signal in the system.** It comes from the OS
  through LÖVE, on `love.keypressed`'s third argument. A physical press is exactly a
  `love.keypressed` with `isrepeat == false`.
- **`love.textinput` carries neither a key nor a repeat flag** — only `text`. The key it came from
  is *inferred* (`altBaseKey` / `wordsBaseKey`, which agree: `" "` → `"space"`, a letter → its
  lowercase, otherwise the character itself).
- **`love.keyreleased` may never arrive** — focus lost mid-hold, and `capslock`, whose unreliable
  release already forced a hand-written exemption in `appKeypressed`.
- **The repeats exist because the framework turns them on.** `src/main.lua:297` calls
  `love.keyboard.setKeyRepeat(true)` for the console and editor; LÖVE's own default is off.

**One "obvious" fix, ruled out before anyone proposes it:** having the game call
`love.keyboard.setKeyRepeat(false)` while it plays. LÖVE's flag governs **`love.keypressed` only**
— by its own documentation — so this would remove the `isrepeat` signal, the one authoritative
input we have, while (needing measurement, but almost certainly) leaving the OS still producing
repeat `love.textinput`. It makes the problem strictly harder, and it mutates global state the
project must then restore.

### 9.2 The impossibility: immediate decisions cannot satisfy R1 + R2 + R4 together

Suppose the accept/drop decision is made **at the moment each `love.textinput` arrives**, from the
event history alone. Consider the `textinput`-first order (R2 forbids assuming it away), and a
press whose `love.keyreleased` was never delivered (R4's case). Compare two moments:

| | history for key *k* since the last accepted `love.textinput` |
|---|---|
| a **repeat** `textinput` of press *n* | `keypressed(k, false)`, then zero or more `keypressed(k, true)` |
| the **first** `textinput` of press *n+1*, release of *n* missing | `keypressed(k, false)`, then zero or more `keypressed(k, true)` |

**The histories are identical**, and the required decisions are opposite — drop the first, accept
the second. No function of the history can be right in both cases. **Therefore R1 + R2 + R4 forces
the decision to be deferred** until the press's own `love.keypressed` has been seen; nothing else
distinguishes them.

This is why every previous attempt patched an edge instead of solving it, and it is the result that
makes the choice below a real one rather than a matter of taste.

### 9.3 The three mechanisms this leaves

**A — the status quo (`spendGlyph`): claim per key, cleared at `love.keyreleased`, plus a frame-stamp
grace window.**
R1 ✓ R2 ✓ R5 ✓. **R3 ✗** — the grace window (`INPUT.upRecent` + `INPUT_UP_GRACE`, measured in
`DBG_FRAME`, the *debug logger's* counter) rejects precisely the character whose `love.textinput`
trails its own `love.keyreleased`. **R4 ✗**, bounded: a missing release leaves the claim set, the
next press of that key produces nothing, and its release then clears it — one press lost,
self-healing.

**A″ — the same claim, cleared at the FRAME BOUNDARY instead of inside `love.keyreleased`.**
The release queues the key; the queue is drained once per frame, after events and before
`sceneUpdate`. A trailing repeat `love.textinput` arriving in the same batch as the release still
meets a set claim and is dropped — which is the only thing the grace window ever bought.
**This deletes `INPUT.upRecent`, `INPUT_UP_GRACE` and the dependency on `DBG_FRAME` outright.**
R1 ✓ R2 ✓ **R3 ✓** (no window to reject the trailing character — it is the *first* of its press, so
no claim is set) R5 ✓. **R4 ✗**, same bounded residue as A.

**B — pair `love.textinput` events with fresh `love.keypressed` events, once per frame.**
The deferral §9.2 proves is necessary. `appKeypressed` counts fresh presses per key for this frame;
`appTextinput` applies the shared filters and the Caps estimate immediately (both must stay where
they are) and **queues** the character; a resolve step at the top of `love.update` dispatches a
queued character to the scene only if a fresh press of its key was seen this frame, then discards
the leftovers. R1 ✓ R2 ✓ R3 ✓ **R4 ✓** — `love.keyreleased` is not consulted at all, so it cannot be
missed. R5 ✓ via one shared `textBaseKey`, which the two scenes' own helpers already agree on.
**It deletes the claim table as well**, leaving one per-frame count.

Its costs, stated rather than discovered: scene `textinput` handlers stop running inside the event
and run at update time — the same frame, before `draw`, so nothing a player can see, **but it is a
dispatch-architecture change**, and the relative order of a scene's `keypressed` and `textinput`
handling changes for any press that fires both. It also assumes a press's two events land in the
same event batch; a one-frame carry of unconsumed press counts is cheap insurance if that is not
guaranteed.

### 9.5 Option C — the owner's correction (2026-08-11), and it is the best of the four

**The owner's framing first:** *"Words looks like a series of Alt levels with minor adjustment. Can
we take the approach suggested for Alt, with one correction: as soon as a win is registered we start
listening to `keyreleased`; the `keyreleased` of the last won character just clears `lastText` and
deactivates itself."*

**Stated as a mechanism:** accept a character iff `text ~= lastText`. On accepting, set
`lastText = text` and arm a release watch for `textBaseKey(lastText)`. On
`love.keyreleased(key)`, if `key` is that watched key, clear `lastText` and disarm.

**Why it is better than the three above, and not a compromise between them.** It keeps the ratified
design's shape — one remembered character, no table, no counter — and **replaces the content test's
broken premise with a press boundary**. `"all"` now works: the first `l` is accepted, its repeats
are blocked by content, the release clears the field, and the second press is accepted because there
is nothing to match against. **The precondition the design document rests on — one target, one
keystroke — is dissolved rather than worked around**, which is what its own text asked for.

**Scored against R1–R5:**

| | |
|---|---|
| **R1** | ✓ for a single key: repeats blocked by content, the next press freed by the release |
| **R2** | ✓ the accept decision reads only `lastText`; the clear happens on `love.keyreleased`, which always follows both of the press's other events in either order |
| **R3** | ✓ **no grace window exists to reject anything** — a character trailing its own release meets an already-cleared field |
| **R4** | ✗ but with the **smallest residue of any option**: a missed release strands one character, and *any different character* overwrites the field and frees it — where the claim table strands that key until it is pressed and released again |
| **R5** | ✓ one mechanism, no per-scene special cases |

**It also deletes more than A″ does:** `INPUT.upRecent`, `INPUT_UP_GRACE`, the `DBG_FRAME`
dependency, `GLYPH_CLAIMED` **and** — on inspection — the ratified design's own `blocked` field,
whose job (stop the winning character being re-judged as the target advances) is already done by the
content test. One field and one watched key replace all of it.

**Two questions it raises, both real:**

**(a) Arm on a win only, or on any accepted character?** The owner said *"as soon as win is
registered"*. Arming only on wins changes Words' behaviour: press a wrong key, release, press it
again — the field still holds that character, so the second press is silent where the authored game
knocks again. `alt.lua` would not notice (its `ALT.fumbled` already makes repeated wrong answers
no-ops), but `words.lua` would, and §1.1 forbids it. **Recommendation: arm on every accepted
character, win or miss.** The mechanism is unchanged; only the arming point moves.

**(b) One slot, or one per key?** This is the only substantive difference between Option C and A″ —
they are the same idea at different capacities. A single slot has a **rollover hole**: hold `a`
(accepted, field = `"a"`), press `b` while still holding it (accepted, field = `"b"`), and `a`'s
repeats no longer match the field, so they would be accepted as new characters. Whether that hole is
reachable depends on OS auto-repeat following the most recently pressed key and not resuming on the
earlier one — **behaviour no one guarantees**, which is the same class of assumption R2 exists to
refuse. A per-key table closes it and costs a table. **Not recommended either way here; it is a
decision, and it is the one worth taking deliberately.**

**A finding this turned up, which affects every option including the status quo.** The mechanism
needs the character → physical key inference to be correct, and **`wordsBaseKey` is incomplete**:

```lua
function wordsBaseKey(ch)          function altBaseKey(item)
  if ch == " " then                  ...
    return "space" end               if ALT_BASE[item] then
  if isAlphaChar(ch) then              return ALT_BASE[item] end   -- SHIFT_MAP inverted
    return string.lower(ch) end      if isAlphaChar(item) then
  return ch                            return string.lower(item) end
end                                  return item
                                   end
```

`altBaseKey` inverts `SHIFT_MAP`, so `"!"` maps to `"1"` — the key whose release actually arrives.
`wordsBaseKey` does not, so any shifted symbol typed in Words maps to itself and its release never
matches. Words' own *targets* are unaffected (rung 4 adds only `,` and `.`, unshifted), but a player
who types a shifted symbol by mistake strands it. **The same defect exists today under `spendGlyph`**,
which my `ca6d5df` inherited: the claim on `"!"` is never cleared, so that character can never be
typed again in that session.

**So one shared `textBaseKey` belongs in `input.lua`** — not in `alt.lua`, where `ALT_BASE` is built
today: scenes are lazy-loaded, and a Words-only session would find it nil. `SHIFT_MAP` lives in
`config.lua`, which loads before `input.lua`, so the inversion can be built there safely.

### 9.5c Closing the release-loss hole — the owner's two extra clears, assessed

**Owner, 2026-08-11:** *"It's still vulnerable to `keyreleased` loss. But `keypressed` of anything
else than last-won could do the same. Plus a timer after win."*

The diagnosis is right — R4 is exactly that vulnerability, and one clearing path is not enough.
Both proposed clears are assessed below, and a third is recommended in their place.

**Clear #2 — a `love.keypressed` for any key other than the watched one.** It works for the case it
targets: a stranded field is freed by the very next keystroke, which in a typing game is immediate.
Its cost is that it **widens the rollover hole rather than leaving it alone**: while a key is held
and repeating, *any* other press — including `lshift` or `capslock`, which produce no text —
clears the field, so the held key's next repeat is accepted as a fresh character. How reachable
that is depends on whether the OS keeps repeating the first key after a second is pressed, which is
the unguaranteed behaviour R2 refuses to lean on. **Not recommended if the third clear below is
adopted, because that one covers the same case without touching the hole.**

**Clear #3 — a timer after a win.** This one has a failure that cannot be tuned away. To free a
stranded field the timeout must be short; but while it runs, **the key may still be legitimately
held**, and any timeout shorter than the hold clears the field and lets the next OS repeat through
as a new character. A child leaning on a key holds it for seconds; a repeat arrives every few tens
of milliseconds. So the timer either fires too late to be useful or **breaks R1 — a rule change by
§1.1's test**, since holding a key would start typing again. It also reintroduces a clock, which is
the one thing the ratified design was proud of not having.

**Recommended instead — clear #3′: ask the device whether the watched key is still down, once per
frame.**

```
on accept:            lastText = text;  watch = textBaseKey(text)
on keyreleased(watch): clear                      -- precise, immediate
each update, if watch and not Key.any_pressed(watch): clear   -- backstop
```

Why this is the right shape and not a fourth patch:

- **It closes R4 completely.** The backstop consults no event at all, so no event can be lost. A
  release that never arrives, a focus change, a `capslock` that never reports up — all resolve on
  the next frame.
- **It is not `inputStale` returning.** That defect asked *"is this key held?"* **at
  `love.textinput` time**, where the answer depends on which channel arrived first. This asks
  *"is the key of the character I already accepted still down?"* **at frame time**, about a key
  whose press is already history. There is no ordering for it to depend on. The distinction is the
  one the sprint has already ruled on twice: a poll answering a frame-time question about physical
  state is the sanctioned mechanism (Decision 32), and inference *inside* judgement is not.
- **The precedent is in the same file family and already ruled correct:** `helpHeld` polls the
  keyboard for `h` and Decision 32 confirmed it. This is the same question about a different key.
- **It lands the new platform surface where it belongs.** `Key.any_pressed(watch)` is the ladder's
  last rung for a non-modifier key (`doc/input_api.md`, "Held keys"), which is also P18's onboarding
  half — the poll and the migration are the same edit rather than two.
- **Clear #1 stays and is not redundant.** The release clears *immediately*, which matters for a
  re-tap inside one frame: release and re-press in the same event batch would otherwise meet a field
  the frame-end poll has not yet cleared, and the second character would be lost.

**What it does not fix:** the rollover hole (§9.5b) is untouched — it is a property of the single
slot, not of the clearing paths. That decision stands on its own.

### 9.5d Task-tagged caches — the generation trick, and why this state resists it

**Owner, 2026-08-11:** *"Can we use a cache-busting technique by storing 'last seen' (or some other
caches) per task number? I feel it could help some rearming."*

The idea is sound in general — tag the cached value with the generation it belongs to, and a
generation change invalidates it for free, with no clearing path to lose. Applied here the "task"
would be the presentation: `gaugeCurrent(ALT)` advancing in Alt, `WORDS.pos` advancing in Words.

**It fails on the one repeat the games actually care about, and the failure is a rule change.**

Take `"all"`, and hold the `l` key. The first `l` is accepted at `WORDS.pos == 2`, and the position
advances to 3 — a new task. The next OS repeat of that still-held key arrives carrying the same
character, but now under a **different task number**, so a task-tagged cache does not match it and
the character is accepted. **The player has typed `"ll"` by holding one key**, which is precisely
the behaviour §1.1 rules out — and it is the same outcome as the "repeat as typing" proposal already
withdrawn.

Alt has the identical shape one level up: the design document's own analysis says *"a correct
character advances the target immediately, so a repeat of the winning character would arrive with a
**different** target displayed and fumble it"* — the case its `blocked` field exists for. **So the
block must survive the task change, which is exactly what a task-tagged cache cannot do.** The
generation trick invalidates at the moment the state most needs to persist.

**The deeper reason, and it generalises past this proposal:** §9.2 proves that identifying *which
press a character belongs to*, at the moment the character arrives, is impossible under R2 + R4.
Every tagging scheme is an attempt at that identification — by task, by press counter, by
generation — and each inherits the proof. A per-key press counter fails it most directly: in the
`textinput`-first order the character arrives *before* the `love.keypressed` that would have
incremented its generation, so it is attributed to the previous press and dropped.

**The two escapes remain the ones already on the table:** decide on content and resolve the press
boundary **later** from the device (Option C + §9.5c), or defer the decision to the frame boundary
(B). Tagging is a third route only if the tag can be known at arrival time, and it cannot.

**Where a task number would genuinely help — and is already there.** Idempotence *per
presentation* is a real requirement and both scenes already implement it where they want it:
`ALT.fumbled` / `st.fumbled` make several wrong answers read as one miss, reset when the target
advances. That is the task-scoped cache this game needed, it exists, and it is not the state under
discussion.

### 9.5e Why the poll is written `Key.any_pressed(watch)`

**Owner, 2026-08-11:** *"Not sure why we should poll `any_pressed` instead of asking 'that specific
last one, is it still pressed'."*

**It does ask exactly that.** `Key.any_pressed` is variadic and wraps `love.keyboard.isDown(...)`,
whose several-name form is an **OR**; called with one name — `Key.any_pressed(watch)` — it is the
single question *"is `watch` down right now"*. There is no OR in the call.

The name carries the OR because of a trap ruled on in session36: `love.keyboard.isDown('a','b')`
means **any of them**, while a future richer predicate over a chord (`Key.pressed('ctrl','h')`)
would mean **all of them**. Shipping the wrapper as `pressed` would have claimed that name for OR
semantics and forced the later predicate to rename or break compatibility, so the owner ruled the
OR into the name and left `pressed` reserved.

**The cost is that the single-key case reads oddly**, which is what prompted the question. The
alternatives, neither recommended here: call `love.keyboard.isDown(watch)` directly — legitimate,
it is the ladder's last rung, but it keeps the example on the `love.` surface the migration exists
to move it off; or add a single-key alias, which is new public API against a mandate to simplify.
**Recorded as a wart, not a defect** — worth the owner's attention when the console and editor are
migrated, since they will hit the same reading.

### 9.5f The two remaining decisions, in full (2026-08-12)

#### (a) When is the field written and the watch armed?

**The mechanism has one write point per accepted character.** The question is which accepted
characters write it. Three readings, and only one preserves the authored behaviour:

**(a-i) Write only on a win** *(the literal reading of "as soon as win is registered")*.
A wrong character then leaves no trace, so a **held wrong key knocks on every repeat**:
`wordsBad` calls `SOUND.reject()` with no guard, so a child leaning on a wrong key hears a knock
every few tens of milliseconds. `alt.lua` would mask it — `ALT.fumbled` silences repeated wrong
answers per target — but Words would not. **Rule change, excluded.**

**(a-ii) Write the field on every judged character, arm the watch only on a win.**
Repeats of a wrong key are blocked by the content test ✓, but nothing ever clears that field except
the next *different* character. So: press a wrong key, release it, press it again — **the second
press is silent where the authored game knocks**. Again invisible in Alt, visible in Words.
**Rule change, excluded.**

**(a-iii) Write the field and arm the watch together, at every write.** Hit, miss, and the chord
record (`Ctrl+Alt+H` writing `h` without judging it) all behave the same: the character is
remembered, its key is watched, and the watch releases it. A wrong key repeats → blocked; released →
freed; pressed again → knocks again, as authored. **This is the only reading that preserves both
scenes**, and it is also the simplest to state: *the field and its watch move together, always.*

It improves the chord record as a side effect. The ratified design had to argue that a recorded `h`
would be cleaned up *"because the next judged character overwrites `lastText` anyway"*; under (a-iii)
the recorded character is released when its key comes up, like any other.

#### (b) One slot, or one entry per key?

The two variants are the same mechanism at different capacities, but they differ in **what
identifies a press**, and that changes how much machinery is needed.

**(b-i) Single slot — identity is the character.**

```lua
LAST = { text = nil, key = nil }        -- one field, predeclared
accept iff  text ~= LAST.text
on accept:  LAST.text, LAST.key = text, textBaseKey(text)
clear on:   keyreleased(LAST.key)  |  update: not Key.any_pressed(LAST.key)
```

**The rollover hole, concretely.** Hold `a` — accepted, `LAST = {"a","a"}`, its repeats blocked.
Press `b` while `a` is still down — `"b" ~= "a"`, so it is accepted and **the slot moves to `b`**.
`a`'s repeats now match nothing and are accepted as fresh characters. Whether that is reachable
depends on the OS: auto-repeat normally follows the most recently pressed key, so pressing `b`
usually stops `a` repeating, and releasing `b` usually does not resume it. **"Usually" is the whole
problem** — it is the same class of unguaranteed platform behaviour R2 refuses to rest on.

**(b-ii) One entry per key — identity is the key.**

```lua
HELD_TEXT = { }                         -- key -> true, one predeclared table
accept iff  not HELD_TEXT[textBaseKey(text)]
on accept:  HELD_TEXT[textBaseKey(text)] = true
clear on:   keyreleased(k) -> HELD_TEXT[k] = nil
            update: for k in HELD_TEXT do if not Key.any_pressed(k) then clear end
```

**The content test disappears.** The key *is* the identity, so `"all"` works because the release
clears the entry, the winning character's repeats are blocked because its key is still consumed, and
rollover is correct because `a` and `b` are separate entries. **One concept — a key stays consumed
while it is held — replaces two** (a remembered character plus a watched key).

It also retires the ratified design's most delicate invariant: that document has a whole paragraph
arguing `lastText` *"can never equal the live target"*, and why a chord record must not violate it.
With per-key entries there is no such interaction to protect — claiming a key says nothing about
what the target is.

**What (b-ii) costs.** A table rather than a field, and a per-frame loop over it (at most a handful
of entries — the keys physically down). It is also, structurally, `GLYPH_CLAIMED` **kept** rather
than deleted — with its clearing rule corrected from *release plus a frame-stamp grace window* to
*release plus a device poll*. The subtraction the ratified design promised is then smaller than
advertised: `INPUT.upRecent`, `INPUT_UP_GRACE`, `DBG_FRAME` and `blocked` still go; the table stays.

**One behaviour both variants share, stated so it is not discovered later.** `textBaseKey` cannot
always name the physical key — a character from an IME, a dead key, or an AltGr composition may map
to itself. Under either variant the entry is then keyed by a name that no `love.keyreleased` will
ever match; **the frame poll rescues it** (`Key.any_pressed("é")` is false, so it clears on the next
frame) at the cost that such a character, if genuinely held, could repeat once per frame. Neither
game has such a target, and the alternative — no poll — strands the character permanently, which is
strictly worse.

**Recommendation: (b-ii), the per-key entry.** Three reasons, in order of weight: it removes the hole
instead of betting on auto-repeat semantics; it needs *one* concept rather than two, and drops the
invariant the ratified design had to defend in prose; and the diff is smaller than it looks, since it
keeps a structure that already exists and replaces only how it is cleared. The single slot is the
more elegant sentence and the less predictable mechanism — and the strategic frame's question is
predictability, not elegance.

### 9.5g The filter/judgement separation (owner, 2026-08-12) — and it collapses further

**The owner's reading, which is the right architecture:** *"I see how it can become a filtering
mechanism separate from judgement. The filter judges whether new text was already registered. If it
was — noop. If it was not: register and fire `on_new_text()` — the hook of judgement, which is
different on the two games. Registration activates a watcher that polls the keyboard (and caps lock
state?) to understand when registered text stops being sent. The `keyreleased` event may fill its own
track with timestamps, that could be consulted by the poller."*

Two things fall out of taking this seriously: the separation is already available in the code with
**no new registration surface**, and once the watcher exists, **`love.keyreleased` drops out of the
mechanism entirely**.

#### The shape

```lua
-- input.lua, shared: the FILTER
function appTextinput(t)                    -- unchanged prologue
  ...PAUSED / Alt / Ctrl / help guards...
  if isAlphaChar(t) then capsReconcile(t, INPUT.shift) end   -- MUST stay above the filter
  local k = textBaseKey(t)
  if CONSUMED[k] then return end            -- already registered: noop
  CONSUMED[k] = true                        -- register, and the watcher is live by that fact
  local s = SCENES[ACTIVE]
  if s and s.textinput then s.textinput(t) end   -- on_new_text: judgement, per game
end

-- input.lua, shared: the WATCHER, once per frame
function inputWatch()
  for k in pairs(CONSUMED) do
    if not Key.any_pressed(k) then CONSUMED[k] = nil end
  end
end
```

`inputWatch` runs at the top of `love.update`, before `sceneUpdate`. Nothing else is needed.

**The judgement hook already exists.** `on_new_text` is the scene descriptor's own `textinput`
entry, which `input.lua` already dispatches to. `altTextinput` and `wordsTextinput` each lose their
first line and otherwise stay exactly as their authors wrote them — the filter moves *above* them
instead of being called *by* them. **No new API, no new registration, two lines deleted.**

#### `love.keyreleased` drops out — and that is the point, not a side effect

The step's earlier drafts kept a release-clear alongside the poll. Working the cases shows it is not
merely unnecessary but **actively worse**, because a release and a trailing repeat are
indistinguishable in shape:

| sequence | with clear-on-release | with clear-in-watcher only |
|---|---|---|
| press, character, **release**, trailing repeat character | claim gone → **phantom character judged** | still registered → correctly ignored |
| press, **release**, character (the character trails its own release) | no claim was ever set → accepted ✓ | accepted ✓ |
| press, character, release … next frame … press again | freed at release ✓ | freed by the watcher ✓ |
| release and re-press **inside one frame** | freed ✓ | **the second character is lost** |

The last row is the only thing clear-on-release buys, and it requires a human to release and
re-press within a single frame — under 16 ms at 60 fps. The first row is the case
`INPUT_UP_GRACE` was invented for. **So the watcher alone is the better of the two, and the whole
`love.keyreleased` dependency goes with it** — which is R4 satisfied by construction rather than by
mitigation: an event that is never consulted cannot be missed.

The residue, stated: a repeat character arriving a **full frame after its key is physically up**
would find the entry cleared and be judged. The current grace window has the same exposure at the
same size (one frame), so this is not a regression, and the OS stops repeating a key that is up.

#### The timestamp track, assessed

The owner's suggestion that `love.keyreleased` fill a timestamped track for the watcher to consult
is a way to distinguish those two indistinguishable sequences by *age* — trailing repeats arrive
within milliseconds of the release, a deliberate re-press does not. **It works, and it is
`INPUT_UP_GRACE` rebuilt**: a duration constant, tuned against timings nobody guarantees, deciding
judgement. Clearing in the watcher gets the same protection from the frame boundary, which is a
boundary we already have and did not have to choose a number for. **Recommended: no track, no
timestamps, and no `keyreleased` handler at all.**

#### Caps Lock: the watcher does not need it, and this is where per-key wins again

The owner's question — should the watcher also poll the Caps Lock state? — has a clean answer under
per-key registration: **no, because the registry is keyed by the physical key and Caps changes only
the character.** Hold `a`, toggle Caps mid-hold: the OS's repeats now carry `"A"`, whose
`textBaseKey` is still `"a"`, so they are still registered and still ignored. That is also the
authored behaviour (upstream's `inputStale` keyed on the held **key** too).

Under the single-slot content variant the same sequence **leaks**: the remembered text is `"a"`, the
arriving text is `"A"`, they differ, and the character is accepted — a repeat typed by holding one
key. So Caps Lock is a second, independent argument for per-key registration, alongside rollover.

**What Caps Lock still needs, unchanged:** `capsReconcile` must run **above** the filter, on every
character including the ones the filter discards. Repeats and characters arriving mid-celebration are
all valid evidence of a lock state nobody reported, and the design of record is explicit that
reconciliation precedes all suppression. The sketch above preserves that ordering, and it is the one
line in this mechanism whose position is load-bearing.

#### What the whole mechanism is, in one sentence

**A key whose character has been delivered to the scene stays registered until the device says it is
no longer down.** One table, one frame-time poll, one hook. No content comparison, no timestamps, no
clock, no grace constant, no release handler, and no dependence on the order of anything.

### 9.5h Minimising the change, and keeping the project's own names (owner, 2026-08-12)

**Owner:** *"Can we minimize changes to `keyboard` — let bubble drive on keypressed/keyreleased, let
alt judge 'play keys' on keypressed/keyreleased, and only change textinput processing in both alt and
words, to surgically eliminate the inter-channel dependency assumption… I would even keep the names
the original uses, as long as the machinery stays the project's own."*

**Adopted.** The mechanism is confined to the `love.textinput` path; every other channel keeps the
shape its author gave it.

**One correction to the premise:** `alt.lua` registers **`keypressed` and `textinput` only** — it has
no `keyreleased` handler at all. The **only** scene in the game with one is `bubble.lua`, for its
hold judge. So "alt judges play keys on keypressed/keyreleased" is really "on `keypressed`", via
`altPlayKey`, and that path is already correct: `appKeypressed` drops OS repeats at source using
`isrepeat`, so the play-key channel has never had the inter-channel problem.

**What is NOT touched, stated so the step cannot creep:**

| | |
|---|---|
| `bubble.lua`'s hold judge | untouched — `keypressed` + `keyreleased`, its own state, its own timing |
| `altPlayKey` and `ALT_KEYTARGET` | untouched — `backspace`, `tab`, `return` stay judged on `keypressed` |
| the nine `keypressed`-only scenes | untouched — they never see `love.textinput` |
| `appKeypressed`'s `isrepeat` filter and `capslock` exemption | untouched |
| `capsReconcile`'s position above everything | untouched, and load-bearing |
| every scene's judging logic | untouched — the filter sits beside it, not inside it |

**Names: the project's, not ours.** The register already exists and is already called
`GLYPH_CLAIMED`; the filter already exists and is already called `spendGlyph`. **Both keep their
names and their meaning** — a key whose character has been taken is *claimed*, and the claim is
*spent* by the character that takes it. What changes is only **how a claim is released**. The
working names used earlier in this document (`CONSUMED`, `textBaseKey`, `on_new_text`) were
descriptive scaffolding and are dropped.

#### The diff, in full

```lua
-- input.lua
GLYPH_CLAIMED = { }                       -- unchanged name, unchanged meaning

function spendGlyph(k)                    -- unchanged name and signature
  if GLYPH_CLAIMED[k] then return true end
  GLYPH_CLAIMED[k] = true                 -- the upRecent branch is GONE
  return false
end

function inputTick()                      -- new: called from love.update
  for k in pairs(GLYPH_CLAIMED) do
    if not Key.any_pressed(k) then GLYPH_CLAIMED[k] = nil end
  end
end
```

- **deleted:** `INPUT.upRecent`, `INPUT_UP_GRACE`, their reset in `inputInit`, and the two lines in
  `appKeyreleased` that maintained the claim — that handler keeps only its debug line and its scene
  dispatch, which `bubble.lua` needs;
- **`main.lua`:** one call to `inputTick()` in `updateStep`, **above** the `PAUSED` and
  `helpOverlayShown` returns — beside `pastelTick`, which is already there for the same reason: a
  key can be released while the game is frozen behind an overlay;
- **the shifted-symbol map moves down** from `alt.lua` (where `ALT_BASE` inverts `SHIFT_MAP` at load)
  into `input.lua`, because `alt.lua` is lazy-loaded and a Words-only session must not find it nil.
  `altBaseKey` keeps its name and its key-target branch and delegates the rest; `wordsBaseKey` keeps
  its name and delegates, which is also what fixes its missing shifted-symbol case.

#### The poll's surface: `love.keyboard.isDown`, with a comment pointing at `Key.any_pressed`

**Owner, 2026-08-12:** *"I would leave `love.keyboard.isDown` in the example code, for minimizing
changes — but could add a comment recommending the switch."* **Adopted**, and there is a second
argument for it the owner did not need to make: **upstream's `keyboard` is a standalone LÖVE
program**, so a heal written in plain LÖVE can be offered to its author independently of feature
#77's migration. A poll written as `Key.any_pressed` would carry the platform into a bugfix that
does not need it.

It is also consistent with the nearest precedent in the same file family: `help.lua`'s `helpHeld`
already polls `love.keyboard.isDown("h")` directly, as the ladder's last rung, and Decision 32 ruled
that poll correct. The new poll reads the same way.

The comment carries what the code cannot: that `Key.any_pressed(k)` is the platform's form of this
question, that it is what a Compy project should reach for, and that the plain call is kept here so
the mechanism stays portable to the upstream program.

**Whether the filter stays at the two call sites or moves above the dispatch is a real choice, and
the smaller diff is to leave it.** Today `altTextinput` and `wordsTextinput` each open with
`if spendGlyph(baseKey(ch)) then return end`. Leaving those lines means **no scene file changes at
all** beyond the delegation above, and each scene stays explicit about its own filtering. Moving the
call into `appTextinput` expresses the filter/judgement separation structurally and makes it
impossible for a future scene to forget it, at the cost of two deletions and of registering
characters typed in scenes that ignore text. **Recommended: leave the call sites** — the register's
correctness does not depend on where it is called from, and this is the reading of "minimize
changes" that keeps the authors' code recognisable.

#### The delayed poll, assessed — the owner's own doubt is right

**Owner:** *"probably augmenting this register with a timestamp — so that we only start polling e.g.
0.1 second (or 5 frames) after textinput registered 'pressed' — to eliminate uncertainty on short
time ranges… hm, probably the last suggestion makes no sense."*

**It does not, and the structural reason is worth recording** so it is not re-derived: **the poll
cannot run between a `love.keyreleased` and a `love.textinput` that trails it.** LÖVE drains the
whole event queue before it calls `love.update`, so every event of a batch — press, character,
release, trailing repeat — is delivered *before* the frame's poll. The uncertainty the delay would
guard against is therefore only *"a repeat character generated after its key is physically up"*,
which is not a thing the OS does.

And the delay has a cost that is not theoretical: for its whole window, a key that was genuinely
released stays claimed, so a **deliberate re-press of the same character inside 0.1 s is swallowed** —
doubled letters in Words are exactly that keystroke. It also puts back a tuned constant, which is
the thing being removed. **Declined, on the owner's own instinct.**

### 9.5i `fn.ignore_repeat` on the keypressed hook — blocked by one exemption, and worth recording why

**Owner, 2026-08-12:** *"`keypressed` taking no `isrepeat` argument caught my eye — could be a good
candidate for an `ignore_repeat` wrapper on the hook (if repeat filtering is universal) — unless the
game tries to *not* depend on the flag, assuming it could be disabled in OS settings?"*

**The wrapper would work mechanically.** `compy.input.fn.ignore_repeat` wraps any handler with the
`(k, sc, isr)` signature — `consoleController.lua:486` — and hooks receive exactly that, so
`compy.input.hooks.keypressed = fn.ignore_repeat(appKeypressed)` is a legal registration.

**There is an exemption in both baselines, and its stated reason does not survive the migration.**

```lua
-- upstream                                    -- merged tree
if inputStale(k) and k ~= "capslock" then       if isr and k ~= "capslock" then
  return end                                      return end
```

**[2026-08-12] Corrected after an owner challenge.** An earlier draft of this section asserted that
*"`capslock`'s release is not reliably delivered"* as the reason. That phrase is the **author's**,
from upstream's own comment — *"capslock is exempt from the stale filter (its release may not
arrive, wedging the set and freezing Caps)"* — and **it describes a failure of the held-set
mechanism specifically**: if the release never arrives, `INPUT.held['capslock']` stays true forever,
so every later press is stale, `capsToggle` never runs again, and the estimate freezes for the rest
of the session. Sound reasoning about **upstream's** filter.

**The owner's reading is the purpose underneath it, and it is the better statement:** *capslock is
tracked because it toggles the caps state on every new press.* The exemption exists so the repeat
filter cannot **eat a toggle**. Upstream's filter genuinely could: through a wedged `held` flag, and
through the one-frame `upRecent` window on a fast re-press.

**Under `isrepeat` the filter cannot eat a toggle at all**, because a fresh press is never flagged as
a repeat — the OS knows the key is up regardless of what events reached us. So this branch's comment
(*"its next press can come in flagged as a repeat"*) re-justifies an inherited exemption with a claim
the new mechanism does not support. **That comment is wrong and must be corrected whatever else is
decided.**

**And the exemption's effect has inverted.** It no longer protects a toggle; the only thing it now
decides is what happens to capslock **repeats**. If the OS emits them while the key is held and does
*not* toggle the lock on each one, then letting them through makes `capsToggle` flip the estimate
every repeat — **the exemption would now cause the drift it was written to prevent**.

**Which way it behaves needs one observation, not an argument** — hold `capslock` down for a second
on the target platform and watch whether the OS lock and the Caps decal flicker. This container
cannot inject keystrokes, so it is owed by a human, and it is a minute's work. Both outcomes are
cheap: if the OS does not repeat lock keys the exemption is inert and can go for tidiness; if it does
repeat without toggling, the exemption is a live defect and **must** go.

**This is what actually gates the wrapper.** If the exemption is dropped, `appKeypressed`'s first
line disappears and `fn.ignore_repeat(appKeypressed)` becomes exactly equivalent to it — the owner's
suggestion lands, with the filter stated at the registration instead of inside the handler. If the
exemption is kept, the wrapper cannot be used as-is, and the escape is to move `capsToggle` onto its
own registration: `capslock` is not a modifier by `Key.is_mod`, so a bare
`shortcuts.keypressed['capslock'] = fn.side_run(capsToggle)` is expressible and runs ahead of the
hooks. **That is restructuring rather than minimisation and is not recommended inside this step** —
recorded so the option is on file.

**Scope note:** all of this is on the `keypressed` channel and therefore **outside the heal**, which
is confined to `textinput` (§2.2). The comment correction is owed regardless; the exemption's fate is
a separate decision that the observation above settles.

**On the second half of the question — no, the game is not avoiding the flag deliberately.**
Upstream never *received* it: `main.lua` defines `love.keypressed(k)` and forwards **one** argument,
discarding `scancode` and `isrepeat`, and `appKeypressed`'s signature takes one parameter. It
filtered repeats by held state instead — the same intent by a worse means.

**This branch fixed that, in three moves and with one wrong turn**, recorded because the middle one
would have been a live defect:

- `4814407` (the migration) deletes `main.lua`'s three forwarding wrappers outright; the game
  registers `compy.input.hooks.keypressed = appKeypressed` and the framework calls it with LÖVE's
  own arguments;
- `5de5a6d` **narrowed** the signature from `(k, _, isr)` to `(k, isr)`, on the assumption that the
  hook delivers `(key, isrepeat)`. It does not — so `isr` bound to `scancode`, which is always
  truthy, and `if isr and k ~= "capslock" then return end` would have dropped **every** non-capslock
  keypress: deaf on that channel;
- `f938fbc` restored `(k, _, isr)` the same day, citing LÖVE's real signature.

**The contract that settles it is documented**, so no future session needs to re-derive it:
*"Every shortcut, hook and callback receives exactly the arguments LÖVE delivers for that event —
`keypressed(key, scancode, isrepeat)`"* (`doc/input_api.md`, "Event hooks and shortcuts"). The
current `(k, _, isr)` is correct.

**Consequence for the eventual patch:** those two commits cancel out. A branch assembled off upstream
as *"one commit or two"* carries neither — worth knowing so nobody preserves the intermediate state
in the name of history.

**And the OS-settings worry does not bite.** If key repeat is disabled — by the user, or because
`love.keyboard.setKeyRepeat(false)` was called — then no repeat `love.keypressed` events are
generated at all, so `isrepeat` is simply never true and the filter is a no-op. The flag does not
become *unreliable*; the events it describes stop existing. What varies by environment is whether
repeats occur, and the filter is correct either way. (In Compy they do occur: `src/main.lua:297`
enables key repeat globally for the console and editor.)

### 9.6 What I recommend, now that Option C is on the table

**Option C, armed on every accepted character (§9.5a), with the slot-versus-table question
(§9.5b) decided deliberately and the shared `textBaseKey` landing with it.**

- **With the frame-time backstop of §9.5c it satisfies R1, R2, R3, R4 and R5** — every requirement,
  which no option had before — while **deleting more apparatus than any of them**: the claim table,
  the frame stamp, the grace constant, the debug counter, and the ratified design's own `blocked`
  field. Without the backstop it still carries R4's residue, the smallest of any option.
- **It supersedes A″**, which was my recommendation before this: A″ is Option C with a per-key table
  and without the content test. The remaining live question between them is §9.5b, which is narrow
  and answerable on its own.
- **B is no longer needed.** The impossibility result (§9.2) says R1+R2+R4 cannot be settled *at
  the moment a character arrives* — and §9.5c does not try to: it decides acceptance on content and
  resolves the press boundary **later**, from the device. That is deferral of a different kind, and
  it costs one poll rather than a dispatch-architecture change. B remains the answer if the poll is
  ever ruled out.
- **The `love.focus` mitigation is superseded** and need not be verified: a frame-time poll covers
  focus loss along with every other cause of a missing release, without depending on whether a
  project-defined `love.focus` survives the framework's handler management.

**Against the ratified design:** its *rule* is replaced (content-scoped fails R1 in Words) while its
*shape and intent* survive intact — one remembered character, no table, no counter, judgement that
infers nothing. **So the document is revised in this step rather than merely implemented**, which is
what the step was told it may do, and the revision is small enough to state as an amendment rather
than a rewrite.
