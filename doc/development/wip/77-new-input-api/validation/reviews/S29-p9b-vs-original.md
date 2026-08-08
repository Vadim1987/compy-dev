---
description: S29 conceptual comparison of the P9b keyboard-judgement design against the mini-game's own implementation history (A original, B Compy-API migration, C shipped fix, D paper design)
status: active
audience: developer
authored: llm
reviewed: none
---

# S29 — the P9b design against the mini-game's own history

Scope: `src/examples/keyboard` (separate git repo, read-only) at four points —
**A** `c904338`, **B** `4814407`..`6eb7919`, **C** `3a9d48c` (`HEAD`) — against
**D**, the paper design at `doc/development/internals/examples/keyboard.md`
(main repo). Builds on, does not re-litigate,
`../reviews/S29-p9b-design-revalidation.md` (its findings are cited by section
number, e.g. "§1", "§4").

---

## 0. The question that matters most: was A correct?

**No — A was comprehensively broken on desktop LÖVE, not just at the margins,
from the moment it was written.** This is the single most important finding
in this review and it inverts the framing of the owner's question.

A's own header (`input.lua:12-14` at `c904338`) states the assumption
plainly: *"the IDE delivers textinput BEFORE the matching keypress (the
reverse of desktop LOVE)"*. A's suppression rule, `inputStale`
(`input.lua:112-117`), drops a `textinput` glyph if its producing key is
already in `INPUT.held`. `appKeypressed` (`input.lua:123-134`) sets
`INPUT.held[k] = true` **before** dispatching to the scene, on every fresh
press.

Trace a single, first, deliberate press of a target character under desktop
ordering (`keypressed` before `textinput`, the order `c904338`'s own header
names as "desktop LOVE", and the order the platform actually uses):

1. `keypressed('a')` fires. `inputStale('a')` is false (nothing held yet) →
   `INPUT.held['a'] = true` is set, scene dispatch proceeds.
2. `textinput('a')` fires. `altTextinput` calls
   `inputStale(altBaseKey('a'))` → `INPUT.held['a']` is **already true**
   (step 1) → **dropped**.

The character is never judged. This is not a first-press-only quirk: every
subsequent fresh press behaves identically, because `inputStale` only ever
asks "is the key held right now," and under desktop ordering it always is by
the time `textinput` arrives. The commit that eventually fixes this,
`3a9d48c`, says exactly this in its own words: *"Subgame 4 showed a target
letter and ignored it when pressed... on desktop LOVE the keypress arrives
before the glyph, so a key is always held at its own first textinput. Every
fresh target was thrown away as a repeat."*

So: **A was not simple-and-correct.** It was correct only in the one
environment ("the IDE") its author tested against, and non-functional — no
printable target could ever be accepted — in the other real environment
(desktop LÖVE) the game also had to run in. The defect was latent in A from
`c904338` onward; it did not enter later. B (below) carries it forward
unchanged. C is the first version that fixes it. D re-solves the same
underlying problem (order-independent judging) with a different mechanism,
not a non-problem — but, as Part 5 shows, C had already solved it with far
less machinery than D adds.

---

## 1. Plain-language account of each version's judging rule

**A** (`c904338`). A character is judged the instant its `textinput` arrives,
gated only by `inputStale`: drop if the producing key (via `altBaseKey`) is
currently in the `INPUT.held` mirror, or was released within
`INPUT_UP_GRACE` (1) frames. State: `INPUT.held` (set, mirrored on every
press/release), `INPUT.upRecent` (frame stamps). Non-printing targets
(`backspace`/`tab`/`return`) are judged on a **second**, independent path,
`altPlayKey`, called from `keypressed`, gated only by `gaugeGlowing` and
`altIsKeyTarget` — no `inputStale`, no dedupe, protected from OS repeats
purely because repeated `keypressed` calls are already filtered by the
held-edge check before `altPlayKey` is ever reached.

**B** (`4814407`..`6eb7919`). Pure input-plumbing migration onto
`compy.input`. `alt.lua` is byte-for-byte unchanged
(`git diff c904338 6eb7919 -- alt.lua` is empty). `inputStale`'s logic is
unchanged; only its data source changes, from a hand-rolled mirror to a live
proxy over `compy.input.keys_pressed`. `INPUT.held[k]` still answers "is the
key down right now," set by the framework "at the gateway, before dispatch"
(`input.lua:39-40` at `6eb7919`) — the same timing relationship to
`textinput` that broke A. The commit's own stated intent: *"the game's
behaviour is meant to be unchanged."* It is unchanged, defect included.

