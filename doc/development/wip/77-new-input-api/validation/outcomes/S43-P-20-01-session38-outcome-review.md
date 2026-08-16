# P-20-01 — session38 outcome review

**Commissioned by session43, 2026-08-16. Worker: Sonnet, read-only. Object: session38's P-18
close-out** — the keyboard-example deepfix, its four cold revalidations, and the claim that its
gesture behaviour is "provably identical to upstream, measured, not argued."

---

## Verdict

**The parity claim is sound in substance and honestly scoped — this is not the P13 failure mode.**
The harness calls the production dispatcher directly rather than going through
`love.event.push → queue → love.run's pump → love.keypressed`, exactly as CHECK 1 asked me to test
for. But unlike the P13 fixture, this is disclosed, not concealed: three separate review documents
carry an explicit "Limits" section naming exactly this gap, in the session's own words ("my harness
calls the dispatcher directly; it does not go through SDL, LÖVE's event pump, or the framework's own
`love.keypressed`" — `S38-P18-final-revalidation-3.md:298-300`, repeated near-verbatim in
`S38-P18-narrow-review.md:256-257`). I found the original harness scripts still on disk
(session38's scratchpad survived) and re-ran them myself against the current `keyboard` HEAD
(`e568961`): **108 stimuli, 0 diff against upstream**, reproducing the claim independently rather
than trusting the reports. The one place the short-circuit created a real, load-bearing, *unverified*
assumption — whether `love.keyboard.isDown` reflects a key's own press by the time its `keypressed`
handler fires — was itself surfaced by the narrow review (`F4`) and closed by a follow-up commit
(`e568961`) that removes the dependency on that assumption for the one case it mattered
(`Key.is_alt(k)`, name-based and order-free, replaces relying on the device poll for Alt's own press).

**One real process gap, not a defect**: that follow-up commit, `e568961`, is the one that actually
carries the fix to the guard under test, and it was written and self-verified *after* the narrow
review (P-18-21, the "last" independent review) had already been finalized — so it was never itself
subject to independent review, only to the session re-running its own instrument. The platform commit
that closes the step (`84b6e0c5`) calls `e568961` "the reviewed head," which overstates what happened.
This is CHECK 2's "unreviewed final batch" concern, materialized at the granularity of one commit
rather than a whole batch. See **F1** below. It did not hide a defect: I reproduced the harness's
zero-diff result against `e568961` myself.

The two regressions (menu-digit `textinput`, the sixth and fifth modifier-tolerant gestures) are
genuinely present in code, not merely recorded. No platform `src/` or `tests/` code was touched.

---

## Findings

### F1 (S2) — the branch's last behavioural commit postdates its last independent review, and the close-out mischaracterizes it as reviewed

**Timeline, reconstructed from commit timestamps and the narrow-review file's mtime** (all
`2026-08-12`, keyboard repo unless noted):

| time | event |
|---|---|
| 20:30:56 | `80bca7b` — P-18-19, closes the three bare-modifier parity deltas |
| 20:37:25 | `f09f1e7` — P-18-20, the tidy batch |
| 20:49:52 | `S38-P18-narrow-review.md` written (file mtime) — object of review is `1033252..f09f1e7`, i.e. `80bca7b`+`f09f1e7` only. Finding **F4** in that document: the just-landed guard depends on the device already reporting Alt down inside Alt's own `keypressed`, which the reviewer calls "unmeasurable here" and says "my zero-diff result assumes the thing rather than proving it" |
| 20:51:45 | `e568961` — fixes exactly `F4` ("named rather than polled"), commit message says "Raised by the narrow review... MEASURED after the change with the parity harness: still ZERO differences" — **self-verified, by the same author/session, with the same instrument, not by a fresh reviewer** |
| 20:52:10 | `534bd174` (platform) — lands the narrow-review document, unchanged from what was drafted at 20:49:52 |
| 20:52:28 | `84b6e0c5` (platform) — re-pins the smoke anchor to `e568961`; commit message: *"The anchor moves to keyboard `e568961`... **the head the narrow review's finding landed on**"* — calling `e568961` "the reviewed head" |
| 21:21:42 | `dd7a7548` — session wrap |

`e568961` is exactly the commit that carries the fix to the parity-critical guard
(`input.lua:201-211`, `appKeypressed`'s bare-Alt swallow). It is real, it is small (8 insertions, 5
deletions, one guard clause), and I independently re-ran the preserved harness against it and got the
same zero-diff result the commit message claims (see Verdict). But no independent cold pass ever read
its diff — the narrow review's text, verifiably, was already finalized before the commit existed.
Framing it in `84b6e0c5`'s message as "the reviewed head" is not accurate: it is the head a review's
*finding* produced, self-verified, not the head a review *read*.

This is precisely the shape of thing CHECK 2 asked me to watch for ("an unreviewed final batch is the
plausible weak point — say so plainly if you find it"), materialized at commit granularity. I rate it
S2 rather than S1 because I could independently confirm the commit does what it claims and introduces
no diff against upstream — the gap is a process violation of the session's own four-independent-passes
contract, not a defect it let through.

### F2 (S3) — the session report's headline phrase overstates what the harness itself claims

`implementation/sessions/session38/report.md:8`: *"ended with the game's gesture behaviour **provably
identical to upstream**."* Read alone this could be taken as an event-loop-level guarantee. It is not
— the harness is dispatcher-level, not event-loop-level (see Verdict), and the same report says so
plainly 80 lines later (`report.md:87-89`: *"Nothing in this work has ever run in a game scene, at any
head, by anyone. Every claim about what a player sees is inference from driven paths."*). The
qualifier exists, just not adjacent to the headline claim it should be attached to. Low severity: the
report is self-correcting within its own length, and the review chain underneath it (three separate
"Limits" sections) is unambiguous about scope. Worth a wording fix if anyone revisits this document;
does not change any decision that rests on it.

---

## What I verified clean

- **CHECK 1, the harness itself** (found on disk, not just described): `/tmp/claude-1000/-repo/6f512c55-e690-4ef3-9962-d6ea3490f5cb/scratchpad/{drive_new,parity,run_new,run_up}.lua` and
  the `rv_*` family survived from session38's container. `drive_new.lua:53` (`dofile("/repo/src/examples/keyboard/input.lua")`) and `parity.lua:112-127` load the **real** `input.lua`, the real
  `require("controller.projectInputController")`, and the real `require("util.key")`; `Controller.combo_string`/`any_mod`/`INPUT_FN` are verbatim copies of `controller.lua`/`consoleController.lua` locals (I diffed the copies' logic against
  `projectInputController.lua:104-114`'s `find_shortcut` behaviour and `key.lua`'s mod folding — matches). The driver calls `PIC:keypressed(m, m, false)` (`run_new.lua:13,17`), where `PIC = ProjectInputController()` (`drive_new.lua:57`) — and I confirmed in production code
  (`controller.lua:236-249`, `controller.lua:527`) that `love.keypressed` is bound to exactly
  `pic[k](pic, ...)` wrapped in `with_canvas_and_errors`. So the harness calls the **real production
  dispatch chain** (shortcuts → hooks → widget, `projectInputController.lua:135-145`) directly —
  it does not traverse `love.event.push`/the queue/`love.run`'s pump, and it does not exercise the
  `with_canvas_and_errors` wrapper. This is a genuine, disclosed short-circuit of the queueing layer,
  not of the dispatch/decision logic under test.
- **Independently reproduced the zero-diff result**: `luajit run_up.lua` (upstream, byte-identical
  copy verified: `diff <(git show 025e858:input.lua) up_input.lua` → identical) vs `luajit run_new.lua`
  (current `keyboard` HEAD `e568961`, since the script's `dofile` path is hardcoded to
  `/repo/src/examples/keyboard/input.lua`) → **108 lines each, `diff` → empty**.
- **F4's resolution, read against the diff**: `input.lua:208-211` (`e568961`) —
  `local alt = Key.alt() or Key.is_alt(k)`; `Key.is_alt(k)` is a name test on the trigger, order-free,
  so Alt's own press no longer depends on the device poll seeing it; other modifiers' presses (Shift,
  Ctrl) still use `Key.alt()`, which is safe since by the time *their* `keypressed` fires Alt has
  already been down for at least one prior event.
- **CHECK 3, the two regressions**:
  - Menu digit: `src/examples/keyboard/menu.lua:93-94` — `spendGlyph(k)` runs before `gotoScene(id)`.
  - Fifth gesture (`Alt+Shift+P`): `input.lua:80-81` — `sc["alt+p"]` and `sc["alt+shift+p"]` both bind
    to the same `pause` closure.
  - Sixth gesture (`Ctrl+Alt+Shift+H`): `input.lua:86-87` — `sc["ctrl+alt+h"]` and
    `sc["ctrl+alt+shift+h"]` both bind to the same `hint` closure.
  - Both counts this batch fixed check out against the current tree: `technical_debt/input.md:1516-1517`
    now says "twelve" (twelve `sc[...] =` assignments counted at `input.lua:69-89`); smoke checklist's
    `108` (not the stale `105`) appears at `smoke_checklists.md:44`; rows `B13` and `D10` are present
    (`smoke_checklists.md:87,114`).
- **CHECK 4, no platform code touched**: `git log dd7a7548~22..dd7a7548 --name-only -- src/ tests/`
  is empty — confirmed directly, not from the session's own claim.
- **CHECK 2, batch review coverage in general**: each of the three reopenings (`P-18-07…13`,
  `P-18-14…18`, `P-18-19…21`) does have its own cold-pass report on disk
  (`S38-P18-final-revalidation.md`, `-2.md`, `-3.md`, plus the narrow review for the third), each
  claiming to be independent and cold, each with its own "Instruments"/"Limits" sections rather than
  reasoning from the commit messages. The **only** gap is `e568961`, per **F1**.
- **Test suite sanity**: `busted tests` on current `/repo` HEAD reports `947/0/0/10`, one more than
  session38's recorded `946/0/0/10` at wrap; `git diff --stat dd7a7548 HEAD -- tests/` shows the delta
  is entirely later sessions' work (`tests/harmony_input_spec.lua` etc.), not session38's — consistent
  with CHECK 4's "no platform code touched" holding at `dd7a7548`.
- **Prompt-of-record path drift, incidental**: the prompt cites the four reports as living under
  `../outcomes/S38-P18-*.md`; they are actually under `../reviews/S38-P18-*.md`. Noted for the record;
  not a session38 defect (a wrong path in the *reviewing* prompt, not the reviewed work).

---

## What I could not check, and why

- **Real event-loop-level parity** (SDL → `love.event.push` → `love.run`'s pump → `love.keypressed`,
  with the `with_canvas_and_errors` wrapper live) was not measurable by session38 and is not
  measurable by me either: this container has no display and cannot inject real keystrokes
  (`xvfb-run` gives a headless GL context, not an input device). This is the same limit the four cold
  passes already named and handed to the human smoke gate (`doc/development/smoke_checklists.md`,
  eighteen `[new]` rows) — I have nothing to add to it beyond confirming it is real and correctly
  attributed, not swept under a "measured" claim.
- **The Android/device build** — untested here, as session38 also states; out of this container's
  reach entirely.
- **Whether `84b6e0c5`'s "reviewed head" wording was a deliberate compression or an oversight** — I
  can only report what the timestamps and the commit message say; intent is not recoverable from git
  history.
