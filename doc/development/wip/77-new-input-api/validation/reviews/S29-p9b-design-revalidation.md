---
description: S29 revalidation of the P9b keyboard-judgement design (doc/development/internals/examples/keyboard.md) — two coherence findings against the declared state, traced through concrete LÖVE event sequences
status: active
audience: developer
authored: llm
reviewed: none
---

# S29 — P9b design revalidation

Reviewed: `doc/development/internals/examples/keyboard.md` (HEAD `36853f54`,
branch `feature/77-newapi-analysis-s20260615`). Read-only; no edits except
this file. Nested repo `src/examples/keyboard` read only, no writes (its
`git status` is clean, `HEAD` `3a9d48c`).

Two connected findings surfaced by tracing the four `ALT_JUDGE` fields through
concrete event sequences, plus one secondary counter-example against rule 3's
claim. Everything else checked below came back clean.

---

## 1. Internal coherence of the rules against the declared state

**FINDING.** The document contradicts itself about what `seenText` is, and
the contradiction breaks either rule 3 or rule 4 depending on which
description an implementer follows.

- §"State" (`keyboard.md:45`): `seenText = nil, -- text of the most recent
  textinput, judged or not`. Read literally, this is an unconditional
  record — it is overwritten by every `textinput`, full stop, and the
  comment gives no exception for `keyreleased`.
- §"Channel ownership" (`keyboard.md:33`): `keyreleased | clear seenText
  when the released key produced it; stamp the frame`. This assigns
  `keyreleased` — not a `textinput` event — the job of nulling the very
  field the State comment just described as tracking "the most recent
  textinput."

These cannot both be built as written:

- Build it per the State comment (never clear `seenText` on release): rule 3
  (`text == seenText`, stop) then suppresses **every future press of that
  character forever**, once it has been judged once — the exact defect this
  design exists to fix (`keyboard.md:20-23`), reproduced.