**C** (`3a9d48c`, `HEAD`). Judging is unchanged (`altTextinput`,
`alt.lua:172-182`) except for the gate: `spendGlyph` (`input.lua:154-160`)
replaces `inputStale`. A key's glyph is **claimed** on first arrival
(`GLYPH_CLAIMED[k] = true`) and the claim is released only at `keyreleased`
(`input.lua:180`). The question asked is no longer "is the key held" but
"has this key's glyph already been judged since its last release" — a
question with the same answer regardless of which channel arrives first.
The post-release grace window (`INPUT.upRecent` + `INPUT_UP_GRACE`, still 1
frame) is kept, checked inside `spendGlyph` after the claim check. Non-printing
targets still travel the separate `altPlayKey` path, unchanged from A.

**D** (`keyboard.md`, unimplemented). One shared table, `ALT_JUDGE`, four
declared fields (`seenText`, `judgedText`, `releasedAt`, `accepting`), six
ordered rules run on every `textinput`: reconcile Caps, drop chords (and
record the glyph into `seenText`), drop if `text == seenText` (hold
suppression), drop if `text` matches `seenText`'s value at release within
`TEXT_TAIL_FRAMES`, drop if not `accepting`, dedupe against `judgedText` then
judge. Non-printing targets are meant to be injected into the *same* function
from `keypressed`, unifying what is two paths in A/B/C into one.

---

## 2. Moving-parts count per version

