# session57 — report

**Date:** 2026-08-30 · **Suite:** **1021 / 0 / 0 / 10** at every commit (1011 at boot + 10)
**Mode:** scoped revalidation → owner-gated ruling → execution → cold peer review → replanning.
Every transition was the owner's, and the last one reopened a design the session had just closed.

---

## 1. What this session was

**`FEAT-01`, complete — all seven rows**, plus a cold peer review of its own output and, out of
that review, a new sprint that overturns part of it.

The session was **deliberately cold** on session56's decisions: the owner chose a fresh reader so
the ledger would be tested as a *specification* rather than trusted as a memory. That framing
earned its keep twice, and both times the finding was about what the ledger did **not** say.

## 2. Outcomes

**Two public-surface changes shipped.** `show{oneshot = true}` closes the widget on a successful
submit (three production lines). `on_text_entered` receives the joined string while `after_submit`
keeps the line list, which is what finally tells the two callbacks apart — **`FIX-02-01` closed with
it**, jointly, as its row required. Both are documented in the guide, the internals doc and the
CHANGELOG; both decisions are `implemented`; both debt entries are retired.

**The owner ruled `oneshot`'s four edges, and reversed one of them.** Decision 36 recommended that
`oneshot` close even when a callback raised, on the ground that *"the submit chain runs under an
error boundary"*. The boundary is real but wraps the **route entry**, not the chain — deliberately,
and the code says why. So a raise already unwinds past `after_submit` today, and honouring the edge
meant new machinery for a case where the first failure is **not** silent. Ruled: clean submit only.

**A cold peer review then found five things, all five verified and acted on.** Its best was the one
neither the parent nor the ruling sheet looked for: **seven live documents outside the sprint's own
blast list still described the old payload**, including `smoke_checklists.md` §B — three sentences a
**human executes by hand**, in a check whose whole point is that a mistake there is silent.

**And the review's one substantive finding reopened the design.** A `oneshot` prompt re-opened from
inside the submit chain is closed before the user can type. The parent documented it and raised the
code fix rather than taking it; the owner answered by changing what `oneshot` *is*. **`FEAT-02` is
filed** — `oneshot` becomes a widget property, readable like `is_shown()`, which **overrules this
session's own Q1 ruling**.

## 3. Non-obvious points worth carrying

- **A decision anchored on the code it replaces is executable; one anchored on a description is
  not.** Decision 36 defines `oneshot` as sugar over `after_submit = function() hide() end`. That
  single sentence settles what "closes" means, *where* the close fires, and that the veto, the empty
  guard and a rejecting validator all suppress it — none of which the decision states. The one edge
  it argued *from a description of the system* is the one that turned out to be wrong.
- **`string.unlines` is idempotent over a string.** It reversed the migration story: the four
  consumers that joined kept working **untouched**, and the three that indexed broke **silently**
  (`("abc")[1]` is `nil`, not an error). The ledger had it the other way round.
- **A payload change's blast radius is every document that quotes a call site**, not the documents
  that describe the call. That is the shape of the seven-document miss, and it is the reusable part.
- **Reading the `oneshot` flag *after* the hooks is load-bearing**, and was arrived at by accident.
  Capturing it before — the owner's first candidate fix — leaves the broken case broken *and* breaks
  the one that works. Established by mutation, not by argument.
- **Disarming a `oneshot` today costs the user's draft.** `configure` refuses the key, so the only
  route is `show{force}`, which is a full re-setup that clears content. Nobody had noticed; it is
  now the strongest argument for `FEAT-02` and it is a defect, not a preference.

## 4. Three things this session got wrong

- **I asserted an unknown instead of running one command.** *"Whether the replaced API's `oneshot`
  self-cleared is not checkable in this repo"* went into the ledger; the base is in this repo's
  history, `agents/validation.md` carries *check the PR base first* as a twice-learned lesson of
  this very phase, and one `git grep` at `3256aac` overturned a claim I had used to argue a rename
  was unavailable. **The failure was not the wrong answer — it was recording an unknown as a fact
  about the world rather than about my own effort.**
- **The documentation sweep stopped at the boundary of what I had edited.** I fixed the guide and
  the internals doc and never asked which *other* documents quote the call sites. Seven did.
- **Q3 of the ruling sheet was put as a formality with a stated recommendation, and ratified by not
  being objected to.** That is recorded on the sheet as what it was rather than dressed as a
  considered ruling — silence is not a ruling, and this one came close to being taken as one.

