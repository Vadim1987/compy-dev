---
description: Running track for session68 — the S67 dispositions, then FIX-02 half (a)'s tail and CHG-01
status: session track
audience: developer
authored: llm
session: 68
date: 2026-09-03
---

# session68 — track

## Boot (2026-09-03)

- HEAD `c610805b` *"docs(session67): re-wrap — the delivery revalidation dispositioned…"*.
- Working tree: only the known untracked scratch (`broken-busted/`, `claude.sh`,
  `input-pr-slices.tar.gz`, `repos.txt`, `src/STEPS.md`, `src/examples/{balloons,keyboard,maze}`,
  `worklog.md`). No tracked modifications.
- Suite: **1050 / 0 / 0 / 10**, 2.29 s, LuaJIT 2.1 in the container — matches the baseline.
- Re-entrance: `session68/track.md` did **not** exist → fresh start. Predecessor kept a full
  track and report; both read.
- Read: `agents/sessions.md`, `agents/validation.md`, `session68/prompt.md`,
  `session67/report.md`, `validation/reviews/S67-delivery-revalidation.md` (findings +
  disposition table).

## Dispositions — the standalone three (2026-09-03)

- **F1 guide half applied.** Verified the mechanism myself before writing: `build_widget_api`
  (`consoleController.lua:879`–`941`) exposes show/hide/is_shown/get_cursor/set_cursor/set_text/
  clear/configure — **no reader**; content leaves only via `run_callback(self,'on_text_entered',…)`
  and `…'after_submit'` in `submit_flow` (`userInputController.lua:469`–`470`), `cancel_flow`
  delivers nothing; `get_cursor` returns `nil` when the flag is down (`:896`–`:899`), silently by
  design (its own comment says so). Two paragraphs after `input_api.md:181`.
- **F9** → `LEDGER-02`: inbound-citation check before a move, with the one known instance named.
- **F8** → `FIX-02-07`'s cell: "was 37; re-count when the row opens" + 34 markers / 12 files at
  HEAD, counted today. Deliberately no new disposition count.
- Three commits, one concern each; suite untouched (docs only).
- **F1's design half escalated to the owner** — the read-only content getter, ship or defer.

## Owner ruling — the getter is release scope (2026-09-03)

> *"Write it as active technical debt to be resolved before release. Disclose the gap but mark it
> as defect fixable with getter until ruled otherwise."*

Neither of the two options I put; the owner took the third. Materialized in one commit
(`e208ca87`):

- `technical_debt/input.md` — the BACKLOG proposal rewritten in place as **ACTIVE
  `T-CONTENT-READ`**. A slug is the commitment to fix, so the promotion *is* the slug.
- `decisions/input.md` — `D-CFG-BOUNDARY` amended: its *"if the case ever arrives"* paragraph now
  describes the interim state. The retirement is untouched, and the amendment says why — it rests
  on no scenario needing restoration, not on the fallback being whole.
- `ROADMAP.md` — **`FEAT-03`** registered (ACTIVE debt with no row is a visible gap, `ledgers.md`
  §5). Placed **in the brace, before `CHG-01`**, by `FEAT-01`'s own argument: a public-surface
  change that `CHG-01` must carry, `ACC-02` must exercise, and a slice cut ahead of is cut twice.
- **F5 folded in** — it was the same paragraph, and `ACTIVE` stopped being empty.

## FEAT-03 — filed, built, documented and retired in one sitting (2026-09-03)

Four commits: `55adbfb3` (five breaking tests + the eight-line implementation), `41852371` (guide +
internals), `56053522` (CHANGELOG + the citation sweep + retirement + roadmap). Suite **1050 →
1055**, LuaJIT 2.1.

- **The read path already existed.** `UserInputController:get_text` has been there all along and is
  not on the project surface, so the work was the surface hop and the string join — which is also
  why the *"is this too late for a surface addition"* worry did not materialise.
- **Return shape ruled: a string.** Three grounds, and the third decided it — it round-trips
  through `set_text`, it makes `== ''` direct, and it hands a project **no internal object**.
  `after_submit` already passes the raw `InputText`; a getter doing the same would have put a class
  the guide never names into project hands as a *new* commitment.
- **`''` vs `nil` is the pair that matters** and neither test would be worth much alone: empty-and-up
  against hidden is how a project tells *nothing typed* from *nothing to report*.