| | A | B | C | D |
|---|---|---|---|---|
| State pieces (judging-relevant) | 2: `INPUT.held`, `INPUT.upRecent` | 2 (same, `held` now a live proxy) | 2: `GLYPH_CLAIMED`, `INPUT.upRecent` | 4 declared + **1 undeclared field the doc's own logic requires** (§1 of the earlier review) = 5 |
| Tunable constants | 1: `INPUT_UP_GRACE = 1` | 1 (same) | 1: `INPUT_UP_GRACE = 1` (unchanged value) | 1: `TEXT_TAIL_FRAMES ≈ 5`, stated as "a starting value," 5× C's grace window, no measurement behind the number |
| Separate code paths a character can travel | 2: `altTextinput` (printable), `altPlayKey` (non-printing) | 2 (same) | 2 (same, unchanged from A) | 1 (rules 1-6 claimed to cover both — see Part 5 on whether rules 3/4 do any real work on the injected, non-repeating, non-printing branch) |
| Places reading *live* held/modifier state at judging time | 2: `INPUT.alt`/`INPUT.ctrl` (chord guard, `appTextinput`), `INPUT.held[k]` (`inputStale`'s staleness check — the defect itself) | 2 (same) | 1: `INPUT.alt`/`INPUT.ctrl` only (the staleness read is gone — this is the whole point of the fix) | 1: rule 2's live Alt/Ctrl read — same defect as A/B/C, and the doc's own Concerns section (`keyboard.md:127-131`) says so |
| Ordered rules governing one event | implicit (2 `if`-guards in `altTextinput`) | same | same | 6, explicit and ordered |

C is a **net reduction** from A/B on exactly the axis that mattered (the
live-held staleness read, the actual bug), at unchanged state/constant count.
D is a **net increase** in state (2→5) and in explicit rule count (implicit→6)
to buy a code-path reduction (2→1) that Part 5 shows is the one piece of D's
added machinery best supported by a concrete case.

---

## 3. Behaviour matrix

Cells: **JUDGED** (reaches hit/miss), **DROPPED** (suppressed, no state
change reaches the target comparison), **STATE ONLY** (no judgement, but
state changes), **UNDETERMINED** (the design text does not fix the answer).
"Order" = keypressed-vs-textinput arrival order; default is desktop order
(`keypressed` first) unless the case itself is about order.

| # | Case | A | B | C | D |
|---|---|---|---|---|---|
|1|Plain single press, desktop order|**DROPPED** — `inputStale` sees the key already held (§0)|**DROPPED** — same mechanism, unchanged|**JUDGED** — `spendGlyph` claims regardless of order|**JUDGED** — rule 3 needs no held-state, order-independent|
|2|Key held, OS repeats, desktop order|**DROPPED entirely** — 1st press already dropped (case 1), repeats also dropped, same reason: zero judgements for the whole hold|**DROPPED entirely** — same as A|**JUDGED once, repeats DROPPED** — claim set on first call, repeats see `GLYPH_CLAIMED[k]==true`|**JUDGED once, repeats DROPPED** — rule 3 fires on repeats *unless* another key was judged mid-hold (earlier review §2 counter-example, not retested here)|
|3|`textinput` before its own `keypressed` (web order)|**JUDGED** — this is the order A's header names as "the IDE," the order it was built and tested for|**JUDGED** — same, unchanged|**JUDGED** — order-independent by design|**JUDGED** — order-independent by design|
|4|`textinput` arrives after its own `keyreleased` (fast tap, key's own first-and-only glyph, delivered late)|**DROPPED (defect)** — `keyreleased` stamps `upRecent`; the late glyph falls inside the 1-frame grace and is dropped as a "trailing repeat" though it is the tap's own legitimate character (traced below)|**DROPPED (defect)** — identical mechanism|**DROPPED (defect)** — `spendGlyph`'s grace check is unchanged from A/B; `GLYPH_CLAIMED[k]` was never set (glyph hadn't arrived before release), so only the `upRecent` grace check runs, and it drops the glyph the same way A does|**JUDGED — but by accident, not by rule 4** (earlier review §3, "SM5 trace"): `keyreleased`'s clear condition tests `altBaseKey(seenText)==k`, which is false here because nothing had set `seenText` for this key yet, so the release touches nothing and rules 3/4 simply don't match. Rule 4 itself is inert (§1 of the earlier review: it needs a value `keyreleased`'s own clear step has already destroyed)|
|5|Chord (Alt/Ctrl held), character not a target|**DROPPED, no state touched** — filtered at `appTextinput`'s `INPUT.alt`/`INPUT.ctrl` guard before the scene ever sees it, and at the keypress level by `appChord`|**DROPPED, no state touched** — same, via the `alt+*` shortcut class|**DROPPED, no state touched** — same|**DROPPED, but WITH a state write** — rule 2 sets `seenText = text` before stopping. A/B/C never let a chord glyph enter judging state at all; D funnels it into the same single scalar a real target's hit/miss uses (see Part 5, and the earlier review §2 on that scalar's fragility under interleaving)|
|6|Chord whose modifiers release before its character arrives|**JUDGED (defect, slips through)** — `appTextinput`'s `INPUT.alt`/`INPUT.ctrl` check is live; if false by the time the glyph arrives, nothing stops it (confirmed against shipped code, earlier review §6)|**JUDGED (defect, slips through)** — same live read|**JUDGED (defect, slips through)** — same live read, unfixed since A|**JUDGED (defect, slips through)** — rule 2's read is equally live; the design's own Concerns section (`keyboard.md:127-131`) names this exact case and says it is "the one live-state read left in the path"|
|7|Non-printing target (`backspace`/`tab`/`return`)|**JUDGED** — via `altPlayKey`, a second path, protected only by `keypressed`'s `isr` filter|**JUDGED** — same path; see A→B transition below for a real regression window on this exact case|**JUDGED** — same path, unchanged|**JUDGED (evaluable, if the seenText contradiction is resolved)** — routed through the same 6 rules; rules 3/4 do no useful work here since `keypressed` already filters repeats before injection (doc's own words, `keyboard.md:85`), so the "unification" is real for code structure but two of the six rules are no-ops on this branch|
|8|Deliberate fast re-press of the same character|**Order- and timing-dependent**: under desktop order, indistinguishable from case 1/2 (dropped, same defect); if it lands within `INPUT_UP_GRACE` (1 frame) of the prior release it is also wrongly dropped even under favorable ordering|**Same as A**|**JUDGED if outside the 1-frame grace of the prior release; wrongly DROPPED if inside it** — a narrow, ~16ms-at-60fps window|**UNDETERMINED as literally written** (rule 4 uncomputable, §1 of earlier review). Under either of the two ways an implementer could resolve the contradiction: (a) never clear `seenText` on release → dropped **forever** after the first judgement (§1, "the exact defect this design exists to fix, reproduced"); (b) clear on release → wrongly dropped only if the re-press lands within `TEXT_TAIL_FRAMES` (≈5 frames, ~83ms) of the release — a window **5× wider** than C's equivalent hazard|
|9|Key still held when the next target appears (post-hit trailing repeat crossing a target boundary)|**Moot under desktop order** — printable judging does not function at all (case 1); under the IDE order it was built for, this is the scenario `inputStale`'s release-grace already covers, same shape as C below|**Same as A**|**Correctly DROPPED** — the pending trailing glyph is caught by `spendGlyph`'s grace check, which runs *before* `gaugeCurrent` is ever consulted; C's suppression decision never depends on which target is showing, so the gauge's synchronous same-call advance (`gaugeOnCorrect`→`gaugeNext`, `gauge.lua:188-198`, unchanged since A) cannot race it|**JUDGED against the NEW target (defect — a real "bleed"), confirmed by the earlier review §4**: `accepting` reopens synchronously inside the same call that judged the hit (`gaugeOnCorrect`→`gaugeNext` is one Lua call), so no later event can ever observe `accepting == false`; and rule 4, which is supposed to catch the trailing glyph via `seenText`'s pre-release value, cannot fire (§1). This is exactly the case the design's own smoke checklist names as a requirement (`keyboard.md:138-140`) and, per the earlier review, fails|

Where this table says A/B "DROPPED (defect)" for case 4, the trace: target
key `a`, tapped fast. `keypressed('a')` (frame 10), `keyreleased('a')` fires
before `textinput('a')` has arrived — `appKeyreleased` stamps
`INPUT.upRecent['a'] = 10` (`input.lua:179` at `HEAD`, `input.lua:140` at
`c904338`). `textinput('a')` then arrives at frame 10 or 11. For A/B:
`inputStale('a')`: `INPUT.held['a']` is nil (cleared at release) → false;
`up = 10`; `DBG_FRAME - up <= 1` → true → **stale, dropped**. For C:
`spendGlyph('a')`: `GLYPH_CLAIMED['a']` is nil (the glyph never arrived
before release, so it was never claimed) → falls through to the identical
`up`/`INPUT_UP_GRACE` check → **also dropped**. This specific hole is present,
unchanged, in A, B, **and** C today; it is not something C fixed, and is not
something the shipped-code contrast section of D credits itself against
correctly either (see Part 4).

---

## 4. Solved / created, per transition

**A → B.** *Solved:* nothing — the migration's own commit message states the
intent as behaviour-preserving, and `alt.lua` is byte-for-byte identical
through `6eb7919`. *Created:* a new failure axis with no analogue in A —
coupling the game's repeat-filtering to an evolving platform argument
contract. Two follow-on commits, `f938fbc` and `5de5a6d` (both dated Aug 7,
four days after the migration), exist solely to chase the shape of
`compy.input`'s `keypressed` hook arguments back and forth between `(k, isr)`
and `(k, scancode, isr)`. `5de5a6d`'s own message: binding `isr` to the wrong
argument position "would have bound nil — silently, with no error and no
visible failure, except that held keys would stop being filtered and every
repeat would reach the scene." Concretely, case 7 (non-printing repeats via
`altPlayKey`, gated only by `appKeypressed`'s `isr` check) had a real
regression window in this lineage where holding Backspace would have
re-triggered `altPlayKey` every frame — a defect A never had, entirely a
byproduct of B's dependency surface, unrelated to the printable-judging story
C is remembered for.

**B → C.** *Solved:* case 1/2's core defect — printable judging now works
under desktop ordering (§0), evidenced directly by `3a9d48c`'s commit
message and the `spendGlyph`/`GLYPH_CLAIMED` trace in Part 1. This is the
single largest functional change across the whole A→D span: it goes from "no
target is ever accepted" to "targets are accepted, order-independently."
*Created:* nothing new — case 4's hole (own-glyph-after-own-release) and
case 6's hole (chord-modifier-released-early) are both *carried forward*
unchanged from A, not introduced. C's own successor doc (`keyboard.md`'s
"shipped code, for contrast" section) names both as remaining gaps.

**C → D.** *Solved (as claimed):* case 7, unifying two judging paths into
one — real, though contingent on resolving the `seenText` contradiction
(earlier review §1) and only partially exercised (two of six rules do no
work on the injected non-printing branch, Part 3 row 7). *Claimed but not
actually solved:* the "shipped code, for contrast" section
(`keyboard.md:145-153`) lists two further shortcomings of C that D
"supersedes" — and neither claim survives inspection (Part 5, first two
bullets). *Created:* the `seenText` double-duty contradiction (earlier
review §1); the acceptance-gate's synchronous reopen defeating case 9 —
a case C is structurally immune to and D is not (Part 3, row 9); and a
5×-wider version of case 8's false-drop window than C already carries.

---

## 5. The accretion question, with evidence

For each of D's moving parts beyond the implicit, two-guard mechanism A/B/C
already run, here is the case that earns it — or the absence of one.

- **`seenText` (core duty: `text == seenText` stop, rule 3).** EARNED.
  Case 2 (held key, OS repeats) needs *some* order-independent hold marker;
  `seenText` is the direct structural analogue of C's `GLYPH_CLAIMED` and
  does the same job with the same cost (one field). Not accretion.

- **`seenText` (second duty: rule 4's "value at release" comparison).** NOT
  EARNED, as written. No case in this matrix is protected by this duty: per
  the earlier review §1, the comparison term names data `keyreleased`'s own
  clear step has already destroyed, so rule 4 as literally specified can
  never fire for the case it exists to cover (case 4/9). This is the same
  field asked to do a second job it structurally cannot do without an
  undeclared fifth field.

- **`judgedText`.** EARNED, narrowly. Case 8 (deliberate re-press of an
  already-judged wrong character against a still-live target) is where rule
  6's dedupe fires, confirmed by the earlier review §2. Its practical bite is
  thin — `gauge.lua`'s own `fumbled` flag already makes a repeated wrong key
  a no-op at the gauge layer regardless — but the case exists and the field
  is not idle.

- **`releasedAt`.** NOT EARNED. It exists to feed rule 4 alone, and rule 4 is
  inert as specified (above). No case in the matrix is currently protected
  by `releasedAt`. This is a field with **no equivalent in C** (C's grace
  check uses `upRecent`, a table already present since A for a different,
  working purpose) — D adds it, and it does nothing.

- **`accepting`.** NOT EARNED. Intended for case 9 (post-hit bleed
  protection), but the earlier review §4 traces `gaugeOnCorrect` →
  `gaugeNext` as one synchronous call (`gauge.lua:188-198`, unchanged since
  A) that reopens `accepting` before any later event is ever dispatched — no
  `textinput` can ever observe `accepting == false`. This is also a field
  with **no equivalent in C**, and it is the field whose absence in C turns
  out not to matter: C is immune to case 9 by construction (its suppression
  never consults which target is current), not by an accepting-style gate.

  **The two state fields D carries that C does not (`releasedAt`,
  `accepting`) are precisely the two the evidence shows do no protective
  work as written.** `seenText` and `judgedText`, D's other two fields, both
  have direct, working, cheaper analogues already present in C
  (`GLYPH_CLAIMED`, and gauge's own `fumbled`, respectively).

- **`TEXT_TAIL_FRAMES`.** NOT EARNED as written (gates unreachable rule 4).
  Even under the most charitable repair (add the undeclared fifth field so
  rule 4 becomes computable), its stated value — "5 at 60 fps, a starting
  value" — is unmeasured and, per case 8, is a strictly worse tradeoff than
  C's existing `INPUT_UP_GRACE = 1`: it is the same kind of grace window,
  five times wider, with no case in this matrix demonstrating the extra
  width is needed and one case (8) demonstrating it actively costs more.

- **Six-rule explicit ordering.** Rules 1 (Caps), 2 (chord/modifier guard),
  3 (hold suppression), and 6 (dedupe) each map to a concrete, currently
  broken-or-fragile-in-A/B/C case (Caps estimation needs *some* live
  reconciliation since LÖVE 11.5 has no query API, per the earlier review
  §5; chord dropping is case 5; hold suppression is case 2; dedupe is case
  8-wrong-key). Rules 4 and 5 — a third of the design's headline six-rule
  structure — are the two shown above to do no protective work as written.

- **One judging path instead of two.** EARNED, modestly, for case 7 — real
  code-structure simplification, the one part of D's added machinery that is
  clearly bought by a concrete, present-day duplication (`altTextinput` vs.
  `altPlayKey` in A/B/C today). Contingent on the `seenText` contradiction
  being resolved first.

**A second, independent finding, found in the course of this comparison, not
carried over from the earlier review:** D's own "shipped code, for contrast"
section (`keyboard.md:145-153`) directly contradicts D's own Concerns
section (`keyboard.md:127-131`) about one of the three things it claims to
fix. The contrast section lists *"a chord whose modifiers are released while
its base key is still held can slip one character through"*
(`keyboard.md:151-152`) as a shortcoming of the shipped code, then says
*"the design above supersedes it"* (`keyboard.md:152-153`). But the
Concerns section, twenty lines earlier in the same document, says of the
identical scenario: *"If a chord's modifiers are released before its
character arrives, the guard does not fire and that character is judged...
This is the same family as the original defect and is **the one live-state
read left in the path**"* (`keyboard.md:127-131`) — an explicit admission
the defect remains. Case 6 in this matrix confirms the Concerns section is
the accurate one: D reproduces this exact slip. The contrast section
overstates D's coverage against its own later text.

The contrast section's *other* claimed advantage — *"judgement still
depends on a release arriving"* (`keyboard.md:149-150`) as a shortcoming
unique to C's `spendGlyph`/`keyreleased` — also does not hold up: rule 3's
`seenText` clearing is driven by the identical event
(`keyboard.md:33`, "clear `seenText` when the released key produced it"),
so if a key's `keyreleased` never arrives, `seenText` is never cleared and
that key's text is suppressed forever after its first judgement — the same
wedge symptom C has, via a different field. Of the three shortcomings D's
own document claims to fix relative to C, only one (the two-path
duplication) is actually earned.

---

## Closing answers

**1. Is D conceptually better or worse than A, and by which criterion?**
Better than A, by the criterion "closer to the platform's actual
guarantees": A's suppression mechanism assumes a fixed channel order that
LÖVE does not provide, and is comprehensively broken — not marginally — the
moment that assumption fails (§0, case 1/2). D's core mechanism (state-based
text matching, not a live held-key read) does not make that assumption.
But this is not a point in D's favor *specifically* — C already has the
identical property, with two pieces of state and one constant instead of
five and one, and no rule ordering to reason about. Measured against C, the
version that actually matters (it is what ships), D is worse by two stated
criteria: **more moving parts for the same guarantee** (Part 2), and **more
failure modes**, not fewer — it reopens case 9 (a bleed C is immune to), and
widens case 8's hazard 5×, in exchange for fixing case 7 alone.

**2. Which of D's moving parts are earned by a real case, and which are
accretion?** Earned: `seenText`'s core hold-suppression duty (case 2),
`judgedText` (case 8-wrong-key, narrowly), rules 1/2/3/6, and the
single-path unification (case 7, contingent on a fix). Accretion, with no
case in this matrix protected by them as written: `releasedAt`, `accepting`,
`TEXT_TAIL_FRAMES`, rule 4, rule 5, and `seenText`'s second (rule-4) duty.
Notably, the two state fields D adds that have no analogue in C at all —
`releasedAt` and `accepting` — are exactly the two found to do no protective
work.

**3. The simplest rule that handles every case in the matrix, and what
defeats it.** *Claim one glyph per physical key-press (drop repeats and
anything already claimed); release the claim at keyup; also drop anything
arriving within a short grace window after that keyup.* This is, in shape,
what C already does, and it is genuinely the minimum needed to pass every
case in this matrix except one: **case 4** — a genuine fast tap whose own
`textinput` is delayed past its own `keyreleased` and happens to land inside
the grace window is, by this rule's own logic, indistinguishable from a
trailing repeat, and gets wrongly dropped. This is confirmed present, today,
unchanged, in A, B, and C. It is also, tellingly, the exact case D's rule 4
was written to solve — and, per the earlier review §1 and this review's
Part 3 row 4, D fails to solve it too (dodging only the bare, isolated
instance, by accident of rule ordering, not by the mechanism credited). That
convergence is itself evidence: case 4 is a genuinely hard boundary of the
problem, not a case anyone has been neglecting. D's other machinery —
`releasedAt`, `accepting`, the wider tail window — is not aimed at this hard
case at all; it is aimed at case 9, a case the simplest rule (and C) already
passes for free, by never coupling suppression to which target is current.

---

## State at close

```
$ git status --porcelain   (main repo)
?? claude.sh
?? doc/development/wip/77-new-input-api/validation/prompts/S29-p9b-design-vs-original-agent.md
?? doc/development/wip/clarification/
?? doc/development/wip/personal-notes/
?? doc/development/wip/pull-26/
?? doc/tall_blocks.md
?? input-pr-slices.tar.gz
?? src/STEPS.md
?? src/examples/balloons/
?? src/examples/keyboard/
?? src/examples/maze/

$ git diff --stat   (main repo)
(empty)

$ git -C src/examples/keyboard status --porcelain
(empty — clean, HEAD 3a9d48c, untouched)

$ git -C src/examples/keyboard diff --stat
(empty)
```

All untracked entries in the main repo are pre-existing owner scratch plus
this session's prompt file and this deliverable. No write command of any
kind was run inside `src/examples/keyboard`; all history reads used
`git show`/`git log`/`git diff` (no ref arguments), never `checkout`,
`reset`, `stash`, or a branch switch.
