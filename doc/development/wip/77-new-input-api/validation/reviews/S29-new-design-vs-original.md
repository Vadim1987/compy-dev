# S29 — the rewritten design (E) vs. the original implementation (A), vs. shared-infrastructure history (B/C)

Cold review, read-only. Nested repo: `src/examples/keyboard` (separate git history).
Versions:
- **A** = `c904338` (original, pre-Compy-API)
- **B** = `4814407..6eb7919` (the Compy-API migration + reserved-chord refactor)
- **C** = `3a9d48c` (HEAD; the `spendGlyph`/`GLYPH_CLAIMED` fix on top of B)
- **E** = `doc/development/internals/examples/keyboard.md` in the main repo, as it stands now (a design, not code)

All file:line references below are against C (HEAD of the nested repo) unless a commit is named.

---

## Part 1 — the counts

### 1a. Judging machinery only (A / C / E), as originally scoped

| | A (`c904338`) | C (`3a9d48c`, HEAD) | E (design) |
|---|---|---|---|
| **State (judging-relevant)** | `INPUT.held` (table), `INPUT.upRecent` (table), `INPUT.shift/ctrl/alt` (3 edge-mirrored booleans) — 5 named pieces, owned by `input.lua`, read by both channels | `GLYPH_CLAIMED` (table), `INPUT.upRecent` (table) — 2 owned tables; `INPUT.held/shift/ctrl/alt` now a **live proxy** onto `compy.input.keys_pressed`, not file-owned state | `ALT_JUDGE = { lastText, blocked }` — 1 table, 2 fields |
| **Tunable constants (judging)** | `INPUT_UP_GRACE = 1` | `INPUT_UP_GRACE = 1` (unchanged) | none |
| **Code paths, printable target** (`altTextinput`/equivalent) | 7: claimed/held-drop, grace-drop, `fkDone`-drop, not-glowing-drop, key-target-drop, hit, miss | 7 (same shape, `spendGlyph` swaps in for `inputStale`) | Rules 1–4 collapse this to: caps-reconcile (side effect), blocked-stop, repeat-stop, hit, miss — **~4** substantive branches (no held-check, no grace-window branch) |
| **Code paths, non-printing target** (`altPlayKey`/equivalent) | 6: not-glowing-drop, not-key-target-drop, hit, mod-exempt-drop, capslock-exempt-drop, miss | 6 (unchanged — `altPlayKey` is byte-identical A→C) | Design states "fed... into the same judging function," but does not restate the mod/capslock exemption (see Finding B, Part 4) — path count for this branch is **UNDETERMINED** under E |
| **Live-state reads in judging** | 4 sites: `inputStale`'s `INPUT.held[k]` (used by *both* the shared keypressed channel and the Alt-only textinput channel — 2 call sites), plus `appTextinput`'s `INPUT.alt`/`INPUT.ctrl` guard (2 reads, shared, input.lua:191-192) | 2 sites: only `appTextinput`'s `INPUT.alt`/`INPUT.ctrl` guard remains (input.lua:191-192); the keypressed channel now uses `isr` (not held-state) and `spendGlyph` uses a claim table (not held-state) | **Design claims 0** ("Judgement never consults... the held set"). Whether this is actually 0 or still 2 depends on the undetermined fate of `appTextinput`'s Alt/Ctrl guard — see Finding D |
| **Clock reads in judging** | 1 site: `inputStale`'s `DBG_FRAME - up <= INPUT_UP_GRACE`, shared by both channels | 1 site: same fallback, now inside `spendGlyph`, reached only from the textinput channel (keypressed no longer calls it) | 0 |

Gauge/scoring constants (`ALT_G`, `ALT_GTOP`, `GAUGE_LOWN_BIAS`, `ALT_HINT_FIRST/MORE`, etc., `config.lua:126-241`) are unchanged across A/C/E — `gauge.lua` is byte-identical between A and C (`git diff c904338:gauge.lua 3a9d48c:gauge.lua` → empty), and E does not touch scoring. Not counted above since they aren't judging machinery.

### 1b. Shared infrastructure (A / B / C) — added per scope extension

