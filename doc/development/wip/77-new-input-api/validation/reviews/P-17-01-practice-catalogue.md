---
description: Catalogue of practices established elsewhere in the sprint, for reference during maze
status: active
audience: developer
authored: llm
reviewed: none
---

# P-17-01 — a practice catalogue, for maze to consult or ignore

**Written:** 2026-08-12, session39, by a worker under `../prompts/P-17-01-practice-catalogue.md`.

**What this is, in the owner's own words:** a catalogue of practices that *"may be used for maze…
or not."* It does not analyse `maze` and was written without reading either
`S39-maze-upstream-input-assessment.md` or `P-17-00-shape-and-plan.md`. It extracts what was
learned elsewhere in the sprint and the shape of code each lesson applies to.

**Sources.** Four commits in `src/examples/maze` (`newinput`, read via `git -C src/examples/maze
show <sha>`, not checked out): `790ac19`, `d2ce7a0`, `aeabb73`, `a045fdb`. The keyboard deepfix's
design and triage documents and five cold reviews, all in this directory.
`doc/development/conventions/input_adoption.md`, cited by question number only.

---

## 1. Owner rulings that generalise

### 1.1 The game's rules are not ours

`P-18-00-keyboard-deepfix-design.md` §1.1, owner, 2026-08-11. **Shape:** a proposed change framed
as "a better fit for the platform." **Ruling, binding:** *"We are never changing game rules… What
we do is tweaking the implementation."* Test: would a player notice? If yes, out of scope. Two
proposals were withdrawn under this in §1.1 alone, recorded so their absence would not be a
mystery. Precedent cited: `sapper`'s mechanically faithful conversion destroyed the feature's
purpose and was reverted — *purpose beats shape*, *ask the author*.

### 1.2 Do not rely on an order the library does not guarantee

`P-18-00-keyboard-deepfix-design.md` §1.2, owner. **Shape:** an accept/reject decision correct
only under one relative order of two events, where the platform promises none. **Ruling,
binding:** *"relying on the order the library does not guarantee is wrong anyway — any release of
LÖVE2D could break both games, irrecoverably."* Governs the mechanism, not the platform's current
behaviour; an unsourced sentence in a design document asserting a specific order was struck, not
corrected.

### 1.3 A deviation lives in the workspace, not only in a commit message

`input_adoption.md`, "Rules of restraint." **Shape:** a migration changes behaviour and only the
commit message says so. **Rule, binding:** *"A commit message is not part of what a reader has
open."* Maze already follows this — `790ac19` states its open question in the code comment itself,
and `d2ce7a0` resolves it there too.

### 1.4 Focus loss and a repeatable inconvenience are not automatic defects

`P-18-00-triage-and-plan.md` §0(a)-(b), owner, 2026-08-12. **Shape:** state strandable by a lost
`love.focus`/`keyreleased`, or a gesture needing one repeat to recover. **Ruling, binding:** *"Many
examples tolerate this risk. If the said risk is the only reason for some change, I'd rather not
enforce the change — just leave a comment with a warning."* [S39: the quotation is restored in full;
the catalogue's first draft cut it before *"just leave a comment with a warning"*, which is the
operative half — the ruling does not say "do nothing", it says "comment instead".] Calibration (b),
*a risk cleared by repeating the chord is an inconvenience, not a harmful degradation*, is the
triage's own heading rather than a quotation. This
downgraded one planned conversion to a comment, and forced a second, correct, change to be
re-grounded on its real reason once the focus-loss justification was disallowed for it.

### 1.5 No comment in an example repository may cite a platform document

`P-18-00-triage-and-plan.md` §9 ruling 1 (now `agents/rules/commenting.md`, "Citations").
**Shape:** a comment in `src/examples/*` pointing at `doc/…`, a decision number, or a Beads id.
**Ruling, binding — the owner's own words:** *"No comment should link to platform docs, it's a
violation of integrity (different repo)."* [S39: the catalogue's first draft quoted *"shipping one
into a third party's tree is an integrity violation"* and attributed it to the owner; that sentence
is the **triage's** prose (§9), not theirs. The ruling is unchanged; the attribution was wrong, and
an assistant's paraphrase promoted to an owner quotation is how a ruling drifts.] Cost a dedicated
sweep removing eight such citations, all introduced by the branch; the author's own `docs/…`
references were left alone — that distinction is the rule.

