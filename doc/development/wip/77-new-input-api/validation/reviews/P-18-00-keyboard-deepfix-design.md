# P-18-00 — the keyboard deepfix: analysis and design

**Step:** P-18-00, the initial analysis/planning pass of P18 (`S27-triage-and-plan.md` §15.4).
**Opened:** 2026-08-11, session37, after the upstream merge landed (`keyboard` @ `ca6d5df`).
**Status: NOTHING HERE IS DECIDED.** §2–§7 are exposition — what the code does, read from the
merged tree. §7.1 states the requirements, §8 the open questions, §9 the derivation from those
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