## 5. Addendum — the two things settled after the wrap was written

**The `oneshot` clearing question is closed, on a reading rather than a lifetime argument.**
`oneshot` **configures a type of behaviour, not one show/hide cycle** (owner): it is an ordinary
project-owned setting, persistent until replaced like `validator`, and a clearing rule would be *"a
new entity — a one-off flag — just for syntactic sugaring"*. My filed row and both of my grounds for
withdrawing it are subsumed by that. **Two obligations ride on it, both rows in `FEAT-02`**: the
persistence must be **ruled** in Decision 36 and **said plainly** in the guide — because the name
says one-off while the semantics say mode, and a reader who takes `oneshot = true` as *"this one
time"* gets a closing widget on every later prompt, silently. Renaming is not available; Decision 36
grounds the flag on being a restoration of that exact name.

**The flag is renamed, and my reason for saying it could not be was false.** The owner overruled
their own position: `oneshot` names a single occurrence while the flag is a mode, so the key gets a
name that reads as one (`auto_close` proposed as an example; the name itself is `FEAT-02-02`'s to
settle, with `auto_hide` carried as a counter-proposal because the surface's verbs are `show`/`hide`
and there is no `close` on it). **I had argued renaming was unavailable on two grounds and both
fail.** The base check I said was impossible took one command
([`validation/notes/oneshot-at-the-pr-base.md`](../../../validation/notes/oneshot-at-the-pr-base.md)):
at `3256aac`, `oneshot` was an **internal model constructor argument** separating the transient
prompt widget from the console's permanent one — suppressing history, pushing the `userinput` event
for the poll idiom, switching the view's draw path. **No project could write it or read it**, so
Decision 36's *"a migrating project author meets a familiar name"* is false: the capability was
restored, the name never reached anyone. The token is also already taken in-tree by the profiler.
`FEAT-02-01` now amends a **ground** as well as an edge.

**The name is `auto_hide`, and no reader is added.** The owner took the counter-proposal — it reads
as a mode and matches the surface's own `show`/`hide`, where `close` appears nowhere. They then
withdrew their own *first-class and readable* row on a good argument: the mode shape **dissolved its
use case**, because disarming is unconditional (`auto_hide = false`, armed or not) and there is
nothing to check before acting. The general line, which `FEAT-02-01` will carry: **a read-only query
earns its place when the framework can change the value, not when only the project can** — why
`is_shown()` stays and `is_auto_hiding()` was never built. **Two of `FEAT-02`'s six filed rows are
now withdrawn, both by the owner, both within a day**, and neither was drift: each was filed against
the `FEAT-01` shape and stopped making sense once the flag became a mode.

**A retirement takes its citations with it** — new standing rule, `agents/rules/roadmap.md` §5, on
the owner's directive: *no reconfiguration of a roadmap should leave references orphaned and
unactionable*. It has a sharp edge worth keeping: the dangerous case is not the dangling citation
but the one that **still resolves**, to a heading that no longer means what it did — a debt entry
retired out of its slug leaves `T-FOO` findable only in a *"Was `T-FOO`"* line, so a reader lands on
a retirement note and reads it as a live obligation. **The pass that causes an orphan owes the fix**;
the sweep is a backstop. `FIX-03-05` is filed as that backstop and adopts the six citations this
session found — the `T-HL-TWO-HOMES` pair in `src/` and `tests/`, and four `ARC-02`-era slugs cited
from `ROADMAP.md` with no heading left.

## 6. Artifacts

- Track: `session57/track.md` · Ruling sheet: `validation/reviews/FEAT-01-01-oneshot-ruling-sheet.md`
  (five questions, dispositions at its foot)
- `validation/reviews/FEAT-01-ledger-executability.md` — the opening scoped revalidation
- `validation/outcomes/FEAT-01-peer-review.md` + parent verification addendum;
  prompt of record `validation/prompts/FEAT-01-peer-review.md`
- `validation/notes/owner-attestation-oneshot-widget-property.md` — the `FEAT-02` ruling
- Persistent corpus: Decisions 36 and 37 implemented, Decision 5 amended by pointer;
  `T-ONESHOT` and `T-PLAINTEXT-ENTERED` retired, **`T-ONESHOT-SCOPE`** opened;
  `doc/input_api.md`, `internals/user_input.md`, `smoke_checklists.md`, six example notes,
  `CHANGELOG.md` (`Added` + a breaking `Changed`)
- Nested repos, committed and unpushed: `maze` `d2be028`, `balloons` `6d6c6e3`
