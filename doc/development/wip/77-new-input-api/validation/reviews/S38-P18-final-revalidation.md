# S38 — final cold revalidation of the keyboard deepfix (`025e858..646674b`)

**Verdict: the mechanism is sound; the adoption is not clean.** The claim/poll design is correct
against the library, correct in both delivery orders, and smaller than what it replaced — I
measured it. But the change set carries **two behaviour regressions a player can notice** (one of
them on the every-session path into the two scenes this work exists for), **one comment that states
the opposite of what the platform API does**, and **one smoke row that cannot be run under the
checklist's own launch instructions**. None of the four is deep; all four are cheap. Not shippable
as it stands; shippable after four small edits and a re-read of the gate.

**Written:** 2026-08-12, cold, read-only. Object of review: the complete diff
`git -C src/examples/keyboard diff 025e858..646674b`. Nothing in any repository was edited,
committed or otherwise touched; this file is the only artifact.

---

## How the findings were obtained

Two instruments, both throwaway, both under
`/tmp/claude-1000/-repo/6f512c55-e690-4ef3-9962-d6ea3490f5cb/scratchpad/`:

1. **Real LÖVE 11.5**, headless under `xvfb-run`, for library facts (`love.keyboard.isDown`,
   `love.mouse.getRelativeMode`), and for a load check of the game in the real platform.
2. **A dispatch harness** (`harness.lua`) that drives the **real** `ProjectInputController` and the
   **real** `util/key.lua` over the **real** `src/examples/keyboard/input.lua`, with
   `Controller.combo_string` / `any_mod` and `INPUT_FN` copied verbatim from the platform sources,
   a stubbed `love.keyboard.isDown` whose raising set is the one measured in instrument 1, and
   scene stubs whose `textinput` is exactly the first line of `altTextinput` / `wordsTextinput`.
   21 cases, each named below where it is cited.

Findings are marked **measured** or **reasoned**. Everything marked measured was reproduced in one
of those two instruments.

---

## Defects

### D1 — the menu digit is judged by the game it opens *(high; measured)*

**What is wrong.** `menuKeypressed` enters a game *synchronously*, inside the keypress handler
(`src/examples/keyboard/menu.lua:82-90` → `gotoScene(id)` → `scene.lua:50-58`). On a build that
delivers `keypressed` before `textinput`, the digit's **`textinput` is then delivered to the scene
that has just become active**, and the two judging scenes judge it:

- game **5**, Words — `wordsTextinput("5")` (`words.lua:229-239`): the claim is free, `want` is the
  first character of the freshly generated line, `"5" ~= want` → `wordsBad()` → a knock and
  `WORDS.wordClean = false`, so the first word cannot fill a gauge notch;
- game **4**, Alt characters — `altTextinput("4")` (`alt.lua:179-188`): `gaugeEnter` leaves
  `st.phase == "glow"` immediately (`gauge.lua:261-267` → `249-257` → `237-243` → `194-205`), so
  unless the first target happens to be `backspace`/`tab`/`return` the digit is judged →
  `altWrong()` → a knock and `ALT.fumbled`.

**Upstream did not do this.** `appKeypressed` set `INPUT.held[k] = true` (upstream `input.lua:126`)
**before** dispatching to `menuKeypressed`, so when the digit's glyph arrived at the new scene
`inputStale(altBaseKey(ch))` found the key held and dropped it. The claim mechanism takes **no
claim on an unmodified keypress** (`input.lua:266` claims only under Ctrl or Alt), so the digit's
glyph is fresh when the new scene sees it. The protection was invisible and it was removed.

**Reachable by.** From the menu, press `5`. Or `4`. Every time.

**Evidence.** Measured, harness case **T20**: with `SCENES.menu.keypressed` doing `gotoScene`, a
keypress-first `5` produces `words: JUDGED "5" -> wrong char`. Case **T21** (textinput-first) is
clean — the glyph reaches the menu, which has no `textinput` handler. So the defect is
**order-dependent**, and it manifests on the order the owner attested for desktop Linux: upstream
was *deaf* there under a held-key test, which is only possible if the key is already held at its own
first glyph, i.e. keypressed arrives first (§1.2 of the design doc).

**What I would do.** The design of record already states the right rule for chords — *"whoever takes
a chord claims its trigger"*. This is the same rule with a wider subject: **a keypress consumed by
a scene transition owns its key.** One line, in the game's own vocabulary:

```lua
function menuKeypressed(k)
  local n = tonumber(k)
  if not n then return end
  if n == 0 then n = 10 end
  local id = MENU_ORDER[n]
  if id and sceneAvailable(id) then
    spendGlyph(k)          -- this press is spent on entering; it is not typing
    gotoScene(id)
  end
end
```

**Do not** claim unconditionally in `appKeypressed` instead: in keypress-first order that claims the
key before its own glyph arrives, and every fresh target is thrown away — the deafness the whole
design exists to rule out. Add a smoke row (C-section: *enter game 5 from the menu — no knock, the
first word still scores*), and a line in `internals/examples/keyboard.md` under "A chord owns its
trigger key", which is where this rule now lives.

### D2 — `Alt+Shift+P` no longer pauses *(medium-low; measured)*

**What is wrong.** Upstream's `appChord` was one-sided — *"Alt and not Ctrl"* — so `Alt+Shift+P`
toggled the pause exactly as `Alt+P` did (upstream `input.lua:102-107`: `if k == "p" then
pauseToggle() end`). In the new registration, `alt+shift+p` is not bound; it falls to the
`alt+shift+*` class (`input.lua:117`), which claims the trigger and swallows. The gesture now does
nothing.

**Reachable by.** In a timed game, hold Alt and Shift and press P.

**Evidence.** Measured, harness case **T11**: no `pauseToggle`, against **T10** (`Alt+P`) which
toggles once. Upstream behaviour read directly from `git show 025e858:input.lua`.

**Why it matters more than its size.** This is the **fifth** member of a family this work has now
twice gone back for: §5 RULE 1 restored `alt+shift+escape` and `ctrl+alt+shift+up/down`; S37's F3
restored the `alt+shift+*` swallow. `alt+p` is the one gesture in that family that carries an
**action**, and it is the one that was not double-bound. The comment at `input.lua:94-99` —
*"Each gesture is therefore bound twice, to the same handler, so Alt+Shift+Esc still goes back and
Ctrl+Alt+Shift+Up still notches"* — is not true of `alt+p`, and `input.lua:78-79` stops at the
claim without noticing the action. So the code and the comment are wrong together, which is why it
survived three passes.

**What I would do.** Hoist the handler the way `back` and `notch_up` are hoisted, and bind it twice:

```lua
local pause = fn.stop_here(function(k, _, isr)
  claimChord(k)
  if not isr then pauseToggle() end
end)
sc["alt+p"] = pause
sc["alt+shift+p"] = pause
```

and correct `input.lua:78-79` to say the same thing it says about escape and the notch. Add a smoke
row beside D8.

### D3 — `help.lua`'s comment states the opposite of the platform API *(low; reasoned, citation checked)*

**What is wrong.** `help.lua:10-15` says:

> *"'h' is not a modifier, so **Key has no answer for it** and the keyboard is asked directly — the
> last rung of `doc/input_api.md`, 'Held keys', and the rung it is there for."*

The last rung of that section is **`Key.any_pressed`**, and it is documented as exactly this case:
*"**3. Ask `Key.any_pressed` — for a key that is not a modifier** … This is the rung to use when the
folded accessors have no answer — an ordinary key"* (`doc/input_api.md:397-412`). Key **does** have
an answer for `h`. The same section closes with the sentence that describes `helpHeld`'s body
verbatim as the thing to avoid: *"using `Key` for both kinds of question just keeps one surface in
your code instead of two spellings of the same question in one expression"* — and
`help.lua:17-18` is `love.keyboard.isDown("h") and Key.alt() and not Key.ctrl()`, two spellings in
one expression.

It is also **circular with `input.lua:233-236`**, which concedes *"`Key.any_pressed(k)` is the
platform's form of this call and is what a Compy project should reach for"* and then keeps `isDown`
*"because this game asks it directly elsewhere too (helpHeld)"*. Each comment justifies itself by
pointing at the other; the one they both rest on is false.

No behaviour consequence: `Key.any_pressed` **is** `love.keyboard.isDown` (`src/util/key.lua:134-138`).
But this repository has no tests, and a comment is the only thing a future reader gets — the
mandate's own priority 3.

**What I would do.** Minimum: correct the comment to say Key *does* answer this (`any_pressed`), and
that the project keeps `isDown` deliberately. Better, and a literal no-op at runtime:
`local h = Key.any_pressed("h")`, which makes the expression one surface and makes the comment true
as written.

### D4 — smoke rows `D9` and `G1` cannot be run under the checklist's own launch *(medium; reasoned from platform source)*

