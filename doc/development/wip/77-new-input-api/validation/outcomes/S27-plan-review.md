---
description: Cold review of S27-triage-and-plan.md, from outside the session that produced it
status: final
audience: session27 (parent), owner
authored: llm (Fable, cold advisor)
reviewed: none
---

# S27 plan review — cold read

**Reviewing:** `../reviews/S27-triage-and-plan.md`. Read-only; no source, test,
doc, or plan edit made. `lua-lsp` (MCP) was unavailable for this session —
every `references`/`definition` call returned a broken-pipe error after
retries. All impact claims below are therefore grep-plus-manual-trace, used
as the standing rules direct when the LSP is unusable; I flag this once here
rather than caveating every citation.

## Required changes, ranked

**Must fix before implementation starts:**

1. **Freeze decision numbering before W9 touches the ledger.** 69 in-source
   comments across 7 files cite decisions **by number**
   (`grep -rn "Decision [0-9]" src/` → `src/util/key.lua`, `src/main.lua`,
   `consoleController.lua`, `projectInputController.lua`,
   `userInputController.lua`, `controller.lua`, `src/examples/keyboard/input.lua`).
   W9(a) proposes striking Decisions 6, 7, 12, 15, 16 as non-decisions. If
   that means deleting their sections outright, every decision numbered
   above the lowest deletion (17–25) either renumbers — silently invalidating
   an unknown subset of those 69 citations — or leaves a gap. The plan states
   neither choice. `decisions/input.md` already has the safe precedent
   in hand: Decision 11 was retired **in place** ("SUPERSEDED IN PART... see
   Decision 25"), number kept, content marked. W9 should commit explicitly to
   the same move — tombstone, don't renumber — and say so in the plan, not
   leave it to whoever executes P10 to improvise. This is exactly the
   "silently invalidated by a later phase" failure question 4 asks about, and
   it is real, not hypothetical.
2. **Correct P5's stated dependency.** The phase table gives P5 (W5,
   `before_submit`/`before_cancel` veto) `Depends on: P1` only. But
   `UserInputController:keypressed(k, keys_pressed, isr)`
   (`userInputController.lua:495`) is the same signature W1 drops
   `keys_pressed` from, and `keys_pressed` is what flows into
   `submit_flow`/`cancel_flow` and out through `before_submit(keys_pressed)`/
   `before_cancel(keys_pressed)` (`userInputController.lua:413-436`, and
   `doc/input_api.md:75,94`). P5 and P2 touch the same parameter on the same
   method. The linear table order happens to save this (P2 precedes P5), so
   nothing breaks in practice — but the dependency column is wrong, and a
   plan whose own "should I reorder this" answer is only correct by
   coincidence is the thing to fix, not leave.

**Should fix:**

3. **Name the `examples/keyboard` regression explicitly, don't fold it into
   "incl. the examples."** `appKeypressed(k, _, isr)`
   (`src/examples/keyboard/input.lua:142`) reads `isr` positionally as the
   **third** argument, matching today's `(k, keys_pressed, isr)` payload.
   After W1 drops `keys_pressed`, dispatch calls `hooks.keypressed(k, isr)` —
   two arguments — and the *same, unmigrated* function would silently bind
   `_=isr, isr=nil`. `appKeypressed`'s repeat filter
   (`if isr and k ~= "capslock" then return end`) would then never fire, so
   held-key repeats stop being filtered — no crash, no error, no test
   failure unless one specifically probes it. This is precisely the failure
   class session26's report names twice ("green and blind"; the `wrap`
   arity bug that "vanished silently"). P2 already says "incl. `ignore_repeat`
   and the examples," which is enough intent but not enough evidence that
   whoever executes it will find this specific gotcha before shipping it.
   Name the file and the exact regression in P2's own text.
4. **The three nested repos have no automated tests** — confirmed:
   `find src/examples/{balloons,maze,keyboard} -iname "*spec*" -o -iname
   "*test*"` returns one static spec doc (`balloons/docs/spec_baloons_v2.md`),
   no runnable suite. P9's gate is "one commit per repo, never pushed" —
   no re-verification step. Given the confirmed silent-regression risk in
   (3), and this project's own repeated experience that this class of bug is
   only ever caught by driving the actual app, P9 needs an explicit
   smoke-test re-pass on the channels W1/W2/W3 touch (at minimum
   `examples/keyboard`, since it's the one real hook consumer that reads a
   dropped positional argument), not just "committed."
