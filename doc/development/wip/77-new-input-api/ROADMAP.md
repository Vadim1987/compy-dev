# Roadmap — feat #77, from here to the PR

**The navigable view.** One page, current, ordered. The reasoning lives in
[`validation/plan.md`](validation/plan.md) and the review documents this points at; **this file is
the sequence**. Updated 2026-08-27.

## Where things stand

| | |
|---|---|
| branch | `feature/77-newapi-analysis-s20260615` |
| suite | **979 / 0 / 0 / 10** — 970 + ARC-01's nine (3 store resolution, 6 widget lifetime); the 10 pending are an owner ruling, an 11th is a finding |
| marker gate (`src`/`tests`) | clean — **but it never covered `doc/`**, which is FIX-02-01 |
| slices | regenerated, **100 / 100 complete and disjoint** |
| baselines | pinned as local tags, [`TAGS.md`](TAGS.md) — nothing fetched since |
| upstream | **86 commits behind the edge** (a floor: our view is 23 days old) |

**The spinoff sprint is closed and TF2 with it.** With `ARC-01` complete, what remains is `ARC-02`
(planned 2026-08-27, not started), acceptance, four defect sprints, reconciliation, and assembly.

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

## ⬜ ARC-02 — `show` composes `configure`; the user's content is `show`'s alone — **PLANNED, not started**

**Plan: [`validation/reviews/ARC-02-configure-boundary-plan.md`](validation/reviews/ARC-02-configure-boundary-plan.md).**
Owner-settled design (2026-08-27), grown out of `ARC-01-07`. `configure` runs everything except the
user's input and refuses `text`/`cursor`; `text`/`cursor` are `show`'s alone; every other flag is
processed only when non-nil, in both calls. `show{force = true}` becomes the **full re-setup** the
stakeholder was shown and gated — intent recovery in
[`validation/reviews/force-and-configure-intent-recovery.md`](validation/reviews/force-and-configure-intent-recovery.md) §1.

**An `ARC` row because it deletes rather than patches:** `re_show`, the `live` filter table, `text`
inside `apply_config`, and — under pick A(ii) — `state.pending` entirely.

**Both picks settled** (owner, 2026-08-27) and the shape is ratified as **Decision 35** in
`doc/development/decisions/input.md` — the persistent ledger, so it outlives `wip/77`, and that entry
is also the deviation record. `text`/`cursor` at `configure` **raise** as keys belonging to another
call, so `ARC-02-01`'s Decision 15 amendment is in scope and is the gate; the hidden-`configure`
stash **goes**, on the owner's ground that the promise was redundant when it was made — content for a
widget about to come up is set by the `show` that brings it up, before it is visible.

**`reset()` is recommended but not built in this release** (owner). The recommendation and the two
constraints on whoever builds it live in Decision 35's closing section, not in the ephemeral plan.

| id | step | note |
|---|---|---|
| ARC-02-01 | the ledger gate — amend Decision 15's scope paragraph | **in scope** (pick A settled). Decision 35 is written; this step amends **Decision 15**'s scope paragraph to move `text`/`cursor` at `configure` from the warn side to the raise side. The `ARC-01-03` pattern: amend, do not reinterpret |
| ARC-02-02 | breaking tests first, one per claim | `force` applies the prompt / applies the highlighter **now** / clears with no `text`; `configure{text}` refuses; hidden `configure{prompt}` shows next time. Each seen to fail first |
| ARC-02-03 | `text` leaves `apply_config`; `reset_content` on the activation path | the single-policy move. **Trap:** `clear_input` ≠ `set_text('')` — it also clears the selection, the custom status and the history index (plan §2a) |
| ARC-02-04 | `re_show` deletes; `show` composes | the payoff commit — `BUG-01-06` and its sibling dissolve here |
| ARC-02-05 | `configure` refuses `text`/`cursor`; `pending` **deletes** | `consoleController` key sets, `consume_pending`, `stash_hidden_configure`, `WIDGET_STORES` |
| ARC-02-06 | **`BUG-01-08`** — the cursor shapes | must precede any documented "unset by a reasonable default" rule, which is what would make a scalar cursor something a project writes |
| ARC-02-07 | docs + the deviation record + **`CHANGELOG.md`** | executes **`FIX-02-21`** and answers **`FIX-02-12`**; `false` as the uniform unset; the balloons rationale into the persistent internals doc. **`CHANGELOG.md` is in scope here**: `LEDGER-02` wrote its input bullets against today's behaviour, and `ARC-02` changes some of what they describe (a forced `show` clears; `configure` refuses `text`/`cursor`) |
| ARC-02-08 | sweep the fixture and specs | the `ARC-01-06` lesson — expect it partly absorbed by `-03`…`-05` |

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

