# FEAT-02 — cold peer review

**Verdict: approve with comments.**

The code does what the owner ruled, and it does it in five lines. `auto_hide` is
seated in `configure_core` and nowhere else, so both entry points set it by the
same statement; `~= nil` is the set-if-given test, so `false` unsets; the flag is
never cleared anywhere, so it persists; and nothing of the show-only shape
survives — the unconditional seat in `open_widget` is gone and the key is out of
`SHOW_ONLY_KEYS`. I mutated the source six ways and every ruled property has a
test that catches its inversion. The two claims the sprint asked me to verify
rather than assume — no text getter, and read-after-the-callbacks being
load-bearing — are both true, and I reproduced the second exactly.

The comments below are four documentation defects and two nits. Two of them
matter: the project-facing guide still teaches the code this sprint deleted from
`turtle`, and states a re-arming rule that `auto_hide` breaks; and the ledger
entry the sprint wrote to rule the persistence contains one clause that
contradicts it. Both are the sprint's own blast radius, and both are the
silent-trap class this feature keeps naming: right-looking, wrong, no error.

**Reviewer's own verification, re-run here rather than taken from a document:**

- `busted tests` from `/repo`: **1023 successes / 0 failures / 0 errors / 10
  pending** — matches the claim. (Container interpreter; I did not check PUC Lua
  on the owner's machine.)
- Test arithmetic reconciles: two cases inverted in place (`it is spent by its
  own show` → `a later bare show still closes on submit`; `configure raises on
  oneshot, naming show()` → `a widget armed at configure closes on submit`) and
  two added, so 1021 + 2 = 1023.
- `lua-language-server` diagnostics on `src/controller/userInputController.lua`
  and `src/controller/consoleController.lua`: clean.
- Working tree left as I found it. **I mutated `src/controller/*.lua` seven times
  and reverted every one** (`git status` clean for `src/controller/`); I also
  created and deleted a scratch spec `tests/input/zz_tmp_probe_spec.lua`, and
  created and removed a git worktree at the base commit.

---

## Finding 1 — the guide still teaches the code this sprint deleted, and its re-arming rule is now false

**`doc/input_api.md:735-754`. Severity: medium. Confidence: certain.**

**What is wrong.** Two things in the same section, *"Worked example: the trigger
key echoes into the widget it opened"*:

1. The code block at `doc/input_api.md:744-748` is, verbatim, the `after_submit`
   the sprint just removed from `src/examples/turtle/main.lua`:

   ```lua
   compy.input.callbacks.after_submit = function()
     compy.input.hide()
     arm_echo_guard() -- the next open needs a fresh one-shot
   end
   ```

   The worked example is derived from `turtle` — same `'i'` trigger, same guard,
   same wording — and `src/examples/turtle/main.lua:54-56` cites this section
   **by name**. The in-tree example now says `auto_hide = true` +
   `after_submit = arm_echo_guard`; the page it points a reader at says the
   opposite. The citation still resolves and no longer means what it did.

2. Worse, because it is a rule and not an illustration —
   `doc/input_api.md:751-754`:

   > **Re-arming** ... is needed wherever you close the input widget: one closed
   > without a fresh guard takes the echo on its next open. **Only your own
   > `hide()` calls need this** — Escape *clears* the field without closing, so
   > the spent one-shot is still correct.

   "Only your own `hide()` calls need this" is **false as of this sprint**.
   `auto_hide` closes the widget, and a widget closed by `auto_hide` needs the
   re-arm exactly as much as one closed by hand. That is precisely what `turtle`
   now does — it keeps an `after_submit` purely to re-arm, while the close comes
   from the flag — so the repo's own example is the counterexample to the
   sentence.

**How I verified it.** Read `doc/input_api.md:719-758` against
`src/examples/turtle/main.lua:54-81` and against `submit_flow`
(`src/controller/userInputController.lua:478`). The close at 478 is a `hide()`
the project did not write, and nothing in the echo-guard machinery is aware of
it.

**Consequence.** A project author who reads *"Asking one question — `auto_hide`"*
(`doc/input_api.md:249`), adopts the flag, and then reads the echo-guard section
concludes no re-arm is needed. Their trigger character lands in the field on the
second open. Nothing raises, nothing warns.

**What I would do.** Rewrite the worked example on `auto_hide` (it is now the
shorter and better answer), and change the re-arming rule to name **every** close
— your own `hide()`, and `auto_hide`. One sentence: *"any close needs a fresh
guard, whether you called `hide()` or `auto_hide` did."* The ROADMAP's
`FEAT-02-04` obligation was *document the persistence and the teardown edge*; it
was met, but it did not send anyone back to the one other place in the guide that
reasons about closing.

---

## Finding 2 — Decision 36's own "what it does NOT fix" paragraph contradicts the amendment above it

**`doc/development/decisions/input.md:1580`. Severity: medium. Confidence:
certain (reproduced).**

**What is wrong.** The paragraph is new in this sprint (the whole block is a `+`
in `git diff 4811a4e5~1..HEAD -- doc/development/decisions/input.md`; the base
had no such paragraph). It closes:

> The escape is to re-show **after** the widget is down, **or to leave the
> follow-up plain**; `doc/input_api.md` says so.

Leaving the follow-up plain is exactly what no longer works. Under the persistent
mode the amendment rules four paragraphs earlier, a follow-up that says nothing
about `auto_hide` inherits it and is closed by the submit still in progress. And
`doc/input_api.md` does **not** say so — it says the opposite, at
`doc/input_api.md:293-297`: *"a follow-up that says nothing about `auto_hide` is
closed straight away, before the user can type into it ... `show{force = true,
auto_hide = false}` is the follow-up that survives."*

**How I verified it.** A scratch spec through the public surface:

```lua
input.show({ text = 'a', auto_hide = true,
  on_text_entered = function()
    input.show({ prompt = 'again?', force = true })   -- plain follow-up
  end })
F.session.press('return')
-- VISIBLE_AFTER_PLAIN_FOLLOWUP = false
```

Three other documents in the sprint's own output agree with the probe and against
the ledger: `technical_debt/input.md:1275-1277` (*"still closed ... unless it
passes `auto_hide = false`"*), `doc/input_api.md:291-298`, and the sprint's note
`validation/notes/auto-hide-persistence-vs-the-forced-follow-up.md` (*"Silence is
no longer a disarm"*). So this is a single stale clause, not a disagreement about
the ruling.

**Consequence.** It is in the **decisions ledger** — the most durable place in
this repo for a wrong statement, and the one a later implementer is told to treat
as authority. It also mis-cites the guide, so a reader who checks the citation
finds a contradiction and has to decide which document is lying.

**What I would do.** Delete the clause. The paragraph is otherwise correct and
the escape it should name is the one the guide names: pass `auto_hide = false` on
the follow-up, or re-show after the widget is down.

---

## Finding 3 — the turtle smoke checklist's row A6 cannot be run as written

**`doc/development/smoke_checklists.md:517-518`. Severity: low-medium.
Confidence: certain.**

**What is wrong.** A5 and A6 are in the wrong order for the state each leaves
behind:

| | do | expect |
|---|---|---|
| A5 | press `i`, press Enter on the **empty** field | nothing happens and **the prompt stays open** |
| A6 | **press `i`**, type `left`, then press **Escape** | the line clears and the prompt stays open |

A5 deliberately ends with the prompt **open** — that is its whole point. A6 then
opens with "press `i`". With the prompt already up, `love.keyreleased` declines
to re-show (`src/examples/turtle/main.lua:92`, `not compy.input.is_shown()`), and
the echo guard is **spent**: it was consumed by A5's open and never re-armed,
because an empty submit early-returns before `after_submit`
(`src/controller/userInputController.lua:462`). So the `i` is typed into the
field as ordinary content and the tester types `ileft`.

A6's stated expectation still nominally holds after Escape, so the row does not
*fail* — it is worse than that. B2, eleven rows later, has just told the tester
that *"a stray `i` here means the guard was not re-armed"*. A6 manufactures
exactly that symptom for an unrelated reason and invites a false defect report
against `FEAT-02`.

**How I verified it.** Traced `src/examples/turtle/main.lua:39-103` against
`submit_flow`'s empty-field early return; the shortcut table lives on the surface
(`consoleController.lua:894-905`), not on the widget, so nothing re-registers it
at hide or show.

**What I would do.** Either put A6 before A5, or open A6 with *"the prompt is
still open from A5 — type `left`, then press Escape."*

---

## Finding 4 — the one behaviour the sprint changed for existing project code has no test

**`tests/input/input_widget_callbacks_spec.lua:616`. Severity: low.**

The sprint's own note calls it *"a deviation from pre-change functionality"*: a
follow-up `show{force = true}` from inside the submit chain **survived** under
`FEAT-01` and is **closed** now. The inverted case pins only the *disarming*
follow-up. Nothing in the suite fails if the plain-follow-up behaviour moves
again, in either direction — including a future "fix" that restores the implicit
disarm and quietly re-introduces the show-only semantics `FEAT-02` retired.

I checked the four new/inverted cases individually and they all discriminate
(table below), so this is a gap at the edge of the sprint rather than a weak
test. But it is the gap over the one case where a working project changes
behaviour silently, and it is one `assert.is_false(F.is_widget_visible())` away.

**What I would do.** Add the negative beside the positive, cross-referencing the
note: *"a plain forced follow-up does not survive"*.

---

## Finding 5 — `WIDGET_KEYS` is labelled "NOT sticky", which reads as the opposite of the ruling

**`src/controller/consoleController.lua:613-615`. Severity: low (comment
accuracy).**

This file defines its own vocabulary at `consoleController.lua:578-581`:

> **STICKY:** one `state` entry each, shared by the config key and the direct
> `compy.input.callbacks` write, and **kept across shows**.

The new block then says:

> Project-owned and **NOT sticky**: these land on the widget itself rather than
> in the store above, and persist with it.

`auto_hide` *is* kept across shows — persistence is the entire ruling, and
`prompt` behaves the same (I confirmed `clear_input` does not touch
`custom_label`: `src/model/input/userInputModel.lua:363-368`). Both kinds also
"land on the widget": `state.callbacks` resolves through `widget_store`
(`consoleController.lua:717-725`) to the widget's own table. The real distinction
is *which code applies them* — `merge_callback_keys` versus `configure_core` —
not stickiness or ownership.

**What I would do.** Drop "NOT sticky" and say what differs: these are applied by
`configure_core` and have no `state` entry, because nothing writes them through a
second channel the way `compy.input.callbacks` writes the callbacks.

---

## Finding 6 — the sprint pushed a compliant line over the 64-char limit

**`src/examples/turtle/main.lua:58`. Severity: nit.**

`-- key in no guaranteed order. This one-time guard eats that echo` is 65
characters. It was 59 at the base (`This one-shot eats that echo`); the rewording
put it over. `agents/rules.md:33` sets the hard limit at 64, and
`agents/rules.md:156` calls the surrounding practices *"mandatory in
student-facing examples"*.

The file's overall count is unchanged (7 lines over 64 before and after — the
sprint deleted one overflow and added this one), so a line-count check does not
catch it. Six of the seven are pre-existing and out of scope per the
*don't-size-refactor-another-author's-file* rule; this one is the sprint's.

---

## What I checked and found correct

**The ruling, against the code** — all mutation-verified. I edited
`src/controller/*.lua`, re-ran `busted tests`, and restored the file each time:

| mutation | result | reads as |
|---|---|---|
| delete `if self.auto_hide then self:hide() end` | 4 failures (`callbacks_spec` 517, 549, 584; `control_spec` 161) | the close is pinned from both entry points |
| capture the flag **before** the callbacks | **exactly 1** failure — `a disarming forced follow-up survives the close` (616) | reading after the hooks is load-bearing; **the sprint's claim is true, reproduced** |
| `if cfg.auto_hide ~= nil` → `if cfg.auto_hide` | 3 failures (597, 616, `control_spec` 175) | `false` really is the unset, at both calls |
| clear the flag when it fires (consumption semantics) | 1 failure — `a later bare show still closes on submit` (584) | persistence is pinned, and the withdrawn clearing rule would be caught |
| `auto_hide` accepted at `show` only | 2 errors (`control_spec` 161, 175) | `configure` genuinely takes it; `check_keys` would raise |
| make `configure` clear the draft | `disarming at configure keeps the draft` (175) fails | the draft assertion discriminates, not decoration |

**Reachable cases I constructed and found correct** (scratch spec, deleted):

- `configure{auto_hide = true}` on a **hidden** widget, then a bare `show` →
  closes on submit. Matches `doc/input_api.md:170-173`.
- the mode **does not survive a run**: a second `F.activate_project()` builds a
  fresh widget and a bare `show` stays open. The flag lives on the controller,
  which `build_input_widget`/`destroy_input_widget` create and drop per run
  (`consoleController.lua:200-219`), so the owner's *"project exit tears it
  down"* holds without machinery, exactly as ruled.
- `configure` **between runs** is inert, not a raise —
  `api_configure`'s `if ui then` (`consoleController.lua:786`).
- a project that **never names the key**: `self.auto_hide` is never initialised
  in `new` (`userInputController.lua:29-44`) and `nil` is falsy, so the guard at
  478 is a plain no-op. No behaviour change for any existing project.
- **`force`**: a forced show runs the same `open_widget` → `configure_core`, so
  it neither arms nor disarms unless it names the key. Consistent with
  set-if-given, and the documented idiom (`doc/input_api.md:276-278`) is right,
  though its "a forced `show` would also disarm it" is elliptical — it means the
  forced form of the `show{auto_hide = false}` in the block above, and a hurried
  reader could take it as "`force` disarms". Worth one word.

**Console and editor widgets are unreachable, verified structurally.**
`love.state.user_input_controller` is written in exactly one place —
`build_input_widget` (`consoleController.lua:206`), the project widget — and that
is the only handle `build_widget_api` resolves (`consoleController.lua:917-920`).
The console's widget is `cc.input` and the editor's is its own; neither is ever
published, so `compy.input.configure` cannot reach them and `self.auto_hide` on
an `always_shown` widget is not a constructible state. `hide()`'s
`if self.always then return end` is a second line of defence, not the only one.

**The two facts I was asked to verify rather than assume:**

- **No text getter.** `build_widget_api` (`consoleController.lua:816-882`)
  returns exactly `show`, `hide`, `is_shown`, `get_cursor`, `set_cursor`,
  `set_text`, `configure`, `clear`. There is no `get_text`, and
  `build_input_surface` resolves only `shortcuts` / `hooks` / `fn` / `callbacks`
  plus those methods. So a forced re-setup destroys a draft nothing can restore —
  the defect Decision 36's *"What it fixes"* claims, and it is real.
- **`oneshot` in-tree.** The surviving tokens are the profiler
  (`controller/profiler.lua:15-60`, `controller/controller.lua:842,1080-1082`,
  and the reserved-combo test at `input_global_shortcuts_spec.lua:338`), two
  historical comments about the deleted model field
  (`view/input/userInputView.lua:290`, `model/input/userInputModel.lua:436-439`),
  and the vendored metalua compiler (`src/lib/metalua/...`, unrelated). The
  sprint's claim is accurate; it just did not mention metalua or the mermaid
  diagrams. The diagrams (`doc/mermaid/{input,editor,classes}.md`) still list
  `oneshot: boolean`, but that is **filed, not missed** —
  `technical_debt/input.md:29-44` (`T-MERMAID-MODEL`) and `FIX-02-24`, with the
  right reason for deferring (the drift is presumed wider than one line).

**Documents, read against the code:**

- `src/types.lua:192-201, 244-248` — correct on both counts, including the
  `configure`-takes-everything-but-the-show-only-keys note the sprint fixed.
- `doc/development/decisions/input.md:1379` — the project-owned row now carries
  `auto_hide` and says "persisting until replaced"; the show-only paragraph at
  1382-1387 states the two reasons correctly and does not pretend the old ground
  was never ruled.
- Decision 36's superseded edge 1 is **marked and kept**, not rewritten
  (`decisions/input.md:1507-1513`) — the standard `ARC-01-03` was held to.
- Decision 15 (`decisions/input.md:518-560`) never named the key, so there is no
  drift there. I checked.
- `doc/development/internals/user_input.md:660-694` — the `submit_flow` snippet
  matches the source line for line, and the persistence paragraph is accurate.
  (Pre-existing nit, not this sprint's: the snippet's line 664 calls the helper
  `gate`; it is `validate` in the source. Introduced at `6157222a`.)
- `technical_debt/input.md` — `T-ONESHOT-SCOPE` and `T-ONESHOT` both retired with
  correct resolutions, and `T-ONESHOT` carries the explicit *"read the paragraph
  above as history, not as behaviour"* marker. That is the right treatment.
- `CHANGELOG.md:24-32` — in `CURRENT_SCOPE`, which is unreleased, so renaming an
  entry in place is correct and no `Changed` line is owed. The "mode, not a
  one-off" wording is the one a project author needs.

**The example.** `src/examples/turtle/main.lua` is behaviourally equivalent to
its old shape, which I checked rather than assumed:

- old order was `hide()` then `arm_echo_guard()`; new order is `arm_echo_guard`
  then the framework's close. Immaterial — the guard writes
  `compy.input.shortcuts.textinput['i']`, which lives on the surface's own combo
  table (`consoleController.lua:894-899`), not on the widget, so shownness does
  not affect the registration.
- `after_submit` is now `arm_echo_guard` directly and receives `lines`
  (`userInputController.lua:469`); it ignores its argument, so no change.
- every early return of `submit_flow` suppresses both the old hand-written hide
  and the new close identically, so the empty-submit and rejected-validator paths
  are unchanged.
- a raise in `on_text_entered` unwinds past both, so `eval` blowing up leaves the
  widget standing in both shapes.
- the commands the checklist lists match `src/examples/turtle/action.lua` exactly,
  and A2's "moves up" matches `moveForward` (`ty = ty - incr`).

**The checklist, apart from Finding 3.** Rows A1-A5, B1-B4, C1-C4 and D1-D2 are
runnable and match the code; A3 is a genuinely good row (it is the one that
catches a flag that clears itself, which is the withdrawn rule); the launch
command matches the four existing sections and `agents/context.md:23`; the
"what a failure here means" section correctly routes A3 to the platform rather
than to `turtle`.

**Style.** Function bodies, parameter counts and nesting are all within limits —
`configure_core` is 11 statement lines with the comment excluded, which
`agents/rules.md:44-45` explicitly permits. No added line in `src/controller/` or
`tests/` exceeds 64 characters (the only two overlong added lines are in
`turtle`; see Finding 6).

---

## What I could not check, and why

- **The manual smoke pass itself.** It needs a human, a display and key presses;
  I reasoned about the rows against the code but did not run `love`. Finding 3 is
  from that reading, so a human running the list will hit it before I could.
- **PUC Lua on the owner's machine.** The suite is green here; per the standing
  note, container-green is not their-machine-green. The change touches no
  interpreter-sensitive construct (`~= nil`, a field write, a table entry), so I
  have no specific concern — only no evidence.
- **The `serial` API author's expectations.** Decision 36 records that the
  capability was requested under the old name by a developer outside this repo,
  and the amendment accepts losing that name. That surface is not in this tree
  and I could not weigh the cost.
- **The workspace bookkeeping** — `sessions/session58/track.md`, the ROADMAP's
  crosswalk, and the pre-execution review `FEAT-02-case-and-executability.md`. I
  read the crosswalk and the `FEAT-02` rows for what they commit the code to, and
  the note
  `validation/notes/auto-hide-persistence-vs-the-forced-follow-up.md` because it
  makes checkable claims about behaviour (it is correct, and its third run is the
  one I reproduced). I did not audit the session logs; nothing in the code
  required them, which is a point in the work's favour.