| | A | B (post-migration, `6eb7919`) | C (`3a9d48c`) |
|---|---|---|---|
| **Held-set ownership** | `INPUT.held`, self-maintained mirror, set/cleared in `appKeypressed`/`appKeyreleased` | `compy.input.keys_pressed`, framework-owned; `INPUT` becomes a metatable proxy (`input.lua:54-60`, unchanged since B) | same as B |
| **Keypressed-channel repeat filter** | `inputStale(k)` — reads `INPUT.held[k]` (correct on this channel: fresh press is not yet in the mirror) | `isr` (the API's own `isrepeat`, 3rd hook arg) — `appKeypressed(k, _, isr)` in the **first commit of B**, `4814407` | same as B (signature reshuffled twice more, `5de5a6d`/`f938fbc`, semantics unchanged) |
| **Textinput-channel repeat filter** | `inputStale(k)` — same function, same `INPUT.held[k]` read, **wrong** on this channel (see below) | **unchanged from A**: `alt.lua` was not touched by any B commit (confirmed: `git diff c904338:alt.lua 6eb7919:alt.lua` — only `3a9d48c` later changes it) | `spendGlyph`/`GLYPH_CLAIMED`, replacing the held-read with a claim table |
| **Reserved-chord dispatch** | Hand-written `reservedChord()`/`appChord()`, called from inside `appKeypressed`, reading the self-mirrored `INPUT.shift/ctrl/alt` | `compy.input.shortcuts.keypressed` entries (`register_reserved`, `input.lua:75-88`), which the framework consults **ahead of** the hooks — an ownership move from in-hook imperative code to framework-level declarative dispatch | unchanged from B |
| **What a scene's `.keypressed` receives** | `k` only (isr/scancode consumed upstream) | `k` only (unchanged) | `k` only (unchanged) |

---

## Part 2 — failure modes

### A (known-defective; listed for completeness, not as new findings)
Correct action fails to register:
1. **Every printable target's first press, on desktop.** `inputStale(k)` reads `INPUT.held[k]`, and on desktop `keypressed` (which sets `INPUT.held[k]=true`) fires before `textinput`, so the producing key already reads "held" at the moment its own glyph is judged. This is the settled, known defect — not counted as a new finding.
2. A correct glyph whose `textinput` arrives after its own `keyreleased` — dropped by the grace-window branch of `inputStale`.

Incorrect action wrongly registers: none found. The `isMod`/`capslock` exemption in `altPlayKey` (unchanged since A) correctly prevents modifier/Capslock presses from knocking a non-printing target.

### C (today)
Correct action fails to register:
1. A correct glyph whose `textinput` arrives after its own `keyreleased` — `GLYPH_CLAIMED[k]` is cleared by then, but `INPUT.upRecent[k]`'s grace window still trips inside `spendGlyph`. (Settled fact: "A and C alike.")

Incorrect action wrongly registers: none found — same protections as A, structurally unchanged (`altPlayKey` byte-identical; `spendGlyph` prevents a held/repeating wrong key from knocking every frame, same as `inputStale` did for A).

### E (design)
Correct action fails to register:
1. **None** for the "arrives after keyreleased" case — this is the explicit, stated fix.
2. **A genuinely identical back-to-back target.** Rule 3 (`text == lastText` → stop) would swallow the correct keystroke for a target that repeats the immediately-prior winning character. Verified against `gauge.lua`: `gaugeCandidates`/`gaugeCollect` already exclude `st.cur` from the next pick *unless it is the only available candidate* (`gauge.lua`: "avoid an immediate repeat unless it is the only choice"), so this is reachable only in a single-candidate situation (e.g., the reserve phase with exactly one mandatory glyph left, or a one-token level) — narrow, as E itself states ("rare rather than impossible today"). This is a new failure mode relative to A/C (where a release-then-repress naturally clears the claim and lets the repeat re-register), but it is **stated and accepted by E**, with the fix explicitly assigned to `gaugePick` (unchanged).

Incorrect action wrongly registers — two UNDETERMINED risks, not confirmed defects:
3. **If** the mod/Capslock exemption in the keypressed-feed path (A's `altPlayKey` behavior) is not carried into E's "same judging function," then holding Shift or pressing Capslock while a non-printing target (Backspace/Tab/Return) is displayed would register as a miss. E's text does not say either way (Finding B).
4. **If** `appTextinput`'s Alt/Ctrl live-held guard (`input.lua:191-192`) is removed to match E's "no modifier guard" claim, a chord glyph that does *not* match the live target (not just the "release Alt, get a trailing hit" case E describes) could now knock a target — the reverse of A's explicit "a chord cannot fumble a target" guarantee. E only describes the win case (Finding C/D).

---

## Part 3 — A's intent inventory

| A's intent | Evidence | Under E |
|---|---|---|
| A repeated wrong character changes nothing (per presentation) | `gauge.lua` `gaugeOnWrong`: `if st.fumbled then return end` | **PRESERVED** — E cites this explicitly and it is verified unchanged (`gauge.lua` identical A/C) |
| A correct character advances the target synchronously | `gauge.lua` `gaugeOnCorrect` calls `gaugeNext` in the same call when not fumbled | **PRESERVED** — cited by E, verified unchanged |
| A held/repeating wrong key cannot knock every frame | A: `inputStale` drops the repeat before `altWrong` is ever called. E: no per-channel held/claim guard; instead rule 3 (`lastText`) stops repeats of the *same* wrong text after the first judged miss, and `gaugeOnWrong`'s own idempotency absorbs a run of *different* wrong keys | **PRESERVED**, by a different mechanism (E lets the event reach the judge and relies on `lastText` + `gaugeOnWrong`'s idempotency instead of dropping it upstream) |
| A chord glyph cannot fumble a live target | A/C, `input.lua` (unchanged A→C): "An Alt+key chord is swallowed... AND its glyph dropped in `appTextinput`... so a chord cannot fumble a target." | **CHANGED-AND-STATED for the hit case** (E: "a player who reaches h by releasing Alt... has typed h, and that is a win" — deliberate reversal). **UNDETERMINED / possibly CHANGED-SILENTLY for the miss case** — E never states whether a chord's trailing glyph that does *not* match the live target can now knock it, which is the direct symmetric case of the guarantee A wrote down (Finding C) |
| Non-printing targets are matched via `keypressed` because they emit no `textinput` | `alt.lua` `altIsKeyTarget`, unchanged A→C | **PRESERVED** — E states explicitly: "`altIsKeyTarget` stays — it is what selects the feeding channel" |
| A wrong key that is a modifier or Capslock never knocks a non-printing target | `alt.lua:193` (unchanged A→C): `elseif not isMod(k) and k ~= "capslock" then altWrong() end`; the same idiom appears independently in `findkey.lua:133` (`fkKeypressed`, shared by Press/Find) and `hunt.lua:350` | **UNDETERMINED** — E's "non-printing targets are fed from `keypressed` into the same judging function" does not mention this exemption at all (Finding B) |
| Ctrl+Alt+H stays outside the Alt-chord class, for the scene's hint re-arm | A: `appChord`'s `if INPUT.ctrl then return false end`. C: `register_reserved`'s comment, "Ctrl+Alt+H is NOT in the class." | **PRESERVED** — E does not touch reserved-chord dispatch at all (out of its stated scope); nothing in the design implies a change here |
| Caps Lock's estimate is corrected from *every* alphabetic `textinput`, system-wide, not scoped to one scene | A/C `input.lua:195-196` (`appTextinput`, unchanged A→C): `capsReconcile` runs unconditionally before scene dispatch, for whichever scene is active. Consumed by `alt.lua:288`, `findkey.lua:216` (Press **and** Find, during live play), and `intro.lua:129` | **UNDETERMINED, and this is the strongest single risk in this review** — E's Rule 1 ("Reconcile Caps first, unconditionally") is written as step 1 of ALT_JUDGE's own ordered `textinput` rules, i.e. framed as part of the Alt scene's judging function. E's "Scope" line explicitly excludes "other subsystems (scenes...)" from its remit, yet the mechanism it is describing currently lives in the *shared* `input.lua`, not in `alt.lua`. If Rule 1 is implemented literally inside the Alt-scoped judging function (replacing the shared call), Caps-Lock re-estimation stops working while Press, Find, Hunt or Menu are active — even though Press/Find display the same indicator during play. E's account does not match the current code's ownership (Finding A) |
| One glyph per physical press reaches the scene at most once (no double hit/miss for one press) | A/C: `inputStale`/`spendGlyph`, one claim per press | **PRESERVED** — verified: the mutual exclusivity of `altIsKeyTarget` (kept by E) means a single keystroke cannot feed both the textinput judge and the keypressed judge for the same event, so no double-count arises from channel overlap |

---

## Part 4 — findings, most serious first

### Finding A — Caps Lock reconciliation's shared scope is not acknowledged by E (UNDETERMINED, high risk)
`input.lua:189-199` (`appTextinput`, unchanged since A) runs `capsReconcile(t, INPUT.shift)` for **every** alphabetic `textinput`, before checking which scene is active, i.e. for Press, Find, Hunt, Menu and Alt alike. `findkey.lua:216` (`fkDraw`, shared by `press.lua` and `find.lua`) calls `drawIndicators(CAPS_STATE.on)` during live play, not just on a completion screen; `intro.lua:129` also renders it. E's design frames Caps reconciliation as "Rule 1" of the Alt scene's own `textinput` rules ("On `textinput(text)`, in order: 1. Reconcile Caps first..."), inside a document whose own Scope line says "other subsystems (scenes...) are not covered here." A literal implementation of Rule 1 as part of `ALT_JUDGE`'s function, replacing the current shared call, would silently stop the Caps indicator from re-deriving itself while playing Press/Find/Hunt/Menu — a real, player-visible regression, not merely a code-organization change. E does not say which reading is intended. **A player's experience if this is implemented literally:** toggle Caps Lock with the window unfocused, then play Find (not Alt) — the Caps decal (`findkey.lua:216`) would stay wrong for the whole session, where today it self-corrects the first time a letter is typed on any screen.

### Finding B — the modifier/Capslock exemption for non-printing targets is unaddressed (UNDETERMINED)
`alt.lua:193` (`elseif not isMod(k) and k ~= "capslock" then altWrong() end`), unchanged since A, is a deliberate exemption: pressing Shift, Ctrl, Alt or Capslock while Backspace/Tab/Return is the displayed target never knocks. The identical idiom is independently written in `findkey.lua:133` (Press/Find) and `hunt.lua:350` — a repeated, deliberate cross-scene pattern. E's account of the keypressed-feed path ("Non-printing targets are fed from `keypressed` into the same judging function; their repeats are already filtered by `isrepeat` at the source") says nothing about which keys are eligible candidates. **Consequence if unaddressed:** a child who reaches for Shift in anticipation of a later capital, while the current target happens to be Tab, would knock — a game-rule change A explicitly coded against, at a place natural for a small child's hands to trigger it (Shift/Capslock are large, easy-to-brush keys).

### Finding C — A's "a chord cannot fumble a target" guarantee is reversed for hits but silent on misses
A's `input.lua` (both A and C, unchanged in this respect): "An Alt+key chord is swallowed... AND its glyph dropped in `appTextinput`... so a chord cannot fumble a target." E deliberately reverses half of this: "If a chord produces a `textinput`, it is judged like any other... that is a win." E gives only the winning example (Alt+H → releasing Alt → "h" happens to be the live target). It does not address the symmetric case: a chord's trailing glyph that does **not** match the live target. Under E's stated rules as written (no modifier guard, `textinput` is the only judge, no exemption for a chord-origin glyph), such a glyph would be judged and could knock — something A explicitly built machinery to prevent, in both directions.

### Finding D — the shared `appTextinput` Alt/Ctrl guard is not mentioned by E at all
`input.lua:191-192` (`if INPUT.alt then return end` / `if INPUT.ctrl then return end`), byte-identical from A through C, currently gates dispatch of **every** `textinput` event to **every** scene's `.textinput` handler (only Alt has one today, but the guard itself is written at the shared, all-scenes level). This is a live-held-state read that runs before any scene ever sees the character. E's central claim — "Judgement never consults `keypressed`, `keyreleased`, or the held set" — and its "no modifier guard, deliberately" consequence are in tension with this: either (a) the guard stays, in which case E's "never consults the held set" and its Alt+H win-scenario are both narrower in practice than described (the win only reaches judging once Alt is fully released and the guard's live read of `INPUT.alt` has already gone false — consistent with E's own example, but then the "no modifier guard" framing overstates what changed), or (b) the guard is removed, which is an edit to shared `input.lua` beyond what E's stated scope ("how the keyboard example decides that a typed character matched its target," explicitly excluding "other subsystems") claims to cover. E does not say which. This is exactly the class of gap the brief asked to hunt for: a scoped design touching shared plumbing without saying so.

### Finding E — a genuinely-repeated target's correct keystroke can go unregistered (stated, low severity)
Covered in Part 2. E states this itself as an accepted consequence and correctly attributes the fix to `gauge.lua`'s `gaugePick`, which the review confirms already minimizes (not eliminates) the case via `gaugeCandidates`'s `st.cur`-avoidance. Listed for completeness; not silent, not a game-rule violation E is unaware of.

---

## Part 5 — B, the shared-infrastructure migration

### What B actually changed
Confirmed by `git diff --stat c904338 6eb7919` (nested repo): **only `input.lua` and `main.lua`** changed across the entire B range; `alt.lua`, `gauge.lua`, `find.lua`, `findkey.lua`, `hunt.lua`, `press.lua`, `menu.lua`, `intro.lua`, `help.lua`, `indicators.lua`, `scene.lua` are all untouched (verified: `git diff c904338:alt.lua 6eb7919:alt.lua` is empty — alt.lua only changes later, at `3a9d48c`).

`main.lua`'s change is mechanical: `love.keypressed/keyreleased/textinput` wrapper functions are deleted since the Compy framework captures `love.*` into the same `compy.input.hooks` anyway (`main.lua` diff, `c904338..6eb7919`).

`input.lua`'s change, in kind:
- **Held-set ownership moves to the framework.** A's self-mirrored `INPUT.held/shift/ctrl/alt` (updated by hand in `appKeypressed`/`appKeyreleased`) becomes a metatable proxy reading `compy.input.keys_pressed` live (`input.lua:51-60`). The commit message (`4814407`) states this explicitly: "INPUT is now a proxy reading the framework's held set live... Every call site is unchanged — help.lua, alt.lua, findkey.lua, hunt.lua and keyboard_view.lua still read INPUT.shift and INPUT.held."
- **Keypressed-channel repeat filtering moves to the platform's `isrepeat` flag**, in the very first B commit (`4814407`): `appKeypressed(k, _, isr)`, `if isr and k ~= "capslock" then return end`, replacing `inputStale(k)`'s held-read for this channel. This is a single, one-shot change to the *shared* function every scene's keypressed dispatch runs through.
- **Reserved-chord dispatch moves from in-hook imperative code to declarative `compy.input.shortcuts` entries**, run by the framework ahead of the hooks (`register_reserved`, settling at `43fd9e9`/`032265d` after several intermediate refactors within B — `ced8f40` combo classes, `e00430b` fix to consume shortcuts explicitly, `28d84cd`/`43fd9e9` naming/composition cleanups).
- **The textinput channel's repeat filter (`inputStale`, reading `INPUT.held[k]`) is untouched by B.** Confirmed by the commit message itself (`4814407`): "textinput still cannot [use isrepeat]: it carries no such flag, so `inputStale` keeps judging a glyph by whether its producing key is held, now asking `compy.input.keys_pressed` instead of our copy." This is the exact split the coordinator described — B fixed the right half (keypressed) of the one function that did both jobs, and explicitly left the wrong half (textinput) in place, in the same commit that migrated everything else. The textinput-channel fix did not land until `3a9d48c` (`spendGlyph`/`GLYPH_CLAIMED`), which also only touches `alt.lua` and `input.lua`.

### Whether the keypressed-channel replacement is equivalent for other scenes
Yes, and uniformly so. `appKeypressed` is the single shared entry point for `find.lua` (`findKeypressed`→`fkKeypressed`), `hunt.lua` (`huntKeypressed`), `press.lua` (`pressKeypressed`→`fkKeypressed`), `menu.lua` (`menuKeypressed`), `intro.lua` (`introKeypressed`) and `alt.lua`'s own `altKeypressed`. None of these scene functions receive `isr`/`scancode` — only `k`, after `appKeypressed` has already dropped repeats. The B-era switch from `inputStale(k)`'s held-read to `isr` therefore benefits every scene identically and simultaneously: it is strictly more direct (the platform's own flag, not an inference from a mirrored set) and was already semantically correct for this channel at A (a fresh press is genuinely not yet in the held mirror at the point the check runs) — B did not fix a bug here, it removed an inference in favor of the authoritative signal.

### Do any other scenes judge or gate input on held state, or on their own repeat inference?
Read in full: `find.lua`, `findkey.lua`, `hunt.lua`, `press.lua`, `menu.lua`, `intro.lua`, `pause.lua`, `help.lua`, `scene.lua`.

- **None carry an `inputStale`-shaped defect.** `fkKeypressed` (`findkey.lua:125-136`, shared by Press/Find) and `huntKeypressed` (`hunt.lua:345-352`) both compare the *already-filtered* `k` directly against a target and use the same `isMod`/`capslock` exemption as `altPlayKey` — no held-state read, no separate repeat inference; both rely entirely on `appKeypressed`'s upstream `isr` filter. `menu.lua`'s `menuKeypressed` and `intro.lua`'s `introKeypressed` do plain key-string comparisons with no repeat/held logic at all (menu entries are single-shot digit presses; intro reacts to any key once).
- **`help.lua:11`** (`helpHeld`, `return INPUT.held.h and INPUT.alt and not INPUT.ctrl`) is the one place besides Alt-judging that reads `INPUT.held` — but it is a **continuous live poll from `draw`**, asking "is the player holding this combo right now," not an event-time inference about whether a just-arrived event is a repeat. This is the same kind of read E's own "Suggested, not adopted" section endorses as legitimate for a genuinely different question ("is the player still holding the key," answered directly) versus the defect class (inferring "is this event a repeat" from held state at event time, which depends on undefined event order). `helpHeld` is not exposed to the keypressed/textinput ordering problem at all, since it isn't consulted from either event handler — it's read once per draw frame. No defect found here.
- **`keyboard_view.lua:171,178`** reads `INPUT.shift` for rendering (case of on-screen keycap labels) — presentation only, not gating any judgment.

**Conclusion: no other scene carries a latent `inputStale`-shaped defect.** The textinput-channel held-read defect was structurally confined to Alt-keys because Alt is the only scene that ever registered a `.textinput` handler (`grep -n "textinput\s*=" *.lua` → only `alt.lua`); every other scene's input pipeline runs exclusively through the (correctly-filtered, since B's first commit) keypressed channel.

### Does E's subtraction interact with anything B introduced?
No collision found. Confirmed by two independent passes:
1. `grep -n "spendGlyph\|GLYPH_CLAIMED\|upRecent\|INPUT_UP_GRACE" *.lua`, run across the full file list of the nested repo (`alt.lua config.lua find.lua findkey.lua firework.lua gauge.lua help.lua hints.lua hunt.lua indicators.lua input.lua intro.lua keyboard_view.lua layout.lua locale.lua main.lua menu.lua notch.lua pastel.lua pause.lua press.lua scene.lua sound.lua` — every `.lua` file in the repo, `find . -name "*.lua"` enumerated first to confirm the file list is exhaustive) — hits only in `alt.lua` and `input.lua`.
2. Read every other scene file in full (listed above) looking for any reference to these names by a different route (e.g. through a shared helper) — none found; `register_reserved`'s shortcut bindings (B's contribution) don't touch `INPUT.upRecent`/`INPUT_UP_GRACE` at all, and `GLYPH_CLAIMED` didn't exist until `3a9d48c`, entirely after B.