**Closes or dissolves:** `BUG-01-06` (+ its unfiled sibling), `BUG-01-08`, `FIX-02-21`, `FIX-02-12`,
and it drops `BUG-01-02` out of the design-escalation column — `highlighter = false` already works,
so that row becomes ratification. **Not in scope, but recommended:** `reset()` (predecessor §8d) — a public addition
needing its own justification line, deliberately kept out of a sprint whose value is deletion, and
carried forward as a recommendation in Decision 35 rather than lost with `wip/77`.

---

## ⬜ The six defect sprints — **the current work**

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

### BUG-01 — runtime defects (10), in priority order

| id | defect | blast radius |
|---|---|---|
| ~~**BUG-01-01**~~ ✅ | `state.pending` survives a project stop | **CLOSED, fixed** — `bd2a5d49` (fix + breaking test + behaviour docs), `abadf244` (the false-premise debt entry). No shipped example reaches it, but the path is public API. **Its siblings were then swept** (owner-scoped: `compy.input` + the widget singleton) and one more was found and fixed — the prompt label, `8a9022ec`. Evidence: [`validation/notes/BUG-01-01-pending-lifetime.md`](validation/notes/BUG-01-01-pending-lifetime.md) |
| **BUG-01-02** | a highlighter cannot be turned off | **design escalation** — sentinel vs a new `clear_highlighter` member; either changes the public surface. **Wait for ARC-01**, which removes this row's teardown half and leaves only the within-run call. **ARC-01-07 may have dissolved it outright** (2026-08-27, superseding this row's earlier note in the same session): **`highlighter = false` already turns the highlighter off, exactly**, and needs no machinery at all. `apply_config` guards on `~= nil`, so `false` is *stored*; every consumer then guards on **truthiness** — `if ev.highlighter then` (`userInputModel.lua:384/393`) — so a stored `false` takes the **same branch as absent**, `ev:validation_hl(text)`, which is the channel that displays the validator's error in the field. Identical by construction, not by approximation. **Verified by probe**: `validator = false` lifts a rejecting validator, `on_text_entered = false` submits without a crash, `highlighter = false` leaves `get_highlight()` working. *(An earlier note on this row said no user-space value reproduces absent and that the row needed machinery or nothing. That was wrong — it reasoned about `nil` and missed that the code tests truthiness.)* **What remains here is a documentation and ratification call, not a design one:** `false` means *"no such thing"* is already the de-facto contract (Decision 14's situation exactly), it is idiomatic Lua, and it is uniform across `highlighter`, `validator` and the widget outputs. Ratify it and write it down, or reject it and then build machinery. **`prompt` is de-scoped either way** — it has `''` for an empty label and `false` for "back to the default label", both verified |
| **BUG-01-03** | `turtle` double-handles its own keys | **may implicate every migrated example** — it is a finding about the migration. Fix with FIX-02-11 |
| **BUG-01-04** | a `textinput` shortcut cannot bind an upper-case character | **deep** — the fix is in combo serialisation, which every shortcut match runs through |
| **BUG-01-05** | `set_cursor` clamps bytes, boundary event measures characters | medium — two functions disagree; which is right is a small design call |
| **BUG-01-06** | `show{force = true, prompt = …}` silently drops the prompt | narrow — one call path, and **it may dissolve rather than be fixed**: intent recovery ([`validation/reviews/force-and-configure-intent-recovery.md`](validation/reviews/force-and-configure-intent-recovery.md)) found the stakeholder gated *"reconfigured in-place with the new config"* behind `force`, and the code kept only that sentence's parenthetical — so `force` applies content and **nothing else**, the complement of what was specified. Making `force` the full re-setup it was reviewed as removes this row's defect along with three others. `force` has **no consumers in-tree**. **A sibling is NOT covered by this row, and it has since been traced to a root cause — `BUG-01-10`:** the same call *defers* the **`highlighter`** — and only it. **Corrected 2026-08-27 by the cold review:** `validator` / `on_text_entered` / `on_limit_reached` are **applied immediately**, because `merge_callback_keys` writes into the widget's own `callbacks` table, the very table `apply_config` would write. The `highlighter` alone defers, because it lives on `model.evaluator`, which that merge never touches. Verified by probe. So the call has three behaviours for its keys — applied (`text`, three callbacks), dropped (`prompt`, `cursor`), deferred (`highlighter`). Rule on them together |
| **BUG-01-07** | **balloons keeps a shadow copy of the widget's label and re-pushes it every game cycle** | narrow — one example repo, no platform code. Pre-feature fossil: `ui_messages.hint` + `ui_draw_hint()` re-assert the label on each state transition because in the legacy era the label died with each `input_text()` call. With stickiness ratified (owner, 2026-08-27) the widget owns the label and the shadow state is redundant. Two vestigial arguments ride along — `terminal_write(msg, flushed)` never reads `flushed`, and `ui_set_hint(fmt(GAME_PROMPT, txt), true)` passes a second argument `ui_set_hint` does not take — plus a stale `-- NOTE: won't work if there was no real input`. `ui_messages.hint`'s initial `SPLASH_HINT_START` never reaches the widget (`game_init` calls `ui_show_command_prompt` immediately); the same text does reach the screen via `graphics.lua:575`, so nothing is visibly missing. **Filed by the owner, 2026-08-27**, on reading the ARC-01-07 evidence. Modest severity: redundancy and misleading fossils, no user-visible misbehaviour found |
| **BUG-01-10** | **the highlighter has two homes, and one of them lags** — `compy.input.callbacks.highlighter = fn` on a shown widget does **nothing** until an unrelated later `show`/`configure` flushes it | **the root cause `BUG-01-06`'s sibling is a symptom of**, and the only one of the four callback fields with this shape. `highlighter` lives both in the widget's `callbacks` table (the sticky store, shared with the `compy.input.callbacks` surface) **and** on `model.evaluator`, which is what the model actually reads (`userInputModel.lua:384/393`). Only `apply_config` copies store → evaluator, so **any path that writes the store without calling it leaves the live copy stale**. Two symptoms, both probed: a forced `show` defers it (dissolved by `ARC-02`), and a **direct assignment does not take effect at all** — then appears later at an unrelated `configure{}`. `doc/input_api.md` ("Callback assignments") documents `highlighter` as assignable that way. `validator` and the widget outputs have **one** home and work. **RULED (owner, 2026-08-27): one home, proxied via `callbacks`** — the widget's `callbacks` slot is the single source of truth and the evaluator stops holding a copy; the `compy.input.callbacks` surface proxies to it, so a direct assignment and a `show`/`configure` key reach the same place by construction. **The drift this replaces is documented in `doc/development/internals/user_input.md`** — a reader meeting the old two-homes shape in an older tree needs to know why the evaluator no longer carries it. No longer an escalation; the shape is settled and the work is implementation. Third defect from the evaluator split — session48 fixed the shared-singleton one. Found 2026-08-27 |
| **BUG-01-09** | **`set_text` silently ignores a multi-line *string***, so `show{text = "a\nb"}` leaves the previous content standing | narrow fix, **but the failure mode is the worst on this list**: silent, on a **documented** input shape, on the primary call. `UserInputModel:set_text` (`:125-134`) assigns `self.entered` only when `#string.lines(text) == 1`; a multi-line string falls through every branch and nothing is written, so the **previous session's content survives into the new one**. A list of line strings works. `doc/input_api.md` documents `text` as *"a string or list of line strings"*. Found by the `ARC-02` cold review, re-probed here: `show{text='previous'}` → `hide()` → `show{text='a\nb'}` leaves `previous` on screen. Belongs with `ARC-02-03`, which is the step that touches the content path |
| **BUG-01-08** | **`show{cursor = {}}` raises a raw Lua error from inside the framework** | narrow — one unguarded function, but it is a **public path that crashes the project**. `set_cursor_pos` (`userInputController.lua:169-175`) does `math.min(line, n)` with no nil guard, so a partial or empty cursor table — `{}`, `{1}`, `{nil, 2}` — and a direct `compy.input.set_cursor(nil, nil)` all die with *"bad argument #1 to 'min' (number expected, got nil)"*. Two reasons it matters beyond the crash: the config table is otherwise **strictly** validated (an unknown key raises with a message naming the key and where it belongs), and `doc/input_api.md` promises out-of-range cursor values **clamp** rather than fail. **Base-checked: ours** — `set_cursor_pos` does not exist at `3256aac`; it is FR-9's implementation. Distinct from `BUG-01-05`, which is about byte-vs-character clamping of *valid* input. Found 2026-08-27 probing empty values; **widened the same day** — `cursor = 1` and `cursor = false` raise too, at `:309` (*"attempt to index field 'cursor' (a number value)"*), because the config path indexes `cfg.cursor[1]` without checking the shape. **This row now gates a design rule:** a scalar or defaulted cursor is the proposed "unset" for the field, and it cannot be documented while it raises. **Numbered last, but its radius argues for running it with `BUG-01-05`/`-06`** — all three are cursor/config call-path fixes in the same two files |

