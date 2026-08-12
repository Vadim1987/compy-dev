# S38 — narrow review of the third pass's corrections (`1033252..f09f1e7`, `a05a3829..HEAD`)

**Verdict: the batch discharges the third pass's findings, and the parity closure is sound.**
Every finding got a disposition I would defend; the one behavioural change is correct and I
**measured** it — the gesture-parity diff against upstream is **zero**, over the previous pass's
own stimulus set *and* over a widened one I built (385 stimuli, including right-hand and mixed
left/right modifier holds), fresh presses and OS repeats alike. **No defect found in this batch.**
The findings below are five observations, all documentation or wording, none reachable by a player.

**Written:** 2026-08-12, cold, read-only. Object of review: `git -C src/examples/keyboard diff
1033252..f09f1e7` (commits `80bca7b`, `f09f1e7`) and, in `/repo`, `a05a3829..HEAD` restricted to
`smoke_checklists.md`, `technical_debt/input.md`, and the step's plan/prompt/outcome files. No file
in any repository was edited, committed, staged or otherwise touched; this document is the only
artifact, and the only thing I wrote outside it are throwaway harness scripts in the scratchpad.

---

## Instruments

The previous pass's harness, reused and re-run from
`/tmp/claude-1000/-repo/6f512c55-e690-4ef3-9962-d6ea3490f5cb/scratchpad/`:

1. **Instrument integrity first.** `up_input.lua` is byte-identical to `git show 025e858:input.lua`
   — verified by `diff`, before trusting a single row it produces.
2. **`run_new.lua` / `run_up.lua`** — the live `/repo/src/examples/keyboard/input.lua` driven by the
   real `ProjectInputController` / real `Key`, against upstream's unmodified `input.lua`.
3. **Three instruments of my own**, because two claims in the batch were asserted rather than shown:
   - `rv_up_rep.lua` — an **upstream** repeat driver (upstream has no `isrepeat`; a repeat is a
     second `appKeypressed` with the key already in `INPUT.held`). The previous pass measured the new
     side's repeats and *reasoned* the upstream side; this diffs them.
   - `rv_run_pre.lua` — the same sweep against `1033252:input.lua`, to confirm the three deltas
     existed at the pre-fix head and that `80bca7b` is what closed them.
   - `rv_wide_new.lua` / `rv_wide_up.lua` — a widened stimulus space: 16 modifier holds (each
     generic subset in all-left, all-right, and one mixed l/r variant) × 22 triggers, including
     `rshift` / `rctrl` / `ralt` as triggers. **385 stimuli.** The fixed harness never held a
     right-hand modifier, and the new condition is exactly where an l/r fold error would surface.
4. **Load check in the real IDE**, from `/repo`:
   `timeout 25 xvfb-run -a stdbuf -oL -eL love src play src/examples/keyboard` → *"Project play
   opened"*, *"Running 'play'"*, killed by the timeout, **no `Error:` line**.
5. **`lua-lsp`** for `glyphBaseKey`'s callers and for diagnostics on the changed `input.lua`.

Findings are marked **measured** or **reasoned**.

---

## 1. Item by item, judged from the tree and not from the commit messages

