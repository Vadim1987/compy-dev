# ACC-01-02 — full defect register from the cold PR review

**Input:** `../outcomes/ACC-01-02-cold-pr-review.md` · **commission:** `../prompts/ACC-01-02-cold-review-commission.md`
**Author:** session46 (parent). **Triage only — nothing here is fixed** (owner, 2026-08-26).

**Corrected 2026-08-26 after owner challenge.** The first pass of this document triaged **7**
findings, taken from the reviewer's summary rather than its body. The report carries **13 numbered
findings plus three analysis sections** that raise more, and the owner added one. Every one is a defect row. **Total:
21**, plus this session's own document findings, registered here rather than living only in a track.

**Nothing is dropped as "not a defect" without the owner saying so.** Two rows are closed already
(one fixed, one scoped down by ruling) and stay visible so the count reconciles.

## Sprints

| sprint | contents | rows |
|---|---|---|
| **BUG-01** | runtime defects — the code misbehaves | 6 |
| **FIX-02** | documentation, vocabulary and process defects from this review | 15 |
| **FIX-01** | *(pre-existing, unchanged)* citations, session numbers, editorial list | 3 |

---

## BUG-01 — runtime defects

| id | defect | severity | verified |
|---|---|---|---|
| **BUG-01-01** | `state.pending` survives a project stop | major | parent, structurally |
| **BUG-01-02** | a highlighter cannot be turned off for the rest of a run | major | reviewer only |
| **BUG-01-03** | `show{force = true, prompt = …}` silently drops the prompt | minor | reviewer only |
| **BUG-01-04** | `set_cursor` clamps in bytes, the boundary event measures characters | minor | reviewer only |
| **BUG-01-05** | the migrated `turtle` example double-handles its own keys | minor | reviewer only |
| **BUG-01-06** | a `textinput` shortcut cannot bind an upper-case character | nit | reviewer only |

### BUG-01-01 — `state.pending` survives a project stop

`compy.input`'s private `state` — including `pending` — is built in the `get_compy_input()` closure
(`consoleController.lua:775`), reached from `prepare_project_env`, called **once** from
`ConsoleController.new:80`. So `pending` has **application** lifetime. A hidden `configure{text=…}`
stashes into it (`:651`), the next `show()` consumes it (`:665`), and nothing clears it between
projects. Project A's draft opens in project B's widget — contradicting this PR's own contract,
*"Nothing a project installed survives it."*

**Two things to establish before sizing:** whether the path is reachable from a shipped example
(the reviewer confirmed the code path by reading, not a caller), and whether `shortcuts`/`hooks`/
`callbacks` share the hole.

**Compounding:** the debt-ledger entry covering this area accepts the debt on the premise that
*"`compy.input` is rebuilt per project environment"* — which the call graph contradicts. **A ledger
entry resting on a false premise is worse than none**, because it closes the question.

**Carries a test gap:** the `stop teardown` block checks handlers, hooks, visibility and callbacks —
**not `pending`**. The fix ships with that case.

### BUG-01-02 — a highlighter cannot be turned off

`merge_callback_keys` re-injects the sticky value because **nil is indistinguishable from absent**,
and the live highlighter is mirrored onto the evaluator, which only `apply_config` writes and only
project stop clears. **Needs a design call, not a patch:** "absent means keep, nil means clear"
wants a sentinel, and a sentinel is new vocabulary in an API whose mandate is *fewer* moving parts;
the alternative is a new `clear_highlighter` member. Neither is obviously right. Owner called it a
bug, 2026-08-26.

### BUG-01-03 — `show{force = true, prompt = …}` silently drops the prompt

A caller passing both gets the force and loses the prompt, with no warning. **Silent is the
problem:** the same call behaves differently for no visible reason.

### BUG-01-04 — byte-vs-character clamping disagreement

`set_cursor` clamps in bytes while the boundary event measures characters — a defect for any
non-ASCII prompt, which is a case this project documents elsewhere.

### BUG-01-05 — the migrated `turtle` example double-handles its own keys

**The example-level symptom of a documentation gap** (FIX-02-09). Because the lockout fix means a
project's own handler now runs *while the widget is shown*, a hook that does not `return true` runs
**in addition to** the widget's editing. `turtle` was migrated without accounting for it. Being a
finding *about the migration*, it may have siblings among the other migrated examples — **check them
all; do not fix only this one.**

### BUG-01-06 — a `textinput` shortcut cannot bind an upper-case character

The combo serialisation lower-cases, so `shortcuts.textinput['A']` is unreachable. Small, but a hole
in a surface the guide presents as general.

---

## FIX-02 — documentation, vocabulary and process defects