**What is wrong.** `doc/development/smoke_checklists.md` says to launch with
`love src play src/examples/keyboard`, and then asks:

- **D9** — *"`Ctrl+Esc` | quits the project **back to the console**"*
- **G1** — *"leave the game with `Ctrl+Esc` and **use the console** | the pointer behaves as it did
  before the game was started"*

In **play** mode there is no console to return to. `love.quit` takes the play branch
(`src/controller/controller.lua:660-666`): `CC:quit_project()`, `app_state = 'shutdown'`,
`love.draw = View.end_draw` — a full-screen "press any key" farewell (`controller.lua:640-646`) —
and `ConsoleController:textinput` documents the state plainly: *"console is disabled in this mode"*
(`consoleController.lua:1418-1421`). On the device (`.apk`) it is the same mode.

G1 is the **only** row covering P-18-05, the `compy.before_exit` pointer restore — and it is the row
a tester physically cannot perform as written. (The restore itself does fire on that path: I traced
`handlers.keyreleased` Ctrl+Esc → `love.event.quit` → `love.quit` → `quit_project` →
`stop_project_run` → `framework_before_exit`, `consoleController.lua:1340-1345`. The hook runs; the
observation is what is impossible.)

**What I would do.** Give G1 (and D9) their own launch: `love src` in console mode, open and run the
project from the console, then `Ctrl+Esc`, then move the mouse. State in the row that this is why
the launch differs, so the next editor does not "simplify" it back.

---

## Observations

**O1 — a re-press faster than one frame is dropped** *(measured, T17)*. Claims are cleared only by
`inputTick`, once per `love.update`. A release and a re-press with no update in between leaves the
claim standing and the second character is discarded. That is ~16 ms; no child can reach it, and the
smoke row it would threaten (B5) is a human "immediately" of 50-100 ms. But it is the one residue of
choosing a poll, and `internals/examples/keyboard.md`'s "Consequences, accepted" — which names four
smaller ones — does not mention it. One sentence there would complete that list.

**O2 — the branch breaks the author's own line-width convention 25 times** *(measured)*. Upstream
keeps every line at ≤64 columns: 0 violations across `input.lua`, `alt.lua`, `words.lua`,
`main.lua`, `help.lua`, `bubble.lua` (~1300 lines). The branch introduces **25** — 19 in
`input.lua`, 3 in `alt.lua`, 3 in `main.lua`, all comments, worst `input.lua:254` at 67. This branch
itself committed `eb90389 style: wrap a comment line to 64`, so the convention was known. It is the
author's repository and the platform's rule agrees (`agents/rules.md`, line ≤64). Cheap to fix; it
should not be left for the author to find.

**O3 — the prose now outweighs the code by 1.55:1** *(measured)*. `input.lua` goes from 98 code /
49 comment lines to **114 code / 177 comment** — +16 code, +128 comment, 58% of the file. The
*mechanism* is genuinely small, and that is the right answer to the strategic frame's question:
one table, one function, one per-frame poll, one inverted map, one memoised predicate, and 16 net
lines of code to replace an order-dependent stale filter, a frame counter and two bookkeeping
handlers. **The apparatus did buy predictability.** The commentary is another matter: much of it
restates `internals/examples/keyboard.md` and the P-18 review documents in a repository owned by
someone else, who will read it as a diff. Consider trimming the header toward pointers before the
PR — the durable argument already has a home.

**O4 — a reviewer's REMARK shipped into the game** (`input.lua:130`):
`--> REMARK: what is it for? (setTextInput)`. That is the platform's own annotation notation,
left inside a third-party file, asking a question the header two screens above already answers
(*"Text input is enabled to match the IDE default"*). Delete it.

**O5 — `claimChord` is an alias for nothing** (`input.lua:58-60`): `spendGlyph` with the return
value dropped, carrying six lines of comment. This branch removed exactly such a wrapper in
`9a20433 refactor(input): call Key.is_mod directly; the wrapper was an alias for nothing`. Weak —
it does name intent at four call sites, and the name is better than the call — but it is the same
shape the branch rejected elsewhere.

**O6 — the game now depends on two undocumented platform members.** `Key.is_mod` (six files) and
`Key.is_alt` (`input.lua:277`) are exported (`src/util/key.lua:186-193`) but appear **nowhere** in
`doc/input_api.md` — "Held keys" documents only `shift/ctrl/alt/any_pressed`. The triage recorded
`Key.is_mod` as a platform doc gap owned by P10 (§3); `is_alt` joined the dependency list afterwards
in `c1ee63c` and is not recorded anywhere. Add it to that item so P10 covers both.

