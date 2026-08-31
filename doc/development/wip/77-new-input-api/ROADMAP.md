# Roadmap — feat #77, from here to the PR

**The navigable view.** One page, current, ordered. The reasoning lives in
[`validation/plan.md`](validation/plan.md) and the review documents this points at; **this file is
the sequence**. Updated 2026-08-30.

---

## The one-line sequence

**ACC-01 ✅ → ARC-01 ✅ → LEDGER-01 ✅ → ARC-02 ✅ → OP-01 ✅ → FEAT-01 ✅ → FEAT-02 ✅ → { BUG-01 ✅ · BUG-02 · FIX-01 · FIX-02 · DEC-01 · CHG-01 } → FIX-03 → ACC-02 → REC-01 → MERGE-01 → PR-01**

| stage | what it is | why it sits here |
|---|---|---|
| **ACC-01** ✅ | device-free acceptance — a cold PR review against the original stakeholder ask | it found the 26 defects everything after it works through; nothing could be sized before it ran |
| **ARC-01** ✅ | the project widget gets a **run lifetime** instead of an application one | structural: it *dissolved* a defect class rather than patching it, and deleted the teardown machinery the later rows would have been sized against |
| **LEDGER-01** ✅ | the three ledgers get a shape — changelog, decisions, debt | the rows after it record their state somewhere; the somewhere had to exist first |
| **ARC-02** ✅ | `show` composes `configure`; the user's content is `show`'s alone | the second structural row — it dissolved four defects, including two nobody had filed yet |
| **OP-01** ✅ | ledger upkeep for the owner's three hand-filed entries → **Decisions 36 and 37** | needed no ruling, and it produced the design inputs the next stage implements |
| **FEAT-01** | the two surface proposals: **`oneshot`**, and the **payload split** that tells the submit callbacks apart | **leads by blast radius** — it changes the public surface, so `FIX-02-01` is one of its rows' seams, `CHG-01` carries what it breaks, and a slice cut before it lands is cut twice |
| **FEAT-02** ✅ | **`oneshot` becomes `auto_hide`**, a widget property — overruling `FEAT-01-01`'s Q1 | **leads for the same reason `FEAT-01` did, and it is the last surface change**: it moves a key out of the show-only category, so `FIX-02-01`'s neighbours and every slice are sized against it. It also closes a live defect — disarming a `oneshot` today costs the user's draft |
| **{ BUG-01 ✅ · BUG-02 · FIX-01 · FIX-02 · DEC-01 · CHG-01 }** | the defect sprints — runtime defects, citation hygiene, docs and vocabulary, the decisions ledger's rename, the changelog | one brace, not a sequence: they interleave. Two hard constraints — **DEC-01 and CHG-01 finish before any slice is cut**, and **CHG-01 also gates ACC-02**. A third is conditional: **if `BUG-02`'s weighing goes to *fix*, it finishes before `CHG-01`** |
| **FIX-03** | the ephemeral-citation sweep, **and retired-id citations** | **runs last of the fixes on purpose** — it catches what the others miss, and running it first means three brooms over one floor |
| **ACC-02** | human acceptance — a second cold review, then the smoke passes on real hardware | the first row that needs a keyboard and a device; everything before it is desk work |
| **REC-01** | upstream reconnaissance — measure the real drift, decide what it means | 🟡 platform repo **done**; the three example repos remain |
| **MERGE-01** | upstream reconciliation — actually merge | 🟡 platform repo **done** (`f4913833`); `maze`, `keyboard`, `balloons` remain |
| **PR-01** | assembly — the shipping slice cut, the description, the coordinated PRs | last by construction: a slice regenerated before the tree stops moving is regenerated twice |

*The ordering principle throughout is **blast radius, not severity** — anything that can reveal more
defects, escalate into a design decision, or reach deep enough to cause regressions goes first, and
narrow mechanical rows follow. Sizing a small row against an unsettled surface is sizing it twice.*

## Where things stand

| | |
|---|---|
| branch | `feature/77-newapi-analysis-s20260615` |
| suite | **1032 / 0 / 0 / 10** — 1030 + the two the sprint's cold peer review earned (a shortcut receiving the typed case, and the parser's byte column reaching the caret); 1030 was 1028 + `BUG-01-05`'s two (the character clamp, at `set_cursor` and at the `set_text` keep_cursor landing); 1028 was 1025 + `BUG-01-04`'s three (upper-case serialisation bare and modified, and the end-to-end textinput dispatch); 1025 was 1023 + `BUG-01-09`'s two breaking tests (the multi-line string, at `show` and at the live `set_text`); 1023 was 1021 + `FEAT-02`'s two (the `configure` disarm that keeps the draft, and `false` as the unset; two further cases replaced the ones pinning the retired category); the 10 pending are an owner ruling, an 11th is a finding |
| marker gate (`src`/`tests`) | clean — **but it never covered `doc/`**, which is FIX-02-01 |
| slices | regenerated, **100 / 100 complete and disjoint** |
| baselines | pinned as local tags, [`TAGS.md`](TAGS.md) — nothing fetched since |
| upstream | **Platform repo reconciled** with `upstream/dev` (`aldum/dev`) via MERGE-01-04 (commit `f4913833`) |
| downstream | **this build is the experimental foundation of the platform's `serial` API work** (owner, 2026-08-30) — the snapshot taken after the upstream merge and before the hand-filed debt entries. It **does not delay the release; it sets the mark** — see the note below |

**A downstream consumer now stands on this branch** (owner, 2026-08-30). Platform work on the
**`serial` API** took this build as its experimental foundation — the snapshot after the upstream
merge (`f4913833`, `75a7e5b3`) and before the hand-filed debt entries (`880c45ef`). Two consequences,
and the owner has ruled on the first: **it does not delay the release**, it *sets the mark*. The
second is `FEAT-01`'s business — the payload split (`FEAT-01-03`/`-04`) is a **breaking change with
a real consumer now**, not a theoretical one, so `CHG-01`'s migration note has an audience and
should be written for it. The `serial` surface is also the origin of two of the three hand-filed
entries: its author asked for `oneshot` and met the namespace-clone hazard.