| id | defect | severity | state |
|---|---|---|---|
| **FIX-02-01** | 14 unresolved `> REMARK:` blocks ship in `3a`; **and the marker gate never covered `doc/`** | major | triaged in full → [`FIX-02-01-remark-triage.md`](FIX-02-01-remark-triage.md) |
| **FIX-02-02** | provenance front matter missing | nit | **scoped to 3 files by owner ruling** |
| **FIX-02-03** | `pong/README.md` — 316-line diff hiding a 2-line change | nit | verified |
| **FIX-02-04** | CHANGELOG omits the breaking change it exists to record | minor | verified |
| **FIX-02-05** | two docs in `3a` disagree about whether the route is released at `running → project_open` | minor | reviewer only |
| **FIX-02-06** | **"tier" / "chain" / "the walk"** — three names for one thing, interchangeable across `3a`, `3d`, `3e` | minor | reviewer only |
| **FIX-02-07** | **"overlay" / "input widget" / "input area" / "field"** — four names for the widget, all in active use | minor | reviewer only |
| **FIX-02-08** | **"combinator"** — concept earned, word not; the guide's own table header says "wrapper" | nit | reviewer only |
| **FIX-02-09** | the guide never states that a shown widget **always consumes** on the keyboard side | minor | reviewer only |
| **FIX-02-10** | the guide never states that callbacks cannot be un-set | minor | reviewer only |
| **FIX-02-11** | the guide never says the widget is a persistent singleton that `hide()` merely deactivates — so FR-2's teardown question has no answer | minor | reviewer only |
| **FIX-02-12** | the channel list exists twice — the exact duplication the commenting rules forbid | nit | reviewer only |
| **FIX-02-13** | a `pending()` routing case is deferred in the area the review was asked to read hardest | minor | verified (one of the ruled 10) |
| **FIX-02-14** | **`release_keyboard_route` — name, doc comment and cited decision all describe retired behaviour** | minor | **parent-verified in code** |
| **FIX-02-15** | **the input debt ledger is 34% resolved entries, many about scaffolding this feature invented** | minor | **parent-verified** |

### FIX-02-15 — the debt ledger carries its own scaffolding

**Raised by the owner, 2026-08-26**, by analogy with the decision tombstones: *is the ledger
carrying items introduced and fixed within this branch, which from upstream's perspective never
existed?* **It is.**

**Measured:** `doc/development/technical_debt/input.md` is 1610 lines and 62 entries. **20 are
already marked `RESOLVED` / `CLOSED`, occupying 547 lines — 34% of the file.**
`technical_debt/general.md` is clean; this is an input-ledger problem only.

**Two kinds inside those 20, and they need different rulings.** The mechanical test is the one Phase
L used — *does the subject exist at the PR base `3256aac`?*

- **Rot — invented here, resolved here.** Subjects with **zero** occurrences at base:
  `compy.input`, `compy.keys_pressed`, `compy.before_exit`, `is_active`, `normalize_combo` /
  `new_handler_table`, `_generic_callback`. Entries about these record a problem this feature
  created and then fixed. **From upstream's perspective they never happened**, which is the owner's
  own rule for the decisions ledger, and there is no reason it stops there. One is doubly dead —
  the `compy.keys_pressed` entry is debt about a member Decision 30 later dissolved entirely.
- **Real, pre-existing, fixed by this work.** Subjects present at base: the `userinput` round-trip
  (3 sites), the `wrap` xpcall arity, `compy.singleclick` (6), `userlove` (8). These are honest
  records of genuine fixes. **Ruling wanted:** a resolved entry is arguably CHANGELOG material
  rather than debt-register material, but that is the owner's call and it is not rot.

**A caution for whoever runs this, from a near-miss.** I first classified `love.handlers.userinput`
as rot because that exact string returns **0** at base — it is written `handlers.userinput` there.
It is real pre-existing debt. **Test the subject with the spelling the base actually uses**, not the
one today's ledger uses; the exact-string grep will lie in exactly the cases that matter.

**OWNER RULING, 2026-08-26 — the disposal is settled:**

- **rot debt is vacuumed** — deleted outright, no tombstone;
- **pre-existing-but-resolved → the CHANGELOG**;
- **behavioural changes → the CHANGELOG**.

**This gives the CHANGELOG two feeders, and it should be written once.** FIX-02-04 owes it a
`Removed` section for the retired globals; this row owes it the resolved pre-existing fixes and the
behavioural changes. **Do them together** — a CHANGELOG assembled twice from two rows will
duplicate and disagree.

**Scope for the row:** enumerate all 20 (the split above is a sample, not an enumeration), test each
against base with the base's own spelling, then dispose per the ruling.

**Third instance of one pattern.** Decision tombstones, `release_keyboard_route`'s comment, and now
this: **every ledger this feature keeps has accumulated entries about its own scaffolding.** Worth
checking the remaining persistent docs for the same shape rather than waiting for someone to ask.

### FIX-02-14 — a live function that documents a mechanism this feature removed

**Raised by the owner, 2026-08-26**, asking whether the keyboard/pointer asymmetry had dissolved
back. It has — and checking it found this.

**The behaviour is correct.** The project route occupies all twelve channels and holds them until
the project stops; the `running → project_open` release is gone. Against the PR base there is no
asymmetry, so the round trip this feature made — introduce a keyboard-only release, exempt pointer
from it, then dissolve both — **shipped as a no-op**.

