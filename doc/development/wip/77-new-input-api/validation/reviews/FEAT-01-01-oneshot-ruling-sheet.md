# `FEAT-01-01` — `oneshot`: the edges, put to the owner

**Session57, 2026-08-30. RULED — the dispositions are at the foot of this document.**

Decision 36 rules `oneshot` **in** and leaves its edges as *recommendations, not rulings*. This sheet
puts each one to the owner: **evidence first, then the question**. Five questions — the four edges
Decision 36 recommends, plus one the ledger does not raise and cannot be built without
([`FEAT-01-ledger-executability.md`](FEAT-01-ledger-executability.md) §2).

**The specification anchor, stated once.** Decision 36 defines the flag as sugar over
`compy.input.callbacks.after_submit = function() compy.input.hide() end`. That anchor is doing real
work: it settles what "closes" means (`hide()`), where the close fires (`submit_flow`'s last line,
`userInputController.lua:447`), and therefore that a `before_submit` veto, the empty guard and a
validator rejection each suppress it with no rule of their own (`:439-445`). **Every question below
is a place where the anchor runs out.**

---

## Q1 — a `show`-only key, spent by its `show`?

**Recommended:** yes. `oneshot` describes *this* prompting session, not a standing preference, which
puts it beside `text`, `cursor` and `force` on Decision 35's boundary; a sticky flag means a later
bare `show()` closes on submit for reasons written in an earlier call.

**Evidence.** The mechanism is already there: an entry in `SHOW_ONLY_KEYS`
(`consoleController.lua:595-599`) buys both the acceptance at `show` and a refusal at `configure`
that *names where the key belongs* rather than merely rejecting it. Non-sticky is one unconditional
assignment on the activation path — a later bare `show()` clears it by construction.

**Nothing is lost by refusing it at `configure`.** A project that decides mid-session that the next
submit is the last still has the exact call `oneshot` is sugar for.

**The complication, and it is the reason this question is not a formality.** `text`, `cursor` and
`force` are all **consumed during the call** — seated into the model, or read and dropped. `oneshot`
must be **remembered from activation until a later submit**. It is therefore the first show-only key
that outlives its call, and Decision 35's category is currently *"keys that belong to activation"*
read as *"keys activation spends"*. The two readings have been the same thing until now.

- It is a **per-widget** store, not a surface one, so it does not resurrect `state.pending` (deleted
  by `ARC-02-05`, and which buffered config for a widget that was **not up yet**).
- Under `ARC-01`'s per-run widget lifetime the flag dies with the run, which is the lifetime it
  wants. No teardown list, no wipe to maintain.

**Question.** Ratify show-only and non-sticky? And if yes: should Decision 36's ruled text say
explicitly that the show-only category now holds two kinds of key — spent, and remembered for the
session — so a later reader does not infer "show-only" ⇒ "consumed at the call"?

## Q2 — submit only, never cancel?

**Recommended:** yes. `cancel_flow` clears and leaves the widget standing (Decision 6;
`userInputController.lua:455-461`), and no reading of `oneshot` should quietly change what Escape
does.

**Evidence.** Escape-clears-but-stays is a ruled behaviour with its own decision, and a project that
wants Escape to close writes `after_cancel = function() compy.input.hide() end` — the same one-liner
on the other channel.

**The cost, named because it lands on the flag's own headline case.** Decision 36 sells `oneshot` to
*"a project whose subject is not user input"* — one call, **nothing to install and nothing to tear
down**. Under submit-only, that project's user presses Escape and the widget **clears and stays up**,
with the project holding no callback that could take it down. The only exit is submitting something.
So the flag's advertised case is exactly the case with no dismissal path.

Three coherent answers, and this is the owner's to pick:

- **(a) Ratify submit-only as recommended** — the widget is dismissible by the framework's own means
  and a project that wants more writes the second one-liner; `FEAT-01-05` documents the asymmetry so
  nobody meets it by surprise.
- **(b) `oneshot` closes on cancel too** — a *one-shot session* rather than a *one-shot submit*. It
  matches the name better and fixes the hole above, at the price of Escape doing something new when a
  flag set in a different call says so.
- **(c) Ratify submit-only now and file the dismissal hole** as debt against the guide, to be ruled
  if it is ever met in practice.

**Question.** (a), (b) or (c)?

## Q3 — composes with a project's own `after_submit`, rather than refusing one?

**Recommended:** yes — the project's callback runs first, the close follows it.

**Evidence.** Refusing the combination forces back exactly the boilerplate the flag exists to remove:
a project that wants to *react and close* would have to write the hide by hand anyway, and would then
have no use for the flag. The composition is already coherent in-tree — `balloons` sets
`after_submit = clear` (`examples/balloons/terminal.lua:32-34`), and clear-then-hide is a sensible
pair. Ordering is forced: the close must come last or the callback runs against a hidden widget.