- Build it per the Channel-ownership row (clear on matching release): rule 4
  cannot be evaluated. Rule 4 (`keyboard.md:74-75`) reads: *"If `text ==
  seenText`'s value at release and `frame - releasedAt <= TEXT_TAIL_FRAMES`,
  stop."* This names a value — *`seenText`'s value at the moment of
  release* — that is not any of the four declared fields once `keyreleased`
  has nulled `seenText`. `releasedAt` is declared as a bare frame number
  (`keyboard.md:47`, "frame at which seenText's key was released"), not a
  frame+text pair. By the time rule 4 runs on the delayed `textinput`, the
  only field is `seenText == nil`; comparing `text == nil` is never true, so
  rule 4 as literally written can never fire for the case it exists to
  cover.

A competent implementer facing this has to invent a fifth field (a frozen
copy of the released text) that the document never declares under its
"four named fields" state block (`keyboard.md:41-50`) — which is exactly the
kind of unspecified state the closing question asks about.

Per-rule verdict on "can this be evaluated from the declared state, given
what the other two channels do to it":

| Rule | Verdict | Note |
|---|---|---|
| 1 Caps reconcile | CONFIRMED | Reads `text` + live `shiftHeld`, writes `CAPS_STATE.on` only — no `ALT_JUDGE` dependency. |
| 2 Modifier guard | CONFIRMED | Reads live Alt/Ctrl, writes `seenText`. No prior-state dependency. |
| 3 Hold suppression | CONFIRMED evaluable, but see §2 — the *claim behind* the rule is not always true. |
| 4 Tail window | **FINDING** — needs a value the declared state cannot hold once `keyreleased` clears it (above). |
| 5 Acceptance gate | CONFIRMED evaluable (declared field `accepting`), but see §4 — evaluable does not mean protective. |
| 6 Judge | CONFIRMED — needs only `judgedText`, declared and never touched by the other two channels. |

---

## 2. Rules 3, 4, 6 claims on their own terms

**Rule 3** (`keyboard.md:70-73`): *"`text == seenText` proves 'the producing
key has not been released since it was last seen.' ... No timing involved: a
key held for ten seconds stays suppressed for ten seconds."*

**FINDING — the proof fails when a second key is judged while the first is
still held.** `seenText` is a single scalar, not a per-key set, and rule 6
overwrites it unconditionally on every judge (`keyboard.md:77-78`, "set
`seenText` and `judgedText` to `text`"). Concrete sequence:

1. Target = `a`. Player presses and **holds** `a`. `textinput('a')` → rule 6
   judges it (hit or miss, doesn't matter), sets `seenText = 'a'`.
2. Without releasing `a`, the player's other hand hits `x` (a mash, not a
   modifier — `x` is not Alt/Ctrl so rule 2 doesn't intercept it) and
   releases it. `textinput('x')` → rule 3: `'x' == seenText('a')` → false,
   continues; rule 6 judges `x` against the (still-live) target, sets
   `seenText = 'x'`.
3. `a` is **still physically held** and its OS key-repeat fires:
   `textinput('a')` (repeat) → rule 3: `'a' == seenText('x')` → **false**.
   Hold suppression does not fire, even though key `a` was never released.
   The repeat falls through to rule 5/6 and gets **judged again**, as if it
   were a fresh press.

So "a key held for ten seconds stays suppressed for ten seconds, at any
repeat rate" is false the moment any other key is judged during that hold —
a realistic sequence for a mashing child, not a contrived one. The rule's
*mechanism* (evaluable, single comparison) is fine; the *proof it claims to
establish* is not general, because the state has no notion of "which key",
only "which text was judged most recently."

**Rule 4** (`keyboard.md:74-75`, "Why rule 4 needs a clock",
`keyboard.md:87-98`): *"a `textinput` can arrive after its own
`keyreleased`, and at that moment two cases are indistinguishable by state
alone... Only elapsed time separates them."*

**FINDING — the necessity argument's premise is not quite right, and the
rule as stated is unimplementable (§1).** The two cases the document names —
a repeat tail from the hold that just ended, vs. the press's own late
character — are *not* fundamentally indistinguishable by state: "has this
text already been judged for this key" is exactly the information `seenText`
held immediately before `keyreleased`'s own "clear seenText" step discarded
it. If that value survived the clear, the disambiguation is a plain
equality check, no clock needed for the disambiguation itself. What a clock
*is* legitimately needed for is different from what the document says: since
that "already judged" memory has to be forgotten eventually (or a genuine
second press of the same character, after a full release-and-repress, would
be dropped forever — reproducing rule 3's failure mode from above), a bound
on how long the memory is kept is the real job of `TEXT_TAIL_FRAMES`. The
document's own framing — drift between two channels for the *same* event —
is the wrong mental model for what the constant is actually doing; the right
one is "how long a just-completed hold's dedupe memory survives," which
happens to be a defensible design, just not the one argued for, and not
implementable with the four declared fields as written regardless.

**Rule 6** (`keyboard.md:77-78`, `keyboard.md:116-121`): *"a dedupe, not
repeat detection... harmless here — a wrong key knocks once per target
(`gauge.lua`, `fumbled`) and a correct one closes acceptance."*

**CONFIRMED.** Traced a deliberate double-tap of the same wrong character
against a still-live target: the second press's `textinput` reaches rule 6
with `text == judgedText` (unchanged since a miss never resets `judgedText`,
per `keyboard.md:80-81` — only a hit does) and is deduped silently. But
`gauge.lua`'s own `st.fumbled` flag (`gauge.lua:201-212`, `gaugeOnWrong`)
already makes every wrong key after the first a no-op at the gauge layer, so
the *observable* game behavior is identical whether rule 6's dedupe fires or
the character reaches `gaugeOnWrong` and no-ops there. The claim holds as
stated, and its self-declared scope (dedupe, not repeat detection) is
accurate — this is the one of the three claims that fully survives.

---

## 3. The SM5 trace

> A `textinput` that arrives after its own `keyreleased` finds no claim
> recorded, falls through to the post-keyup grace window, and is dropped as
> a trailing repeat — although it is the press's own legitimate character.

Traced against the new design for the case the SM5 hole actually describes —
a fast tap where the key's *own first* `textinput` has not arrived yet when
`keyreleased` fires:

1. `keypressed('a', _, false)` — not a repeat; §"Channel ownership" gives
   `keypressed` no job touching `ALT_JUDGE`.
2. `keyreleased('a')` fires **before** `textinput('a')` has ever arrived.
   The clear condition (`keyboard.md:33`, "when the released key produced
   it") tests `altBaseKey(seenText) == k`; `seenText` still holds whatever
   was last judged for an *earlier* key, not `'a'` — the condition is false,
   so `seenText` is **not** cleared and `releasedAt` is **not** stamped for
   this release.
3. `textinput('a')` now arrives (late). Rule 3: `seenText` is unrelated to
   `'a'`, doesn't match. Rule 4: `releasedAt` was never stamped for `a`'s
   release, so this comparison is against stale, unrelated data — doesn't
   match. Rule 5: `accepting` unaffected by any of the above, still true.
   Rule 6 judges `'a'` normally.

**CONFIRMED for this exact case** — but not for the reason the design
claims. The character is judged because `keyreleased`'s clear-condition
*fails to fire* when a hold's own first character hasn't arrived yet (so
nothing about that key's tracking state is touched), not because rule 4's
clock correctly disambiguated it. §2 already showed rule 4 cannot fire
correctly at all once the clear *does* apply (the value it needs is gone).
The design does not reproduce the SM5 defect for a bare tap-then-late-glyph,
but it does so by accident of the conditional-clear's guard condition, not
by the mechanism ("Why rule 4 needs a clock") the document credits. See §4
for the case where a *held* key crosses this same boundary — there the same
accident does not save the design.

---

## 4. Interaction with the acceptance gate

**FINDING — the gate provides no protection against the exact scenario it
exists for, and the smoke-checklist promise is not met for a normal
held-then-released hit.**

`gauge.lua`'s target-advance is synchronous and immediate, by its own
documentation: `gaugeNext` (`gauge.lua:123-127`, "Pick and show the next
target... no inter-target pause") is called directly from `gaugeOnCorrect`
(`gauge.lua:188-199`) on every hit that doesn't complete the level's goal —
which is most hits during ordinary play; only the level's *final* hit takes
the `gaugeWin` branch instead and skips the advance. `altHit` →
`gaugeOnCorrect` → `gaugeNext` is one Lua call stack, run to completion
inside the same `textinput` event handler that judged the hit, before
control returns to LÖVE's event pump. The design's own transition rule
(`keyboard.md:80-81`) — `accepting = false` on the hit, `judgedText = nil,
accepting = true` when the next target displays — therefore executes
**both halves within that single call**: `accepting` closes and reopens,
and `judgedText` resets to `nil`, before any other event (same frame or
next) is ever dispatched. No subsequent `textinput` event can ever observe
`accepting == false`. `seenText` is left unchanged by this transition
(`keyboard.md:80-81` only mentions `judgedText`/`accepting`), so it still
equals the just-hit character.

Concrete trace, target `a` → hit → new target `b`, key `a` released with one
OS-repeat glyph already queued (the standard race `TEXT_TAIL_FRAMES` exists
to bound, per `keyboard.md:95-98` and the shipped code's own comment,
`input.lua:37-40`):

1. `textinput('a')` (fresh) — rules 1-2 pass, rule 3 (`seenText` stale)
   doesn't match, rule 4 doesn't match, rule 5 (`accepting` true) passes,
   rule 6 judges HIT. `altHit` → `gaugeOnCorrect` → `gaugeNext`: target
   becomes `b`, and **within this same call** `accepting = true`,
   `judgedText = nil`. `seenText = 'a'` (untouched).
2. `keypressed('a', _, true)` — OS repeat, dropped by the `isrepeat` filter.
3. `textinput('a')` (repeat, while `a` still held) — rule 3:
   `'a' == seenText('a')` → **stops**. Protected — while the key stays
   physically down, rule 3 covers it regardless of what happened to
   `accepting`.
4. Player releases `a`. `keyreleased('a')`: `altBaseKey(seenText) ==
   altBaseKey('a') == 'a' == k` → true → `seenText = nil`,
   `releasedAt = <frame>`.
5. The queued trailing repeat glyph arrives: `textinput('a')`. Rule 3:
   `'a' == seenText(nil)` → false, doesn't stop (this is exactly why
   clearing was needed — but it is also exactly the hole from §1: nothing
   replaces the protection rule 3 just gave up). Rule 4: the comparison
   needs `seenText`'s pre-clear value; the only field available is the
   now-`nil` `seenText`, so the comparison is `'a' == nil` → false, doesn't
   stop. Rule 5: `accepting` is **already `true`** (reopened in step 1, long
   before this event was even dispatched) → doesn't stop. Rule 6:
   `'a' != judgedText(nil)` → **judges `'a'` against target `b`** → miss,
   knock.

This is precisely "holding the right key ... bleed[s] a miss onto the next
target" — the smoke checklist's own named requirement
(`keyboard.md:138-140`) — for an entirely ordinary sequence (hold long
enough for one OS repeat, then release), not a contrived one. The design
does **not** achieve the checklist item as written, for the reason above:
§1's coherence hole (rule 4 has nothing to compare against) combines with
the gate's own synchronous reopen (independently confirmed against
`gauge.lua`) to remove every layer that could have caught the trailing
glyph. A key released and **not** re-pressed near a target boundary is the
exposure; a key that stays down through the boundary is fine (step 3).

---

## 5. Factual claims about the platform and LÖVE

| Claim | Status |
|---|---|
| No guaranteed order between `keypressed`/`textinput` | **CONFIRMED** — `user_input.md:56`, "LÖVE2D does not guarantee the relative *order* the two arrive in for the same physical key," near-verbatim match to the design's framing, under "Data flow" (`user_input.md:29`) as cited. |
| Desktop LÖVE sends `keypressed` first | **UNCLEAR — could not independently verify.** Not stated as platform fact anywhere in `user_input.md`; asserted identically across several documents in this repo (`input.lua:20-21` in the nested repo, `keyboard.md:16-17`) but always as inherited belief, never as a cited platform source. |
| The web build sends `textinput` first | **UNCLEAR — could not independently verify, and the repo's own record flags it as unconfirmed.** `S25-keyboard-verdict-overturned.md:87-92` calls the same claim (from an *unrelated* project's comment) "corroboration," then states plainly: "Whether the *direction* it claims still holds under the current run loop is **untested**." No LÖVE/love.js source is present in this repo to check against. |
| `textinput` carries no repeat flag | **CONFIRMED** — `/opt/lua-language-server/meta/3rd/love2d/library/love.lua:297`: `@alias love.textinput fun(text: string)`, one argument, no `isrepeat`. |
| LÖVE 11.5 has no API to query Caps Lock state | **CONFIRMED** — `/opt/lua-language-server/meta/3rd/love2d/library/love/keyboard.lua` (the installed 11.5 meta, matching the installed `liblove-11.5.so`) exposes only `isDown`/`isScancodeDown`/`hasKeyRepeat`/`hasScreenKeyboard`/`hasTextInput`/`setKeyRepeat`/`setTextInput`/`getKeyFromScancode`/`getScancodeFromKey` — nothing that reads lock-toggle state. |
| `keyreleased('capslock')` is unreliable | **UNCLEAR — not independently verifiable from anything authoritative in this repo.** The claim recurs in `doc/development/wip/77-new-input-api/notes/stakeholder-3-input/compy-lua-game-patterns.md:141,145,177` (a separate hands-on notes file, itself describing a different runtime's behavior) — internally consistent with the design doc, not independently sourced against LÖVE/SDL documentation. |

---

## 6. Claims about the shipped code

All verified directly against `src/examples/keyboard` at its current `HEAD`
(`3a9d48c`, working tree clean):

- **`spendGlyph` / `GLYPH_CLAIMED` exist as described** — `input.lua:154-160`
  (`spendGlyph`), `:101` and `:147` (`GLYPH_CLAIMED = {}`), `:180`
  (`GLYPH_CLAIMED[k] = nil` in `appKeyreleased`). **CONFIRMED.**
- **"Judgement still depends on a release arriving"** — accurate for the
  claim material to it: the *first* press of a key is judged immediately by
  `spendGlyph`'s own claim-on-first-call return (`input.lua:158-159`), not
  gated on a release; what depends on a release arriving is the claim being
  **reset** for the *next* press of the same key (`GLYPH_CLAIMED[k] = nil`
  only in `appKeyreleased`, `input.lua:180`) — if no release ever arrives,
  the key is wedged for future presses. **CONFIRMED**, with that
  clarification.
- **Non-printing targets judged on a second path (`altPlayKey`)** —
  `alt.lua:184-196` (`altPlayKey`), distinct from `altTextinput`
  (`alt.lua:172-182`). **CONFIRMED.**
- **A chord whose modifiers release while the base key is held can slip one
  character through** — `appTextinput` (`input.lua:189-200`) reads
  `INPUT.alt`/`INPUT.ctrl` live on every call (`:191-192`); if those go
  false before a subsequent (unmodified) repeat glyph of the base key
  arrives, `GLYPH_CLAIMED` for that key was never set (the chord's own
  glyph returned early at the modifier check, before ever calling
  `spendGlyph`), so the next arriving glyph claims and is judged.
  **CONFIRMED.**
- **Things the design says should disappear, confirmed present today:**
  `spendGlyph` (`input.lua:154`), `GLYPH_CLAIMED` (`input.lua:101,147,155,158,180`),
  the held-set read in judging (`INPUT.alt`/`INPUT.ctrl` in
  `input.lua:191-192`, `INPUT.shift` in `input.lua:194,196`), and
  `altPlayKey` as a second judging path (`alt.lua:188-196`, wired from
  `altKeypressed`, `alt.lua:202-212`). All present, all at the cited
  locations.

---

## 7. Citations and vocabulary

- `../user_input.md`, "Data flow" — **resolves.** `user_input.md:29`,
  `### Data flow`, exact heading text match.
