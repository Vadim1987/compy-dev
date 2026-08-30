# session58 — `FEAT-02`: `oneshot` becomes a widget property

Read `agents/sessions.md` and `agents/validation.md` first, then the predecessor report
[`../session57/report.md`](../session57/report.md).

Baseline: **1021 / 0 / 0 / 10**.

## Carryover

Session57 completed **`FEAT-01`** — `show{oneshot = true}`, and the payload split that finally tells
the two submit callbacks apart (`on_text_entered` takes the joined string, `after_submit` the
lines). Both decisions are implemented, both debt entries retired, `FIX-02-01` closed with the
split, and a cold peer review of the whole sprint came back **approve with comments**; all five of
its findings were verified in code and acted on.

Its last finding reopened the design, and that is your task. **`FEAT-02` overrules `FEAT-01-01`'s
Q1 — a ruling made the same day.** The owner's grounds: the show-only category exists to protect
**user-owned** content, and `oneshot` is *machinery*. The user does not own lifecycle.

## You are cold on purpose — and this time it is about a specific bias

`FEAT-01` was ruled *and* executed inside one long context, and this sprint overturns part of it.
The owner wants a reader who did not argue for the thing being overturned. Two consequences:

- **The attestation and the roadmap row are your source**, not session57's track or its ruling sheet.
- If the case for the change does not survive your own reading, **say so before building it**. An
  overruling that only one session believes in is worth catching now, not after the ledger moves.

## Your task — `FEAT-02`, five rows

`ROADMAP.md` holds them; read them there. The ruling and its reasoning, including what was
**rejected** and what this **does not fix**, are in
[`../../../validation/notes/owner-attestation-oneshot-widget-property.md`](../../../validation/notes/owner-attestation-oneshot-widget-property.md).
Debt goal: **`T-ONESHOT-SCOPE`**. In outline: amend Decisions 36 and 35 **first** (the ledger gate —
amend, never reinterpret); move `oneshot` to the project-owned keys, `show` **and** `configure`,
`false` to unset; make it **readable by a project**, the way `is_shown()` is; document the
teardown-path advice; invert the two tests that pin the old category and update the CHANGELOG.

### Three things not to rediscover the hard way

- **Do not re-file the clearing rule, and do not soften the persistence.** *Disarmed when the
  widget goes down* was filed by session57 and **withdrawn by the owner the same day**. The settled
  reading is that **`oneshot` configures a type of behaviour, not one show/hide cycle** — so it is
  an ordinary project-owned setting, persistent until replaced exactly like `validator`, and it
  needs no category of its own. The roadmap keeps the withdrawn row with its full reasoning; read
  that section before re-deriving the argument.
  **The persistence carries two obligations, both owner conditions, both rows:** Decision 36's
  amended text must **rule** it (`-01`), and the guide must **say** it plainly (`-04`). They are not
  bookkeeping — `oneshot = true` reads as *"this one time"*, so a reader who assumes it self-clears
  gets a closing widget on every later prompt, silently. Renaming is off the table: Decision 36
  grounds the flag on being a restoration of that exact name.
- **It does not fix the peer review's case, and is not meant to.** A hook doing
  `show{force, oneshot = true}` still re-arms and the trailing close still fires. Do not quietly
  widen the sprint into fixing it — that needs a generation token, and the state was judged not
  worth it. `FEAT-02-04` is where the user learns to avoid it.
- **Do not "simplify" the close by capturing the flag before the hooks.** It looks like the obvious
  shape and it is wrong: mutation-tested in session57, it leaves the broken case broken **and**
  closes the plain forced follow-up that currently survives. The test
  `a forced follow-up show survives the close` pins this; if you find yourself making it pass a
  different way, stop.

### Opening move — revalidation, and it is genuinely scoped

`agents/rules/revalidation.md` applies (session57 exercised judgment). **A cold review of that
session's work already ran** — `validation/outcomes/FEAT-01-peer-review.md`, with a parent
verification addendum. **Do not repeat it.** What it could not cover, because `FEAT-02` did not
exist when it ran:

- **Does the case for `FEAT-02` hold up?** In particular the claim that disarming a `oneshot` today
  costs the user's draft — verify it in code, it is the strongest argument and it is load-bearing.
- **Is the attestation executable on its own?** Session57's ledger-executability check found real
  gaps by asking exactly this; the instrument works and costs one pass.

Report both before starting `-01`, then proceed.

## Facts worth having up front (verified 2026-08-30 — re-verify before relying on them)

- `oneshot` lives on the widget (`self.oneshot`), seated in `open_widget` **unconditionally**, and
  spent by the last line of `submit_flow`. It is in `SHOW_ONLY_KEYS` in `consoleController.lua`.
- `hide()` refuses on an `always_shown` widget (console, editor) — worth knowing before hanging
  anything off it, which is part of why the clearing rule was withdrawn.
- A project's `love` is a sandboxed deep clone, so a project **cannot** read widget state without a
  surface built for it — that is Decision 18's shape, and `is_shown()` is the precedent `-03` should
  follow.
- `false` is the uniform unset across the config table (Decision 35, statement 3), so the disarm
  idiom needs no new vocabulary.
- The widget lives for one project **run** (Decision 3 as amended by `ARC-01`), so the flag dies
  with the run and needs no teardown entry.

## Standing constraints

- Suite green at every commit, count stated in the message; commit at the seam, one concern each;
  **never push**.
- A behaviour change is **never** documented in the commit message alone — it lands in a document,
  or in a code comment where no document fits.
- Say **widget**, not "field" or "overlay".
- The owner also works in this tree. Never sweep their unrelated working-tree changes into a commit.
- One loose finding stays parked and is **not** yours unless the owner says so: `ROADMAP.md`'s
  status table cites `FIX-02-01` for a `doc/`-markers concern that has no row anywhere. The
  retired-id citations that were parked with it now have a home — **`FIX-03-05`**, filed on the
  owner's directive that a retirement takes its citations with it
  ([`agents/rules/roadmap.md`](../../../../../../agents/rules/roadmap.md) §5). That rule binds
  **you**: if `FEAT-02` retires or renumbers anything, sweep its citations in the same pass rather
  than leaving them for the broom.