**No complication found.** This one looks like a formality, and is included only so the ruling is
complete.

**Question.** Ratify?

## Q4 — does it close when a callback **raised**? And by what mechanism?

**This is the one that cannot be built from the ledger.** Decision 36 recommends *"it closes even if
a callback raised"* on the grounds that *"the submit chain runs under an error boundary"*.

**Evidence — the boundary is real, but it is not where the decision assumes.**
`with_canvas_and_errors` wraps the **route entry** (`controller.lua:161`, installed at `:238`), and
the comment at `:152-157` says the placement is deliberate: wrapping individual chain participants
made a raise in the widget look like *"did not consume"*, so the walk carried on past it.
`run_callback` calls the project's function directly (`userInputController.lua:427-431`). Therefore:

- A raise in `on_text_entered` **unwinds straight out of `submit_flow`**. Today it already skips
  `after_submit` — that is current behaviour, not something this row introduces.
- **Appending the close after the callbacks does not honour the recommended edge.** There is no
  `finally` here to hang it on.

Three mechanisms, each with a different observable:

| | mechanism | what changes |
|---|---|---|
| **(1)** | protected call around the callback pair inside `submit_flow`; hide; **re-raise** so the route boundary still suspends the project | nothing observable except the close. Costs a `pcall` on every submit and a careful re-raise (session54 already paid for one argument-loss bug in this family) |
| **(2)** | hide **before** running the callbacks | cheapest, and **it breaks a shipped example.** A callback would see `is_shown() == false` for its own submit, and `set_text`, `set_cursor` and `clear` all warn-and-refuse while hidden (`consoleController.lua`, `build_widget_api`). `balloons` sets `after_submit = function() compy.input.clear() end` (`examples/balloons/terminal.lua:32-34`) — under (2) that call would warn and do nothing for any `oneshot` session. Not recommended |
| **(3)** | don't guarantee it — `oneshot` closes on a clean submit only | zero machinery. A project whose callback raises is already suspended into the debugger with its error on screen; the widget standing behind that is arguably the *smaller* of the two failures, not a second one |

**The argument Decision 36 gives for the guarantee** — *"a widget left standing after an error would
be a second, silent failure mode on top of the first"* — is worth weighing against the fact that the
first failure is **not silent**: the project suspends and the error is reported. Under (3) the
widget's fate matches what a hand-written `after_submit = hide` would have done, which is the anchor
this whole decision is built on. **Under (1) `oneshot` becomes strictly more reliable than the
boilerplate it replaces** — defensible, and worth saying out loud, because it means the flag is no
longer *only* sugar.

**Question.** (1), (2) or (3)? And if (1): if `on_text_entered` raises, should `after_submit` still
run? Recommended **no** — that is today's behaviour and this edge is not a reason to change it.

## Q5 — the justification-table line

`oneshot` **grows** the public surface, which is the one direction the strategic frame watches. The
grounds are on the record and are not in question: it **preceded this feature** (a restoration, not
an invention) and it was **asked for by the `serial` API's author**, a consumer outside the input
work. The PR's justification table needs one line saying that.

**Question.** Is that line the owner's to write, or drafted here for approval?

---

## Rulings — owner, 2026-08-30

| | ruled | note |
|---|---|---|
| **Q1** | show-only and non-sticky, **as recommended** | the "two kinds of show-only key" note was offered and **declined** — the category stays as Decision 35 words it, and this sheet is where the distinction is recorded if anyone needs it later |
| **Q2** | **(a)** submit only, and **document the asymmetry** | the dismissal hole is accepted, not deferred: `FEAT-01-05` writes it into the guide rather than leaving a reader to find it. No debt entry — a documented behaviour is not an obligation |
| **Q3** | composes with `after_submit`, **as recommended** | put as a formality with a stated recommendation; ratified without objection. Recorded plainly because *silence is not a ruling* and this one came close to being taken as one |
| **Q4** | **(3)** — closes on a clean submit only | **reverses Decision 36's own recommendation.** The reversal is the point of running this gate: the recommendation's ground (*"the submit chain runs under an error boundary"*) did not survive contact with where the boundary actually is. No new machinery in `submit_flow` |
| **Q5** | drafted here, for approval | the justification-table line lands with `CHG-01`/`PR-01`, not in this sprint |

**Decision 36's edge section is rewritten as ruled text**, and `T-ONESHOT`'s `State` and `Revisit`
lines follow it — both in the same commit as this disposition, so no reader meets a recommendation
sitting next to its own ruling.

## What happens once this is ruled

`FEAT-01-02` implements it, breaking test first; Decision 36's *"Recommended edges, pending
`FEAT-01-01`"* section is rewritten as ruled text **in the same commit as the ruling**, not later —
the recommendations must not survive next to their own ruling. `FEAT-01-05` documents the flag with
the one-line-question worked example Decision 36 names, plus whatever asymmetry Q2 leaves standing.