*(The exact snapshot is unpinned. If it matters later, tag it — `TAGS.md` is where this branch's
baselines live, and the range is `75a7e5b3..880c45ef` with nothing in between but this session's
predecessor's work.)*

**The spinoff sprint is closed and TF2 with it.** With `ARC-01` and `ARC-02` both complete, what
remains is acceptance, the residue of the four defect sprints, reconciliation, and assembly.

---

## ✅ ACC-01 — device-free acceptance — **COMPLETE**

| id | step | result |
|---|---|---|
| ACC-01-01 | slice regeneration, the review cut | found **5 files outside every pathspec**, one production code |
| ACC-01-02 | cold PR review vs the original stakeholder ask | **merge with changes — 26 defects** (19 from the review, 2 the owner found reading it, 5 from the remark triage) |

Detail: [`validation/reviews/ACC-01-02-findings-triage.md`](validation/reviews/ACC-01-02-findings-triage.md) ·
report: [`validation/outcomes/ACC-01-02-cold-pr-review.md`](validation/outcomes/ACC-01-02-cold-pr-review.md)

---

## ✅ ARC-01 — the project widget gets a run lifetime — **COMPLETE**

**Landed in session48** (`e684458b`, `e28a20f6`, `314fca05`, `55f9edd4`, `e13ef346`, `739d17ea`): the widget is built at the run seam and destroyed at the stop, the ledger is amended, the teardown machinery is deleted, and `close_project` no longer leaves a closed project's widget behind. **Cold review: approve** — [`validation/outcomes/ARC-01-cold-review-s48.md`](validation/outcomes/ARC-01-cold-review-s48.md). `ARC-01-07` was answered by the cold session49 — a research row, so it closes with a written reason
and no code: the two policies are one rule plus one exception, `prompt` is on the right side of it by
owner ruling, and the residue was redistributed to `FIX-02-21`, `BUG-01-06` and the new `BUG-01-07`.

*(New KIND: `ARC` — structural work that dissolves a defect class. Filing it as a `BUG` row would
hide from a reader that it removes machinery rather than patching it. Owner-ruled 2026-08-26.)*

**Leads everything, and dissolves work rather than adding it.** Two defects fixed today
(`bd2a5d49`, `8a9022ec`) were the same shape: a store on an application-lifetime object holding
something a project put there. Both fixes are hand-maintained wipes, and a third store was missed
for months precisely because the wipe list is maintained by hand. **This row removes the need for
the list.**

### The finding that unlocked it (owner, 2026-08-26)

Decision 3 is read as "the input widget is a singleton, forever". **Its NFR does not say that:**

> *"A non-functional requirement forbids allocating a fresh object graph **per input session** — the
> device is memory-constrained and the common pattern is **repeated prompting**."*

**Per input SESSION — not per project RUN.** Repeated prompting is a within-run pattern; a project
run is a human-scale event already doing far more expensive work. The NFR was applied one boundary
wider than it states, and that boundary was never examined. **Decision 3 is therefore not withdrawn
— it is implemented at the boundary it specifies** (owner: *"we do not even have to withdraw it —
just implement it properly"*).

Its own guards agree: `input_nfr_mechanism_spec.lua` asserts identity across **show/hide cycles**
(`the widget keeps identity across cycles`, `no widget model is reallocated`) — both pass unchanged
under a per-run lifetime.

**Provenance, recorded because it bears on the ratification question:** the NFR was the owner's own,
not a stakeholder ask — stakeholders agreed *reluctantly*, and real feasibility was never computed.
There is no show-and-hide-many-times-per-second pattern in this codebase.

### Measured blast radius — production is net deletion

| site | change |
|---|---|
| `main.lua:379` | construction moves to the run seam |
| `consoleController.lua:782` | **the one real coupling** — `state.callbacks` / `state.pending` are captured **by reference**; must resolve dynamically |
| `consoleController.lua:183/809/813`, `projectInputController.lua:158` | already resolve dynamically — no change |
| `userInputView.lua:294` | self-identity guard — unaffected |
| `controller.lua:349` | `reset_widget_outputs` **deletes**, and with it `reset_callbacks`, `clear_pending`, and both of today's fixes |

**Tests:** 101 `F.widget` touchpoints across 8 files, but **every one of those files also calls
`activate_project`** — so none is structurally incompatible, and the fix is one fixture seam
(re-point `F.widget` at activation). Then 5 local aliases and 26 `F.show_widget` uses need eyes.

### Steps

| id | step | note |
|---|---|---|
| ~~ARC-01-01~~ ✅ | ~~choose the seam~~ — **the seam is `run`, not `open`**; nil audit and pen-and-paper **both confirmed by experiment** (session48) | `ConsoleController:restart()` (`consoleController.lua:1179`) and Ctrl+T quickswitch (`controller.lua:793-808`) both call `stop_project_run()` + `run_project()` **directly, bypassing open/close** — construct-at-open would leave every restart on a stale widget. **Nil audit: all six consumers survive a nil widget, and every guard was mutation-tested to prove the probe would have caught it.** **Pen-and-paper: sapper run in the real app** — passes through `run_project`, is fully alive at `project_open`, and `stop_project_run` fires once, *from* `project_open`. No can of worms; proceed. [`validation/notes/ARC-01-01-verification.md`](validation/notes/ARC-01-01-verification.md) |
| ARC-01-02 | `state.callbacks` / `state.pending` resolve dynamically instead of being captured | **bigger than "one coupling"** — captured in two places (`:790-805`, `:512-527`) and read as plain tables by four functions (`merge_callback_keys`, `consume_pending`, `stash_hidden_configure`, `api_show`). A shape change, not a one-liner. **Must land BEFORE ARC-01-04** (the construction move; `-03` as
filed): **proven** at `ARC-01-01` — constructing a `ConsoleController` with the widget nil raises.
`get_compy_input` runs at boot, before any project exists, so under a per-run widget the capture would index nil (`main.lua:379` publishes the widget, `:383` builds the console — today's ordering exists for exactly this) |
| ARC-01-03 | **amend the ledger: Decision 3 AND Decision 7** — the gate before any lifetime code | **owner-gated.** Decision 3 says *"created once at load"* and names four instances; per-run is not a reading of that, it is a change to it. **Decision 7 needs the same treatment and was missed when this row was filed** (found session48): it freezes the *identity* of `callbacks`, and a per-run widget changes that identity between runs. Nothing a project can observe — within a run both hold — but "amend, don't reinterpret" applies to both. Base check makes both easy to write: the singleton is this branch's own invention |
| ARC-01-04 | construction + destruction move to the seam | |
| ARC-01-05 | delete the teardown machinery the lifetime replaces | the payoff commit |
| ~~ARC-01-06~~ ✅ | fixture seam + the spec fallout | **mostly landed inside `ARC-01-04`** — suite-green-at-every-commit forced the fixture seam to move with the lifetime rather than after it. `F.widget` stopped being a captured field and now resolves to the current widget, so all touchpoints follow the lifetime; `F.run_project` and `F.other_widget` were added; the stop-teardown cases were restated as "the stop destroys the widget and the next run gets a clean one". What remained is a sweep for stale assumptions, done in session48 |
| ~~ARC-01-07~~ ✅ | ~~**why do two reconfiguration policies coexist in the widget instead of uniform logic — and is `prompt` on the wrong one?**~~ **ANSWERED (session49):** the split is *one* policy plus one deliberate exception — **content resets, everything the project sets persists until replaced** — and `prompt` is on the **right** side, by owner ruling. What was never written down is the rule itself. Three things survive as work: **FIX-02-21** (the classification + doc unit, no behaviour change), **BUG-01-06** (the `force` path's three behaviours for one call's keys), **BUG-01-07** (balloons' shadow label). Analysis: [`validation/reviews/ARC-01-07-reconfiguration-policies.md`](validation/reviews/ARC-01-07-reconfiguration-policies.md); ruling: [`validation/notes/owner-attestation-prompt-field.md`](validation/notes/owner-attestation-prompt-field.md); probes: [`validation/notes/ARC-01-07-behaviour-probes.md`](validation/notes/ARC-01-07-behaviour-probes.md). *Original filing:* | **owner, 2026-08-26 — filed here so it is not forgotten, deliberately not investigated yet.** `apply_config` treats some fields as *set-if-given* and others as *always-set*; `cfg.prompt` is on the first policy, which is how `8a9022ec`'s cross-project label leak was possible. Answer whether the split is intentional and whether `prompt` sits on the right side of it. A little orthogonal to the lifetime work, but it lands in the same function ARC-01 is already reshaping, and it may escalate into a design call — handed to a COLD session (owner, 2026-08-27) — it is a fresh question and deserves a reader who has not spent a session inside the lifetime work |

**Crosswalk — two inserts, both 2026-08-26/27.** No ARC id appears in `src/` or `tests/`, so rule
2's renumber branch applies; earlier notes, prompts and commit messages carry the old numbers.

| as filed | after the two inserts | **final** | step |
|---|---|---|---|
| `ARC-01-03` | `ARC-01-04` | **`ARC-01-04`** | construction + destruction move |
| `ARC-01-04` | `ARC-01-05` | **`ARC-01-05`** | delete the teardown machinery |
| — | `ARC-01-05` → `-06` | **`ARC-01-07`** | the reconfiguration-policy question (owner) |
| `ARC-01-05` | `ARC-01-06` → `-07` | **`ARC-01-06`** | fixture seam + spec fallout |

`ARC-01-03` is new and is the ledger-amendment gate. The last swap is the owner's (2026-08-27):
the policy question was filed ahead of the churn step and then executed after it, so the ids were
put back in execution order rather than left disagreeing with it — rule 2's whole point.
**Session48's `prompt.md` uses the ORIGINAL numbers** — its `ARC-01-03` is now `-04`, its `-04` is
`-05`, and its `-05` is `-06`.

### Pen-and-paper projects — asked by the owner, answered by reading, still to be confirmed

**Do projects that live in `project_open` and never stay in `'running'` (sapper-like) lose their
widget?** Read says **no, and the seam answer stands**: they still go *through* `run_project`, which
sets `'running'`, executes the top level, and — when the run is non-blocking — settles at
`'project_open'` **without releasing anything** (`consoleController.lua:286-320`). So construction at
`run_project` reaches them, and destruction at `stop_project_run` is the same boundary Decision 11
already uses for every channel.

**The trap to avoid is precise:** bind destruction to `stop_project_run`, **never** to the
`running → project_open` transition. That transition is exactly where `release_keyboard_route` once
fired, and pointer had to be exempted from it *because* pen-and-paper projects broke — the asymmetry
Decision 11 was amended to delete. Rebuilding the same mistake with a widget instead of a route is
the live hazard here.

**CONFIRMED 2026-08-26 with the real `sapper`, in the real app** (harmony under `xvfb`), not by
reading. It passes through `run_project`, settles at `project_open` and *plays* there — a started
board, twelve cells opened — and `stop_project_run` fires exactly once, at Ctrl+Shift+Q, entered
*from* `project_open`. Both seams are reachable for pen-and-paper projects; the transition between
them is not one of them. Evidence and screenshot:
[`validation/notes/ARC-01-01-verification.md`](validation/notes/ARC-01-01-verification.md).

### Risks, stated before starting

1. ~~**Nil between runs**~~ — **RETIRED 2026-08-26, confirmed not a risk.** Every consumer guards,
   and each guard was mutation-tested. One caveat survives into the later steps: on the **dispatch**
   path a raise is swallowed by `with_canvas_and_errors`, so nil-safety there must be asserted
   against the **error channel** (`suspend_msg` / `app_state`), never against "no crash"
   ([`validation/notes/ARC-01-01-verification.md`](validation/notes/ARC-01-01-verification.md)).
2. ~~**Owner ruling 2026-07-20 softens**~~ — **RE-MADE BY THE OWNER 2026-08-27: granted, "trivial".**
   *"`compy.input.callbacks` IS the widget's table"* becomes *"resolves to the current widget's
   table"*. What follows from it is work, not risk: the ruling is quoted in three code comments
   (`main.lua`, `consoleController.lua` ×2) that say **IS**, and they are corrected as part of
   `ARC-01-02`. The ledger half — Decision 7's frozen `callbacks` identity — is `ARC-01-03`.
3. **Test churn is moderate, not trivial** — sized at the fixture seam, not before it.

### The scope boundary a reviewer will ask about (checked at ARC-01-02, 2026-08-27)

**Why does the widget get a run lifetime while `compy.input` itself stays application-lifetime?**
The surface keeps two stores of its own — `shortcuts` and `hooks` — and they are still wiped by hand
at teardown (`reset_compy_input`), which looks like the very class this row exists to kill.

**Checked, and it is not the same class.** That wipe walks `_bindable` — *the same channel list the
dispatcher itself dispatches on*, not a hand-copied roster of it. A channel cannot exist for
dispatch and be absent from teardown, so the list cannot drift. What made the widget's stores
dangerous was the opposite: `reset_widget_outputs` named individual *fields* (`custom_label`, the
evaluator's `highlighter`) one by one, and a third field went missing from that list for months.
**Deliberately out of scope, with a reason — not an oversight.**

### What it dissolves

- **`BUG-01-02`** loses its teardown half; only the within-run design call (sentinel vs
  `clear_highlighter`) survives for the owner to rule on. **Which is why ARC-01 runs first.**
- **`FIX-02-21`**'s cross-run dimension is already gone (`8a9022ec`) and stays gone structurally.
- The debt entry's revisit trigger (*"a third run-scoped store here should move `state` to a per-run
  lifetime"*) is **this row**, arriving early.

**Nothing a project can observe changes, except that the leaks stop** — which is the PR story: the
NFR implemented at the boundary it specifies, deleting the machinery that existed to fake it.

### Cold second opinion (2026-08-26): **sound, but not now**

[`validation/outcomes/ARC-01-cold-second-opinion.md`](validation/outcomes/ARC-01-cold-second-opinion.md).
Its three substantive findings were **verified in code** and are folded into the steps above. Two
corrections to this row as originally filed:

- **Decision 3 needs an explicit amendment, not a reinterpretation.** Its literal text says *"created
  once at load"* and enumerates four instances by name. The per-session reading is defensible on the
  stated *mechanism* but reaches past the words — so the honest move is to amend the decision and say
  why, not to argue the words already allow it. **Conceded — and it now has a step of its own,
  `ARC-01-03`, which session48 widened to cover Decision 7 as well.**
- **"Net deletion" was optimistic** — likely a wash once the `get_compy_input` reshape, the boot
  ordering fix and the Decision 3 amendment are counted. The 101 test touchpoints are exact, but only
  4 sites call `run_project`, so most of that churn would not exercise the new lifetime **without
  new tests written for it** — a coverage gap, not just churn.

**The argument for deferring:** a table-driven `reset_config` symmetric to `apply_config` closes the
same defect class, so ARC-01's *urgency* collapses even though its *correctness* stands.

### The base check that overturns the deferral (owner, 2026-08-26)

**The reviewer did not check the PR base, and the owner did.** At `3256aac` the project's input
widget was constructed **per activation** — model, controller AND view, fresh inside the `input()`
closure on every `input_text`/`input_code` call (`consoleController.lua:563-580` at base), with
`love.state.user_input = nil` on the way out. Three consequences:

1. **The singleton is this feature's own invention**, not inherited. Decision 3's *"created once at
   load"* describes something that did not exist before this branch — which makes the amendment far
   easier to write, and largely dissolves the reviewer's "looks like a loophole" concern.
2. **Per-run allocation is still strictly less than the base did**, and the base shipped on the same
   memory-constrained device without complaint. The NFR's premise was never tested against the
   system that had been doing the opposite all along.
3. **The merge argument for deferring is backwards.** ARC-01's merge-sensitive sites are the
   `main.lua` boot block (code *this feature added*, which ARC-01 removes) and
   `reset_widget_outputs` (likewise). **Deferring means reconciling both against 86 commits of
   upstream drift and then deleting them** — reconciliation spent on code already scheduled for
   removal. Doing ARC-01 first shrinks our side of the diff before the merge is computed.

**Ruling: ARC-01 runs before MERGE-01, as originally filed.** The cold review's *"not now"* was
priced on a merge-cost argument this fact does not support; its other four findings stand and are
folded in above.

---

## ✅ ARC-02 — `show` composes `configure`; the user's content is `show`'s alone — **COMPLETE**

**Plan: [`validation/reviews/ARC-02-configure-boundary-plan.md`](validation/reviews/ARC-02-configure-boundary-plan.md).**
Owner-settled design (2026-08-27), grown out of `ARC-01-07`. `configure` runs everything except the
user's input and refuses `text`/`cursor`; `text`/`cursor` are `show`'s alone; every other flag is
processed only when non-nil, in both calls. `show{force = true}` becomes the **full re-setup** the
stakeholder was shown and gated — intent recovery in
[`validation/reviews/force-and-configure-intent-recovery.md`](validation/reviews/force-and-configure-intent-recovery.md) §1.

**Debt goal: `T-CFG-BOUNDARY`** (`technical_debt/input.md`) — this whole sprint is the tasks that
fulfil it.

**An `ARC` row because it deletes rather than patches:** `re_show`, the `live` filter table, `text`
inside `apply_config`, and — under pick A(ii) — `state.pending` entirely.

**Both picks settled** (owner, 2026-08-27) and the shape is ratified as **Decision 35** in
`doc/development/decisions/input.md` — the persistent ledger, so it outlives `wip/77`, and that entry
is also the deviation record. `text`/`cursor` at `configure` **raise** as keys belonging to another
call, so `ARC-02-01`'s Decision 15 gate is in scope and comes first; the hidden-`configure`
stash **goes**, on the owner's ground that the promise was redundant when it was made — content for a
widget about to come up is set by the `show` that brings it up, before it is visible.

**`reset()` is recommended but not built in this release** (owner). The recommendation and the two
constraints on whoever builds it live in Decision 35's closing section, not in the ephemeral plan.

| id | step | note |
|---|---|---|
| ARC-02-01 ✅ | the ledger gate — `text`/`cursor` join `force` as `show`-only keys in Decision 15 | **DONE.** Landed as an **addition, not an amendment** (owner ruling, 2026-08-27, on the cold review's argument): Decision 15's warn list names three runtime states and `configure{text}` was never one of them, and the decision already raises for a key belonging to another call — `force`. So the keys join an existing category instead of crossing a line. Decision 35's own framing was aligned to match |
| ARC-02-02 ✅ | breaking tests first, one per claim | `force` applies the prompt / applies the highlighter **now** / clears with no `text`; `configure{text}` refuses; hidden `configure{prompt}` shows next time. Each seen to fail first |
| ARC-02-03 ✅ | `text` leaves `apply_config`; `reset_content` on the activation path | the single-policy move. **Trap:** `clear_input` ≠ `set_text('')` — it also clears the selection, the custom status and the history index (plan §2a) |
| ARC-02-04 ✅ | `re_show` deletes; `show` composes | the payoff commit — `BUG-01-06` and its sibling dissolve here |
| ARC-02-05 ✅ | `configure` refuses `text`/`cursor`; `pending` **deletes** | `consoleController` key sets, `consume_pending`, `stash_hidden_configure`, `WIDGET_STORES` |
| ARC-02-06 ✅ | **`BUG-01-10`** — the highlighter gets one home, proxied via `callbacks` | **folded in at the owner's direction, 2026-08-27**, rather than run after. It rewrites the same `apply_config` / `callbacks` seam that `-03` and `-05` rewrite, and touching that seam twice is how the copy step that causes this defect got missed in the first place. The evaluator stops holding a copy; `compy.input.callbacks` proxies to the widget's slot, so a direct assignment and a `show`/`configure` key reach the same place **by construction**. **Land it after `-05`**, once the config paths have settled. Ruling and rationale on the `BUG-01-10` row; the drift it replaces is documented in `internals/user_input.md` at `-08` |
| ARC-02-07 ✅ | **`BUG-01-08`** — the cursor shapes | must precede any documented "unset by a reasonable default" rule, which is what would make a scalar cursor something a project writes |
| ARC-02-08 ✅ | docs + the deviation record + **`CHANGELOG.md`** | executes **`FIX-02-21`** and answers **`FIX-02-12`**; `false` as the uniform unset; the balloons rationale into the persistent internals doc. **`CHANGELOG.md` is in scope here**: `LEDGER-02` wrote its input bullets against today's behaviour, and `ARC-02` changes some of what they describe (a forced `show` clears; `configure` refuses `text`/`cursor`) |
| ARC-02-09 ✅ | sweep the fixture and specs | the `ARC-01-06` lesson — expect it partly absorbed by `-03`…`-05` |

**Cold review of the plan: approve with changes** —
[`validation/outcomes/ARC-02-plan-cold-review.md`](validation/outcomes/ARC-02-plan-cold-review.md).
It confirmed §2(a) and the containment of every deletion, and returned four changes that are folded
in above or listed here: **(1)** a forced `show` with no `text` reverses package-approved text and a
green spec, so it needs its own deviation line — **written into Decision 35**; **(2)** the hidden
`configure{prompt}` path needs a nil-widget guard (`input_nfr_mechanism_spec.lua:117-125`) and must
keep `merge_callback_keys`; **(3)** `-02` cannot be its own commit under suite-green-at-every-commit
— the breaking tests land **with** the step that makes them pass, and `-08` cannot trail; **(4)** the
"unfiled sibling" claim was wrong and is corrected in `BUG-01-06` above. It also found
**`BUG-01-09`**.

**Crosswalk (one insert, 2026-08-27).** `BUG-01-10` was folded in as `-06`; the three steps after it
each moved up one — the old `-06` (cursor shapes) is now `-07`, the old `-07` (docs) is `-08`, and the
old `-08` (fixture sweep) is `-09`. No `ARC-02` id appears in `src/` or `tests/`, so rule 2's
renumber branch applies. **The plan document and the cold review use the pre-insert numbers.**

**Closes or dissolves:** `BUG-01-06` (+ its unfiled sibling), **`BUG-01-10`**, `BUG-01-08`, `FIX-02-21`, `FIX-02-12`,
and it drops `BUG-01-02` out of the design-escalation column — `highlighter = false` already works,
so that row becomes ratification. **Not in scope, but recommended:** `reset()` (predecessor §8d) — a public addition
needing its own justification line, deliberately kept out of a sprint whose value is deletion, and
carried forward as a recommendation in Decision 35 rather than lost with `wip/77`.

---

## ✅ LEDGER-01 — the three ledgers get a shape — **COMPLETE**

**Owner directive, 2026-08-27.** `CHANGELOG.md`, `decisions/*` and `technical_debt/*` become three
ledgers that answer *where are we* at **project altitude**, so that question stops requiring a read of
a plan that is reorganised every few sessions. All three are in the persistent corpus and survive the
deletion of `wip/77`. The contract binding them is
**[`agents/rules/ledgers.md`](../../../../agents/rules/ledgers.md)** — a sibling to
`agents/rules/roadmap.md`, which governs planned work where this governs state.

| unit | result |
|---|---|
| `LEDGER-01-01` | **changelog** — `Unreleased` → `CURRENT_SCOPE` with its release protocol stated in-file; `Removed` leads with the breaking change; `Added`/`Changed` brought up to the work. Commits `f4c85ec5`, `b76ed826` |
| `LEDGER-01-02` | **decisions** — `ACTIVE` (28) / `RETIRED` (6); numbers and text untouched, 34 in and 34 out. Produced the verified ruled-but-unimplemented list. Commit `b54e5e81` |
| `LEDGER-01-03` | **debt** — `ACTIVE` (10 + 4 in `general.md`) / `BACKLOG` (41 + 1) / `RETIRED` (23) on the owner's release-scope rule; 64 → 74 entries, the ten additions being two unimplemented decisions and eight uncovered defects. Commit `1e635f6f` |

Sub-agent prompts of record in `validation/prompts/LEDGER-0*`; their reports in
`validation/outcomes/LEDGER-0*`. Each was reviewed and corrected before landing — see the commits.

### The cross-check, run once — and it found one thing

`agents/rules/ledgers.md` §5: *an `ACTIVE` debt entry with no roadmap row pointing at it is a visible
gap.* Run 2026-08-27 over all 15 ACTIVE entries. **Fourteen map to a row** — the ten `BUG-01` rows,
`ARC-02` (Decision 35), `FIX-02-15`, `CHG-01-04`, `FIX-02-05` and `DEC-01`.

**One did not: Decision 1's console/editor convergence** — and the absence was the symptom rather
than the cause. The decision itself calls that convergence *"deliberately left as a follow-on"*, so
under the release-scope rule it is **BACKLOG**, and it was filed ACTIVE only because the sub-agent
prompt said to file unimplemented decisions there. That instruction was mine and it was too broad: a
decision deliberately deferred past this release is deferred debt, not release-blocking debt. Re-sorted.

**Both directions are now wired** (2026-08-27). Every `ACTIVE` debt entry carries a **`T-` slug** —
uppercase mnemonic, 16 characters at most, declared first in its heading, matching the shape the
decisions ledger is converting to — and every roadmap row that works towards one cites it. So the
cross-check is a grep rather than a careful read:

```sh
# the goals                                   # the tasks pointing at them
grep -h '^### T-' doc/development/technical_debt/*.md | sed -E 's/^### (T-[A-Z-]+) .*/\1/' | sort -u
grep -ohE '`T-[A-Z][A-Z-]+`' doc/development/wip/*/ROADMAP.md | tr -d '`' | sort -u
```

`comm` the two: a goal missing from the second list is unscheduled release-blocking work, and a
citation missing from the first is a pointer to nothing. **Match the goal side on `^### T-`, not on
a bare `T-[A-Z]`** — a loose pattern also catches the convention being *described* in prose, and the
check comes back green because both sides picked up the same prose. It did exactly that the first
time it was run here.

`BACKLOG` and `RETIRED` entries are deliberately **not** slugged. A decision is cited from `src/` and
`tests/`, which is what makes *its* numbering dangerous; a debt entry is cited from plans, so the ones
needing a stable handle are exactly the ones a row points at. An entry earns its slug when it becomes
`ACTIVE`.

### The absorption was partial, and saying so is the point

The three rows below were expected to be **absorbed** by this work (owner, 2026-08-27). Reading them
in full afterwards, they are not: the restructuring did the *structural* half of each and left real
work standing. Closing them would have been the "omission is not a ruling" failure
(`agents/rules/roadmap.md` §5) with a ruling as its cover. **What each still owes is annotated on the
row itself.** The recommendation to absorb them wholesale was mine and it was wrong in detail.

**Each non-absorbed remainder now earns a debt entry** (owner, 2026-08-27: *"docs/readability debt
is still a debt"* — including work on the ledgers themselves). All three are in
`technical_debt/general.md` under `ACTIVE`, since they are ledger-hygiene debt rather than
subsystem behaviour, and each is exempt from the cite-a-decision rule as an **obvious operational
need** (`agents/rules/ledgers.md` §4): the unsettled **version number**, the **unverified resolved
entries**, and the **decisions ledger's numbering**.

---

## ✅ FEAT-01 — the two surface proposals the owner filed from the device — **COMPLETE**

**New KIND, owner-ruled 2026-08-30: `FEAT` is design-and-implementation of a proposed surface
change** — distinct from `BUG` (something misbehaves), `FIX` (docs and process) and `OP` below
(ledger upkeep). The owner wrote the two proposals straight into `technical_debt/input.md` from the
device (`880c45ef`); **the ledger entries are the authority on content**, these rows are the
sequence.

**This sprint leads the remaining work, by the ordering principle rather than by preference.** Its
design inputs are in hand — `OP-01` wrote Decisions 36 and 37 first, so what is left here is
ratifying the edges and building. Both rows change the **public surface**, so everything downstream is sized against them: `FIX-02-01` is
the same seam as `-03`, the CHANGELOG's breaking-change section is `CHG-01`'s subject, and a slice
cut before either lands is cut twice. It is also the sprint that **grows** the API, which is the one
direction the strategic frame watches — see the note under `FEAT-01-01`.

**Four rows of work and two of documentation, deliberately.** Both changes are meaningless to a
project author who cannot find them: `oneshot` is a convenience nobody uses if the guide does not
show the one-line form, and a payload split that is not explained just moves the confusion
`FIX-02-01` names from the callbacks to their arguments. `-05` and `-06` are not a write-up phase
appended at the end — they are what makes `-02` and `-04` worth having.

| id | step | notes |
|---|---|---|
| **FEAT-01-01** ✅ | **the `oneshot` design ruling** — what the option means at the edges, before any code · **`T-ONESHOT`** | **RULED 2026-08-30.** Three edges ratified as recommended, one **reversed**: `oneshot` closes on a **clean submit only**, because the error boundary the recommendation stood on wraps the route, not the submit chain. Sheet: [`validation/reviews/FEAT-01-01-oneshot-ruling-sheet.md`](validation/reviews/FEAT-01-01-oneshot-ruling-sheet.md). *Original filing:* **owner-gated, and the design questions are real**: does `oneshot` close on *submit only*, or also on cancel/escape? Does it survive a `configure`? Does it compose with an `after_submit` the project also set, or refuse one? The entry's own attestation is the constraint — it was **removed in-flight to avoid over-sugaring** and comes back because **microbit development re-confirmed the need**, so the ruling must say what earns it back |
| **FEAT-01-02** ✅ | implement `oneshot` | breaking-test first per `agents/development.md`; the framework side *is* testable, unlike the example side (`general.md` BACKLOG) |
| **FEAT-01-03** ✅ | **the payload split** — `on_text_entered` yields concatenated plain text, `after_submit` yields the list of lines · **`T-PLAINTEXT-ENTERED`** | **ruled together with `FIX-02-01`, never separately.** That row asks whether the two hooks are one callback set two ways; this is a candidate *answer* — keep both, differentiate their payloads, and `after_submit` gains a reason to exist beyond closing. The owner's framing is a **recommended convention, not an enforced one**. **RULED 2026-08-30, jointly with `FIX-02-01`** — Decision 37 is the ruling and says so in its own text; this row confirmed it is executable and corrected its consequence paragraph, which read as though all seven consumers merely simplify. They do not: four keep working untouched (`string.unlines` is idempotent over a string) and three break **silently**. |
| **FEAT-01-04** ✅ | implement the split; **feed `CHG-01`** | a payload change on a documented callback is **breaking** — the `Removed`/`Changed` sections and the justification table both carry it |
| **FEAT-01-05** ✅ | **document `oneshot`** in `doc/input_api.md` — the `show` config table, and a worked example | the worked example is **the one-line question** (prompt + `on_text_entered` + `oneshot`, nothing installed and nothing torn down), because that is the case the flag exists for. Decision 36 names it. Also the config-key lists and the CHANGELOG's `Added` section |
| **FEAT-01-06** ✅ | **document how to choose between `on_text_entered` and `after_submit`** | the guide currently describes both and distinguishes neither, which is `FIX-02-01`'s complaint. The text to write, per the owner: **either or both may be used; the recommendation is `on_text_entered` for text-centric work and `after_submit` for generic machinery — useful for clarity and for cutting boilerplate, and explicitly not enforced.** Write it *with* `-05`: a reader meeting `oneshot` is a reader deciding which callback to hang their work on |
| **FEAT-01-07** ✅ | **consider rewiring the examples that join the lines themselves** — *only where it makes the example clearer* | **DONE 2026-08-30 — all four joiners rewired, none `wontfix`, and the reason is the same in each: the join was never what the example is about.** `repl` becomes `print(text)`, `tixy` `body = text` (its parameter was already *named* `text` while holding a line list), `maze` `start_program(text)`, `balloons` `current_handler(text)`. Two of the four — `maze` and `balloons` — carried comments stating that the API hands you LINES, which the split made **false**, so those two would have needed a commit whether or not the code moved. The three `lines[1]` consumers are not this row's: they broke silently and migrated with `FEAT-01-04`. `maze` (`d2be028`) and `balloons` (`6d6c6e3`) are commits in their own repos. *Original filing:* **conditional by design** (owner, 2026-08-30), and it runs **after `-04`**, not inside it. Four examples call `string.unlines` on the payload as their first statement (`maze`, `tixy`, `balloons`, `repl`) and three take `lines[1]` (`turtle`, `valid`, `guess`); every one of them *could* drop that line under the new payload. The row asks whether doing so **reads better**, example by example — an example exists to be read, and a mechanical sweep that leaves a call site less obvious has spent clarity to buy consistency. `wontfix` per example is a legitimate outcome. Two of the seven are in **separate repos** (`maze`, `balloons`), so their changes ride their own PRs |

**The frame question, stated once so the ruling is taken with it in view.** The stakeholder ask was a
*simpler and more robust* input API, and the PR must not carry moving parts beyond it without a
line in the justification table. `FEAT-01-01` adds an option; `FEAT-01-03` changes what a documented
callback hands you. **Both are defensible and neither is a new moving part**: `oneshot` is a
*restoration* of a name the replaced API had, requested by the `serial` API's author from outside
this work, and the payload split makes two confusingly-similar hooks distinct instead of redundant
— it answers a simplicity complaint rather than adding to one. Both still need that line written,
not assumed.

---

## ✅ FEAT-02 — `oneshot` becomes `auto_hide`, a widget property

**Owner ruling, 2026-08-30, in discussion — it overrules `FEAT-01-01`'s Q1, made the same day.**
Attestation with the reasoning, what was rejected and what this does *not* fix:
[`validation/notes/owner-attestation-oneshot-widget-property.md`](validation/notes/owner-attestation-oneshot-widget-property.md).
Debt goal: **`T-ONESHOT-SCOPE`**.

**The principle replaces an analogy.** Decision 36 put `oneshot` beside `text`, `cursor` and `force`
because it *describes this session*. The category's real reason is narrower — `text` and `cursor`
are **the user's**, and `force` sits there because it is *meaningless* at `configure`, not because it
is protected from it. **`oneshot` is machinery, and the user does not own lifecycle**, so it was
admitted on a resemblance to two keys it does not resemble.

**It also closes a live defect.** Today, disarming a `oneshot` mid-session requires `show{force}`,
which is a **full re-setup that clears the user's draft** (Decision 35, statement 4, pinned by
`force without text clears the content`). Changing your mind about the flag costs the user's typing.
That is the strongest argument for the change, and it is a defect rather than a preference.

**Cold by preference (owner):** `FEAT-01` was executed and ruled inside one long context, and this
row overturns part of it. A reader who did not argue for the thing being overturned is the right one.

**DONE 2026-08-30 (session58), suite 1021 → 1023.** `-01` `19f47df0` (Decisions 36 and 35 amended,
preceded by `8bca3c04` repairing three citations of what had been withdrawn), `-02` `fe076244`
(token-only rename), `-03` `2c6fe978` (the category move, with its four breaking tests — **the test
inversions `-05` was filed for landed here**, because tests-first is what proves the move), `-04`
`5ad6e518` (guide + internals + the retired `T-ONESHOT` entry marked as history), `-05` `6d0aa9af`
(the CHANGELOG says *mode*, and `T-ONESHOT-SCOPE` retires).

**One collision, ruled by the owner mid-sprint.** The persistence retires the *implicit* disarm a
bare `show{force}` used to perform, so `a forced follow-up show survives the close` could not pass
unchanged — it pinned the category as well as the placement, which neither this cell nor the session
prompt had noticed. Ruled: *"there is no working idiom"* — `FEAT-01`'s shape was a quick
implementation of a disposable flag, ruled and overruled within a day and never released, so a
contradiction with it is the thing being removed rather than a cost to weigh. The case now pins the
placement on a **disarming** follow-up, and the forbidden capture-before-hooks mutation was re-run
and still fails it. Evidence:
[`validation/notes/auto-hide-persistence-vs-the-forced-follow-up.md`](validation/notes/auto-hide-persistence-vs-the-forced-follow-up.md).

| id | step | notes |
|---|---|---|
| **FEAT-02-01** | **amend Decision 36 — TWO things — and Decision 35's boundary note** — the ledger gate, first | **amend, never reinterpret** — the same standard `ARC-01-03` was held to. Edge 1 is *ruled text ruled today*; it does not get quietly rewritten. Say what it said, what replaces it, and that the ground was a resemblance rather than a reason. Decision 35's show-only category loses a member and should say why the remaining three belong. **The second amendment is to Decision 36's own first GROUND**, and it is a correction of fact: *"a migrating project author meets a familiar name"* does not hold — the base check shows `oneshot` was an internal model constructor argument, never a project-facing key ([`validation/notes/oneshot-at-the-pr-base.md`](validation/notes/oneshot-at-the-pr-base.md)). The **capability** was restored; the name never reached a project author. Amend the ground, do not delete it — the restoration argument survives, the familiarity claim does not. **The amended text must state the persistence** (owner: *if the flag is persistent until disabled it should be clearly said in docs, and probably mentioned in decisions*) — a mode that outlives its `show` is exactly what a reader will assume it is not |
| **FEAT-02-02** | **rename the key** — `oneshot` → **`auto_hide`** | **name settled 2026-08-30:** it reads as a mode, and it matches the surface's own verbs — `compy.input` has `show` and `hide`, and `close` appears nowhere on it, so `auto_close` would have been a third word for what `hide()` does in a feature already paying `FIX-02-08`/`-09` for that. | **owner ruling, 2026-08-30, overruling their own earlier position.** *"Use a new name without semantic ambiguity — it does not bear the one-off vibe and reads like a mode."* `oneshot` names a *single occurrence* while the flag is a persistent **behaviour mode**, which is the ambiguity `FEAT-02-04` would otherwise have to warn a reader about; renaming deletes the warning instead of writing it. **Three findings support it and none was known when the flag was named:** the familiarity ground is false (row `-01`), the token is already taken in-tree by the **profiler** (`Prof.start_oneshot`, `love.PROFILE.oneshot`, and a reserved-combo test that names it), and `FIX-02-08`/`-09` exist because one word meaning two things is this feature's recurring defect. Costs: the `serial` author asked for the flag under the old name, and eight tests, three production sites, four documents and two ledgers carry it |
| **FEAT-02-03** | **the flag moves to the project-owned keys** — `show` **and** `configure`, set-if-given, `false` to unset, **persistent until replaced** | the disarm idiom arrives **free** from Decision 35 statement 3 (`false` is the uniform unset); no new vocabulary. In code: out of `SHOW_ONLY_KEYS`, into `CALLBACK_KEYS`' company and `configure_core`. **The persistence is the point, not a side effect** — `oneshot` configures a *type of behaviour*, so it is an ordinary project-owned setting and needs no category of its own. `FEAT-02-01` rules it in Decision 36; this row must not smuggle in a clearing step |
| **FEAT-02-04** | **document the teardown-path edge and the persistence**, in the guide | the owner's wording is the shape of the advice: a `show{force}` from a teardown path should either **check the flag and disarm it first**, or run **after** the widget is hidden with the project holding its own state. This **replaces** the bullet `9eebbe3a` added, which describes the old shape. **Second and larger obligation: say plainly that the flag persists until replaced.** A reader who takes it as *"this one time"* expects it to clear itself and gets a closing widget on every later prompt — silent, right-looking, wrong. **Corrected 2026-08-30 (session58):** this row was written when renaming was believed unavailable and said so, citing a base behaviour it called *"not checkable in this repo"*. Both are overturned — `FEAT-02-02` renames the key, and the base check ran ([`validation/notes/oneshot-at-the-pr-base.md`](validation/notes/oneshot-at-the-pr-base.md)). The rename removes the *one-off vibe* but **not** the obligation: `auto_hide` says nothing about lifetime either way, and a mode that outlives its own `show` is what a reader will assume it is not. Say it, and say the disarm idiom (`auto_hide = false`) beside it. Be blunt, not merely accurate |
| **FEAT-02-05** | tests and the CHANGELOG | **two existing cases invert**: `configure raises on oneshot, naming show()` becomes `configure arms it`, and `it is spent by its own show` becomes **the persistence rule** — a later bare `show()` inherits the mode, and `auto_hide = false` is what disarms it. **Corrected 2026-08-30 (session58):** as filed this cell said *"becomes the going-down rule"*, which is the **withdrawn** row (`disarmed when the widget goes down`); executed literally it would re-file the clearing rule in a test, the most durable place there is. `a forced follow-up show survives the close` must keep passing — it pins the placement, not the category |

### The row that was filed and withdrawn — `disarmed when the widget goes down`

**Filed by the parent, withdrawn by the owner the same day, and recorded rather than deleted**
(`agents/rules/roadmap.md` §5 — omission is not a ruling). The parent argued that *cleared on
consumption* alone leaves the flag armed when a session ends with **no** submit, so an Escape
followed by a later bare `show()` would get a `oneshot` nobody asked for.

**Settled by a reading of the flag, not by a lifetime argument (owner, 2026-08-30).** `oneshot`
**configures a type of behaviour**, not one show/hide cycle — *"it avoids introducing a new entity,
a 'one-off flag' just for syntactic sugaring"*. Under that reading a clearing rule is not merely
unnecessary, it is a category of its own for a setting that should be ordinary. **The condition
attached: persistence must be said clearly in the docs and ruled in the decisions** — `FEAT-02-01`
and `FEAT-02-04` carry it.

The lifetime argument that first retired the row still holds and is kept because it answers a
different question. The owner's objection was: the flag lives on the widget as `callbacks` do, the widget lives one **run** (Decision 3
as amended by `ARC-01`), so project exit tears it down and no machinery is needed — verified, and
pinned by `gives the next project clean output fields`
(`input_route_lifecycle_spec.lua`). That answers **cross-run** leakage, which is a different hazard
from the within-run stickiness the row was aimed at. The row fails for two further reasons:

- **It is an exception to the single reconfiguration policy.** *Content resets, everything the
  project sets persists until replaced* — `ARC-01-07`'s answer, carried in Decision 35. Once
  `FEAT-02-03` makes the flag project-owned, persisting until replaced is what the policy
  **requires**; clearing it at `hide` is a second policy, which is the thing `ARC-02` existed to
  delete.
- **The argument proves too much.** A later bare `show()` validates "for reasons written elsewhere"
  too. Nobody finds `validator` surprising, because that *is* the documented rule — so the same
  objection would condemn every project-owned key.

**What replaces it:** nothing, deliberately. A project that wants a continuous session after a
one writes the flag as `false` at `show` or `configure`, which `FEAT-02-03`
gives it for free. `FEAT-02-04` should say so, since it is the one place a reader will look.

**Crosswalk — two withdrawals and one insert, all 2026-08-30.** No `FEAT-02` id appears in `src/`
or `tests/` — the sprint has not started — so `agents/rules/roadmap.md` rule 2's renumber branch
applies, and §5's *a retirement takes its citations with it*: the successor prompt was corrected in
the same pass each time, not left to the sweep. **Both withdrawn rows keep their sections above**;
neither was deleted.

| as originally filed | **final** | step |
|---|---|---|
| `FEAT-02-01` | **`FEAT-02-01`** | the ledger gate — now amending **two** things, plus the getter line |
| — | **`FEAT-02-02`** | **the rename** to `auto_hide` (inserted) |
| `FEAT-02-02` | **`FEAT-02-03`** | the flag moves to the project-owned keys |
| `FEAT-02-03` | — | ~~disarmed when the widget goes down~~ — **withdrawn** |
| `FEAT-02-04` | — | ~~first-class and readable~~ — **withdrawn** |
| `FEAT-02-05` | **`FEAT-02-04`** | the teardown-path + persistence documentation |
| `FEAT-02-06` | **`FEAT-02-05`** | tests and the CHANGELOG |

*Two of the six rows this sprint was filed with are gone, both by the owner, both within a day of
being written — and the sprint is better for it. Neither was drift: each was filed against the
`FEAT-01` shape and stopped making sense once the flag became a mode.*

**What this does NOT fix, stated so nobody expects it to.** The peer review's case survives: a hook
doing `show{force, oneshot = true}` still re-arms, and the trailing close still fires. Owning the
close by the submit that armed it needs a generation token, judged not worth the state. What changes
is that the behaviour gains a one-line explanation — *the close reads the flag at the end of the
submit it is running* — and the hook gains the clean escape it lacks today.

**Rejected, on evidence:** capturing the flag *before* the hooks. Mutation-tested during `FEAT-01` —
it leaves the `oneshot` follow-up closed **and** closes the plain follow-up that currently survives,
failing exactly `a forced follow-up show survives the close`. Reading the flag after the hooks is
what makes any forced follow-up survivable.

---

## ✅ OP-01 — ledger upkeep for the three hand-filed entries — **COMPLETE**

**Ran 2026-08-30, on the owner's direction to start it immediately** — *"it derives decisions from
my input and documents them with rationale, then restyling debt entries and rederiving them from
written decisions is mechanical."* That is the order it ran in, and it inverted this sprint's own
first plan: `-02` led, `-01` followed from it. **Decisions 36 and 37** are the output
(`71d1f260`, corrected `96683802`), and `T-NAMESPACE-CLONE` is **retired** — its obligation was
documentation, and it is paid by a **suggested practice, not a decision** (owner, 2026-08-30):
*"A Namespace Hands Out Live Tables by Reference, Never by Value"* in
`conventions/architecture_principles.md`, with the one-line pointer from Decision 7 that `serial`'s
author asked for. The rule binds any subsystem, not the input surface, and a genuine snapshot may
still be passed by value — a practice with a question attached is the right instrument, and a
ruling was not.

**One thing the writing surfaced: half of `FEAT-01-03` is already true.** `after_submit(lines)` is
what the submit chain passes today and what the guide documents, so only `on_text_entered`'s
payload moves.

**And one thing it got wrong, corrected by the owner the same day.** The first draft of Decision 36
weighed `oneshot` by counting shipped examples and called its case thin. That census measures the
wrong thing — the examples were written for the API as it stands, and four of them demonstrate
repeated prompting on purpose. `oneshot` **preceded this feature** and was **asked for by the
`serial` API's author**; those two facts settle it, and the ergonomics (a one-line user-facing
question from a project whose subject is not input) is the third.

**`OP` is the second KIND ruled 2026-08-30: operational need, no parent decision required**
(`agents/rules/ledgers.md` §4 — *"the need argues for itself"*). Keeping a register legible is named
there as exactly such a need.

| id | step | notes |
|---|---|---|
| **OP-01-01** ✅ | **rewrite the three entries in-place to the register's own style** — slug in the heading, then `Where` / `State` / `Why it stands` / `Revisit` | **DONE** (`f819d19b`), and it ran **after `-02`**, as the owner directed: house style has an entry cite the decision it derives from, so the decisions were written first and the entries re-derived from them — the alternative was writing them twice. `T-NAMESPACE-CLONE` did not need restyling in the end; it was retired instead. The translation from Russian survives in its retired entry, faithful rather than paraphrased |
| **OP-01-02** ✅ | **create or amend the ratified decisions the entries call for** | **DONE** (`71d1f260`): Decision 36 (`oneshot`'s existence, edges left to `FEAT-01-01`) and Decision 37 (the payload split, which is also `FIX-02-01`'s answer). The third — the live-table/namespace rule — turned out **not** to be a decision at all and left the ledger for the conventions doc; see the sprint note above. A proposal sitting in the debt register is an obligation with no ruling behind it, and this row is what made the register honest |
| **OP-01-03** ✅ | **the namespace-clone documentation** — the lines the entry asks for, next to Decision 7 · **`T-NAMESPACE-CLONE`** | **DONE** (`84882f01`, relocated `96683802`) — paid by documentation, with no code and no surface change, and it closed the entry outright. The content is the owner's: the project environment is deep-cloned before a run, so a live platform table placed in a namespace *by value* travels as a copy — the program assigns into the copy, the dispatcher reads the original, and **both sides stay silent**. Input dodges it by holding the surface up-value behind `__index`, and `serial` was since built the same way. **Filed as a generic practice, not an input decision**, at the owner's direction |

**Why these are not one sprint with `FEAT-01`.** They are different work with different gates: `OP`
rows need no ruling and can run any time; `FEAT` rows are owner-gated design. Folding them together
would hide which half is waiting on a decision.

---

## ⬜ The six defect sprints — **the work `FEAT-01` and `OP-01` now run ahead of**

**The remark triage already ran** (owner directed it to lead; it did, and produced five new rows —
`FIX-02-01/02/03/04/15`). What remains of it is execution, now `FIX-02-07`.

**Rows are ordered by blast radius, not severity** — see the principle below. Three hard
constraints on top of that: **DEC-01 and CHG-01 must both finish before any
slice is cut**, **CHG-01 also gates ACC-02**, and **FIX-03 runs last** — it is the sweep that catches what FIX-02 and DEC-01 miss, and running it
first means three brooms over one floor. Within BUG-01, `01`
and `02` are the majors.

### Ordering principle (owner, 2026-08-26)

**Rows that can change the shape of the work go first.** Anything that may reveal more defects,
escalate into a design decision, or reach deep enough to cause regressions — anything whose blast
radius is **big or unknown** — leads. Narrow mechanical rows follow, because sizing them against an
unsettled surface is sizing twice.

**Renumbered once, here, and stable from now on.** Crosswalk at the end of this section.

### ✅ BUG-01 — runtime defects (11), in priority order — **COMPLETE (session60)**

**All eleven rows are closed.** Session60 took the five that were still open: `-09`, `-04` and
`-05` fixed in the platform, `-07` fixed in the balloons repo, `-11` ruled `wontfix` with its
premise corrected. Suite 1023 → 1032 — seven breaking tests across the three platform fixes, plus
two the cold peer review earned. **Three provenance patterns worth
carrying into the PR description:** `-09` was inherited from the base, `-04` was introduced whole
by this feature, and `-05` was mixed — a pre-existing bound our own wrappers made reachable by
copying its convention on purpose.

| id | defect | blast radius |
|---|---|---|
| ~~**BUG-01-01**~~ ✅ | `state.pending` survives a project stop | **CLOSED, fixed** — `bd2a5d49` (fix + breaking test + behaviour docs), `abadf244` (the false-premise debt entry). No shipped example reaches it, but the path is public API. **Its siblings were then swept** (owner-scoped: `compy.input` + the widget singleton) and one more was found and fixed — the prompt label, `8a9022ec`. Evidence: [`validation/notes/BUG-01-01-pending-lifetime.md`](validation/notes/BUG-01-01-pending-lifetime.md) |
| ~~**BUG-01-02**~~ ✅ | **RATIFIED by `ARC-02-08` (`e4748e60`), no code — `false` is the uniform unset (Decision 35, statement 3) and is documented as such. The design escalation dissolved: every consumer already tested truthiness, so a stored `false` always took the absent branch.**  a highlighter cannot be turned off · **`T-HL-UNSET`** | **design escalation** — sentinel vs a new `clear_highlighter` member; either changes the public surface. **Wait for ARC-01**, which removes this row's teardown half and leaves only the within-run call. **ARC-01-07 may have dissolved it outright** (2026-08-27, superseding this row's earlier note in the same session): **`highlighter = false` already turns the highlighter off, exactly**, and needs no machinery at all. `apply_config` guards on `~= nil`, so `false` is *stored*; every consumer then guards on **truthiness** — `if ev.highlighter then` (`userInputModel.lua:384/393`) — so a stored `false` takes the **same branch as absent**, `ev:validation_hl(text)`, which is the channel that displays the validator's error in the field. Identical by construction, not by approximation. **Verified by probe**: `validator = false` lifts a rejecting validator, `on_text_entered = false` submits without a crash, `highlighter = false` leaves `get_highlight()` working. *(An earlier note on this row said no user-space value reproduces absent and that the row needed machinery or nothing. That was wrong — it reasoned about `nil` and missed that the code tests truthiness.)* **What remains here is a documentation and ratification call, not a design one:** `false` means *"no such thing"* is already the de-facto contract (Decision 14's situation exactly), it is idiomatic Lua, and it is uniform across `highlighter`, `validator` and the widget outputs. Ratify it and write it down, or reject it and then build machinery. **`prompt` is de-scoped either way** — it has `''` for an empty label and `false` for "back to the default label", both verified |
| ~~**BUG-01-03**~~ ✅ | **FIXED (Session 56) — `compy.input.is_shown()` guard added to `src/examples/turtle/main.lua:love.keypressed` to match `love.keyreleased` and prevent double-handling when prompt is open.** `turtle` double-handles its own keys · **`T-TURTLE-DUP`** | **FIXED and REVALIDATED** — cold peer review 2026-08-30, **approve with comments**: [`validation/outcomes/BUG-01-03-turtle-fix-peer-review.md`](validation/outcomes/BUG-01-03-turtle-fix-peer-review.md). The guard is the framework's own documented idiom, not a patch over a framework defect (`doc/input_api.md`, *"Why the widget sits at tier 3"*), and is test-pinned in `input_widget_control_spec.lua:621-637`. Both comments dispositioned in the report's addendum: the blanket return's cost is the example's *shortcut*, not the capability (`ctrl+pause` is a reservation above tier 1) and is now written at the guard (`c80b9638`); **no test pins the fix and none can** without inventing an example-under-test genre this codebase has nowhere — recorded, not chased |
| ~~**BUG-01-11**~~ ✅ | **WONTFIX (owner, 2026-08-31), and the premise was wrong — no code changed.** `ctrl_pressed` is maze's control-mode slot (`controls.lua` defines the modes and each assigns it), not a neutralisation idiom; `core_editor.lua`, held up as the counter-example, does the same `ctrl_pressed = nil` in `arm_editor`, and its `is_shown` is a show-vs-configure branch rather than a guard. Double-handling is prevented on the paths that occur, but **by level ordering, not by construction** — the sprint's peer review falsified the stronger claim: `jump_level` → `start_level` → `cur_controls()` re-arms `ctrl_pressed` and hides nothing, so an editor-to-`keys` level jump would leave both live. Maze's own latent defect, **reported to the owner, not fixed**; it does not disturb the ruling. The owner's reading: this is the shape the guide advises — read the hardware early into a deterministic variable (*"Perform hardware polling before complex processing"*) — merely named after the keyboard where its role is mode selection, which is taste and is **not** being fixed in another repo's working code. `T-MAZE-NEUTRALIZE` retired as NOT DEBT. Weighing: [`validation/notes/BUG-01-11-maze-neutralisation-weighing.md`](validation/notes/BUG-01-11-maze-neutralisation-weighing.md) | **unknown, and the row opens by weighing rather than by fixing** (owner, 2026-08-30). `draw_main.lua` and `maze_main.lua` set `ctrl_pressed = nil` where `core_editor.lua` uses a pre-existing `is_shown` guard; the cold review could not trace every path, so this is **unverified, not known-broken**. **Step one is the pros-and-contras**, and `wontfix` is a legitimate outcome: for it, `maze` is a reference implementation and a superseded pattern there teaches the next reader wrongly; against it, `maze` is a **separate repo** whose working code must not be overfixed to match a house idiom when the approach is legitimate and contradicts no convention. Only if the weighing goes the first way does any code follow |
| ~~**BUG-01-04**~~ ✅ | **FIXED (session60) — `combo_string` lower-cases the trigger, so dispatch emits what registration stores. Decision 8 already ratified the rule; only the dispatch half failed to implement it, and `normalize_combo`'s docstring asserted an agreement that did not hold. Three breaking tests written first, `doc/input_api.md` (*"Event hooks and shortcuts"*) states the case-insensitivity and its remedy, `T-COMBO-CASE` is RETIRED. Base-checked: at `3256aac` neither half exists, so this feature introduced the asymmetry ITSELF — the opposite provenance to `BUG-01-09`. Narrower than "deep" looked: only textinput carries a cased trigger; the reservation path has no textinput channel and key constants are already lower.**  a `textinput` shortcut cannot bind an upper-case character · **`T-COMBO-CASE`** | **deep** — the fix is in combo serialisation, which every shortcut match runs through |
| ~~**BUG-01-05**~~ ✅ | **FIXED (session60) — all three byte-bounded clamps now count characters. NOT a design call after all: the unit was already decided everywhere else in the model and the view; three clamps were the outlier. Mixed provenance — `move_cursor`'s bound is pre-existing and was inert (18 internal callers all pass character values), while `set_cursor_pos` and `_clamp_cursor_pos` are OURS and made it externally reachable, having copied the byte convention deliberately. Two breaking tests on a Cyrillic line; `doc/input_api.md` had contradicted itself and now states the rule with a multi-byte example. `T-CURSOR-BYTES` RETIRED.**  `set_cursor` clamps bytes, boundary event measures characters · **`T-CURSOR-BYTES`** | medium — two functions disagree; which is right is a small design call |
| ~~**BUG-01-06**~~ ✅ | **DISSOLVED by `ARC-02-04` (`af1e8ec6`) — `re_show` deleted, so the path that dropped `prompt` no longer exists. Its highlighter-deferral sibling went with `ARC-02-06`.**  `show{force = true, prompt = …}` silently drops the prompt · **`T-FORCE-PARTIAL`** | narrow — one call path, and **it may dissolve rather than be fixed**: intent recovery ([`validation/reviews/force-and-configure-intent-recovery.md`](validation/reviews/force-and-configure-intent-recovery.md)) found the stakeholder gated *"reconfigured in-place with the new config"* behind `force`, and the code kept only that sentence's parenthetical — so `force` applies content and **nothing else**, the complement of what was specified. Making `force` the full re-setup it was reviewed as removes this row's defect along with three others. `force` has **no consumers in-tree**. **A sibling is NOT covered by this row, and it has since been traced to a root cause — `BUG-01-10`:** the same call *defers* the **`highlighter`** — and only it. **Corrected 2026-08-27 by the cold review:** `validator` / `on_text_entered` / `on_limit_reached` are **applied immediately**, because `merge_callback_keys` writes into the widget's own `callbacks` table, the very table `apply_config` would write. The `highlighter` alone defers, because it lives on `model.evaluator`, which that merge never touches. Verified by probe. So the call has three behaviours for its keys — applied (`text`, three callbacks), dropped (`prompt`, `cursor`), deferred (`highlighter`). Rule on them together |
| ~~**BUG-01-07**~~ ✅ | **FIXED (session60), in the balloons repo — `ui_messages.hint` and `ui_draw_hint` deleted, `ui_set_hint` writes through, and the three named fossils (the stale NOTE, `terminal_write`'s unread `flushed`, the extra argument) go with them. The copy had no second reader, so nothing was lost. Not runtime-verified — no suite, needs a display; it is desk-checked and parses, and the manual smoke pass exercises it. `T-BALLOON-LABEL` RETIRED. One unrelated defect found, raised, and then fixed on the owner's ruling (*fix it if it is clearly a typo, delete it if it is clearly dead code*): `ui_draw_status` read `ui_messages.results`, which nothing sets (`result`, singular, is the field). It is a self-consistent dead **pair**, not a typo — repairing it to `result` would be a no-op during play and a regression across games — so the branch was **deleted**, a second balloons commit.**  balloons keeps a shadow copy of the widget's label and re-pushes it every game cycle · **`T-BALLOON-LABEL`** | narrow — one example repo, no platform code. Pre-feature fossil: `ui_messages.hint` + `ui_draw_hint()` re-assert the label on each state transition because in the legacy era the label died with each `input_text()` call. With stickiness ratified (owner, 2026-08-27) the widget owns the label and the shadow state is redundant. Two vestigial arguments ride along — `terminal_write(msg, flushed)` never reads `flushed`, and `ui_set_hint(fmt(GAME_PROMPT, txt), true)` passes a second argument `ui_set_hint` does not take — plus a stale `-- NOTE: won't work if there was no real input`. `ui_messages.hint`'s initial `SPLASH_HINT_START` never reaches the widget (`game_init` calls `ui_show_command_prompt` immediately); the same text does reach the screen via `graphics.lua:575`, so nothing is visibly missing. **Filed by the owner, 2026-08-27**, on reading the ARC-01-07 evidence. Modest severity: redundancy and misleading fossils, no user-visible misbehaviour found |
| ~~**BUG-01-10**~~ ✅ | **FIXED by `ARC-02-06` (`cad0bb25`) — `bind_highlighter`; the evaluator resolves the callbacks slot instead of holding a copy.**  **the highlighter has two homes, and one of them lags** — `compy.input.callbacks.highlighter = fn` on a shown widget does **nothing** until an unrelated later `show`/`configure` flushes it · **`T-HL-TWO-HOMES`** | **the root cause `BUG-01-06`'s sibling is a symptom of**, and the only one of the four callback fields with this shape. `highlighter` lives both in the widget's `callbacks` table (the sticky store, shared with the `compy.input.callbacks` surface) **and** on `model.evaluator`, which is what the model actually reads (`userInputModel.lua:384/393`). Only `apply_config` copies store → evaluator, so **any path that writes the store without calling it leaves the live copy stale**. Two symptoms, both probed: a forced `show` defers it (dissolved by `ARC-02`), and a **direct assignment does not take effect at all** — then appears later at an unrelated `configure{}`. `doc/input_api.md` ("Callback assignments") documents `highlighter` as assignable that way. `validator` and the widget outputs have **one** home and work. **Scheduled inside `ARC-02` as `ARC-02-06`** (owner, 2026-08-27) rather than after it — same
`apply_config`/`callbacks` seam. **RULED (owner, 2026-08-27): one home, proxied via `callbacks`** — the widget's `callbacks` slot is the single source of truth and the evaluator stops holding a copy; the `compy.input.callbacks` surface proxies to it, so a direct assignment and a `show`/`configure` key reach the same place by construction. **The drift this replaces is documented in `doc/development/internals/user_input.md`** — a reader meeting the old two-homes shape in an older tree needs to know why the evaluator no longer carries it. No longer an escalation; the shape is settled and the work is implementation. Third defect from the evaluator split — session48 fixed the shared-singleton one. Found 2026-08-27 |
| ~~**BUG-01-09**~~ ✅ | **FIXED (session60) — the string branch of `UserInputModel:set_text` splits with `string.lines` and hands every line to `InputText`, as the table branch already did with a list. Two breaking tests written first; `CHANGELOG.md` *"Fixed"* carries it for a reader, and `T-MULTILINE-STR` is RETIRED. Base-checked: the `== 1` guard is at `3256aac` in the same shape, so the defect is PRE-EXISTING — what this feature added is the documented shape and the surface that reaches it.**  `set_text` silently ignores a multi-line *string*, so `show{text = "a\nb"}` leaves the previous content standing · **`T-MULTILINE-STR`** | narrow fix, **but the failure mode is the worst on this list**: silent, on a **documented** input shape, on the primary call. `UserInputModel:set_text` (`:125-134`) assigns `self.entered` only when `#string.lines(text) == 1`; a multi-line string falls through every branch and nothing is written, so the **previous session's content survives into the new one**. A list of line strings works. `doc/input_api.md` documents `text` as *"a string or list of line strings"*. Found by the `ARC-02` cold review, re-probed here: `show{text='previous'}` → `hide()` → `show{text='a\nb'}` leaves `previous` on screen. Belongs with `ARC-02-03`, which is the step that touches the content path |
| ~~**BUG-01-08**~~ ✅ | **FIXED by `ARC-02-07` (`3bade47a`) — `checked_cursor` at the project boundary; `false` is the unset, out-of-range still clamps.**  **`show{cursor = {}}` raises a raw Lua error from inside the framework** · **`T-CURSOR-SHAPE`** | narrow — one unguarded function, but it is a **public path that crashes the project**. `set_cursor_pos` (`userInputController.lua:169-175`) does `math.min(line, n)` with no nil guard, so a partial or empty cursor table — `{}`, `{1}`, `{nil, 2}` — and a direct `compy.input.set_cursor(nil, nil)` all die with *"bad argument #1 to 'min' (number expected, got nil)"*. Two reasons it matters beyond the crash: the config table is otherwise **strictly** validated (an unknown key raises with a message naming the key and where it belongs), and `doc/input_api.md` promises out-of-range cursor values **clamp** rather than fail. **Base-checked: ours** — `set_cursor_pos` does not exist at `3256aac`; it is FR-9's implementation. Distinct from `BUG-01-05`, which is about byte-vs-character clamping of *valid* input. Found 2026-08-27 probing empty values; **widened the same day** — `cursor = 1` and `cursor = false` raise too, at `:309` (*"attempt to index field 'cursor' (a number value)"*), because the config path indexes `cfg.cursor[1]` without checking the shape. **This row now gates a design rule:** a scalar or defaulted cursor is the proposed "unset" for the field, and it cannot be documented while it raises. **Numbered last, but its radius argues for running it with `BUG-01-05`/`-06`** — all three are cursor/config call-path fixes in the same two files |

### BUG-02 — the `set_text` list branch does not split (1), opened 2026-08-31

**Opened by the owner at session61's revalidation**, from a finding of the `BUG-01` sprint's cold
peer review that the sprint left undispositioned. **The row opens by weighing, not by fixing**, and
the minimal outcome — already delivered — is that the defect is written down where a developer
meets it. Whether it is *fixed* before the release is an owner call taken at this row.

| id | defect | blast radius |
|---|---|---|
| **BUG-02-01** | **weigh fixing vs postponing** the list branch's non-splitting · unslugged entry, *"`set_text`'s list branch does not split embedded newlines"* | **the weighing is narrow; the fix is not.** `UserInputModel:set_text` is the content path every activation and every live text change runs through, and `BUG-01-09` has just rewritten it — which is exactly the argument for deciding rather than reaching. Against fixing: no in-tree caller can reach it (all three pass a raw string or `string.lines(…)`, which never emits an element containing a newline), so a project must hand-build such a list. For fixing: `doc/input_api.md` documents `text` as *"a string or list of line strings"* and the two branches now disagree about what that means, which is the same **one fact stated twice** family as `FIX-02-08`/`-09` |

**Ordering.** It sits in the defect brace beside `FIX-01`/`FIX-02`, and it carries one hard
constraint of its own: **if the weighing goes to *fix*, `BUG-02` finishes before `CHG-01`**, because
a behaviour change on a documented surface earns a CHANGELOG line and `CHG-01` is the pass that
validates them. If it goes to *postpone*, the entry stays unslugged in BACKLOG and nothing else
moves.

**Provenance, kept straight for the PR description.** **Pre-existing** — at `3256aac` the table
branch is `InputText(text)` with no split and no sanitise. What this feature did was fix the
*string* half (`BUG-01-09`) and thereby make the two halves visibly disagree; it did not introduce
the branch.

### FIX-02 — docs, vocabulary, process (25), in priority order

*(was 20, then 19 — the old `05` and `14` merged into `06`, being one defect in three places — and
back to 20 with `FIX-02-20`, and 21 with `FIX-02-21`, both registered 2026-08-26; **24 with
`FIX-02-24`**, registered 2026-08-30; **25 with `FIX-02-25`**, registered 2026-08-31.)*

| id | defect | blast radius |
|---|---|---|
| **FIX-02-01** ✅ | **`on_text_entered` and `after_submit` are two ways to set one callback** | **ANSWERED 2026-08-30 by Decision 37, ruled jointly with `FEAT-01-03` as this row required.** They are not two ways to set one callback: they are told apart by their payload, and each acquires a reason to exist a reader can state in one sentence. The *documentation* half — saying which to choose, and that the convention is not enforced — is **`FEAT-01-06`**, so this row closes against a decision plus a scheduled write-up, not against a decision alone. *Original filing:* **design escalation, public surface.** The cold review missed it; the owner raised it twice. Bears on the strategic frame's "no moving parts beyond the ask". **Do not work this row without `FEAT-01-03`**: the owner has since proposed keeping both hooks and differentiating their payloads (`T-PLAINTEXT-ENTERED`), which is a candidate answer to exactly this question — and `FEAT-01` runs ahead of this sprint, so the answer should be in hand by the time this row opens |
| ~~**FIX-02-02**~~ ✅ | **RATIFIED (Session 56) — `legend = ""` on submit is the example's own code in `src/examples/tixy/main.lua:submit_body` (submitting custom formula retires canned caption; see `validation/notes/S24-W7-A4-A5-invisible-overlay.md`). No framework defect.** `tixy` may drop the legend on submit | **RATIFIED** — verified by `S24-W7-A5` investigation note |
| **FIX-02-03** | the A-doc's three factual claims (`:79`, `:650`, `:675`) | **may reveal the code is wrong, not the doc** |
| **FIX-02-04** | pointer annotations in `project_sandbox_env.md` — completeness never checked | **unknown yield** — a verification task |
| **FIX-02-05** | the debt ledger's 20 resolved entries · **`T-RETIRED-UNVER`** | **unknown yield** — each tested against base; may find more rot. **NOT absorbed by `LEDGER-01-03`**, which sorted them into `RETIRED` on their headings without testing one of them against the base. The sort is done; **the verification this row exists for is untouched**, and it now has a section to walk rather than a scattered set |
| **FIX-02-06** | the stale keyboard/pointer divergence claim | **one defect in three places** — `release_keyboard_route`'s comment, `event_dispatch_layers.md:112`, and the second doc. **Fix as one**; any survivor re-seeds the others |
| **FIX-02-07** | execute the 37 remark dispositions | triage **complete**; breadth known, 12 files |
| **FIX-02-08** | "tier" / "chain" / "the walk" — three names, one thing | known breadth, 3 slices |
| **FIX-02-09** | "overlay" / "widget" / "area" / "field" — four names | known breadth; `src` half done in S45, docs half open. **The examples were not in that sweep** — found 2026-08-30. `turtle` was fixed on the spot while it was being edited anyway; what remains is the **nested repos**, `keyboard` (six files) and `maze` (`maze_render.lua`), which open their own PRs and are swept there. **Scope clarified by the owner, 2026-08-31 — see the note below** |
| **FIX-02-10** | "combinator" — concept earned, word not | narrow |
| ~~**FIX-02-11**~~ ✅ | **RESOLVED — `doc/input_api.md:69,321,333` already states the widget always consumes when shown and explains tier 3 placement. Symptom (`BUG-01-03`) fixed in `turtle/main.lua`.** the guide never says a shown widget **always consumes** (keyboard) | **RESOLVED** — documented in `doc/input_api.md` |
| ~~**FIX-02-12**~~ ✅ | **ANSWERED by `ARC-02-08` (`e4748e60`) — `false` documented as the uniform unset in `doc/input_api.md`, with the `computed or false` idiom. Ratified rather than built: every consumer already tested truthiness.**  the guide never says callbacks cannot be un-set | narrow — depends on BUG-01-02's ruling. **Write with `FIX-02-21`**: both are answered by the same paragraph — the ownership rule (*content resets; everything the project sets persists until replaced*) plus the sentence saying what "replaced" cannot mean. Not a duplicate of it; the same edit |
| **FIX-02-13** | `hide()` vs teardown — the singleton is never stated | narrow — **write with `FIX-02-22`**, same paragraph of the same doc |
| **FIX-02-14** | the channel list exists twice | narrow |
| **FIX-02-15** | `technical_debt/general.md` carries an entry that is not debt · **`T-GFX-GLOBAL`** | narrow |
| **FIX-02-16** | a `pending()` routing case deferred in the hardest-read area | narrow |
| **FIX-02-17** | CHANGELOG omits the breaking change | narrow — **feeds CHG-01** |
| **FIX-02-18** | `pong/README.md` — 316-line diff, 2-line change | narrow |
| **FIX-02-19** | provenance front matter, 3 files | narrow |
| **FIX-02-20** | **"draft" — unratified vocabulary, and the widest-spread of them** | **runs with the 08–10 cluster, not last** — see the note below |
| ~~**FIX-02-21**~~ ✅ | **EXECUTED by `ARC-02-05` + `ARC-02-08` — the misleading `PER_SHOW_KEYS` membership is gone with the list itself, and `prompt` is documented as persisting until replaced. The balloons rationale is in `internals/user_input.md` so it outlives `wip/77`.**  **`prompt` is classified per-show but behaves sticky** — ~~which is right is undecided~~ **RULED: the behaviour is right, the classification is wrong** | **no longer escalates** — stays a FIX. Owner ruled 2026-08-27 (below); the work is a comment, a list membership and two doc sentences |
| **FIX-02-23** | **the guide never says a project's own keys stay live while the widget is shown**, nor names the whole-handler guard as the remedy · **`T-GUARD-LIVE`** | narrow — *a few lines at the `is_shown` paragraph of `doc/input_api.md`*, the paragraph a project author reads before mixing native handlers with a prompt. Earned by `BUG-01-03`: the guide documents the tier mechanism and the trigger-key case, and a reader of it alone still would not know to write the guard that fixes `turtle` — which the suite already pins as the idiom (`input_widget_control_spec.lua`). **Scope corrected 2026-08-30:** the row first also claimed the reservation exemption was undocumented; *"Combos the framework keeps"* documents it, `ctrl+pause` included, so these lines **point at that section** rather than restating it |
| **FIX-02-24** | **the mermaid class diagrams show a model field the feature deleted** · **`T-MERMAID-MODEL`** | narrow to fix, **unknown to verify** — `doc/mermaid/{input,editor,classes}.md` all list `oneshot: boolean` on `InputModel`/`UserInputModel`. The model lost that constructor argument in this feature ([`validation/notes/oneshot-at-the-pr-base.md`](validation/notes/oneshot-at-the-pr-base.md)), and the `auto_hide` key that restored the *capability* lives on the **controller**, so the diagrams show a field on the wrong class rather than an old name. `custom_label` is missing from the same blocks. Nobody has walked them since the input work, so the row is *verify all three against the current classes*, not *delete one line*. **A diagram is read before the code and carries no hedge**, which is why it outranks its size. Found 2026-08-30 during `FEAT-02`'s rename sweep; **numbered out of execution order** for the reason `FIX-02-20` records |
| **FIX-02-25** | **the set of config keys the surface accepts has no single home, and disagreeing with the widget fails silently** · **`T-KEYSET-SPLIT`** | **narrow to fix, and the fix is a test** — `consoleController.lua` decides what `show`/`configure` accept, `userInputController.lua` decides what they apply, and nothing reconciles them: a key on the accept side alone is taken by the surface and ignored by the widget, with no raise. **Scoped deliberately as *pin the agreement*, not *unify the lists*** — unifying crosses the surface/widget boundary the architecture keeps separate, which is a larger change than the defect and reads worse on review than the duplication does. No such test exists today; every key is covered individually and nothing asserts the set is closed. **Promoted from BACKLOG to ACTIVE 2026-08-31 (owner):** it is a code-quality defect and a drift source, so it is fixed before release, but it is **not functional and does not block it**. Found at session59's `FEAT-02` revalidation — `FEAT-02` had to add `auto_hide` to each side and the old entry's *"revisit when either list changes"* trigger did not fire. **Numbered out of execution order** for the reason `FIX-02-20` records |
| **FIX-02-22** | **three documents say a hidden widget keeps its content; the code clears it** | narrow, but **one site is in the persistent corpus** and outlives `wip/77`. `design/spec.md:155` (*"Content preserved for the next `show()` without `text`"*, contradicting its own §3 five lines up), the round-2 reviewed text `spec.versions/version01.md:191-194`, and **`decisions/input.md` Decision 3** (*"hide and bring back with state intact"*, amended last session). Code clears (`open_widget`), the suite pins it, and **turtle depends on it in a comment** (`main.lua`, the `after_submit` block — line numbers moved 2026-08-30 when the example took `auto_hide`). **Disposition: fix the documents** — the owner ruled the behaviour 2026-08-27, and the stakeholder requirement (FR-3/FR-4, the sapper complaint) is about not tearing the widget down, which still holds. Decision 3 needs one qualifier: state survives *except the draft text*. Found 2026-08-27, ARC-01-07 follow-up |

**FIX-02-21, found while fixing BUG-01-01's sibling.** `consoleController.lua` splits config keys into
two lists with a comment saying so: `CALLBACK_KEYS` are *"kept across shows until overwritten"*,
`PER_SHOW_KEYS` are *"spent by the show() that reads them"*. **`prompt` is on the per-show list and
does not behave that way**: `apply_config` writes `model.custom_label` only when `cfg.prompt` is
given, so within one run `show{prompt = 'x'}` → `hide()` → bare `show()` comes back up labelled
`'x'`. `doc/input_api.md` does not say which is intended — its table says only *"Label shown next to
the field."*

**Two readings, and the owner picks.** Either the behaviour is right and `prompt` is a sticky key
mis-filed under per-show (a comment and a list-membership fix), or the classification is right and a
bare `show()` should come up unlabelled (a behaviour change, and then this is a **BUG** row, because
migrated examples may lean on the current stickiness — `maze` re-prompts through `configure`
precisely because *"show() only opens: over an already-open field it is ignored and cannot change the
prompt"*). **Cross-run leakage is settled and already fixed** (`8a9022ec`); this row is only about
within-run behaviour.

**ANSWERED — the first reading, by owner ruling at ARC-01-07 (2026-08-27).** The behaviour is right;
`prompt` is a sticky key mis-filed under per-show. The owner's grounds, attested in
[`validation/notes/owner-attestation-prompt-field.md`](validation/notes/owner-attestation-prompt-field.md):
`prompt` entered FR-1 by **their** ruling against a real balloons defect (no way to change the label
mid-run), and a label surviving a bare `show()` is *wanted* — **the label is decoration surface the
project owns, where content is user-owned and must reset.** That yields the rule the design never
wrote down and this row was really asking for:

> **Content resets; everything the project sets persists until it is replaced.**

So the remaining work is classification and prose, with **no behaviour change**: correct
`PER_SHOW_KEYS`'s comment (or split `prompt` out of the constant, which says it structurally), add
`prompt` to `doc/input_api.md`'s persistence list under "Callback assignments", state the rule where
`show`/`configure` are described, and record the balloons rationale in
`doc/development/internals/user_input.md` so it outlives `wip/77`. Full analysis:
[`validation/reviews/ARC-01-07-reconfiguration-policies.md`](validation/reviews/ARC-01-07-reconfiguration-policies.md) §7.

**FIX-02-09's scope, clarified by the owner (2026-08-31).** Two things, and the second is why this
row cannot be finished early.

**"Docs" means comments too.** Prose documents and the comments in `src/`, `tests/` and the
examples are one corpus for this sweep, on equal footing — a term that survives in a comment is as
misleading as one that survives in the guide, and comments are where `FIX-02-14` already hid once.
`doc/input_api.md` alone still carries eight "field"s.

**The vocabulary is still being minted, which makes this a LATE row.** "Field is open" kept
resurfacing in session60's own conversation and went into a validation note five times before it
was caught — long after this row was scoped, by a session that knew the rule. A sweep run before
the writing stops sweeps a floor that is still being walked on; this one belongs beside `FIX-03`,
which exists for the same reason. The phrase to watch is not the noun alone but the whole idiom:
say **the widget is shown**, not *the field is open*.

**FIX-02-20 is numbered out of execution order, deliberately.** `agents/rules/roadmap.md` §2 wants
numeric order to *be* execution order, but it also says renumber **once, before execution starts**;
execution started, a crosswalk already shipped, and commit `bd2a5d49` cites these ids. Renumbering
19 rows a second time to insert one costs more than this line does. It belongs with the vocabulary
cluster (`FIX-02-08/09/10`) and should be worked there.

**Found 2026-08-26 (session47), by owner challenge during BUG-01-01.** `git grep -i draft 3256aac --
src/ doc/ tests/` returns **zero** text hits at the PR base: the word is this feature's own. Its
spread is wider than any other vocabulary row, and unlike them it reaches **production code and the
A-doc**, not only prose:

- `src/controller/userInputController.lua` — `discard_draft()`, a method name. **At base this was
  `cancel()`**, so the rename is ours.
- `src/controller/consoleController.lua:629`, `controller.lua`, `userInputController.lua` — comments.
- `doc/input_api.md:45` · `doc/development/internals/user_input.md` · `doc/development/smoke_checklists.md:227`
- `tests/input/input_widget_control_spec.lua` — **one real citation and a lot of noise, and the two
  must not be confused.** The file also uses "draft" as fixture *text*, which is not a citation;
  but `:175` is `it('disarming at configure keeps the draft', …)` — a **test description**, which
  this feature treats as contract text and as *the most durable place there is* (the reasoning is
  `FEAT-02-05`'s correction, which caught a rule about to be re-filed in a test). **Corrected
  2026-08-31 (session59):** as written this bullet said hits here were noise and *"should not be
  counted as a citation"*, which after `FEAT-02` would have led this row's executor to skip the one
  hit that matters.

**Inventory re-dated 2026-08-31.** `FEAT-02` widened the spread while this row waited, which is
nobody's error — "draft" is the right word for the sentences it added, and that is exactly why the
ruling below is still owed. Three corpus files the 2026-08-26 inventory does not name now carry it:
`doc/development/decisions/input.md` (5 — two added by Decision 36's Amendment),
`doc/development/technical_debt/input.md` (3 — `T-ONESHOT-SCOPE`), and a further `doc/input_api.md`
instance at `:272`. Current spread: `input_api.md` 3, `decisions/input.md` 5,
`technical_debt/input.md` 3, `src/` 3, `tests/` 13. **Re-count before executing** rather than
trusting these numbers — the row has now been re-sized twice.

**The word is already overloaded, which the cold review caught (2026-08-26).** It carries **two
different meanings** in the shipping tree, both involving text:

- `discard_draft()` — the **user's** in-progress typed content, thrown away (`model:cancel()`);
- the hidden-`configure` sense — the **programmer's** staged config for the next `show()`.

One is what a person typed, the other is what a project pre-loaded, and a reader meeting `text` in
either place has no way to tell which. This is no longer only a ratification question.

**The ruling the row needs, and it is the owner's:** does "draft" stay or go? It is ordinary English
for unsubmitted text, so unlike *combinator* it may have earned itself — but it is currently used
without ever being defined. **If it stays**, define it once in `doc/input_api.md` so it reads as a
term rather than as loose description. **If it goes**, the row is bigger than the other three,
because `discard_draft()` is a production rename with call sites.

### Crosswalk — old id → new id

**BUG-01:** `01→02` · `02→01`... in full: old `01`(pending)→**01** · old `02`(highlighter)→**02** ·
old `03`(show/force)→**06** · old `04`(clamping)→**05** · old `05`(turtle)→**03** ·
old `06`(uppercase)→**04**.

**FIX-02:** old `01`(remarks)→**07** · `02`(provenance)→**19** · `03`(pong)→**18** ·
`04`(CHANGELOG)→**17** · `05`+`14`(stale claim)→**06** · `06`(tier/chain)→**08** ·
`07`(overlay)→**09** · `08`(combinator)→**10** · `09`(always-consumes)→**11** ·
`10`(callbacks-unset)→**12** · `11`(hide/singleton)→**13** · `12`(channel list)→**14** ·
`13`(pending routing)→**16** · `15`(debt ledger)→**05** · `16`(tixy)→**02** ·
`17`(API duplication)→**01** · `18`(general.md)→**15** · `19`(A-doc claims)→**03** ·
`20`(pointer annotations)→**04**.

*Commit messages and the triage documents dated 2026-08-26 use the old numbers; this table is the
bridge. Unlike the decision ids, these have **no citations in code**, which is why renumbering them
is cheap and renumbering those was not.*

### FIX-01 — pre-existing citation hygiene (3), in priority order

| id | defect | blast radius |
|---|---|---|
| **FIX-01-01** | P11's deferred editorial list — **named as a count, never enumerated** | **UNKNOWN SIZE** — re-derive before sizing; this is why it leads |
| **FIX-01-02** | ephemeral citations in the persistent corpus — 10 step-id/`wip/` paths, **plus the `FR-1`/`FR-6` namespace** found by the remark triage | known, ~12 sites |
| **FIX-01-03** | session numbers in the persistent corpus | known, 4 sites |

*(Old `01`→**02**, `02`→**03**, `03`→**01**.)*

### CHG-01 — CHANGELOG validation and update (4 steps) — **gates ACC-02 and every slice cut**

**Owner, 2026-08-26: runs before ACC-02 and before any PR reassembly.** The CHANGELOG ships in slice
`3a` and is the first thing a stakeholder scans for what breaks; sending a cold reviewer or a smoke
sitting at a tree whose CHANGELOG is wrong wastes the pass.

**Its state today:** 22 lines, **the entire file added by this feature**, one `### Changed` section —
with retired vocabulary in its own prose (*"an active **overlay**"*), no `Removed` section, and a
`> REMARK:` **above its own H1**.

| id | step |
|---|---|
| CHG-01-01 | **validate what is there against the actual diff** — the claims-vs-reality check that caught the PR description |
| CHG-01-02 | add the **`Removed`** section for the four retired globals *(feeder: FIX-02-17)* |
| CHG-01-03 | absorb pre-existing-resolved debt and behavioural changes, per the owner's ruling *(feeder: FIX-02-05)* |
| CHG-01-04 | completeness against the breaking changes; settle the **version question** — `1.0.0-rc` against the scale of the change. **Three independent askers**: the CHANGELOG's own remark, `user_input.md:470`, `project_sandbox_env.md:71` | · **`T-VERSION-NUM`**

**Write it once.** Three rows feed this file; assembled separately they duplicate and disagree.

**PARTLY DONE by `LEDGER-01-01`** (2026-08-27): `-02` is complete — the `Removed` section exists and
leads with the breaking change, closing `FIX-02-17`. `-01` and `-03` are **partly** done: the file
was written from the PR artifacts and spot-checked, not validated claim-by-claim against the diff.
**`-04` is untouched, and it carries the one thing here nobody else will do — the version question**
(`1.0.0-rc` against the scale of the change, asked independently in three places). `ARC-02-07` also
revisits this file, because `ARC-02` changes behaviour its bullets describe.

### FIX-03 — the closed-arc sweep (4 steps) — **runs after FIX-02 and DEC-01**

Retire prose that narrates history which opened *and closed* inside this branch. Spec:
[`validation/reviews/FIX-03-closed-arc-sweep-spec.md`](validation/reviews/FIX-03-closed-arc-sweep-spec.md)

**Why a sweep and not more rows:** three instances were found this session by three unrelated
routes, none by looking — the signature of a class defect. **The test is mechanical:** subject
absent at base `3256aac` **and** absent today → the arc closed inside the branch.

| id | step |
|---|---|
| FIX-03-01 | enumerate subjects failing both greps |
| FIX-03-02 | classify: closed arc / lesson-bearing / pre-feature-deviation record |
| FIX-03-03 | for lesson-bearing, locate the materialized lesson — or promote it before deleting |
| FIX-03-04 | dispose: closed arcs vacuumed |
| **FIX-03-05** | **retired-id citations** — every reference to a retired, renumbered or withdrawn id, wiped |

**`FIX-03-05` is new (owner directive, 2026-08-30):** *"references to a retired ID should be wiped
during doc sweep; no reconfiguration of a roadmap should leave them orphaned and unactionable."* The
rule itself is now standing, in [`agents/rules/roadmap.md`](../../../../agents/rules/roadmap.md) §5
— **the pass that causes an orphan owes the fix**, and this row is the backstop for what slipped
through, not the plan for handling it.

**Two known subjects, both surfaced by session57 and parked until now:**

1. **`T-HL-TWO-HOMES` is cited from `src/` and `tests/`** — `userInputController.lua` (the
   `bind_highlighter` doc comment) and `input_widget_callbacks_spec.lua`. The entry retired, and the
   register's convention drops the slug from the heading and says *"Was `T-HL-TWO-HOMES`"* in the
   body. So the citations still **grep**, and land a reader on a retirement note that reads like a
   live obligation — §5's second and worse failure mode, exactly.
2. **Four more slugs are cited from `ROADMAP.md` with no heading left:** `T-CFG-BOUNDARY`,
   `T-CURSOR-SHAPE`, `T-FORCE-PARTIAL`, `T-HL-UNSET`. Found by the ledger cross-check
   (`LEDGER-01`'s two greps `comm`'d), all four from the `ARC-02` era. These are on **completed**
   rows, so the citation is historical rather than actionable — decide per row whether to re-point
   at the retirement or to say plainly that the goal is retired.

**Check it is clean with the cross-check already written for it** (`LEDGER-01`, above): `comm` the
`^### T-` headings against the roadmap's `T-` citations. A citation missing from the heading side is
a pointer to nothing.

**Two exclusions.** Lessons already materialized in a decision or convention — *verify, then
delete*. And **prose that is the only record of a deviation from pre-feature behaviour**: Decision
11's rot paragraph sits directly above one such record, so a sweep matching on *tone* takes both.
**Match on subjects, never on tone.**

**Scope includes `src/` and `tests/` comments** — where FIX-02-14 hid, and where no doc sweep
reaches.

### DEC-01 — decisions ledger: names, not numbers (6 steps)

**Debt goal: `T-DEC-NUMBERED`** (`technical_debt/general.md`) — six tasks, one goal.

**NOT absorbed by `LEDGER-01-02`** (2026-08-27) — I recommended absorbing it before reading it in
full, and it is a different job: this sprint is the numbers→names conversion, not a sectioning. The
split took the structural half and nothing else; all six steps stand.

**`DEC-01-04` (remove the four tombstones) needs no reconciling — owner-ruled 2026-08-27:**
*"the need to vacuum retired decisions which were not stakeholder's is an obvious operational need;
absence of a formal process should not prevent it from being ruled in place."* I had proposed
sequencing the removal after `DEC-01-05` so that names would make a dangling citation safe; the
ruling makes that a **precaution, not a gate**. `agents/rules/ledgers.md` §2 now carries both the
permission and its one real condition — **only entries that were not the stakeholder's**.

**`RETIRED` holds six entries, not four**, so `DEC-01-03`'s inventory needs Decision 9 and Decision
12 added to whatever it decides for the others, and `DEC-01-04` should say which of the six it
sweeps and which it keeps as stakeholder record.

**Blocks slice cutting.** Spec + drafted inventory:
[`validation/reviews/DEC-01-ledger-denoising-spec.md`](validation/reviews/DEC-01-ledger-denoising-spec.md)

| id | step | gate |
|---|---|---|
| DEC-01-01 | join the 3 line-broken mentions; normalise plural/lower-case | `grep -cE 'Decision$'` = 0 |
| DEC-01-02 | wrap every id in sentinels | **the governing gate** — no bare `Decisions?` in scope |
| DEC-01-03 | inventory: 29 slugs + 4 removals | drafted; owner will grep-and-rename if a slug displeases |
| DEC-01-04 | remove the 4 tombstones (13, 16, 20, 29) | no `TOMB-` survives · decide where Decision 20's `keys_pressed` history goes |
| DEC-01-05 | substitute slugs, one pass per file | reflow long lines **in the same commit** |
| DEC-01-06 | strip sentinels; read the diff; append the crosswalk to the ledger | suite green |

**Scope:** the ledger, ~10 persistent docs, and **`src/` + `tests/` (165 citations)**. **`wip/` is
out of scope** — frozen history, and it carries its own dead `D-1…D-10` namespace.

---

## ⬜ ACC-02 — human acceptance — **blocked on the six sprints**

Runs only once the tree is fixed. Every row costs owner time; re-running them against a tree about
to change is what this ordering exists to prevent.

| id | step | note |
|---|---|---|
| ACC-02-01 | **a second cold PR review**, over the fixed tree | before any keyboard time |
| ACC-02-02 | `balloons` smoke | **first** — 5 ahead / 0 behind, the one result recon cannot invalidate |
| ACC-02-03 | `keyboard` smoke | the review could not check `4c`'s timing — run this one carefully |
| ACC-02-04 | `maze` + `draw` smoke | **against `newinput-edge`** — `da9d1c2` is on that branch only |
| ACC-02-05 | `sapper` smoke | **section C is expected to fail** — P19's accepted defect, described in the list |
| ACC-02-08 | `turtle` smoke | **added 2026-08-30** — `FEAT-02` put its prompt lifecycle on `auto_hide`, so the game no longer closes the widget itself. In-repo, so **run it beside `ACC-02-05`**; numbered out of execution order for the reason `FIX-02-20` records. List: `doc/development/smoke_checklists.md`, *"turtle"* |
| ACC-02-06 | slice regeneration, if the passes moved anything | |
| ACC-02-07 | owner's readability review of the slices | |

Lists: [`doc/development/smoke_checklists.md`](../../smoke_checklists.md). **Tag every green pass**
(`TAGS.md`, round 2) so "it passed" names a commit.

---

## 🟡 REC-01 — upstream reconnaissance — *discovery, not release* — **PARTIALLY COMPLETE (Session 55)**

**Renamed from "recon" and lifted out of the release path (owner, 2026-08-26)**, because it is not
release work: it measures **86+ commits** of drift we currently cannot see, and if upstream moved in
our surfaces its output is **new defect work**. It may spawn a sprint. Fetch-only, read-only;
nothing merges here.

**Session 55 status:** Platform repo RECON analyzed against `feature/77-newinput-premerge` (`aldum/dev` merge).
Upstream 24 commits analyzed: no architectural overlap with #77 input API, single unit-test regression identified in `src/util/filesystem.lua` (`FS.sync` stub missing for `TESTING=true`).
Recon for external example submodules (`maze`, `keyboard`, `balloons`) remains pending.

| id | step | status |
|---|---|---|
| REC-01-01 | fetch every remote; measure the real drift against the pinned tags | **DONE (Platform repo)** — 24 commits in `aldum/dev` evaluated via `feature/77-newinput-premerge` |
| REC-01-02 | assess whether it touched our surfaces — the reported edge-side editor overhaul above all | **DONE (Platform repo)** — no collision with #77 input surface/routing grid |
| REC-01-03 | triage anything it surfaces into a sprint, or record that it surfaced nothing | **DONE (Platform repo)** — single defect: `FS.sync` missing test stub in `filesystem.lua` |

## 🟡 MERGE-01 — upstream reconciliation — **PARTIALLY COMPLETE (Session 56)**

*(was Phase U — renamed, unchanged in substance.)* Four repos, each with its own remote and its own
PR.

| id | step | note |
|---|---|---|
| MERGE-01-01 | `maze` | a **re-merge**, not a first one — reconciled already at a base dated 2026-07-24 |
| MERGE-01-02 | `keyboard` | merged at S37; ancestry preserved so re-merges stay cheap |
| MERGE-01-03 | `balloons` | zero divergence today |
| MERGE-01-04 | the platform repo | **DONE (Session 56)** — merged `aldum/dev` into platform repo (`f4913833`), test mock fix committed (`75a7e5b3`), 1011/0/0/10 green |

**Mechanic, standing:** pull each upstream into **its own branch**; never merge into the working
branch as the first move.

## ⬜ PR-01 — assembly

*(was Phase G — renamed and shrunk. Its opening item, the B→C→D collapse ruling, is already
settled; its checklists are written; its description was rewritten.)*

| id | step |
|---|---|
| PR-01-01 | the final slice cut — **the shipping one**, after MERGE-01 |
| PR-01-02 | the justification table in the PR description |
| PR-01-03 | reviewability gate: `doc/input_api.md` + the description, alone |
| PR-01-04 | open the coordinated PRs — platform + three example repos |
| PR-01-05 | the `wip/77` deletion ruling — **owner-gated, after the PRs are up** |

### Phase L — **retired** (owner-approved, 2026-08-26)

Ledger compaction had three items and **none needs a phase**:

1. excise the collapsed decisions → **DEC-01-04**, which is a *superset* (it also removes 16);
2. remove Decision 11's withdrawn-rationale trail → **already a row**: it is REMARK `:429`, inside
   FIX-02-01;
3. demote Decision 12 → **parked**, the owner disposes it during review.

Retiring L therefore drops nothing.

### Phases B, C, D — **dissolved** (owner ruling, 2026-08-26)

They are absent from this roadmap by **ruling**, not by omission. They were a prediction of the
shape of pre-release work; that shape emerged differently, so the placeholders go.

- **B, the intent check** → done by the **cold reviews** (`ACC-01-02`, repeated at `ACC-02-01`) —
  and by a reviewer with no stake, which a self-check could never be.
- **C2, the disposition table** → emerged as the **defect register**.
- **C1 and D** → dissolved outright: *principles are enforced at the row, without abstract
  encoding first.* The parked calls below are that method.

**This settled the gate early.** The collapse ruling was scheduled as step zero of Phase G; it is
done, and G no longer opens with it. **Phase F** goes with them — its "final revalidation" is what
`ACC-02-01` is.

---

## Parked, with the moment each gets answered

Not open questions to chase — each has a trigger:

| question | answered at |
|---|---|
| highlighter: sentinel, or a `clear_highlighter` member? | **when BUG-01-02 is fixed** |
| the 14 remarks: ruled individually, or swept? | **when FIX-02-01 starts** |
| does "draft" stay (and get defined) or go? | **at FIX-02-20**, with the 08–10 vocabulary cluster |
| is `prompt` sticky or per-show *within* a run? | **at FIX-02-21** — escalates to a BUG row if the answer is per-show |
| Decision 12 — a ledger entry that says it is not a decision | **owner disposes during review** — needs context, stays in place |
| the slug table | **no review needed** — grep-and-rename if a slug displeases |
| provenance beyond the 3 files | **deferred** — a formal violation does not displace real work |
| where Decision 20's `keys_pressed` history lives after removal | **at DEC-01-04**, per entry |
| ~~which sprint (and KIND) the three owner debt entries are filed into~~ | **ANSWERED 2026-08-30** — two new KINDs, owner-ruled: `OP-01` for the ledger upkeep (operational, no parent decision), `FEAT-01` for the design and implementation |
| does `oneshot` close on cancel as well as submit, and what happens when the project also set `after_submit`? | **at `FEAT-01-01`** — the design ruling, before any code |
| is `maze`'s flag-clearing neutralisation worth rewriting, or `wontfix`? | **at `BUG-01-11`**, whose first step is that weighing |