- `gauge.lua`, "where the current target is set" — **resolves.**
  `gauge.lua:128-140`, `gaugeNext`, `st.cur = k` at `:135`; called from
  `gaugeStartLevel` (`:149-159`, level start) and `gaugeOnCorrect`
  (`:188-199`, after a non-final hit) — both places the design's phrase
  covers.
- `gauge.lua`, `fumbled` (Concerns section) — **resolves.** `st.fumbled`,
  set at `gauge.lua:207`, read at `:189` (`gaugeOnCorrect`) and `:206`
  (`gaugeOnWrong`'s own re-entry guard).
- `altBaseKey(text)` — **resolves.** `alt.lua:68-74`.

Nothing checked in this pass failed to resolve.

---

## Closing lines

1. **No.** A competent implementer following this document as written
   cannot build rule 4: its own comparison term ("`seenText`'s value at
   release") names data that `keyreleased`'s own "clear `seenText`" step
   (assigned in the very same document) has already destroyed by the time
   the rule runs, and the declared four-field state has no field to hold
   it. Getting a working implementation requires either inventing an
   undeclared fifth field, or silently not clearing `seenText` on release
   (which reproduces the state's original defect via rule 3, §1). Either
   choice is invention the document doesn't license.

2. **No, not as stated, for two of the three.** Rule 3's mechanism is
   evaluable but its stated proof ("proves the key has not been released")
   is false once a second key is judged during the first key's hold (§2).
   Rule 4 is unimplementable from the declared state (§1), and its
   necessity argument's premise — that state alone cannot distinguish a
   repeat tail from a late-delivered character — does not hold either: the
   two cases are distinguishable by state (whether the text was already
   judged for that key), using exactly the information `keyreleased`'s own
   clear step throws away. Rule 6 holds as stated and is the one of the
   three that survives cleanly (§2).

3. **What came back clean:** rules 1, 2, 5, and 6 are each evaluable from
   the declared state given what the other channels do to it (§1); rule 6's
   dedupe-not-repeat-detection self-assessment is accurate and matches
   `gauge.lua`'s independent fumble-guard (§2); the SM5 trace does not
   reproduce for a bare tap-then-late-glyph, though not for the reason
   credited (§3); every platform/LÖVE claim that this repo can check
   (order-exists-but-unguaranteed, no repeat flag on `textinput`, no
   Caps-Lock query API in 11.5) is confirmed against `user_input.md` and the
   installed LÖVE 11.5 API meta, with the platform-*direction* and
   Caps-Lock-release claims correctly out of this repo's reach to verify
   (§5); every fact claimed about the shipped code — `spendGlyph`/
   `GLYPH_CLAIMED`, `altPlayKey` as a second path, the live modifier read,
   the chord-slip case, and the four things named for removal — checks out
   against `src/examples/keyboard` at its current commit (§6); and both
   citations (`user_input.md` "Data flow", `gauge.lua`) resolve to the exact
   section/mechanism named (§7).

---

## State at close

```
$ git status --porcelain
?? claude.sh
?? doc/development/wip/77-new-input-api/validation/prompts/S29-p9b-design-agent.md
?? doc/development/wip/clarification/
?? doc/development/wip/personal-notes/
?? doc/development/wip/pull-26/
?? doc/tall_blocks.md
?? input-pr-slices.tar.gz
?? src/STEPS.md
?? src/examples/balloons/
?? src/examples/keyboard/
?? src/examples/maze/

$ git diff --stat
(empty)
```

All untracked entries are the owner's pre-existing scratch (per the task
brief) plus this session's own prompt file and this deliverable; nothing
else in the working tree changed. `src/examples/keyboard` (nested repo) has
a clean working tree at `HEAD 3a9d48c`; no git command was run there beyond
`log`/`status`/`show`.