No LSP query was needed for this one: these are plain global identifiers (no receiver-type ambiguity), so a whole-repo grep is exhaustive rather than a hint to cross-check.

---

## Closing

**1. Is E better than A on machinery and reliability, by the counts above?**
By the counts, yes. State drops from 5 judging-relevant pieces to 2 fields in one table; the tunable grace constant disappears; the textinput-path branch count drops from 7 to ~4; clock reads in judging drop from 1 to 0; and (independent of E) B+C already removed the held-state read from the keypressed channel that A used correctly, while C's `spendGlyph` removed it from the textinput channel A used incorrectly — E removes the *claim table and grace window* that C still needed on top of that fix. On reliability, E closes the one dropped-correct-input case that persisted from A through C ("arrives after its own keyreleased") and introduces one narrow, self-acknowledged new one (an exact-repeat target, gated to a rare single-candidate situation by `gauge.lua`'s existing logic).

**2. Does E break, overlook or degrade any intent A encoded — and is any game rule changed that should not have been?**
Two scoring-adjacent intents (idempotent-miss, synchronous-advance) are verified preserved and are the actual load-bearing premise E leans on — that premise checks out against the code. But question (b) turns up real gaps, concentrated exactly where the brief predicted: at the boundary between Alt's judging and the *shared* `input.lua`. The most serious is Finding A — E frames Caps-Lock reconciliation as belonging to Alt's own judging function, when the code that exists has it as global, shared, and already consumed by Press/Find's own indicator; a literal implementation would degrade those other scenes silently. Findings B and C are UNDETERMINED gaps in E's account of two behaviors A explicitly engineered (the modifier/Capslock exemption on non-printing targets, and "a chord cannot fumble a target" in the miss direction) — not proven regressions, but real, checkable holes in what E says, in exactly the territory the brief asked to hunt in. None of this is E manufacturing a defect; all of it is E's document not saying what happens at a boundary it draws around itself but that the actual code crosses.