**The description did not follow.** `controller.lua:703` still reads:

> *"Hand keyboard/text back to the console at the moment a project's code finishes running but the
> project stays open (the `'running' -> 'project_open'` state change — Decision 11). **Pointer
> handlers stay hooked until the project stops (same decision).**"*

Both sentences describe retired behaviour and both cite Decision 11 as authority. Three things are
wrong at once:

- **the name** — its only surviving call site is the **crash path** (`consoleController.lua:301`,
  after `run_user_code` raised), not the transition it is named for;
- **the body** — it calls `project_input:deactivate()`, dropping the *whole* route, and empties the
  derived click slots, so it is not keyboard-specific either;
- **the citation** — Decision 11 is marked `SUPERSEDED IN PART` and says the opposite now.

**Probable parent of FIX-02-05.** The reviewer's *"two docs in `3a` disagree about whether the route
is released at `running → project_open`"* is likely this claim propagated into prose. **Check them
together**; fixing the doc without the comment leaves the source in place.

**Fix shape, not decided here:** rename to what it does (it deactivates a route on a crash),
rewrite the comment against the shipped behaviour, and repoint or drop the citation.

### FIX-02-06 / 07 / 08 — the vocabulary rows, and why they are not nits

The strategic frame says the PR must not carry *"moving parts or vocabulary beyond that ask without
a one-line justification."* These three are that clause failing:

- **`06` — tier / chain / the walk.** Three words for one concept, interchangeable across three
  slices. Pick one and sweep.
- **`07` — overlay / input widget / input area / field.** Four for the widget. `doc/input_api.md`
  is consistent on "input widget"; the internals docs and inline comments are not. **`1b`'s own
  remark flags this and it was not acted on** — a known, recorded, unclosed item rather than a new
  discovery. Session45 retired "overlay" from `src`/`tests`; the **docs** half stayed open.
- **`08` — combinator.** Concept earned, word unearned; "wrapper" is what the audience — students
  and their teachers — will understand.

The reviewer explicitly judged **"reservation"**, **"derived event"** and **"route"/"occupy"** as
*earned*. Recorded so nobody sweeps them by association.

### FIX-02-09 — the gap BUG-01-05 is a symptom of

*"Nothing states that a shown widget **always** consumes … That is the single most surprising
consequence of the lockout fix."* The guide states it for **pointer** hooks and never for
**keyboard**. **Fix the guide and the example together**, or the next migration repeats `turtle`'s
mistake.

---

## Closed, kept visible so the count reconciles

| defect | disposition |
|---|---|
| ~~PR description drift~~ — described a member that does not exist, denied a shipped capability | **FIXED** `e123ca9e`; both claims verified in code first |
| ~~five files outside every pathspec~~ — incl. `src/harmony/init.lua` | **FIXED** `16aa25e2`; root cause fixed in `e123ca9e` (guide §1.0, derived classification) |

---

## This session's own document findings, registered

Raised by the parent rather than the reviewer, and previously living only in a track:

| id | finding | state |
|---|---|---|
| **FIX-01-01** | 10 ephemeral step-id and `wip/` path citations in the persistent corpus | planned |
| **FIX-01-02** | session numbers in the persistent corpus (4 sites) | planned, owner-ruled |
| **FIX-01-03** | P11's deferred editorial marker list — **named as a count, never enumerated**; re-derive before sizing | planned, live |
| **FIX-02-01** *(second half)* | **the marker gate greps `src/` and `tests/` only** — `doc/` was never in scope, which is why 14 remarks survived a gate reported clean | planned |

---

## What the review could not check — not defects, but not clean either

Recorded so these are not mistaken for passes:

- **Nothing was run.** No `busted`, no `love`, no device. The suite count and *"every claim in the
  guide is pinned by a row"* are unverified by the reviewer.
- **Nothing that reaches a screen** — paint, examples in motion, click/drag, the double-click
  window. **That is exactly what ACC-02 exists for.**
- **The Web (love.js) build** — no coverage at all, by the ledger's own admission.
- **Whether any untracked project relies on the old loose reserved-combo matching.** The narrowing
  is intentional and tested; its blast radius outside this repo is unknown.
- **`4c` (`keyboard`)** — a large behavioural rewrite replacing a hand-maintained `INPUT.held` mirror
  with device queries, *"whose correctness depends on timing I cannot observe."* **The strongest
  argument for running the `keyboard` smoke pass carefully.**

## Wins, recorded because they are evidence too

The `xpcall` arity fix (`3d:107`) — the message handler received the error as `CC` and raised inside
itself, so **project raises vanished with no error window at all**. A serious latent bug found and
fixed en route. Also ~150 lines of hand-written installers collapsed into one generator; eleven
copies of the gateway's `get_user_input()` dance deleted; the `oneshot` flag, `result` reftable and
`love.event.push('userinput')` round-trip gone with no survivor; and **`doc/input_api.md` judged
"the strongest artefact in the delivery"** — accurate exactly where the PR description was not.