### 1.6 Adoption is the point — but renaming for nothing is not a virtue

`P-18-00-triage-and-plan.md` §10, owner — supersedes an earlier ruling in the same document.
**Shape:** a remaining `love.*` call, weighed against its `compy.*` equivalent. **Ruling, binding:**
*"merely renaming all function calls… would be a migration without gain. But artificial preserving
of old syntax where replacement is justified also makes no sense."* Test: is the replacement
justified on its own terms? This overturned a prior "minimise the change" ruling once its premise
(the game runs standalone) turned out false.

### 1.7 A narrowing is a change: say it, or do not do it

`input_adoption.md`, "Rules of restraint"; independently re-learned four times (§3.5 below).
**Shape:** a hand-matched conditional tolerant of an extra modifier, converted to a combo-string
registration that matches its modifier set exactly. **Rule, binding.** Every recorded instance was
eventually fixed by binding every tolerated variant — never by silently accepting the narrower
behaviour.

### 1.8 A reviewer's own `REMARK:` is reviewed, not swept

`P-18-00-triage-and-plan.md` §9 ruling 2; example in maze's `aeabb73` (owner's review commit, two
markers). **Shape:** a `---> REMARK:` line left by a human reviewer, later met by a worker sweeping
the same file. **Ruling, binding:** resolved → removed with the answer folded in; unresolved →
escalated, never deleted for convenience. **Cost when missed:** one such marker shipped and stayed
unresolved through a whole revalidation pass before a later step answered it from code.

### 1.9 Purpose beats shape; ask before converting an antipattern-shaped thing

`input_adoption.md`, "Rules of restraint"; the `sapper` precedent again. **Shape:** code matching
a known antipattern (a hand-rolled cascade, a mirrored flag) that may exist for an unwritten
reason — a touch-device fallback, a deliberate demonstration of a `love.*` path. **Rule:** *"Code
that demonstrates a path is not a candidate for converting off it."*

---

## 2. Mechanism practices

### 2.1 Claim-on-delivery, release-by-device-poll — one accept per physical press

`P-18-00-keyboard-deepfix-design.md` §9.3-§9.6, §9.5g; landed as `spendGlyph`/`GLYPH_CLAIMED`/
`inputTick`. **Shape:** code accepting exactly one content-only event (`love.textinput`) per
physical key press, with no repeat flag on that channel and an unreliable keypress/keyreleased
pair. **Assistant finding, adopted:** a table keyed by the inferred physical key; first event
registers it, later ones no-op, cleared **only** by a per-frame device poll — never trusted to
`love.keyreleased` alone. **Cost when a related claim was wrong:** the design document itself
wrongly asserted the poll "rescues" an un-nameable key; it crashes instead (§2.5).

### 2.2 Immediate decisions cannot be both order-free and loss-tolerant

`P-18-00-keyboard-deepfix-design.md` §9.2. **Shape:** any design answering "first char of a press,
or a repeat?" from event history alone, at arrival time. **Finding:** under one delivery order plus
a missing release, a repeat of press N and the first character of press N+1 have *identical*
histories, yet need opposite decisions — no function of history can serve both. **Consequence:**
the decision must defer to a later poll of the device; this is why event-only schemes (armed
gates, generation tags, timestamp windows, §9.5d) cannot close the gap.

### 2.3 A consumer that swallows a key on the press channel must claim it on the content channel too

`S37-P18-revalidation.md` F2; `S38-P18-final-revalidation.md` D1. **Shape:** a shortcut or scene
transition intercepting `love.keypressed`, where the same press still produces a trailing
`love.textinput`. **Finding, adopted as a rule ("a chord owns its trigger key"):** the consumer
must also take §2.1's claim on that key. **Cost:** missed at first landing for every consumer but
one, with a commit message wrongly calling the gap "pre-existing" when it was a regression; found
again, independently, for a menu-digit scene transition.

### 2.4 A combo string matches its modifier set exactly