- **The guide example was executed, not reasoned about** (session67's rule). Scratch spec: typed
  into a live widget, saved both reads, hid, re-showed with `text` + `cursor`, asserted the
  round-trip. Deleted after. It passed first time, which is not the point — the point is that the
  earlier reasoning-only draft of a *different* example was wrong.
- **The sweep found a fourth site and it was mine, in a comment I had written an hour earlier** —
  the new spec cited `T-CONTENT-READ`, a slug the retirement drops. Re-homed to
  `doc/input_api.md`, *"Live changes"*. Exactly session67's *"a spec header written an hour
  earlier"*, repeated by the session that read that sentence this morning.

## While the worker runs — `FIX-02-17`, `CHG-01-01`, F4 (2026-09-03)

Owner ruled the mechanical half of `FIX-02-05` delegated; one Sonnet worker is walking the two
registers' `RETIRED` sections. **So I am staying out of both debt files** — inserting anywhere in
them shifts the line numbers it is citing. Two edits are therefore **owed and deferred**, not
dropped:

- **`T-VERSION-NUM` says the input work removed *four* public globals.** It is five, plus the
  debug-only `astv_input`. Belongs to `CHG-01-04`, which owns that entry.
- **`src/examples/repl/README.md` and `src/examples/valid/README.md` still document the removed
  globals** (`input_text()`, `input_code()`, `validated_input()`) — five sites. Both examples'
  `main.lua` *are* onboarded onto `compy.input`, so it is the READMEs alone. **Not covered by any
  existing entry:** the BACKLOG entry for retired-idiom docs is scoped to
  `doc/development/internals/examples/*.md`, a different set of files, and these ship *inside the
  example project* where an author reads them first. Found while base-checking `FIX-02-17`.

**`FIX-02-17` closed, and the row yielded after all.** The `Removed` section had existed since
2026-08-27, so the row read as discharged; nobody had checked its list **against the diff**. The
check that found the gap is a **set difference, not a grep** — `project_env`'s keys at `3256aac`
(23) against HEAD (17) — and it surfaced `astv_input`, which no grep would have looked for.
`compy.text_input` was the other candidate and correctly stays out: at base it assigned a bare
`input_text` that is not in scope there, i.e. **`nil`**, and never functioned.

**`CHG-01-01` advanced to 🟡.** One bullet was half false — *"Submissions are line arrays"*, which
survived `FEAT-01-04` and contradicted the Breaking bullet four entries above it. Rewritten at
user-facing altitude; *"an active overlay"* went with it. `Fixed` is left for after `FIX-02-05`,
because "does this belong in a changelog at all" is that row's classification.

**F4 applied** to `plan.md` with both corrections stated rather than silently patched.

**An owner question surfaced, and it is not one I can settle:** the CHANGELOG says `show` raises on
*"the retired `eval` and `result` keys"*, and `doc/input_api.md`'s **"Migration from the legacy
globals"** table carries two rows for `eval = InputEvalLua` / `eval = ValidatedTextEval(filters)`.
**`eval` was never a project-facing key at the PR base** — evaluators were internal there
(`internals/user_input.md:47`, *"Project overlays"*), and a project called `input_code()` and got one
chosen for it. So both sites migrate from an API no *base* version had. **But there is a downstream
consumer standing on this branch** (the `serial` API work), and the debt register dates the input
API to `1.0.0-rc20260712` — so whether `eval` was ever released to anyone is a fact I do not have.
Batched with `CHG-01-04`'s version question, which is the same *what counts as released* question.

## The owner's four questions, and what they turned up (2026-09-03, after the mandate)

Asked at the point I offered to wrap. **Three of the four changed something**, which is the
argument for asking them.

- **`eval`/`result`: I answered by executing, and it corrected me twice.** A scratch spec printed
  the project environment: `eval` a function (the *Lua evaluator* global, exported at base and
  today — unrelated to the widget), `result` **nil** and never a name at all, the four evaluator
  objects **nil** in `project_env` while still present in `pre_env`. That gap is the finding: they
  were **reachable at base** and are **withheld now** (`project_env[name] = nil`, commented, with
  its reason). A removal the CHANGELOG did not record.
- **`FIX-02-17`'s set difference could not have found it**, and this is the transferable part: the
  check differences *assignment keys*, and `project_env[name] = nil` is **the unmaking of a name,
  not the assignment of one**. It is on neither side. *A set difference finds what is absent; it
  does not find what is actively removed.* The method that caught `astv_input` — which no grep
  would have looked for — was structurally blind to these four.
- **`internals/user_input.md` already documented the withholding, correctly.** The CHANGELOG and
  the guide did not. `FIX-02-06`'s shape exactly: the corpus knows, and the two documents a
  stakeholder reads are the ones that do not.
- **The `result` row went with them.** Nobody wrote `result = ...`; a project wrote
  `r = user_input()` and polled `r`. Folded into the `user_input()` row, which now says there is no
  handle at all.

## The owner corrects a term, and it lands in the cell about terminology (2026-09-03)

> *"one-shot widget is autohiding widget now, because behaviour itself is repetitive."*

I had argued for keeping *"prompt"* on the grounds that *"a one-shot prompt"* reads well where
*"a one-shot widget"* does not. **The behaviour is not one-shot** — `auto_hide` is a standing mode —
and `D-AUTO-HIDE` says so in as many words. **I argued for a name using vocabulary this feature had
already retired, inside the cell whose whole subject is retired vocabulary.** The phrase is *"an
auto-hiding widget"* and it reads fine, so that side of the ruling has no ergonomic case left.

**Grepping for the retired word found a retired mechanism.** `internals/examples/turtle.md`
documented the **pre-`auto_hide`** turtle in five places — *including its Lua code sample*
(`after_submit = function() compy.input.hide() end`, and a `show` with no `auto_hide`). `FEAT-02`
migrated the example and not its document. Fixed against `main.lua`; the file's *vocabulary* drift
is deliberately left to `FIX-02-09`.

## Two process changes, both the owner's (2026-09-03)

- **The turtle drift's disposition** — *"either registered as active debt and planned, or described
  in the step which unifies terminology if it was not yet executed"*. `FIX-02-09` had not executed,
  so it landed there, with its ruling and its sites, rather than becoming a second ledger entry for
  a goal that already has a row. I checked route three first: `src/examples/turtle/README.md` does
  not mention the widget at all, so no deeper rewrite is coming.
- **The closing order is now three steps** (`agents/validation.md`): commit → **Sonnet peer review
  of the changes** → wrap → **Opus delivery-level review**. Neither sub-agent may spawn its own —
  strict, host-protection, stated with its reason in every prompt.

**And I broke a commit rule while writing that down.** `git add -u` swept the workflow change into
the turtle commit, whose message says nothing about it — a change no commit accounted for. Reverted
and re-applied as its own commit rather than amended: **history is not rewritten here, and a trail
showing the mistake is worth more than a tidy one that hides it.**

## `FIX-02-05`, and the half closes (2026-09-03)

- **Worker returned in ~18 minutes**, deliverable complete and **honest about itself** — it reported
  its own scope slip (a `doc`-wide pathspec that briefly surfaced `wip/` filenames) and a batching
  gap it caught by reconciling its running count against 56. Both disclosures are worth more than
  the tidiness they cost.
- **Its best catch is a Trap-1 instance I would have missed:** the malformed-element entry calls its
  own defect *"pre-existing"*, and that word is relative to **`BUG-02-01` the same morning**, not to
  the base — `sanitize_utf8` and the whole `checked_text` apparatus are branch-new. *"Pre-existing"
  in a register entry does not mean pre-existing.*
- **I re-verified all nine pre-existing entries at base by hand**, that being the consequential
  direction. All nine held.
- **`CHG-01-03`'s yield is one line**: a raise in `love.update` or a pointer handler **vanished** —
  no window, no console line, run continuing — while keyboard handlers reported fine, so the same
  project would show you one crash and hide another. Pre-existing, verified at
  `controller.lua:67`.
- **`CHG-01-01` then yielded once more, and it is the subtler defect:** *"Content that is not text
  is refused… rather than being silently repaired or dropped"* describes **our own interim
  behaviour** as the before. At base the element was **stored as it came**. A changelog line is
  judged by *what a user met*, not by what its debt entry says — the two differ, and `LEDGER-02-04`
  now carries that.
- **The `-09` slice: 25 grep hits, 21 sites.** Four are the `Alt+H` **help overlay**, which is not
  the widget and keeps its name. Left alone deliberately: `turtle`'s section says *"the prompt"* ~20
  times — a **fifth** name, colliding with the documented `prompt` **key**. Outside this row's four
  names and unruled; raised for (b) rather than taken.
- **`CHG-01` is complete, so the slice cut and `ACC-02` are no longer gated by the brace.** Next in
  the sequence is `REC-01`/`MERGE-01` on the three example repos.
- **F2 finished last, and nearly did not happen.** Its disposition said *"taken when `FIX-02-05`
  opens that file anyway"* — `FIX-02-05` closed and I had not done it. **A finding parked against
  another row's opening is a finding that leaves with that row.**

**Plan changed, deliberately, and it is a small change:** `FEAT-03` ran **before** `FIX-02-05`,
not after. The prompt's order (`-05` → `-17` → `CHG-01`) was written before this row existed, and
the roadmap's own principle — *sizing a small row against an unsettled surface is sizing it twice*
— puts the code row first. `FIX-02-05` walks the `RETIRED` section, which holds one of the three
*"there is no content getter"* claims that `FEAT-03` falsifies.

## Late record, session69 (2026-09-03) — the wrap carried no track

The wrap commit `ace9a6b8` is three files and none of them is this one. These bullets are
session69's, dated as the late record they are. The booted prompt is not edited for them.

- **Cold peer review** commissioned (`e7fd2af7`) and returned two findings, both arithmetic, both
  confirmed and applied (`882ba6c3`). The deliverable sat untracked until session69 committed it
  (`d8468910`) — step 1 of the three-step order left git in its first run.
- **Wrap** (`ace9a6b8`): report, session69 handover, pointer. No track in that commit; this file
  stopped at *"F2 finished last"*.
- **Delivery review** commissioned (`1a864137`). Its output
  (`validation/reviews/S68-delivery-revalidation.md`) was likewise untracked until session69
  (`3be6da02`). The review claims seven findings and the file ends at F5.