| finding | disposition | how judged |
|---|---|---|
| **D1** `wordsBaseKey`'s comment denies the `SHIFT_MAP` branch | **fixed** | `words.lua:144-146` now reads *"space for a space, a letter's lowercase key, a shifted symbol's unshifted key, else the glyph itself"* — the four branches of `glyphBaseKey` (`input.lua:135-140`), in a different but immaterial order (a letter is never a `SHIFT_MAP` value, so the branches are disjoint). The fix is in place rather than by deleting the alias, and that is the **right** call, not the lazy one: `git show 025e858:words.lua:144-150` shows the comment was **true of upstream's own three-branch body**, and upstream's sibling `altBaseKey` (`alt.lua:57-60`, unchanged) already describes the symbol branch. Per-caller comments are the author's convention; correcting one in place is the smaller deviation |
| **O1** three bare-modifier parity deltas | **closed, not documented** — addressed differently, and I judge the closure correct | `input.lua:208` replaces the unconditional bare-Alt guard. **Measured**: 3 delta rows at `1033252`, **0** at `f09f1e7`, and 0 across my widened 385. See §2 |
| **O2** debt entry says eleven registrations | **fixed** | `technical_debt/input.md:1506, 1516` now say **twelve**. Counted independently: twelve `sc[…] = …` assignments at `input.lua:69-89`, and they are exactly six tolerant gestures × 2, so the entry's *"six … and pays twelve"* is now internally consistent |
| **O3(b)** no smoke row for `Ctrl+Alt+H` in a non-teaching scene | **fixed** | `smoke_checklists.md:108`, row `D10`, marked `[new]` and added to the enumeration at `:134`. **Measured** that it tests the accepted deviation and not a tautology: in a scene with no `onHint`, upstream delivers `scene.keypressed h` (a wrong-key knock in games 1 and 6); this head delivers **nothing at all**. `alt.lua` is the only file defining `onHint`, so "game 1 or 6" is correct |
| **O4** `bubble.lua` ships review dialogue | **fixed** | Eight lines → five (`bubble.lua:152-156`). The caution the pass wanted kept is verbatim; the five-line argument is one clause, *"a chosen channel, not a platform limit"*. The full argument survives where the pass said it belonged, `internals/examples/keyboard.md:175-181`. *"The one judge in the game that keys on the release EVENT"* is **verified true** — `bubble.lua:263` is the only `keyreleased` in any scene descriptor |
| **O5** `main.lua`'s trailing comment repeats its header | **fixed, and moved** | The trailing block is gone; `main.lua:1-5` still carries the pointer once. The one non-duplicate claim moved into `input.lua:3-7`. Judged separately below |
| **O6a** ragged wrap at `input.lua:11` | **fixed** | The paragraph is re-wrapped at 58-64 columns with no short interior line (measured widths: 63/63/64/62/62/60/37). No line over 64 in any file this branch touched; the tree's only 65-column line is `scene.lua:16`, upstream's own and untouched |
| **O6b** the `setTextInput` rationale contradicts itself | **fixed** | `input.lua:10-13` is one statement now. Both halves verified in source: `src/main.lua:296` calls `setTextInput(true)` unconditionally at IDE boot, under *"Android specific settings"*. One residual wording nit — finding 4 |
| **O6c** `GLYPH_CLAIMED` initialised twice | **not addressed** | Still both `input.lua:94` and `input.lua:124`. It was outside the delegated prompt, the pass called it harmless, and it is. Recording it so the next reader does not re-find it |

**On the moved edit specifically (`O5`).** The worker left a two-line comment in `main.lua`; the
parent deleted it and folded the claim into `input.lua:4-5` — *"the framework captures `love.*` into
the same hooks, so this only says it out loud"*. I judge the move **right on all three axes**:

- **True.** Verified in source, not inferred: `seed_hooks` (`projectInputController.lua:65-71`)
  copies each `love.*` handler into `hooks[event]` at activation for every event the project did not
  set explicitly. The game defines no `love.keypressed` / `textinput` / `keyreleased` at all
  (grepped: only `love.update` and `love.draw` remain in `main.lua`), so *"instead of `love.*`
  handlers"* is exact and the captured-anyway claim is a true counterfactual.
- **Correctly placed.** A trailing comment at end of file, below `love.draw`, about keyboard
  registration, is not where a reader looks; `input.lua`'s header is where the registration choice is
  described, and `main.lua`'s own header already points there.