**3. What did you check that came back clean?**
`gauge.lua`'s scoring rules (idempotent miss, synchronous advance, `st.cur`-avoidance in candidate selection) match E's premise exactly and are unchanged A→C. `altIsKeyTarget`'s channel-selection role is preserved and rules out the double-judging scenario a naive reading of "one channel judges" might suggest. Every other scene (`find`, `findkey`/Press, `hunt`, `menu`, `intro`, `pause`) was read in full and carries no `inputStale`-shaped defect of its own — all repeat filtering for those scenes runs through the shared, already-fixed (since B's first commit) `appKeypressed`/`isr` path, and `help.lua`'s live `INPUT.held` poll is a different, legitimate kind of read (continuous "is it held now," not event-time repeat inference). `GLYPH_CLAIMED`/`INPUT.upRecent`/`INPUT_UP_GRACE`/`spendGlyph` are confirmed, by exhaustive grep across every `.lua` file in the nested repo, to be consulted nowhere outside `input.lua` and `alt.lua` — E's subtraction of them has no other-scene blast radius. Ctrl+Alt+H's exemption from the Alt-chord class is untouched by both B and E. Reserved-chord dispatch (`shift+escape`, `ctrl+alt+up/down`, `alt+*`, `alt+p`) is unaddressed by E and shows no sign of being affected.

---

## Git state (recorded as required)

Nested repo (`src/examples/keyboard`), read-only throughout:
```
$ git status --porcelain
(empty)
$ git diff --stat
(empty)
```

Main repo (`/repo`), only the deliverable file below was written by this review; the rest of the untracked/modified state predates this session and is unrelated to it:
```
$ git status --porcelain
 (pre-existing untracked files: claude.sh, doc/development/wip/clarification/,
 doc/development/wip/personal-notes/, doc/development/wip/pull-26/,
 doc/tall_blocks.md, input-pr-slices.tar.gz, src/STEPS.md,
 src/examples/balloons/, src/examples/keyboard/, src/examples/maze/,
 doc/development/wip/77-new-input-api/validation/prompts/S29-new-design-vs-original-agent.md
 — all present before this review started)
?? doc/development/wip/77-new-input-api/validation/reviews/S29-new-design-vs-original.md   (this deliverable)
```