### FIX-02 — docs, vocabulary, process (22), in priority order

*(was 20, then 19 — the old `05` and `14` merged into `06`, being one defect in three places — and
back to 20 with `FIX-02-20`, and 21 with `FIX-02-21`, both registered 2026-08-26.)*

| id | defect | blast radius |
|---|---|---|
| **FIX-02-01** | **`on_text_entered` and `after_submit` are two ways to set one callback** | **design escalation, public surface.** The cold review missed it; the owner raised it twice. Bears on the strategic frame's "no moving parts beyond the ask" |
| **FIX-02-02** | **`tixy` may drop the legend on submit** | **verify → ratify or revert.** A possibly unratified change to pre-feature behaviour, in code |
| **FIX-02-03** | the A-doc's three factual claims (`:79`, `:650`, `:675`) | **may reveal the code is wrong, not the doc** |
| **FIX-02-04** | pointer annotations in `project_sandbox_env.md` — completeness never checked | **unknown yield** — a verification task |
| **FIX-02-05** | the debt ledger's 20 resolved entries | **unknown yield** — each tested against base; may find more rot |
| **FIX-02-06** | the stale keyboard/pointer divergence claim | **one defect in three places** — `release_keyboard_route`'s comment, `event_dispatch_layers.md:112`, and the second doc. **Fix as one**; any survivor re-seeds the others |
| **FIX-02-07** | execute the 37 remark dispositions | triage **complete**; breadth known, 12 files |
| **FIX-02-08** | "tier" / "chain" / "the walk" — three names, one thing | known breadth, 3 slices |
| **FIX-02-09** | "overlay" / "widget" / "area" / "field" — four names | known breadth; `src` half done in S45, docs half open |
| **FIX-02-10** | "combinator" — concept earned, word not | narrow |
| **FIX-02-11** | the guide never says a shown widget **always consumes** (keyboard) | narrow — **but fix with BUG-01-03**, which is its symptom |
| **FIX-02-12** | the guide never says callbacks cannot be un-set | narrow — depends on BUG-01-02's ruling. **Write with `FIX-02-21`**: both are answered by the same paragraph — the ownership rule (*content resets; everything the project sets persists until replaced*) plus the sentence saying what "replaced" cannot mean. Not a duplicate of it; the same edit |
| **FIX-02-13** | `hide()` vs teardown — the singleton is never stated | narrow — **write with `FIX-02-22`**, same paragraph of the same doc |
| **FIX-02-14** | the channel list exists twice | narrow |
| **FIX-02-15** | `technical_debt/general.md` carries an entry that is not debt | narrow |
| **FIX-02-16** | a `pending()` routing case deferred in the hardest-read area | narrow |
| **FIX-02-17** | CHANGELOG omits the breaking change | narrow — **feeds CHG-01** |
| **FIX-02-18** | `pong/README.md` — 316-line diff, 2-line change | narrow |
| **FIX-02-19** | provenance front matter, 3 files | narrow |
| **FIX-02-20** | **"draft" — unratified vocabulary, and the widest-spread of them** | **runs with the 08–10 cluster, not last** — see the note below |
| **FIX-02-21** | **`prompt` is classified per-show but behaves sticky** — ~~which is right is undecided~~ **RULED: the behaviour is right, the classification is wrong** | **no longer escalates** — stays a FIX. Owner ruled 2026-08-27 (below); the work is a comment, a list membership and two doc sentences |
| **FIX-02-22** | **three documents say a hidden widget keeps its content; the code clears it** | narrow, but **one site is in the persistent corpus** and outlives `wip/77`. `design/spec.md:155` (*"Content preserved for the next `show()` without `text`"*, contradicting its own §3 five lines up), the round-2 reviewed text `spec.versions/version01.md:191-194`, and **`decisions/input.md` Decision 3** (*"hide and bring back with state intact"*, amended last session). Code clears (`open_widget`), the suite pins it, and **turtle depends on it in a comment** (`main.lua:63-66`). **Disposition: fix the documents** — the owner ruled the behaviour 2026-08-27, and the stakeholder requirement (FR-3/FR-4, the sapper complaint) is about not tearing the widget down, which still holds. Decision 3 needs one qualifier: state survives *except the draft text*. Found 2026-08-27, ARC-01-07 follow-up |

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
- `tests/input/input_widget_control_spec.lua` — also used as fixture *text*, which is noise when
  grepping the term and should not be counted as a citation.

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
| CHG-01-04 | completeness against the breaking changes; settle the **version question** — `1.0.0-rc` against the scale of the change. **Three independent askers**: the CHANGELOG's own remark, `user_input.md:470`, `project_sandbox_env.md:71` |