5. **W2's "button in the combo" question is framed as fully open; it isn't.**
   R115 — a *member of W2's own remark list* — is the owner's inline note at
   `decisions/input.md:1063`: *"combo is constructed from modifier keys
   pressed, no trigger key"*. That's a direct answer to the sub-question the
   plan poses back to the owner as undecided. An owner remark is correctly
   not an automatic mandate (question 2's own framing), so re-confirming at
   P1 is still right — but the plan should present modifier-only, no button
   vocabulary, as its own recommendation (traceable to R115), not as a coin
   flip. Left as stated, it invites scope to grow toward a second trigger
   vocabulary the owner already leaned against.

**Taste:**

6. W1's own framing ("drop `keys_pressed` ... so they equal LÖVE's") is
   accurate for `textinput` and every pointer channel, but overclaims for
   `keypressed` specifically: LÖVE's real signature is `(key, scancode,
   isrepeat)`, and `set_love_keypressed`'s gateway already discards
   `scancode` (`controller.lua:499`, `local function keypressed(k, _, isr)`)
   — recorded separately in `technical_debt/input.md`, "Combo triggers are
   key-name-only." Post-W1, `hooks.keypressed` becomes `(k, isr)` — closer to
   LÖVE, not identical to it. Worth one clause so nobody reads "equal to
   LÖVE's" and is surprised scancode still isn't there; not worth blocking
   anything over.

---

## 1. Is the plan's central bet right?

Mostly, and the plan already hedges correctly where it should. It is **not**
actually proposing to land W1–W4 as one commit — the phase table splits them
into P2/P3/P4/P6, each its own commit, gated together at P1 only because
they need the same owner attention in one sitting. That structure is sound
and I would not force a different split.

Where the "one movement" framing overstates itself is the *dependency
graph*, not the *bundling*: P3 (W3) is marked `Depends on: P2`, but nothing
in W3 (unifying the `singleclick`/`doubleclick` seeding lists, generalising
`reset_compy_input`'s wipe) touches the payload shape W1 changes — I found
no code path linking them. P4 (W2) genuinely can proceed independently of
W1 too: pointer channels already call `_dispatch(event, nil, ...)`
(`projectInputController.lua:203-205`) with `trigger = nil`, and a
modifier-only combo built from `Controller.keys_pressed` needs nothing W1
removes. The one *real* precondition is W4 on W1 — collapsing the three
keyboard methods into a `pointer_channel`-shaped loop only works cleanly
once their payload construction stops being bespoke (`held_keys()` inserted
mid-argument-list). That's the one dependency claim I'd keep as stated.

**On "more predictable or merely more elaborate":** split the four by what
they do to total mechanism, and the answer differs by item. W1, W3, and W4
each **remove** something — a signature divergence, two lists that must
agree, ten near-identical installers. Those pass the test cleanly. W2
**adds** something — a combo tier that does not exist today for pointer —
and is the one item in the set that should be held to the higher bar the
strategic frame implies for anything that isn't strictly convergence. The
plan already treats it that way (most hedged verdict, most open questions),
which is the right instinct; my only pushback is finding #5 above.

## 2. Scope creep dressed as convergence?

I would not reinstate any of the five declined items (R080, R121/R122,
R017's separate-file idea, R030, R181) — I re-derived R080 independently
below (question 5) and land in the same place; the other four are argued
honestly on both sides in the plan's own text and the "no defect behind it"
test is the right filter.

On what to cut: nothing in W1/W3/W4/W5/W7/W8/W9 reads as scope creep — each
is either removing duplicated mechanism or fixing a doc that misdescribes
shipped code, both squarely inside "PR reviewable from `doc/input_api.md`
alone." **W2 is the one item worth a tighter leash**, not a cut: the owner's
own framing at the top of this commission ("full unification of
pointer/keyboard/singleclick routing") supports adding a combo tier to
pointer as *completing* unification rather than *extending scope* — keyboard
already has shortcuts, so pointer lacking them is the asymmetry, not the
symmetry. But "which channels get a tier" left open invites drift toward
`mousemoved`/`wheelmoved` combos that no smoke-test finding (SM1, the paint
right-click miss) actually needs — SM1 only requires `mousepressed`. I'd
have the plan say so: ship `mousepressed` only unless the owner asks
otherwise at P1, not leave the channel list open alongside the button
question.

## 3. The breaking change

Gating behind P1 is proportionate — nothing has shipped, the full caller set
is enumerable, and the plan already enumerates it correctly at the
grep-verified level: only `examples/keyboard` and `examples/turtle` touch
`compy.input.hooks`/`shortcuts` among the shipped examples
(`grep -rln "hooks\.\(keypressed\|keyreleased\|textinput\)\s*=\|shortcuts\." src/examples/`),
`turtle` only ever reads its handlers' first positional argument so it is
unaffected, and `maze`/`balloons` never touch the hook/shortcut surface at
all (their SM3/SM4/SM5 findings are unrelated to W1). Where the migration
surface is *under*-specified, not *wrong*, is the one real hit —
`examples/keyboard`'s `appKeypressed` — covered in required-changes #3/#4
above. With that named explicitly, I'd call the handling proportionate.

## 4. Ordering

Code → tests → docs → comments is the right call, and it's the lesson this
project already paid for once (session26: "an assistant writes 'currently
the system does X'... including parts it had just invented" — prose written
before the code settles is prose written twice, or worse, prose that
describes intent as fact). I found two dependency-table defects, both
covered above: P5's understated dependency on P2 (#2), and the decision-
renumbering risk between P10 and P11 (#1) — the second is the one genuine
"silently invalidated by a later phase" case I found; the first is cosmetic
because the linear order already saves it.

I looked for a third class of problem — an item whose *test* would be
written against a soon-to-change contract — and didn't find one beyond the
renumbering risk and P5/P2. W8 (test restructuring) is correctly gated to
run only after P2–P7 land, which is the right guard against exactly this.

## 5. R080 — the widget as a special tier

**I agree with the plan: decline it**, and I can tighten the argument with
two facts the plan doesn't cite:

- `dispatch` already discards whatever `widget[event]` returns —
  `widget[event](widget, ...); return true` unconditionally
  (`projectInputController.lua:114-117`) — and **no**
  `UserInputController:*(event)` method returns anything today; I checked
  `keypressed`, `textinput`, `keyreleased`, `mousepressed`, `mousereleased`,
  `mousemoved`, `wheelmoved`, the three touch stubs — none has a `return`
  statement. Making the widget "just another chain element" isn't a
  small edit at the dispatch call site; it's inventing roughly ten new
  boolean-consumption contracts from nothing, each needing its own answer to
  "what does it mean for the widget to decline this specific keystroke."
- There is no fourth tier after the widget for a manufactured `false` to
  fall through to. `dispatch`'s return value is only observed by tests —
  in production it becomes `love.keypressed`'s return, which LÖVE's own
  event pump discards. So the change would add real surface (ten new
  contracts, presumably ten new test rows) for **zero** runtime behavior
  difference. That fails the strategic frame's own question directly: it is
  strictly more elaborate, not more predictable.

One thing worth telling the owner directly, since it's a factual correction
rather than a design argument: R080's own text is attached to Decision 2
but reasons from "discard Decision 5" — and Decision 5 (not 2) is the actual
rule the widget's missing return value falls out of: results travel out
through callbacks, not chain return values, because the widget is terminal
and nothing sits above it to read one. That's a different "specialness"
than the one session26 actually found and removed (the non-overridable
Enter/Escape framework tier, Decision 2's deleted fourth component). The
owner's suspicion that this is a hallucination leftover is reasonable given
this project's history — but checking the record, these are two different
specialnesses, and only one of them was ever hallucinated. I'd put that
distinction in front of the owner alongside the plan's own argument; it
defuses the suspicion on facts, not just design taste.

## 6. What is missing

In order of what I'd want fixed first: the decision-renumbering freeze
(#1), the corrected P5 dependency (#2), the named `examples/keyboard`
regression check (#3), and a smoke-test re-pass gate for the three nested
repos given they carry no automated coverage of their own (#4). All four are
concrete and checkable, not "more could be done" — each is something the
plan needs in order to not silently regress something it has already
correctly identified as in scope.

One more, smaller: P5's tests (before_submit/before_cancel veto) will
assert against `before_submit(keys_pressed)`'s current arity if written
before P2 lands, and the same "written twice" argument the plan uses to
defer doc/comment work applies here in miniature — worth a one-line note in
P5 itself ("write this after P2, even though the dependency table doesn't
force it") rather than relying on the table to communicate it.