`input_adoption.md` Q10; recurred at triage §5 RULE 1, `S37` F3, `S38` D2, `S38-…-2` F1 — the
same defect four times across three passes. **Shape:** `if k=="p" and alt and not ctrl` (silently
tolerant of Shift), converted to `compy.input.shortcuts`. **Finding:** every tolerated modifier
combination needs its own registration; a class key (`'alt+*'`) does not mean "this modifier,
optionally with others." **Cost:** four misses against one six-gesture family before an exhaustive
385-stimulus parity harness against upstream finally proved a zero diff — hand enumeration by
reading missed one member each time.

### 2.5 A device poll can raise, not just answer false, on a name it does not recognise

`S37-P18-revalidation.md` F1, measured in real LÖVE 11.5. **Shape:** code inferring a "key name"
from event *content* (typed character, IME/dead-key symbol) and polling the device with it.
**Finding:** `love.keyboard.isDown` raises on a non-KeyConstant string. **Cost:** a design document
asserted the opposite; the claim reached shipped code and one keystroke crashed the running game
past its own `pcall`. **Fix adopted:** never poll a name that has not passed a memoised `pcall`
gate; an unpollable name is never claimed, so its repeat is accepted rather than crashing.

### 2.6 Clear a claim by device poll, not by the release event

`P-18-00-keyboard-deepfix-design.md` §9.5g. **Shape:** the §2.1 claim table, clearable either on
`love.keyreleased` or by a per-frame poll. **Finding:** they are not equivalent — a release
followed by a trailing repeat in the *same* event batch meets a claim already cleared on release,
and is accepted as a phantom character. Clearing only in the poll (after the batch drains) has no
such hole; its only cost is a release-then-re-press *inside* one batch (~16ms) losing the second
character. **Decided:** poll only, no release handler in the judgement path.

### 2.7 Where the per-frame poll must run

`P-18-00-triage-and-plan.md` §2, correcting the design document's own placement. **Shape:** the
§2.1 poll, sequenced against a game loop with early returns for `PAUSED` or an overlay.
**Decided:** the poll must run ahead of any such return — the state that gates the step (an
overlay held by a chord) is exactly the state whose trigger key needs releasing while the gate is
active. Placed
behind the gate, a claim outlives its key for as long as the overlay is held.

### 2.8 `love.textinput` carries no repeat flag, in any version

`P-18-00-keyboard-deepfix-design.md` §2.3, quoting the upstream author's own header. **Shape:** a
`love.textinput` consumer needing to know fresh-press vs. OS repeat. **Finding:** the
content-channel structurally cannot carry a repeat flag — a character is content, not a key event.
Delivering `isrepeat` on the keypress channel retires every keypress-side workaround; it does
nothing for textinput, which is why §2.1's mechanism is separate work, not a migration side effect.

### 2.9 Ask the framework's own state query; an internal field is invisible from a project

`src/examples/maze` `790ac19`. **Shape:** a per-tick guard reading a framework-internal field (e.g.
`love.state.user_input`) from project code. **Finding:** a project runs in a sandboxed copy of
`love`, so such a field is always `nil` from inside it — the guard never fires, silently. **Fix:**
call the framework's exposed answer (`compy.input.is_shown()`) instead.

### 2.10 Verify a "closing" call's current semantics before building deferral machinery around it

`src/examples/maze` `790ac19` → `d2ce7a0`. **Shape:** a prompt needing to re-show itself with
preserved text after a rejected submit, where calling `show()` from inside the submit callback
does not work because the callback still holds the overlay open. `790ac19` carried the text one
tick forward and reissued `show()` next update, reasoning stated in the code comment (§1.3).
`d2ce7a0`, reading the platform's `submit_flow` directly, found the current `show()`/submit neither
closes the overlay nor clears the field — so the deferral machinery was dead weight, confirmed
against source rather than assumed. **Lesson:** a workaround built for a prior version's semantics,
carried unverified, is the risk.

### 2.11 Continuous "is this held" state is a poll, not a hand-rolled fold

`input_adoption.md` Q1/Q2/Q5; `src/examples/maze` `a045fdb`; design doc §9.5i (`helpHeld`,
Decision 32). **Shape:** a local helper OR-ing two named keys (`is_shift_down()`) standing in for
"is this modifier held." **Decided:** replace with the platform's folded accessor (`Key.shift()`).
`a045fdb` does exactly this, and explicitly separates the fix from a "top rung" (a real combo
replacing the surrounding hand-match) — filed for later rather than guessed at "blind in a repo
with no suite."