**Write it once.** Three rows feed this file; assembled separately they duplicate and disagree.

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

**Two exclusions.** Lessons already materialized in a decision or convention — *verify, then
delete*. And **prose that is the only record of a deviation from pre-feature behaviour**: Decision
11's rot paragraph sits directly above one such record, so a sweep matching on *tone* takes both.
**Match on subjects, never on tone.**

**Scope includes `src/` and `tests/` comments** — where FIX-02-14 hid, and where no doc sweep
reaches.

### DEC-01 — decisions ledger: names, not numbers (6 steps)

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
| ACC-02-06 | slice regeneration, if the passes moved anything | |
| ACC-02-07 | owner's readability review of the slices | |

Lists: [`doc/development/smoke_checklists.md`](../../smoke_checklists.md). **Tag every green pass**
(`TAGS.md`, round 2) so "it passed" names a commit.

---

## ⬜ REC-01 — upstream reconnaissance — *discovery, not release*

**Renamed from "recon" and lifted out of the release path (owner, 2026-08-26)**, because it is not
release work: it measures **86+ commits** of drift we currently cannot see, and if upstream moved in
our surfaces its output is **new defect work**. It may spawn a sprint. Fetch-only, read-only;
nothing merges here.

| id | step |
|---|---|
| REC-01-01 | fetch every remote; measure the real drift against the pinned tags |
| REC-01-02 | assess whether it touched our surfaces — the reported edge-side editor overhaul above all |
| REC-01-03 | triage anything it surfaces into a sprint, or record that it surfaced nothing |

## ⬜ MERGE-01 — upstream reconciliation

*(was Phase U — renamed, unchanged in substance.)* Four repos, each with its own remote and its own
PR.

| id | step | note |
|---|---|---|
| MERGE-01-01 | `maze` | a **re-merge**, not a first one — reconciled already at a base dated 2026-07-24 |
| MERGE-01-02 | `keyboard` | merged at S37; ancestry preserved so re-merges stay cheap |
| MERGE-01-03 | `balloons` | zero divergence today |
| MERGE-01-04 | the platform repo | the big one — 86+ behind |

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

---

## The one-line sequence

**ACC-01 ✅ → ARC-01 ✅ → ARC-02 → { BUG-01 · FIX-01 · FIX-02 · DEC-01 · CHG-01 } → FIX-03 → ACC-02 → REC-01 → MERGE-01 → PR-01**

*`ARC-01` leads because it dissolves part of `BUG-01-02` and removes the teardown machinery the
other rows would otherwise be sized against — the ordering principle firing exactly as written.*