- **Rules-clean.** The dropped clause (*"only drops three wrappers that existed to satisfy LÖVE's
  naming convention"*) is history narration, correctly not carried; the surviving clause cites no
  platform doc and no decision number, which the citation ban requires inside this repository.

It is admissible under *"say what the code does not do"* only because a reader could plausibly
conclude `love.*` handlers are forbidden here — which, faced with a migration patch that deletes
three of them, is exactly what a reader would conclude. It earns its clause.

---

## 2. Did closing the parity deltas introduce anything?

**Measured, three ways, all zero.**

| sweep | stimuli | result |
|---|---|---|
| the previous pass's set, fresh presses, `f09f1e7` vs `025e858` | 108 | **0 differences** |
| the same set as OS repeats, vs an upstream repeat driver I wrote | 108 | **0 differences** |
| my widened set (l/r and mixed holds, l/r triggers), fresh presses | 385 | **0 differences** |
| the same set at the **pre-fix** head `1033252` | 108 | **3 differences** — the exact rows the third pass reported |

The repeat sweep is the one the previous pass did not have: it measured the new side's repeats and
*reasoned* that they matched upstream's `capslock` exemption. They do, and now it is measured — the
only stimulus producing any effect on a repeat is `capslock` (`capsToggle` + the scene keypress),
and only when Alt is not held without Ctrl, in **both** trees, including the quirk that `Alt+CapsLock`
toggles nothing at all because the `alt+*` class takes it before `capsToggle` runs. That is upstream's
behaviour, preserved, not this work's.

**Is parity the right target here?** Yes, under the owner's standing ruling — the game's rules are not
ours, and *"would a player notice a difference?"* is the test. Two things are worth saying anyway:

- The condition now encodes an **upstream accident**, not a designed rule. The reason `Ctrl`-held +
  `Alt`-pressed reaches the scene is that upstream's `appChord` bailed out early on Ctrl
  (`025e858:input.lua:103`), not that anyone wanted a bare `lalt` to finish the intro typewriter. The
  branch is now bound to reproduce it. That is the correct outcome under the ruling, and the cost is
  one condition — but the code reads as though the behaviour were derived, and it is not.
- The change **shrinks** the surface it guards rather than growing it. Before: every Alt key press
  swallowed by name. After: only a modifier's own press, only while Alt is held without Ctrl. I
  checked the claim that nothing else needs the guard: with Alt held and no Ctrl, every non-modifier
  trigger is caught ahead of the hook by `alt+*` / `alt+shift+*` or by an exact binding that wins over
  them, and `find_shortcut` refuses a modifier trigger (`projectInputController.lua:110`,
  `key.lua:147-149`). So `Key.is_mod(k)` is exactly the residue, as the comment claims.

**Does it do anything a reader would not predict?** Almost nothing, and I looked at the four cases
asked for plus two more:

- **a modifier pressed while Alt is held** → dropped, including `Alt` on `Alt` (l/r mixed: hold
  `ralt`, press `lalt` → dropped). Matches upstream. Measured in the wide sweep.
- **Ctrl+Alt combinations** → every modifier press passes to the scene, `Ctrl`-then-`Alt` and
  `Ctrl+Shift`-then-`Alt` included. Matches upstream. Measured.
- **the capslock exemption** → untouched; `capslock` is not in `Key.is_mod`'s set. Measured, fresh
  and repeat.
- **OS repeats** → the guard is unreachable on a repeat; `input.lua:192` returns first for everything
  but `capslock`, and `capslock` is not a modifier. Measured.
- `PAUSED` / help-overlay ordering is unchanged relative to the guard, and `appKeyreleased` was never
  guarded — in either tree, so releases still reach scenes identically.
- One coupling is genuinely new — finding 4 below.

`lua-lsp` reports **no diagnostics** for the changed `input.lua`.

---

## 3. Are the comment edits sound?

Yes, in both directions. Nothing that remains is false — I checked every surviving claim against
source rather than against the commit message: the `seed_hooks` capture, `src/main.lua:296`'s
`setTextInput`, `bubble.lua` being the only release judge, `glyphBaseKey`'s four branches, and
`intro.lua`'s asymmetry note, which the closure has made true **without** the qualifier the third pass
asked for (a lone Shift still skips, a lone Alt still does not — measured, rows 4 and 43 of the sweep).

**Nothing a maintainer needs was cut.** The three deletions were: an argument addressed to a reviewer
(kept as a clause, and preserved in full in the platform's design of record); a history sentence about
three deleted wrappers (git holds it, and the rules forbid it); and a self-contradicting half-sentence
(replaced, not dropped). The `words.lua` edit removes nothing.

**The one thing I would have kept an eye on**, and it survived: the `bubble.lua` caution about a
release lost to focus. It is verbatim, and it is still the only place in the game that says it.

---

## Findings

No defects. Five observations, ordered by severity. None is reachable by a player; all are
documentation or wording.

### F1 — the stimulus count in the smoke checklist is wrong: it is 108, not 105 *(measured)*

`doc/development/smoke_checklists.md:37-38` — *"the gesture-parity diff against upstream is zero
across **105** fresh-press stimuli and **105** repeats"*. The harness enumerates 8 modifier subsets ×
15 triggers = 120, minus 12 self-presses = **108**, and prints 108 lines. I counted the output of both
runners: 108 and 108. The same number appears in the plan addendum
(`reviews/P-18-00-triage-and-plan.md`, §11, where it is even shown as *"8 modifier subsets × 15
triggers"*, which cannot be 105) and in both commit messages, and it originates in the third pass's
own report — so this batch carried it rather than coining it.

**The substantive claim is true and understated**: the diff is zero over 108, and over the 385 I ran.
Worth one word only because this is the human-facing gate document, and because the batch's own `O2`
existed to fix a wrong count in a document. Same class of error, same session.

While there: the plan addendum's closing line says the human owes *"thirteen `[new]` rows"*. The
checklist marks **18** and enumerates **17** (`E3` is deliberately listed apart as a question rather
than a test). The enumeration itself is complete and correct — it is the plan's tally that is stale.

### F2 — the outcome record describes a `main.lua` comment that does not exist at this head *(measured)*

`validation/outcomes/P-18-20-tidy.md:76-78` quotes, as delivered:

```
-- love.* globals would work too -- the framework captures them
-- into the same hooks.
```

There is no such comment in `main.lua` at `f09f1e7`; the parent deleted it and folded the claim into
`input.lua:4-5`. That was the better call (§1), and the commit message `f09f1e7` says so. But the
**workspace** record and the tree now disagree with nothing in the workspace to reconcile them, and
the outcome file is where a later reader goes to learn what the step did. One line in that file —
*"the parent moved this into `input.lua`'s header"* — closes it. This is the shape of thing the
project's own convention says belongs in a document rather than in a commit message alone.

### F3 — `input.lua:205` calls `Ctrl+Alt` a "class", which is what the file calls something else *(reasoned)*

```lua
-- Ctrl+Alt is a different class and passes: scenes ignore
```

`input.lua:49-53`, twenty lines above, reserves *"class"* for the wildcard registrations: *"`alt+*`
and `alt+shift+*` are the swallowing classes"*. There is no `ctrl+alt+*` registration — the Ctrl+Alt
bindings are exact combos, and the reason a modifier press survives with Ctrl held is that **nothing**
takes it, not that a different class does. A maintainer following the file's own vocabulary will look
for a registration that is not there. *"Ctrl+Alt is a different modifier set, and nothing swallows it"*
is the same length and is what happens. The rest of that comment block is accurate.

### F4 — the bare-Alt swallow now depends on the device poll seeing Alt down during Alt's own press *(reasoned; not measurable here)*

The old guard, `if Key.is_alt(k) then return end`, was a name test: order-free and unfalsifiable. The
new one asks the **keyboard** — `Key.alt()` → `love.keyboard.isDown('lalt','ralt')` — at the moment
`lalt`'s own `keypressed` is dispatched. If SDL's key-state array did not already reflect that press,
a lone Alt would reach the scene and skip the intro typewriter, which is precisely smoke row `A2`.

I believe it holds (LÖVE pumps SDL events, which updates the state array, before dispatching the
queued handlers), and my stub reproduces that ordering — which means **my zero-diff result assumes the
thing rather than proving it**, and I would rather say so than let the number carry more weight than
it has. It is cheap to settle: `A2` is already on the checklist and a human running it settles this
finding at the same time.

A second-order case, reasoned and dismissed: two events pumped in one frame — releasing Alt and
pressing Shift within the same ~16 ms — would let the Shift through where upstream's edge-tracked
mirror swallowed it. Sub-frame, one extra intro skip, and it is inherent to the design of record's
choice of polling over mirrors, which is documented and accepted.

### F5 — the new rule is recorded in the checklist note and a code comment, nowhere else *(reasoned)*

`internals/examples/keyboard.md` describes the classes and the claim rule but says nothing about what
`appKeypressed` drops. It is not *wrong* — I grepped it for bare-modifier and asymmetry claims and it
makes none, so nothing in it went stale when the deltas closed — but the durable statement of the
behaviour is now the smoke checklist's re-pin note plus `input.lua:202-207`. One sentence under "A
chord owns its trigger key" would put it with the rest of the mechanism. Optional, and the pass this
one answers did not ask for it.

---

## What I verified and found correct

- **Parity, measured myself, four sweeps**: 108 fresh → 0 diff; 108 repeats vs an upstream repeat
  driver I wrote → 0 diff; **385** widened stimuli (right-hand and mixed l/r holds, l/r modifier
  triggers) → 0 diff; the pre-fix head `1033252` → the 3 rows the third pass named, reproduced
  exactly. The closure is `80bca7b`'s and it is complete.
- **`D10` is a real test, measured**: upstream `scene.keypressed h`, this head nothing. Games 1 and 6
  are correctly named — `alt.lua:300` is the only `onHint` in the tree.
- **The debt count**, recounted from source: twelve registrations, six tolerant gestures, entry now
  self-consistent.
- **The anchor is honest**: the game repo is at `f09f1e7` on `newinput` with a **clean working tree**;
  `7e009536` is `255c83be^`, as the table's own note claims; upstream `025e858` unchanged.
- **The gate document is fit** at this head: `D10` sits in the right section in its neighbours' style,
  is marked `[new]`, and is in the failure-attribution list.
- **Formatting and citation rules hold**: no line over 64 in any changed file (only `scene.lua:16`,
  upstream's, exceeds it anywhere); no `INTERIM:` / `REMARK:`; no comment in the game repo cites a
  `doc/…` path, a decision number or a Beads id.
- **The app loads and runs** in the real IDE, headless, with no `Error:` line.
- **No LSP diagnostics** on the changed `input.lua`.

## Limits — what I could not verify

**Nothing in this work has ever run in a game scene, at any head, by anyone.** No key has been pressed
into this game; my harness calls the dispatcher directly and never goes through SDL, LÖVE's event
pump, or the framework's own `love.keypressed`. Everything above about what a *player* sees is
inference from code paths driven with synthetic events against stubs.

Specifically:

- **The order LÖVE delivers `keypressed` and `textinput`, and whether the key-state array is current
  when a handler runs, are both assumptions of my stub** — see F4. The whole zero-diff result rests on
  the second one for exactly one case (a lone Alt press).
- `Controller.combo_string`, `any_mod` and the three `fn` combinators are **verbatim copies** in the
  harness, not the loaded originals; I re-read them against source, and a divergence would be a
  transcription error inherited from the previous pass's instrument.
- **I did not re-audit the work the third pass cleared** — the acceptance mechanism, the glyph
  claim/poll, the raise-free device poll, `before_exit`, the untouched scenes. I read its report and
  took its clearances. I found nothing that would make me want to reopen one.
- The knock, the gauge, the sounds and the drawing were never driven; "no knock, no miss, no sound"
  in `D10` is measured as *the scene handler is never called*, not as silence observed.
- **The device build is untested**, and nothing here says anything about Android.

The smoke checklist remains the only instrument that can close any of this, and it is owed by a human.

---

## Outside scope

Nothing. I did not find a clearance in the third pass's report that I believe was wrong.

## Recommendation

**Pass, and it is ready for the human smoke gate.** If anything is spent first, it is two one-line
document edits — F1 (the count, in the checklist a human reads) and F2 (the outcome record's stale
quote) — and neither blocks the gate. F3 is a word. F4 is not an edit at all: it is a note that smoke
row `A2` now carries slightly more weight than it did.