---

## 3. Process traps

### 3.1 A count is carried by citation, not recomputed, and goes stale

`S38-P18-narrow-review.md` F1 (a stimulus count of "105" vs. the actual "108," carried into three
documents and two commit messages), O2 (a registration count already stale on arrival), and its
note that a plan's "thirteen" outstanding rows was stale against the checklist's own "eighteen."
**Fix:** recompute a count from the artifact it describes; do not copy it from wherever it was
last stated.

### 3.2 A worker's report can describe a diff the parent later changed

`S38-P18-narrow-review.md` F2. **Shape:** a delegated worker's outcome record quotes code exactly
as written; the parent edits that code before committing (moving a comment to a better file)
without updating the record. **Cost:** the record and the tree disagreed with nothing reconciling
them. **Fix:** when a parent edits a delegated diff, update the outcome record too.

### 3.3 A comment and the document it cites as authority must be corrected together

`S37-P18-revalidation.md` F4. **Shape:** a comment states a now-false reason and points at a
persistent design document for the fuller account — which independently states the same false
reason. **Cost:** fixing the comment alone would leave the cited document corroborating the error
for the next reader who checks it. Both must move together.

### 3.4 An unmeasured claim about library behaviour propagates and gets expensive

`P-18-00-triage-and-plan.md` §7-§8. Three attested instances: an unsourced claim about event
delivery order in the design of record (struck rather than corrected); the design document's wrong
claim that a poll "rescues" an unpollable name — reached shipped code, crashed the game (§2.5); a
debt entry naming a `setKeyRepeat(false)` call inside `examples/keyboard` that never existed
there, per a full-history grep. **Stated in the record itself:** *"Measuring took one throwaway
LÖVE script and 20 seconds."* Every cold review here tags each claim **measured** or **reasoned**
for this reason.

### 3.5 An enumeration that reads as exhaustive is not verified until measured against the full space

The same recurrence as §2.4, read as a process failure: a restoration comment that "reads as an
exhaustive account" missed a fourth family member; the next pass missed a fifth; the pass after
that missed a sixth. **Cost:** three successive cold reviews, each confident, each missing one
more — until enumeration-by-reading was replaced by an exhaustive synthetic-stimulus harness that
could prove a zero diff instead of asserting one. **Fix:** treat a hand enumeration as a
hypothesis, not a proof, once the space is small enough to enumerate mechanically.

---

## What this catalogue does NOT establish

Practices specific to `keyboard`'s shape, not to be carried into `maze` by analogy:

- **The glyph-claim/per-frame-poll mechanism** (§2.1, §2.6-§2.8) solves "judge every
  `love.textinput` character against a live on-screen target, once per press." `maze`'s editor
  prompt, per the four commits read here, is submit-based — it reads a whole string once on
  submission, not character by character. The mechanism's *problem* likely does not exist there;
  do not import its *solution* looking for one.
- **"A chord owns its trigger key" and the reserved-chord/modifier-class apparatus** (§2.3-§2.4)
  answer to `keyboard` having many scene-local judges behind a handful of global chords. Nothing
  in the four maze commits shows a comparable chord surface; the general warning about combo
  strings (§2.4) is worth carrying, the specific gesture family and its count are not.
- **The "one target, one keystroke" precondition** (design doc §7, the `"all"` doubled-letter
  case) is a property of per-character judgement against a string target, with no obvious
  analogue in a line-editor prompt.
- **`helpHeld`, `bubble.lua`'s hold-timeout judge, and Caps Lock reconciliation** are each specific
  to their own minigame's shape. `maze`'s idle-gated prompt (`d2ce7a0`) — an overlay synced to a
  domain predicate each tick — is closer in spirit to §2.1's poll discipline than to any of these
  three, but is not the same mechanism as any of them.
- **The scale of the parity-harness methodology** (105/108/385 synthetic stimuli against upstream)
  matched `keyboard` inheriting a rich reserved-chord system needing byte-for-byte preservation.
  The discipline — measure a library claim before believing it — carries over; the instrument's
  scale does not.