**O7 — restoring what was *found* pins a dirty mode on** (`main.lua:99-103`). If a run ends by
raising, `before_exit` does not fire (ratified contract) and relative mode stays `true`; the **next**
run then records `true` as `POINTER_RELATIVE_WAS` and faithfully restores `true` at its own clean
stop, so the mode never comes back. The measured-rather-than-hardcoded choice is right and I would
not reverse it; one clause in the comment naming this consequence would finish the thought that
*"but NOT on a raise"* starts.

---

## What I checked and found correct

**The mechanism itself, in both delivery orders** — measured, harness T1/T2. One character accepted
per physical press; OS repeats dropped; identical outcome whether `keypressed` or `textinput`
arrives first. R1, R2 and R5 hold. The two cases the superseded design could not serve both work:
a **doubled letter** typed as press/release/press registers twice (T3), and a **fast tap** with
press, character and release in one event batch registers (T4) — the case every earlier version of
this game dropped, i.e. R3.

**No crash on a shifted symbol, and the guard is right for the right reason** — measured in real
LÖVE 11.5: `love.keyboard.isDown` raises on `A`–`Z`, `~`, `{`, `}`, `|` and a literal `" "`, and
accepts every other name the game can produce. `glyphBaseKey` maps every one of those raising
characters to a pollable key (`" "`→`space`, uppercase→lowercase, `~{}|`→`` ` ``,`[`,`]`,`\` through
the inverted `SHIFT_MAP`), so the C5 crash is closed at the mapping; and `pollable`'s memoised
`pcall` closes it again for anything a non-US layout, IME or dead key can produce. `inputTick`
polls only names that passed that gate, so the per-frame loop cannot raise. The residue (an
unpollable character is accepted and would repeat while held) behaves exactly as documented —
measured, T18.

**A chord owns its trigger** — measured, T6 and T7, the cases this work was rebuilt for.
`Ctrl+Alt+H`, then releasing Ctrl and Alt while H stays down, puts **nothing** into the scene; same
for `Alt+H` with Alt released first while the overlay comes down. Smoke B9 and D3 should pass.

**Every reserved chord, and each exactly once per press** — measured, T8-T10, T14, T15:
`shift+escape` and `alt+shift+escape` both go back; `ctrl+alt+up/down` and both `+shift` variants
notch once and are inert on repeats; `alt+p` toggles once; `ctrl+alt+h` re-arms once and is silent
while paused; `alt+shift+`*letter* is swallowed with no knock (F3's restoration holds).

**The deliberate asymmetries survive** — measured, T12/T13/T16: a bare Alt press is swallowed and a
bare Shift press is not (upstream's asymmetry, `Key.is_alt` guard at `input.lua:277`); `capslock`
repeats still reach `capsToggle`, byte-identical in effect to upstream's exemption.

**Nothing dangles.** `INPUT`, `inputStale`, `isMod`, `modHeld`, `inputUpdateMods`, `reservedChord`,
`appChord`, `ALT_BASE`, `INPUT_UP_GRACE`, `upRecent` appear in no file except one comment in
`words.lua` that names `inputStale` as the thing it replaced. `bubble.lua` really is the only
remaining `keyreleased` consumer, as its new comment claims. `Key.is_mod`'s body is
behaviourally identical to the `isMod` it replaced (same six names).

**The real platform accepts the project.** `timeout 25 xvfb-run -a stdbuf -oL -eL love src play
src/examples/keyboard` runs clean — no `Error:` line — against a control run with a bad project path
that does report one. So shortcut registration (every combo string legal and normalising),
`compy.input.hooks.*` assignment, `compy.before_exit = …` and `love.mouse.getRelativeMode()` are all
accepted by the live framework and sandbox.

**The dispatch reasoning in the comments is correct.** `alt+*` cannot catch a bare Alt press —
`find_shortcut` returns on `Key.is_mod(trigger)` (`projectInputController.lua:110`) — and cannot
catch `Ctrl+Alt+H`, because a class is its modifier set exactly. Exact beats class. `stop_here`
consumes regardless of return; `ignore_repeat` reads argument three. `seed_hooks` runs after project
top-level code, so explicit hooks set in `inputInit` are preserved. All as the header says.

**Every citation resolves, and says what the citing comment says it says.** `user_input.md`
"Data flow" (line 56: *"LÖVE2D does not guarantee the relative order the two arrive in"*);
`input_api.md` "Held keys"; `input_api.md` "Stop hook — `compy.before_exit`" (fires on Ctrl+Esc,
does **not** fire on a raise); Decision 30 (device is the source of modifier truth; its errors are
*"bounded by one frame's batch"* — which is exactly what `indicators.lua:21-25` claims of it);
`internals/examples/keyboard.md` "Consequences, accepted" (carries the bubble ruling `bubble.lua`
points at). The one claim that is *not* correct is D3's.

**`main.lua`'s two platform claims hold.** Nothing in the runner restores relative mode — the only
`setRelativeMode` outside the example is LÖVE's own error handler (`lib/error_explorer.lua:303`),
and a project raise never reaches it (handlers are `xpcall`'d into `user_error_handler`,
`controller.lua:123-139`; top-level code is `pcall`'d). And restoring `setTextInput` really would
be a no-op: the platform sets it true at boot (`src/main.lua:297`).

**The design of record is faithful to the shipped code.** I checked
`internals/examples/keyboard.md` claim by claim against `input.lua`, `alt.lua`, `words.lua`,
`bubble.lua` and `gauge.lua`. Its account of the paradigm, the release-by-poll argument, the
`inputTick` placement, the chord rule, the two consumers, the Caps Lock exemption and the accepted
consequences all match. Its one gap is O1; its one omission is D1's rule.

**The smoke checklist has no stale rows.** No row tests a mechanism the code no longer has, which
was the specific risk the checklist's own preamble names. Its recorded commits are consistent:
keyboard `newinput` is at `646674b`, and platform `fd0e2c21` is the commit before the one that added
the table, with only two documentation commits since. What it is missing is coverage, not accuracy:
**no row for D1** (entering game 4 or 5 from the menu), **no row for D2** (`Alt+Shift+P`), and no row
for the accepted change that `Ctrl+Alt+H` is now swallowed in the key-target games where it used to
knock — the one item §8 of the triage flagged as touching the *"would a player notice"* test.

---

## Limits — what I could not verify

- **Nothing in this work has ever been run in a game scene.** Not by the implementing sessions, not
  by me. This container has no display device and cannot inject keystrokes. Every behavioural claim
  above, mine included, is either a library measurement or a simulation.
- **My harness is not LÖVE.** It reproduces the platform's dispatch chain (real
  `ProjectInputController`, real `util/key`, verbatim `combo_string` / `INPUT_FN`) over the real
  `input.lua`, but it does **not** reproduce: LÖVE's actual event ordering and batching, OS
  key-repeat timing, the real `gauge`/`sound`/scene state machines, or the window/focus lifecycle.
  Its scenes are stubs whose `textinput` is the first line of the real handlers. Where I say
  "measured", read: *measured against a faithful model of the dispatch layer and a measured model of
  `isDown`* — not against the running game.
- **I did not measure which delivery order any build uses.** D1 is order-dependent. I call it live
  rather than theoretical because upstream's deafness on desktop Linux implies keypress-first there,
  which is an inference from the owner's attestation, not an observation of mine. On a
  textinput-first build D1 does not occur.
- **The pointer restore (P-18-05) is unverified end-to-end.** I traced the call path and confirmed
  the hook fires on Ctrl+Esc, and that `love.mouse.getRelativeMode()` exists and answers. Whether
  the console's pointer actually behaves afterwards needs a pointer, a console-mode session and a
  human — and D4 says the checklist currently sends that human to the wrong launch.
- **Android / the assembled `.apk` was not exercised at all**, in any form.
- **D1's scoring consequences are read, not seen.** That `wordsBad` costs the word its gauge unit
  and `altWrong` sets `fumbled` comes from `words.lua:210-213` and `gauge.lua`; I did not watch a
  gauge.
- **`E3` (held capslock flicker) remains an open question**, unchanged by this pass and unanswerable
  here.

---

## Recommendation

Four edits, none structural: **D1** (one line in `menuKeypressed`, plus a sentence in the design of
record and a smoke row), **D2** (one hoisted handler, one extra binding, one corrected comment,
one smoke row), **D3** (correct the comment, optionally the call), **D4** (give G1 and D9 a
console-mode launch). Then O2 (rewrap 25 lines) before the PR reaches the author, and O4 (delete the
stray REMARK). O1, O3, O5, O6, O7 are judgement calls for the owner.

With D1 and D2 fixed, I would call the work sound and the gate worth a human's hour. Without them,
the two most common gestures in the game — *press 5 to play Words* and the first thing that happens
after it — are wrong in a way no row on the checklist would catch.
