# Roadmap — feat #77, from here to the PR

**The navigable view.** One page, current, ordered. The reasoning lives in
[`validation/plan.md`](validation/plan.md) and the review documents this points at; **this file is
the sequence**. Updated 2026-09-02.

---

## The one-line sequence

**ACC-01 ✅ → ARC-01 ✅ → LEDGER-01 ✅ → ARC-02 ✅ → OP-01 ✅ → FEAT-01 ✅ → FEAT-02 ✅ → { BUG-01 ✅ · BUG-02 ✅ · DEC-01 ✅ · FIX-01 ✅ · FIX-02 (a) ✅ · FEAT-03 ✅ · CHG-01 ✅ } → REC-01 → MERGE-01 → ACC-02 → FIX-02 (b) → FIX-03 → DEC-02 → LEDGER-02 → DOC-01 → ACC-03 → PR-01 → PROP-01**

*`FIX-02` runs in two halves across the device passes (owner, 2026-09-02) — **(a)** the rows whose
prose a smoke pass reads or whose yield is unknown, **(b)** vocabulary and process. See the sprint's
**"Execution order"** note; the halves are passes, **not new ids**, and the rows are **not
renumbered**.*

*`OP-02` is optional and **does not delay the release** (owner, 2026-09-03) — recover the
truncated S68 delivery review. It is **not in the sequence above**; skip it and ship.*

| stage | what it is | why it sits here |
|---|---|---|
| **ACC-01** ✅ | device-free acceptance — a cold PR review against the original stakeholder ask | it found the 26 defects everything after it works through; nothing could be sized before it ran |
| **ARC-01** ✅ | the project widget gets a **run lifetime** instead of an application one | structural: it *dissolved* a defect class rather than patching it, and deleted the teardown machinery the later rows would have been sized against |
| **LEDGER-01** ✅ | the three ledgers get a shape — changelog, decisions, debt | the rows after it record their state somewhere; the somewhere had to exist first |
| **ARC-02** ✅ | `show` composes `configure`; the user's content is `show`'s alone | the second structural row — it dissolved four defects, including two nobody had filed yet |
| **OP-01** ✅ | ledger upkeep for the owner's three hand-filed entries → **Decisions 36 and 37** | needed no ruling, and it produced the design inputs the next stage implements |
| **FEAT-01** | the two surface proposals: **`oneshot`**, and the **payload split** that tells the submit callbacks apart | **leads by blast radius** — it changes the public surface, so `FIX-02-01` is one of its rows' seams, `CHG-01` carries what it breaks, and a slice cut before it lands is cut twice |
| **FEAT-02** ✅ | **`oneshot` becomes `auto_hide`**, a widget property — overruling `FEAT-01-01`'s Q1 | **leads for the same reason `FEAT-01` did, and it is the last surface change until `FEAT-03`, 2026-09-03**: it moves a key out of the show-only category, so `FIX-02-01`'s neighbours and every slice are sized against it. It also closes a live defect — disarming a `oneshot` today costs the user's draft |
| **FEAT-03** ✅ | **`get_text()`** — the read of its own content the surface never had | **owner, 2026-09-03**, on the escalation F1 raised: the retirement of the hide/show preservation requirement rested on a project keeping the content itself, and it cannot read what the user typed. Placed by `FEAT-01`'s argument at smaller scale — it changes the public surface, so `CHG-01` carries its line, and a slice cut before it lands is cut twice. **An addition, not a break**: nothing that works today stops working. **Session69, same day:** it shipped when the ask was to file it as debt; `doc/input_api.md` marks it **experimental** (may be withdrawn). **`ACC-02` does not exercise it** — no smoke step, owner 2026-09-03 |
| **{ BUG-01 ✅ · BUG-02 ✅ · DEC-01 ✅ · FIX-01 ✅ · FIX-02 (a) ✅ · FEAT-03 ✅ · CHG-01 ✅ }** | the defect sprints — runtime defects, citation hygiene, docs and vocabulary, the decisions ledger's rename, the changelog | one brace, not a sequence: they interleave. Two hard constraints — **DEC-01 and CHG-01 finish before any slice is cut**, and **CHG-01 also gates ACC-02**. **`DEC-01`'s half is discharged** (session65) and **`CHG-01`'s too (session68)**, so **the slice cut and `ACC-02` are no longer gated by this brace** — what remains in it is `FIX-02`'s (b) half alone, and (b) runs after `ACC-02` by the owner's own ordering — **`FIX-01` closed 2026-09-03 (session69)**, so **the brace no longer holds anything before `REC-01`**. A third was conditional and is likewise **discharged**: `BUG-02`'s weighing went to *fix*, and it finished first. **`FIX-02` is here as half (a) only** (owner, 2026-09-02) — the rows a smoke pass reads or whose yield is unknown; the vocabulary and process half runs after `ACC-02`. **`FEAT-03` joined the brace 2026-09-03** and was the one member with an internal order — it finished **before `CHG-01`**, which validates its CHANGELOG line rather than writing it — and it is **done** (session68) |
| **FIX-03** | the ephemeral-citation sweep, **and retired-id citations** | **runs last of the fixes on purpose** — it catches what the others miss, and running it first means three brooms over one floor |
| **DEC-02** | the decisions ledger stops arguing with an interim past that never shipped | **owner, 2026-09-01**, promoted from a `REMARK` in the ledger to a rule in `agents/rules/ledgers.md`. `DEC-01` vacuumed the retired *entries*; this vacuums dead *prose inside live ones*. It sits here for `DOC-01`'s reason and is **not** `FIX-03`: that sweep matches subjects absent at base and today, and a rule's withdrawn version is not an absent subject |
| **LEDGER-02** | the debt register stops keeping defects that never existed outside the branch | **owner, 2026-09-01**, extending `DEC-02`'s principle to the second ledger: *introduced-then-paid never existed for the outer world.* It sits beside `DEC-02` because it is the same rule on a different register, and **after `FIX-02-05`**, which already produces the classification it needs |
| **FIX-02 (b)** | the vocabulary and process half of the same sprint | **after `ACC-02`, owner 2026-09-02.** Its nested-repo scope (`keyboard`, `maze` — `FIX-02-09`) is the very tree `MERGE-01` merges into, so sweeping first means sweeping twice; and nothing in it changes what a device pass can observe |
| **DOC-01** | the documentation compaction sweep — one deliberate pass over the stabilised prose corpus | **owner, 2026-09-01**, restoring a step the roadmap had scheduled for comments only. It runs **after** `FIX-03` because that sweep's deletions are *mechanical* (subject absent at base and today) and shrink the floor this one exercises judgement over, and **before** `ACC-03` because a cold reviewer should read the prose that ships, not the prose that was being written. *(The 2026-09-01 placement named `ACC-02`, which was then the cold read; the 2026-09-02 split moved that role to `ACC-03` and the reasoning is unchanged — only the row name.)* |
| **REC-01** | upstream reconnaissance — measure the real drift, decide what it means | 🟡 platform repo **done**; the three example repos remain. **Moved ahead of `ACC-02`, owner 2026-09-02** — the smoke passes exercise those repos, so merging into them afterwards smokes a tree that then changes |
| **MERGE-01** | upstream reconciliation — actually merge | 🟡 platform repo **done** (`f4913833`); `maze`, `keyboard`, `balloons` remain. Same move, same reason |
| **ACC-02** | **the device passes** — smoke on real hardware | **moved ahead of the prose rows, owner 2026-09-02.** It is the last thing that can find a *runtime* defect, so everything after it is cheap to redo and nothing after it is done twice |
| **ACC-03** | **the cold read** — a second cold PR review over the finished tree, then the slice-readiness pass | **stays late**, on the 2026-09-01 placement of `DOC-01`: a cold reviewer should read the prose that ships, not the prose that was being written |
| **OP-02** | optional — finish the interrupted S68 delivery review | **owner, 2026-09-03**. The review claims seven findings and the file ends at F5; there is no dispositions table. A re-read recovers whatever was not written. **Does not delay the release** |
| **PR-01** | assembly — the shipping slice cut, the description, the coordinated PRs | last by construction: a slice regenerated before the tree stops moving is regenerated twice |
| **PROP-01** | the proposal block — the stakeholders' answer to the shipped surface | **after the PR, owner 2026-09-03.** Items 2–6 reopen the public surface, and everything before `PR-01` is sized against the current one. Three carve-outs stay pre-PR and none is design: the `get_text` promotion (`DOC-01-07`), the destination of the block itself, and a contract-or-defect ruling on Escape |

*The ordering principle throughout is **blast radius, not severity** — anything that can reveal more
defects, escalate into a design decision, or reach deep enough to cause regressions goes first, and
narrow mechanical rows follow. Sizing a small row against an unsettled surface is sizing it twice.*

## Where things stand

| | |
|---|---|
| branch | `feature/77-newapi-analysis-s20260615` |
| suite | **1055 / 0 / 0 / 10** — 1050 + `FEAT-03`'s five (`get_text` reads back what `show` seated and what the **user typed**, joins multiline with `\n`, answers `''` when up and empty and `nil` when hidden); 1050 was 1048 + `FIX-02-25`'s two (every key `show()` accepts reaches the widget, and the same through `configure()`); 1048 was 1043 + the five the second cold review earned (three list shapes an `ipairs` walk let through, `show{text = false}` opening empty, and the error blaming the caller's line); 1043 was 1038 + `BUG-02-02`'s five (four bad element types, and the same refusal through `show`); 1038 was 1036 + the two `BUG-02-01`'s unification earned (both spellings land at the end of shorter content; a non-text value leaves content standing); 1036 was 1032 + its four (the list splits, empty lines survive it, both spellings agree on the cursor, and the same split at the surface); 1032 was 1030 + the two the sprint's cold peer review earned (a shortcut receiving the typed case, and the parser's byte column reaching the caret); 1030 was 1028 + `BUG-01-05`'s two (the character clamp, at `set_cursor` and at the `set_text` keep_cursor landing); 1028 was 1025 + `BUG-01-04`'s three (upper-case serialisation bare and modified, and the end-to-end textinput dispatch); 1025 was 1023 + `BUG-01-09`'s two breaking tests (the multi-line string, at `show` and at the live `set_text`); 1023 was 1021 + `FEAT-02`'s two (the `configure` disarm that keeps the draft, and `false` as the unset; two further cases replaced the ones pinning the retired category); the 10 pending are an owner ruling, an 11th is a finding |
| marker gate (`src`/`tests`) | clean — **but it never covered `doc/`**, which is `FIX-02-07` |
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

## ✅ FEAT-03 — `get_text()`, the read of its own content the surface never had — **COMPLETE (session68)**

**Owner ruling, 2026-09-03**, on the escalation `S67-delivery-revalidation.md` F1 raised: *"write it
as active technical debt to be resolved before release; disclose the gap but mark it as defect
fixable with getter until ruled otherwise."* **Debt goal: `T-CONTENT-READ`** (`technical_debt/input.md`,
promoted from an unslugged BACKLOG proposal the same day — and **RETIRED the same day**, by this
sprint; the entry keeps its filing verbatim above its `Resolution`).

**DONE 2026-09-03 (session68), suite 1050 → 1055.** Registered, built, documented and swept in one
sitting, in the order this table lists. **It was the fastest row in the brace and the only one that
changed the shipped surface** — which is the argument for having placed it here rather than after
`CHG-01`: the CHANGELOG pass now validates a file that already has the line, instead of being
redone once the function lands.

**The gap.** `compy.input` exposes `set_text` and no reader. Content reaches project code only at
**submit** — `on_text_entered` and `after_submit`, both inside `UserInputController:submit_flow`;
`cancel_flow` delivers nothing. So a project can keep what it seated and what a submit handed it,
and never what the user typed and did not submit. `get_cursor()` exists, so the **caret** round-trips
a `hide` → `show` and the **text** does not.

**Why it is release scope rather than a proposal.** `D-CFG-BOUNDARY` retired the ratified
requirement that content survive `hide` → `show`, on the ground that a project which needs it can
keep the content itself — and `doc/input_api.md`'s `hide()` section told an author to do exactly
that. The advice was not followable; the guide's disclosure of the gap was the **interim** state the
owner ruled, and it lasted one sitting — `hide()` now carries the worked save-and-restore example
instead.

**Why it sits in the brace, before `CHG-01`** — `FEAT-01` and `FEAT-02`'s placement argument, at
smaller scale: it changes the **public surface**, so `CHG-01` must carry its line, and a slice cut
before it lands is cut twice. It is the **third and last** surface change, and unlike the first two
it is an addition rather than a break: nothing that works today stops working. **It does not get an
`ACC-02` step** (owner, 2026-09-03, session69): the ship was premature, the guide marks it
experimental, and a device pass would pin a contract that may be withdrawn.

| id | step | notes |
|---|---|---|
| FEAT-03-01 ✅ | the breaking test first — **five, not three** | `agents/development.md`. Content seated by `show` reads back; content the **user typed** reads back (the case the whole entry is about); `nil` while hidden. Two more earned themselves in the writing: multiline joins with `\n`, and **`''` when up and empty** — `''` and `nil` are a deliberate pair, so a project can tell *nothing typed* from *nothing to report*, and pinning one without the other lets them collapse into each other unnoticed. All five failed first with *"attempt to call field 'get_text' (a nil value)"* |
| FEAT-03-02 ✅ | implement `get_text` on the surface — **eight lines, one commit with `-01`** | `consoleController.lua`, `build_widget_api`, beside `get_cursor` and shaped like it: **`nil` while hidden and no warning** — a read of *"nothing to report"* is not a refused mutation. Read-only; it adds no rule about content lifetime, which is the whole reason it was preferred over restoring preservation. `UserInputController:get_text` already existed and is not on the project surface, so the work was the surface hop and the string join, not a new read path. `src/types.lua`'s `CompyInput` class gained the `@field`, and the frozen-shell case (D-FROZEN-SHELL) gained a fourth callable |
| FEAT-03-03 ✅ | `doc/input_api.md`, **and `internals/user_input.md` with it** | the surface entry, **and the `hide()` section's disclosure paragraph is rewritten with it** — it said that no call reads the content, which stopped being true at `-02`. **The example was executed, not reasoned about** — typed into a live widget in a scratch spec, saved, hidden, re-shown, asserted, deleted. A drifted line citation went with it: `internals/user_input.md` located the surface at `consoleController.lua:487-510` and now names `build_widget_api` instead |
| FEAT-03-04 ✅ | the CHANGELOG line | `Added`, at user-facing altitude. `CHG-01-01` validates it with the rest rather than writing it — the line is written by the row that ships the function (`BUG-02`'s precedent) |

**The citation sweep it owed is done, and the three sites were where this row predicted.** *"There
is no content getter on `compy.input`"* was asserted as a supporting fact in `D-CFG-BOUNDARY`, in the
`set_text` list-branch entry in `technical_debt/input.md`'s `RETIRED` section, and in this roadmap's
`BUG-02-01` cell. The decision is **rewritten** — it now describes a whole fallback rather than half
of one — and the two register sites are **past-tensed rather than deleted**, because each was true
when its argument was made and deleting it would remove the argument's ground. A fourth site was
found in the sweep and is not prose: the new spec's own comment cited the debt slug, which the
retirement drops. It cites `doc/input_api.md`, *"Live changes"* instead — **the citation a test
comment makes must outlive the ledger entry that prompted the test**.

**The return shape was the one open question, and the answer is a string.** `set_text` accepts a
string or a list of lines and means the same by both; `on_text_entered` delivers one string,
`after_submit` delivers the `InputText`. A string was chosen on three grounds and the third decided
it: it round-trips through `set_text` losslessly, it makes the common test (`== ''`) direct, and it
hands a project **no internal object** — `after_submit`'s payload is an `InputText`, a class the
guide never names and a project has no business holding. Line structure is not lost, only spelled:
`\n` is where the lines were, and `set_text` splits it back.

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
slice is cut** (`DEC-01` did, session65 — the cut now waits on `CHG-01` alone), **CHG-01 also
gates ACC-02**, and **FIX-03 runs last** — it is the sweep that catches what FIX-02 and DEC-01 miss, and running it
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

### ✅ BUG-02 — `set_text`'s content contract (2) — **COMPLETE (session63)**

**Opened by the owner at session61's revalidation**, from a finding of the `BUG-01` sprint's cold
peer review that the sprint left undispositioned. **The row opens by weighing, not by fixing**, and
the minimal outcome — already delivered — is that the defect is written down where a developer
meets it. Whether it is *fixed* before the release is an owner call taken at this row.

| id | defect | blast radius |
|---|---|---|
| ~~**BUG-02-01**~~ ✅ | **WEIGHED, then FIXED (session63) — the ruling is the owner's and it came with the rule behind it: *"the key reason is same as for utf-8 sanitization — we need cursor to be set without ambiguity"*.** The cursor addresses content as `(line, column)`, so un-normalised content makes that address ambiguous: invalid bytes leave a column's *length* undefined, a newline inside a line leaves its *position* undefined. Both normalisations serve one requirement, which is why this is not a taste call. The fix is **one call** — `InputText(string.lines(clean))`; `string.lines` is already polymorphic over `string | string[]` and `split_array` preserves empty elements — so it neither complicates the code nor removes a capability. Four breaking tests, each seen to fail first; suite 1032 → **1036**. Commits `2986fd80` (fix), `dd19cf64` (guide + internals + CHANGELOG). **Then ratified and unified at the owner's direction** (same day): the rule is **Decision 38** — *content is normalised so the cursor address is unambiguous* (`c7c6b151`) — and `set_text` became **one path preceded by a normalisation step** rather than two branches that agree (`9c718a56`), which is the decision's structural half. A **dead cursor call** went with it: the string branch called `_update_cursor(true)` and the list branch did not, and the call was **inert in every revision it has existed in** — `472c6bba` already ended `set_text` with an unconditional `jump_end`. Mutation-tested across five cases in both spellings before deletion; `_update_cursor` itself stays, **and is itself unsound** — its only reachable caller is `clear_input`, `_set_text_line`'s call being guarded by `if not keep_cursor` which all seven of its callers defeat. Filed BACKLOG. Registered in the debt ledger rather than left in the track (`64441d69`), on the owner's standing rule. Suite 1036 → **1038**. Weighing: [`validation/notes/BUG-02-01-list-branch-weighing.md`](validation/notes/BUG-02-01-list-branch-weighing.md). **Three things the weighing established beyond the entry:** `after_submit` gets the line list itself, so the two spellings handed a project different payloads; the validator would have measured the concatenation and named the wrong line; and the rendering — filed as *"needs a display"* — was read out of the draw code instead, where **the two paths corrupt it differently** (plain draws the tail a row down over its neighbour, highlighted draws nothing and leaves a blank column). The state was also unreachable by typing, by paste and by every in-tree caller. There was **no content getter** on `compy.input` when this landed (`get_text` arrived 2026-09-03 with `FEAT-03`), so no set/get round-trip was broken — but the change *is* observable at submit, via `after_submit`'s line list, which is why it earns a CHANGELOG line (corrected 2026-09-01 by cold peer review, which caught the stronger claim contradicting this row's own evidence). *Original filing:* **weigh fixing vs postponing** the list branch's non-splitting · unslugged entry, *"`set_text`'s list branch does not split embedded newlines"* | **the weighing is narrow; the fix is not.** `UserInputModel:set_text` is the content path every activation and every live text change runs through, and `BUG-01-09` has just rewritten it — which is exactly the argument for deciding rather than reaching. Against fixing: no in-tree caller can reach it (all three pass a raw string or `string.lines(…)`, which never emits an element containing a newline), so a project must hand-build such a list. For fixing: `doc/input_api.md` documents `text` as *"a string or list of line strings"* and the two branches now disagree about what that means, which is the same **one fact stated twice** family as `FIX-02-08`/`-09` |

| ~~**BUG-02-02**~~ ✅ | **`set_text` answers a malformed content element three different ways — FIXED (session63).** Added to `BUG-02`'s scope by the owner rather than filed as a `FIX` row: *"it's our own interim defect which this feature introduced, and it does not go into release."* `{'a', 42}` silently dropped the number, `{42}` **wiped the content**, `{'a', true}` raised `bad argument #1 to 'len'` from inside the framework. The drop and the wipe were introduced by `BUG-02-01`'s own fix hours earlier; the raise is pre-existing. `checked_text` now sits beside `checked_cursor` at the project boundary and refuses all three with one message naming the call — the shape `BUG-01-08` established for `cursor`. Five breaking tests, each seen to fail first; suite 1038 → **1043**. **The rule it settles is Decision 38's boundary — normalise representation, refuse structure:** coercing `{'a', 42}` would be tolerance producing a lie, that shape being `insert_text_line(text, li)`'s arguments, so the likeliest source is a caller confusing two functions. Found by the cold peer review's open item ([`validation/outcomes/session63-BUG-02-cold-peer-review.md`](validation/outcomes/session63-BUG-02-cold-peer-review.md)) and reframed by the owner's challenge to the coercion lean | **narrow to fix, and the fix is a boundary check** — no in-tree caller passes a non-string, but the surface is public and silence on it is the worst available answer |

**Two cold peer reviews ran on this sprint, and both returned *changes needed*.** The first refuted
the claim that `_update_cursor` and `_advance_cursor` are the only raw cursor writers (`insert_text_line`
is a third, on the Shift+Enter path) and caught three overclaims in the durable documents. The second
caught that **`BUG-02-02`'s first fix did not close its own class**: `checked_text` walked the list
with `ipairs`, so `{[1]='a', [3]=42}` was accepted and dropped the number and `{foo = 42}` was
accepted and wiped the content — the same two silent symptoms, one spelling further out. Fixed at
`8451fa63` with a dense-array check; four further document claims corrected at `f179b269`, including
a withdrawn rationale and a citation (`pong/main.lua:104`) that pointed at an unrelated function of
the same name. Reports: [`validation/outcomes/session63-BUG-02-cold-peer-review.md`](validation/outcomes/session63-BUG-02-cold-peer-review.md),
[`validation/outcomes/session63-BUG-02-02-cold-peer-review.md`](validation/outcomes/session63-BUG-02-02-cold-peer-review.md).
Suite 1043 → **1048**.

**Ordering — discharged.** The constraint was: *if the weighing goes to fix, `BUG-02` finishes
before `CHG-01`*, because a behaviour change on a documented surface earns a CHANGELOG line and
`CHG-01` is the pass that validates them. It went to **fix**, and the sprint finished first — the
CHANGELOG line is written (`dd19cf64`) and is `CHG-01-01`'s to validate along with the rest. The
entry left BACKLOG for RETIRED without ever being slugged, which is the register's own rule: a slug
is earned at `ACTIVE`, and this was ruled and fixed in one session.

**Provenance, kept straight for the PR description.** **Pre-existing** — at `3256aac` the table
branch is `InputText(text)` with no split and no sanitise. What this feature did was fix the
*string* half (`BUG-01-09`) and thereby make the two halves visibly disagree; it did not introduce
the branch.

### FIX-02 — docs, vocabulary, process (26), in priority order

#### Execution order — the sprint runs in two halves, across the device passes (owner, 2026-09-02)

**The owner's reasoning, which is the whole ruling:** *"If anything arises, verbose prose could help
troubleshooting, but **incorrect prose could confuse it**. So I would lean to run the editorial
bundle first to reduce possible noise and confusion."* A document that asserts something false about
behaviour is worse during a smoke pass than no document at all — the pass sees the real behaviour and
the prose says it is a defect.

**(a) — before `REC-01`, with `CHG-01`.** Everything whose prose a pass *reads*, plus everything with
**unknown yield**, since a defect found at a desk is cheaper than one found at a sitting
(`agents/rules/roadmap.md` §3):

~~`FIX-02-03`~~ ✅ · ~~`-04`~~ ✅ · ~~`-05`~~ ✅ · ~~`-06`~~ ✅ · ~~`-13`~~ ✅ · ~~`-17`~~ ✅ · ~~`-22`~~ ✅ ·
~~`-23`~~ ✅ · ~~`-24`~~ ✅ · ~~`-25`~~ ✅,
and ~~**the `smoke_checklists.md` slice of `-09`**~~ ✅.

*(Struck rows are done, 2026-09-02 session67.)*

- ~~**`-22` is the sharpest case:**~~ **COMPLETE, 2026-09-02 (session67), with `-13`.** The sites a
  pass or a reviewer reads are corrected and **`design/` is not amended** — the owner retired the
  requirement instead of ruling on the prose, and the deviation is argued in `D-CFG-BOUNDARY` where
  it outlives `wip/77`. The row also records what re-deriving found: the inventory was **five sites
  and two claims** rather than the two-and-one this note assumed, and *"the code clears it"* meant
  `show`, not `hide`.
- ~~**`-13` runs with `-22`, by that row's own instruction**~~ — **DONE with it**, one paragraph,
  one sitting, as the instruction intended.
- ~~**`-23`** is the guard that `BUG-01-03` was~~ — **DONE, 2026-09-02.** A pass meeting that shape
  now finds the remedy named in the guide.
- ~~**`-06`** is a stale routing-lifetime claim in three places~~ — **DONE, 2026-09-02**, and it
  was four places: the third was a paragraph in a document the row had already named. ~~**`-03`** and **`-04`** are verification rows whose yield is unknown~~ — **both done,
  2026-09-02.** `-03` showed neither the code nor the doc wrong: one claim needed a clearer
  distinction, two objected to text already gone. `-04` yielded a **fourth site of the stale
  route-lifetime claim**. **`-24` is done** too, and its yield was that the diagrams were never
  live: marked historical, not corrected.
- **`-05` is here on a hard dependency, not on the criterion** — though it meets that too
  (*"unknown yield"*). `CHG-01-03` names it as its **feeder**, and `CHG-01` is in this half and
  **gates `ACC-02` and every slice cut**: leaving `-05` in (b) schedules the producer after its
  consumer. **It is the largest row in the half** — 51 retired entries, each base-checked (counted
  2026-09-02; the row still says 20). If it proves too large to precede the sitting, the fallback is
  the owner's: record on `CHG-01-03` that it ran on an unverified classification and revisit it
  after (b). Do not simply move it back.
- ~~**`-25` is in (a) although it is the sprint's only code row**~~ — **DONE, 2026-09-02.** The
  reason it was placed here was that its test could surface a key the surface accepts and the widget
  ignores. **It did not**: the two sides agree, so the sitting runs against a known. The test is in
  place, mutation-proven, and no production change was needed.
- ~~**The `-09` slice is bounded to `doc/development/smoke_checklists.md`**~~ — **DONE 2026-09-03
  (session68), 21 sites.** The estimate was *~21* and the count came out at exactly 21, which is
  luck rather than method: the raw grep returns **25**, and **four are the `Alt+H` help overlay** —
  a different piece of UI that is not the input widget and keeps its name. *The count is a sweep
  input, not a scope statement*, and this is what that sentence is for. Two idioms went with the
  nouns: *"the command field is open"* → *"the command widget is shown"*, and *"press Enter on the
  empty field"* → *"press Enter with nothing typed"*, which drops the noun rather than swapping it —
  the turtle section says *"the prompt"* throughout, and inserting *widget* into one row of it would
  have put three names in one paragraph.
  **One thing deliberately not swept:** `turtle`'s section calls the thing **"the prompt"** 21 times
  and says it *opens* and *closes* — a **fifth** name, colliding with the documented `prompt` key.
  Rewriting the owner's device script on my own reading was the wrong trade, so it went to the row
  that unifies terminology, **where it now has its own ruling and its sites** (see `FIX-02-09`'s
  note). The owner's disposition, 2026-09-03: a drift is registered as planned debt **or** described
  in the unifying step if that step has not run — it had not.

**(b) — after `ACC-02`.** The rest: `-07` · `-08` · `-09` (the remainder) · `-10` · `-14` · `-15` ·
`-16` · `-18` · `-19` · `-20` · `-27`.

- **`-09` must not precede `MERGE-01`.** Its remaining scope is `keyboard` and `maze` — the repos the
  merges land in — so sweeping first means the merge brings fresh violations in behind the sweep.
  That is the same inversion the acceptance reorder fixed this morning, and it is why the bundle is
  split rather than moved whole.
- **`-20` is here on its own LATE-row ground** (the note below), **not** on the nested-repo argument:
  *"draft"* appears once in all three example repos (`maze_main.lua:187`) and not at all in
  `keyboard`. It runs with the 08–10 vocabulary cluster because the vocabulary is still being minted.
- **`-07` opens `internals/user_input.md`, which `-03` also edits in (a)** — a second broom over one
  floor, accepted deliberately: `-07`'s blocks are editorial and `-03`'s three claims are factual,
  and only the second kind misleads a troubleshooter.

**REMARK — the crosswalk renumbering is deliberately skipped, and the roadmap's order prevails.**
`agents/rules/roadmap.md` §2 says numbering follows execution order; after this split it does not,
inside `FIX-02`. **We are not renumbering** (owner, 2026-09-02): the rows are cited from prompts,
notes, ledger entries and live goals (`T-NEVER-SHIPPED`, and `T-RETIRED-UNVER` until session68 paid it; `T-KEYSET-SPLIT`,
`T-GUARD-LIVE` and `T-MERMAID-MODEL` were among them until session67 retired all three,
2026-09-02), and a renumber this
close to the PR buys ordering cosmetics at the price of the failure §5 names — a citation that
still resolves, to the wrong row. **(a)/(b) are passes, not ids**;
no row id changes, and **this section is the order of record** where the numbers disagree with it.
Revisit only if the sprint outlives the PR.

*(was 20, then 19 — the old `05` and `14` merged into `06`, being one defect in three places — and
back to 20 with `FIX-02-20`, and 21 with `FIX-02-21`, both registered 2026-08-26; **24 with
`FIX-02-24`**, registered 2026-08-30; **25 with `FIX-02-25`**, registered 2026-08-31; **26 with `FIX-02-26`**, registered 2026-09-01.)*

| id | defect | blast radius |
|---|---|---|
| **FIX-02-01** ✅ | **`on_text_entered` and `after_submit` are two ways to set one callback** | **ANSWERED 2026-08-30 by Decision 37, ruled jointly with `FEAT-01-03` as this row required.** They are not two ways to set one callback: they are told apart by their payload, and each acquires a reason to exist a reader can state in one sentence. The *documentation* half — saying which to choose, and that the convention is not enforced — is **`FEAT-01-06`**, so this row closes against a decision plus a scheduled write-up, not against a decision alone. *Original filing:* **design escalation, public surface.** The cold review missed it; the owner raised it twice. Bears on the strategic frame's "no moving parts beyond the ask". **Do not work this row without `FEAT-01-03`**: the owner has since proposed keeping both hooks and differentiating their payloads (`T-PLAINTEXT-ENTERED`), which is a candidate answer to exactly this question — and `FEAT-01` runs ahead of this sprint, so the answer should be in hand by the time this row opens |
| ~~**FIX-02-02**~~ ✅ | **RATIFIED (Session 56) — `legend = ""` on submit is the example's own code in `src/examples/tixy/main.lua:submit_body` (submitting custom formula retires canned caption; see `validation/notes/S24-W7-A4-A5-invisible-overlay.md`). No framework defect.** `tixy` may drop the legend on submit | **RATIFIED** — verified by `S24-W7-A5` investigation note |
| ~~**FIX-02-03**~~ ✅ | **COMPLETE (session67) — one claim was real, two were already fixed, and the code was right throughout.** All three cited line numbers had drifted, so the claims were recovered from the filing. **Claim 1 refuted with a mechanism:** projects genuinely cannot install evaluator objects — no `evaluator` key on a closed config table, `set_eval` absent from the surface, and `consoleController` **withholds** the four evaluator globals from `project_env`. But the remark was a fair reading of prose that never drew the line between a *function* a project supplies and the *evaluator object* it does not, so the doc now draws it. **Claims 2 and 3 object to text that no longer exists** — the only surviving occurrences were inside the remarks quoting it — and the prose now says `before_cancel` is honoured the same way `before_submit` is, which the code confirms. Remark count in the A-doc 11 → 8; `FIX-02-07` should not hunt for these three. **A false finding caught before filing:** the LSP reported zero references for `UserInputController:set_eval`, which reads as dead code; grep disagreed — `editorController` calls it three times. *Original filing:* the A-doc's three factual claims (`:79`, `:650`, `:675`) | **may reveal the code is wrong, not the doc** |
| ~~**FIX-02-04**~~ ✅ | **COMPLETE (session67) — and the unknown yield was real.** One of the three pointers carried **the stale route-lifetime claim `FIX-02-06` removed this morning**, in a fourth place: *"the route connects only while the project is actively running"*. Found by a row filed for something else, after a sweep that believed it had them all — the claim spreads by being restated in passing. The same line also cited the wrong decision (`D-ROUTE-LIFETIME` for the `before_exit` contract, which is `D-STOP-IS-FW`, correctly cited in this document's own body two paragraphs above). Completeness: three pointers where the document earns six — nothing led from the T1 tier to the dispatch layer that makes it true, nor to the registered T3 leak the body names in prose. Every target resolved before writing. **Out of scope, recorded not fixed:** the body's `consoleController.lua` line citations have drifted (three of four spot-checked), which is the class already held in `technical_debt/general.md`. *Original filing:* pointer annotations in `project_sandbox_env.md` — completeness never checked | **unknown yield** — a verification task |
| ~~**FIX-02-05**~~ ✅ | **COMPLETE (session68) — 56 entries walked, no resolution claim failed, and the yield was a classification rather than a repair.** **Corrected by the peer review, and the correction is the row's own warning arriving:** the walked set was **56** (50 + 6), the snapshot when the pass began — but the section held **59 when this cell first claimed *"56 entries"*** and **61 now. Three entries were retired while the walk ran and two more since, every one of them by this session**, so *"every retired entry"* was an overstatement the moment it was written. The five are listed with their resolutions in the debt goal's own entry; all five are `INTRODUCED-IN-BRANCH` and not close to it (their subjects are `CHANGELOG.md`, `doc/input_api.md`, this register and `auto_hide` — the first three do not exist at `3256aac`). **The transferable half: a verification pass whose subject grows while it runs must claim the snapshot it walked, not the section — and the entries that outrun it are usually its own author's.** The set was re-counted the day the row opened; every earlier figure — 20, 46, 47, 51, 55 — was right when written, and this row grew by one *while it was open* when `T-CONTENT-READ` retired into it. **Two questions per entry in one pass** (does the resolution hold at HEAD; did the subject exist at `3256aac`), each answered with the command behind it: [`validation/outcomes/S68-FIX-02-05-base-evidence.md`](validation/outcomes/S68-FIX-02-05-base-evidence.md), commission in `validation/prompts/`. **Verdict: 39 introduced-in-branch · 9 pre-existing · 5 mixed · 3 cannot-tell.** The lopsidedness is structural, not padding: the *subject* of most entries (`compy.input`, `doc/input_api.md`, the combo grammar, the decisions ledger, the `wip/` tree) is itself absent at base — `compy.input` returns **zero** hits at `3256aac` — so the defect could not have been met from outside. **Mechanical half delegated to a Sonnet worker at the owner's instruction; the classification and the spot-checks are the parent's.** Nine were re-verified at base by hand, the pre-existing set being the consequential direction — a false *pre-existing* invents a changelog line for something nobody met, a false *introduced* deletes the evidence of a real fix — and all nine held. **The three cannot-tells are structural:** `maze`/`balloons` are untracked sibling repos with no comparable base commit, so their provenance is unanswerable by this method and they **stay in the register** — the rule vacuums what is known to be ours, not what is merely unproven. **Twelve resolution claims rest on something not re-derived** (a suite run, a mutation example, a call graph deeper than a grep), each named in the evidence document rather than counted as verified. **One numeric drift found and corrected**: `F.reset()`'s entry claimed nine code lines, and it is eleven — still under the 14-line limit, so the claim held and the figure did not. **Yield for `CHG-01-03`: exactly one new CHANGELOG line** — see that row. *Original filing:* the debt ledger's 20 resolved entries · **`T-RETIRED-UNVER`** | **unknown yield** — each tested against base; may find more rot. **NOT absorbed by `LEDGER-01-03`**, which sorted them into `RETIRED` on their headings without testing one of them against the base. The sort is done; **the verification this row exists for is untouched**, and it now has a section to walk rather than a scattered set |
| ~~**FIX-02-06**~~ ✅ | **COMPLETE (session67) — four sites, not three, and the unnamed third was a paragraph in a document already named.** The row left *"the second doc"* unidentified; sweeping by sense found the survivor **inside `event_dispatch_layers.md` itself**, forty lines below the bullets, asserting the asymmetry again and sourcing it to a debt entry RESOLVED 2026-08-03. Fixing the bullets alone would have left the claim standing and cited. Also repaired: `occupy_keyboard` and `hook_pointer` are cited by name across the persistent corpus and **neither exists** (`occupy_input`, `mark_pointer_liveness` — the second installs nothing now). `internals/user_input.md` was **already correct on substance** and is the document the other two contradicted; only its two stale names moved. **Verified in code first** — `project_handlers` seeds off `_bindable` (keyboard + pointer + derived), and `release_keyboard_route`'s only call site is the crash path. **The completeness claim was not met, and a delivery-level review caught it** (2026-09-02): three **present-tense** sites survived in `technical_debt/input.md` — the one persistent document of the three this sweep did not open — asserting `hook_pointer` and `chain_project_handler` as current. Repaired 2026-09-03 with the line citations that had drifted with them, and the lesson is the row's own predicted failure mode arriving one file over: **a sweep's scope is every document that could carry the claim, and the register is a document.** **Two findings registered rather than fixed here:** the function's *name* (`technical_debt/input.md`, BACKLOG — renaming needs a call on merging it with `clear_user_handlers`, which is design, not docs), and this doc's systematic line-citation drift, which **the ledger already held** (`technical_debt/general.md`) and gained a worked instance instead of a duplicate entry. The `> REMARK:` that triggered the row is answered and removed, so `FIX-02-07` should not hunt for it. *Original filing:* the stale keyboard/pointer divergence claim | **one defect in three places** — `release_keyboard_route`'s comment, `event_dispatch_layers.md:112`, and the second doc. **Fix as one**; any survivor re-seeds the others |
| **FIX-02-07** | execute the remaining remark dispositions — **was 37; re-count when the row opens** | triage **complete**; breadth known. Five dispositions were executed early at `FIX-02-03`/`-04`/`-06` (2026-09-02), each because the marker's defect was solved in the same pass (`DEC-02-04`'s rule), and those three cells say so. Markers standing at HEAD: **34 across 12 files** when this cell was written, **32** after `CHG-01-04` executed two more the same day (`internals/user_input.md`'s and `project_sandbox_env.md`'s requests for a concrete version reference, both answered by the version ruling, and the CHANGELOG's own marker went with them), and — **restated 2026-09-03 after the delivery review found the series did not close** — **two counts, both stated, because the difference is real and small**. Anchored (`git grep -c '^> REMARK' -- doc/ ':!doc/development/wip/'`): **29 at session69's boot → 22 now**. Raw (drop the anchor): **31 → 24**; the extra two are **prose *about* markers**, in `T-ARGUES-INTERIM` and the changelog-version entry, and they are not dispositions. **Both series fall by exactly 7**, which is the attribution: `FIX-01-01` retired five (R091/R092, R150 and R164 *were* the markers on the paragraphs it rewrote) and `FIX-01-02`'s `FR-n` translation retired two. The cell previously narrated 29→24 with a five-marker attribution — an anchored start against a raw end, which is why it read as three unexplained markers. **There is no marker gate over `doc/`:** `agents/rules/commenting.md`'s is unanchored *and* scoped to `src/`/`tests/`, as the row above says — so a `doc/` count is only meaningful with its command attached. **The count only ever falls by side effect**, which is the row's real shape: a marker is retired by the pass that fixes what it points at, and this row is the remainder. Markers are not one-to-one with dispositions, so this sizes the row rather than restating its count. **Do not cite either figure — re-run the command when the row opens**; every count that has gone wrong in this phase has been a roadmap cell quoted after its subject moved |
| **FIX-02-08** | "tier" / "chain" / "the walk" — three names, one thing | known breadth, 3 slices |
| **FIX-02-09** | "overlay" / "widget" / "area" / "field" — four names, **and "prompt" is a fifth, unruled** | known breadth; `src` half done in S45, docs half open. **The examples were not in that sweep** — found 2026-08-30. `turtle` was fixed on the spot while it was being edited anyway; what remains is the **nested repos**, `keyboard` (six files) and `maze` (`maze_render.lua`), which open their own PRs and are swept there. **Scope clarified by the owner, 2026-08-31 — see the note below** |
| **FIX-02-10** | "combinator" — concept earned, word not | narrow |
| ~~**FIX-02-11**~~ ✅ | **RESOLVED — `doc/input_api.md:69,321,333` already states the widget always consumes when shown and explains tier 3 placement. Symptom (`BUG-01-03`) fixed in `turtle/main.lua`.** the guide never says a shown widget **always consumes** (keyboard) | **RESOLVED** — documented in `doc/input_api.md` |
| ~~**FIX-02-12**~~ ✅ | **ANSWERED by `ARC-02-08` (`e4748e60`) — `false` documented as the uniform unset in `doc/input_api.md`, with the `computed or false` idiom. Ratified rather than built: every consumer already tested truthiness.**  the guide never says callbacks cannot be un-set | narrow — depends on BUG-01-02's ruling. **Write with `FIX-02-21`**: both are answered by the same paragraph — the ownership rule (*content resets; everything the project sets persists until replaced*) plus the sentence saying what "replaced" cannot mean. Not a duplicate of it; the same edit |
| ~~**FIX-02-13**~~ ✅ | **EXECUTED (session67, `86f73731`)** — `doc/input_api.md` gains a `### hide()` subsection between `show(config)` and "Live changes". It answers FR-2 where a project author reads: **there is no teardown call**, which is not something a reader can conclude from failing to find one. **"Singleton" is the row's word and the guide does not use it** — `D-WIDGET-AT-BOOT` was amended 2026-08-27 and the project's widget is the **run's**, not the application's, so the guide says one instance *for the run* and that nothing carries across runs. `hide()` vs teardown — the singleton is never stated | narrow — **written with `FIX-02-22`**, same paragraph of the same doc, exactly as this cell required: what survives a hide is stated **once**, in the paragraph that describes hiding, rather than in two documents that can drift apart |
| **FIX-02-14** | the channel list exists twice | narrow |
| **FIX-02-15** | `technical_debt/general.md` carries an entry that is not debt · **`T-GFX-GLOBAL`** | narrow |
| **FIX-02-16** | a `pending()` routing case deferred in the hardest-read area | narrow |
| ~~**FIX-02-17**~~ ✅ | **COMPLETE (session68) — the section was already there and the row's verification still yielded.** `LEDGER-01-01` wrote the `Removed` section on 2026-08-27 and it leads `CURRENT_SCOPE`, naming the five globals and `compy.singleclick`/`doubleclick`; nobody had since checked the list **against the diff**. Doing so found a **sixth** removal: `project_env.astv_input`, debug-only (`if love.debug`) at the base and deleted by `M8-03`'s pinned ruling. `doc/development/tests.md` and `internals/user_input.md` both already name it among the retired globals, so the CHANGELOG was the one document of the three that did not — now one clause, stating it was only ever present in a debug build. **Method, and it is the reusable part — with the blind spot found the same day:** the check is a set difference, not a grep — `project_env.*` assignments at `3256aac` against HEAD, which finds a removal nobody thought to search for. **The figure this cell first carried — *23 keys → 17* — was wrong, and how it was wrong matters more than the number** (peer review, 2026-09-03): the grep was `project_env\.[a-z_]+`, **lowercase-only**, so it read 23 at base correctly (nothing capitalized existed there) and **17 of HEAD's 20**. The true shape is **23 → 20**: six removed, **three added** — `LuaHighlighter`, `LuaSyntaxValidator`, `LineValidators`, the exact keys a case-sensitive character class hid. The `compy` namespace itself lost nothing (`audio`/`fonts`/`graphics`/`terminal` all survive). **One candidate omission was checked and correctly stays out:** `compy.text_input` existed at base as `compy_namespace.text_input = input_text`, and `input_text` is not in scope there — it assigned **`nil`** and never functioned (`design/context.md`, NFR-3), so its removal is not a behaviour anyone could notice. **The difference missed a fifth removal, and there are two reasons, one structural and one mine:** four evaluator objects (`InputEvalText`, `InputEvalLua`, `ValidatedTextEval`, `LuaEditorEval`) were reachable at base through the environment clone and are **withheld** now by `project_env[name] = nil` — *the unmaking of a name is not an assignment of one*, so it appears on neither side of the difference. Found 2026-09-03 by **printing the project environment in a scratch spec** when the owner asked whether `eval`/`result` were really exported. **A set difference finds what is absent; it does not find what is actively removed** — that is the structural half, and it stands. **The proximate half is worse and was found by the peer review:** the same lowercase-only regex hid the three *additions* (`LuaHighlighter`, `LuaSyntaxValidator`, `LineValidators`), and **those additions are the evaluator replacements** — three new evaluator-shaped exports appearing in the difference would have raised *"replacing what?"*, which is the question that leads straight to the withheld four. **The method did not fail; a character class dropped a third of its input silently.** Registered and paid in `technical_debt/input.md`. **A count disagreement was found and is not this row's to fix:** `T-VERSION-NUM` says the work removed *four* public globals, the CHANGELOG named five and `tests.md` names six — the true figure is five public plus one debug-only. Registered for `CHG-01-04`, which owns that entry. *Original filing:* **CHANGELOG omits the breaking change** | narrow — **feeds CHG-01** |
| **FIX-02-18** | `pong/README.md` — 316-line diff, 2-line change | narrow |
| **FIX-02-19** | provenance front matter, 3 files | narrow |
| **FIX-02-20** | **"draft" — unratified vocabulary, and the widest-spread of them** | **runs with the 08–10 cluster, not last** — see the note below |
| ~~**FIX-02-21**~~ ✅ | **EXECUTED by `ARC-02-05` + `ARC-02-08` — the misleading `PER_SHOW_KEYS` membership is gone with the list itself, and `prompt` is documented as persisting until replaced. The balloons rationale is in `internals/user_input.md` so it outlives `wip/77`.**  **`prompt` is classified per-show but behaves sticky** — ~~which is right is undecided~~ **RULED: the behaviour is right, the classification is wrong** | **no longer escalates** — stays a FIX. Owner ruled 2026-08-27 (below); the work is a comment, a list membership and two doc sentences |
| ~~**FIX-02-23**~~ ✅ | **COMPLETE (session67).** `doc/input_api.md`'s `is_shown` paragraph now carries the consequence, the remedy and the distinction between the two guards: blanket on the handler, narrow on the key that opens the widget. The reassurance is **pointed at** rather than restated, as the 2026-08-30 scope correction asked. **A mechanism error was caught in the drafting**: the first draft said the platform's combos survive a blanket guard because they never reach the project's handler — it is the reverse, a reservation *acts and passes the key on* and never consumes, so what survives the guard is the platform's action, not the project's binding. `ctrl+escape` is the example used, being the one reservation marked *"always"* rather than development-only. Debt entry RETIRED as *"The guide never says a project's own keys stay live while the widget is shown"*. *Original filing:* **the guide never says a project's own keys stay live while the widget is shown**, nor names the whole-handler guard as the remedy · **`T-GUARD-LIVE`** | narrow — *a few lines at the `is_shown` paragraph of `doc/input_api.md`*, the paragraph a project author reads before mixing native handlers with a prompt. Earned by `BUG-01-03`: the guide documents the tier mechanism and the trigger-key case, and a reader of it alone still would not know to write the guard that fixes `turtle` — which the suite already pins as the idiom (`input_widget_control_spec.lua`). **Scope corrected 2026-08-30:** the row first also claimed the reservation exemption was undocumented; *"Combos the framework keeps"* documents it, `ctrl+pause` included, so these lines **point at that section** rather than restating it |
| ~~**FIX-02-24**~~ ✅ | **COMPLETE (session67) — the diagrams are marked historical, not corrected, and this cell's premise did not survive the check.** Owner's call: *"if it's not the live doc and never was, maybe we should not update it, just mark (historical)?"* **It never was.** All seven files under `doc/mermaid/` are `aldum`'s — four added 2024-07-29 and three (`eval.md`, `input.md`, `scratch.md`) on 2024-12-18 as *"unfinished docs"* — last meaningfully updated 2025-01-13 — and `InputModel`, which carries `oneshot` in two of them, **did not exist at the PR base either**, along with seven more classes still drawn there. So this cell's *"the model lost that constructor argument in this feature"* holds only for `UserInputModel`. **Of 32 class blocks, exactly one line was ours** — `editor.md`'s `oneshot` on `UserInputModel` — and it is deleted, because a historical marker excuses inherited drift and not drift you caused. `custom_label`, `evaluator: EvalBase` and the `wrapped_error`/`error` conflation were each base-checked and are identical there. `doc/mermaid/README.md` carries the reasoning; each file has a banner. **Audited by a Sonnet worker**, 32 blocks member-by-member ([`validation/outcomes/S67-mermaid-audit.md`](validation/outcomes/S67-mermaid-audit.md), commission in `validation/prompts/`), which also found three source `@field` annotations disagreeing with their own constructors — pre-existing, now in `technical_debt/general.md`. **`ACTIVE` in `technical_debt/input.md` is now empty.** *Original filing:* **the mermaid class diagrams show a model field the feature deleted** · **`T-MERMAID-MODEL`** | narrow to fix, **unknown to verify** — `doc/mermaid/{input,editor,classes}.md` all list `oneshot: boolean` on `InputModel`/`UserInputModel`. The model lost that constructor argument in this feature ([`validation/notes/oneshot-at-the-pr-base.md`](validation/notes/oneshot-at-the-pr-base.md)), and the `auto_hide` key that restored the *capability* lives on the **controller**, so the diagrams show a field on the wrong class rather than an old name. `custom_label` is missing from the same blocks. Nobody has walked them since the input work, so the row is *verify all three against the current classes*, not *delete one line*. **A diagram is read before the code and carries no hedge**, which is why it outranks its size. Found 2026-08-30 during `FEAT-02`'s rename sweep; **numbered out of execution order** for the reason `FIX-02-20` records |
| ~~**FIX-02-25**~~ ✅ | **COMPLETE (session67) — the test exists and no production defect was behind it.** `tests/input/input_config_key_agreement_spec.lua` **reads the real accepted set out of the surface** rather than restating it (`show` → `api_show` → `SHOW_KEYS`, and the `configure` equivalent, by upvalue and by name) and requires every member to carry a proof that the key reaches the widget. A third hand-written list was rejected for the reason the entry exists: it cannot fail on a key it does not know about. **Mutation-tested both ways** — `'ghost'` added to `WIDGET_KEYS` fails both cases naming the key; renaming `SHOW_KEYS` fails with *"upvalue SHOW_KEYS is gone; fix this reader"* rather than silently checking an empty set. **The sides agree today** (`CALLBACK_KEYS` and `CONFIG_CALLBACKS` hold the same four strings), so nothing was fixed and nothing is claimed to be; what changed is that the next divergence cannot be silent. Suite 1048 → **1050**. The debt entry is RETIRED as *"The set of accepted config keys has no single home"* — slug dropped per the register's convention, and its citations were swept with it. *Original filing:* **the set of config keys the surface accepts has no single home, and disagreeing with the widget fails silently** · **`T-KEYSET-SPLIT`** | **narrow to fix, and the fix is a test** — `consoleController.lua` decides what `show`/`configure` accept, `userInputController.lua` decides what they apply, and nothing reconciles them: a key on the accept side alone is taken by the surface and ignored by the widget, with no raise. **Scoped deliberately as *pin the agreement*, not *unify the lists*** — unifying crosses the surface/widget boundary the architecture keeps separate, which is a larger change than the defect and reads worse on review than the duplication does. No such test exists today; every key is covered individually and nothing asserts the set is closed. **Promoted from BACKLOG to ACTIVE 2026-08-31 (owner):** it is a code-quality defect and a drift source, so it is fixed before release, but it is **not functional and does not block it**. Found at session59's `FEAT-02` revalidation — `FEAT-02` had to add `auto_hide` to each side and the old entry's *"revisit when either list changes"* trigger did not fire. **Numbered out of execution order** for the reason `FIX-02-20` records |
| ~~**FIX-02-26**~~ | ~~lift the deviation justifications out of the PR description~~ · **WITHDRAWN 2026-09-01, premise refuted** | **Recorded, not deleted** (`agents/rules/roadmap.md` §5). The row claimed the decisions argue why today's shape is right and never say what it replaced. **They do say it** — `D-ROUTE-LIFETIME` marks itself SUPERSEDED IN PART and quotes the superseded claim, `D-NO-LOG-NOISE` names the design's proposed debug log and declines it, `D-HOOKS-SEEDED` argues the seed against a precedence rule — so the PR table summarises the ledger rather than uniquely holding anything. **And the direction was backwards** (owner): *"we do not make archaeology"* — the corpus needs less reversal narration, not more. Its inverse is **`DEC-02`**. Retirement note: `technical_debt/input.md`, RETIRED |
| **FIX-02-27** | **two shipped example READMEs still teach the removed polling idiom** · **`T-EXAMPLE-README`** | narrow in files, **not narrow in work** — `src/examples/repl/README.md` and `src/examples/valid/README.md`, five sites, but `repl`'s is a tutorial whose narrative *is* the poll loop (create a handle, test it for emptiness, read the value) and the replacement has no handle and no polling, so each needs a rewrite rather than a substitution. **Both projects' `main.lua` are already onboarded**, so each ships working code beside a document that contradicts it: a reader following the README calls a `nil`. **Not blocked by the merges** — unlike `-09`'s remainder these two are tracked in the platform repo, so this row can run whenever (b) does. **Registered `BACKLOG` and promoted to `ACTIVE` the same day** (owner, 2026-09-03: *"document README drifts as active defects to be fixed"*). Found 2026-09-03 while base-checking `FIX-02-17`, by nothing more than the retired names still having hits at HEAD | 
| ~~**FIX-02-22**~~ ✅ | **COMPLETE (session67) — and the owner retired the requirement rather than ruling on the prose.** Asked whether `design/` should be amended, the owner asked the better question: was the rule ever any good? *"Neither of existing known scenarios relies on hiding and restoring widget with exactly same text/cursor… adding support of not-yet-needed and fairly exotic case as first-class scenario would complicate the API… the requirement as originally written is likely useless and batch-approved."* So **`design/` is not amended**, `design/spec/M2.md` is out of scope as a historical spec subslice, and the deviation is **argued in the persistent ledger** where it outlives `wip/77` — `D-CFG-BOUNDARY`, *"Third, content is not preserved across `hide` → `show` either"*. The premise was checked in code and holds: the only two `hide()` call sites (`maze_main.lua:126`, `draw_main.lua:233`) both abandon the prompt for a menu and **want** the clearing. **One gap is named rather than hidden** — `get_cursor()` exists but there is **no content getter**, so the do-it-yourself fallback covers the cursor and not the text; if the case ever arrives the repair is a read-only getter, not a return to preservation — now **registered** as *"PROPOSAL: a read-only content getter"* in `technical_debt/input.md`, BACKLOG and unslugged, after turning out to have been cited as background in three other entries and never filed as one. **That filing was superseded 2026-09-03** (owner, on the delivery revalidation's F1): the entry became `ACTIVE` as **`T-CONTENT-READ`** and **`FEAT-03`** paid it the same day, so this row's *"if the case ever arrives"* is settled — the case arrived from the guide, not from a project, and `compy.input.get_text()` exists. Commits `f3a41997` (decisions), `86f73731` (guide, with `-13`), plus the retirement rationale. **Earlier disposition, superseded:** `decisions/input.md` is corrected and `doc/input_api.md` now states the rule with `FIX-02-13`. **Three corrections to this cell, all found by re-deriving rather than by reading it.** (1) **The persistent corpus had two sites, not one** — `:76`, the problem statement, is where `:194` quotes *"state intact"* from, so fixing `:194` alone would have re-seeded it; fixed as one, `FIX-02-06`'s rule. (2) **The frozen tree has five sites carrying two claims, not two sites carrying one** — `design/spec/M2.md:33` is unnamed here, and the *forced*-`show` variant of the same sentence sits at `spec.md:149`, `version01.md:179-180` and `:534-535`, already reversed on purpose by `D-CFG-BOUNDARY` statement 4. (3) ***"The code clears it"* is true of `show`, not of `hide`** — `hide()` preserves content and the suite pins it (*"a typed character while hidden does not mutate it"*); the round trip loses it (*"a fresh activation with no text is empty"*). A correction that negated the old sentence would have been wrong in the other direction. **Recommendation: do NOT amend `design/`** — it is the record of what was ratified, `D-CFG-BOUNDARY` already quotes the round-2 wording verbatim to say what it reverses, and rewriting the spec would leave that decision citing a sentence that exists nowhere. Inventory, reasoning and the cheaper fallback: [`validation/notes/FIX-02-22-frozen-design-sites.md`](validation/notes/FIX-02-22-frozen-design-sites.md). *Original filing:* **three documents say a hidden widget keeps its content; the code clears it** | narrow, but **one site is in the persistent corpus** and outlives `wip/77`. `design/spec.md:155` (*"Content preserved for the next `show()` without `text`"*, contradicting its own §3 five lines up), the round-2 reviewed text `spec.versions/version01.md:191-194`, and **`decisions/input.md` Decision 3** (*"hide and bring back with state intact"*, amended last session). Code clears (`open_widget`), the suite pins it, and **turtle depends on it in a comment** (`main.lua`, the `after_submit` block — line numbers moved 2026-08-30 when the example took `auto_hide`). **Disposition: fix the documents** — the owner ruled the behaviour 2026-08-27, and the stakeholder requirement (FR-3/FR-4, the sapper complaint) is about not tearing the widget down, which still holds. Decision 3 needs one qualifier: state survives *except the draft text*. Found 2026-08-27, ARC-01-07 follow-up |

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
`doc/input_api.md` alone still carries **13** "field"s, every one of them the widget sense (re-counted 2026-08-31; the note first said eight).

**And "docs" means the whole persistent corpus, not the guide (found 2026-09-01, session64).** Sizing
this row by `doc/input_api.md` understates it: the widget sense is also live in `CHANGELOG.md`,
`doc/development/smoke_checklists.md`, `internals/user_input.md` and `decisions/input.md` — and
`smoke_checklists.md:215` carries **the banned idiom verbatim**, *"the command field is open"*. None
of it is another author's to leave alone: at `wip77/20260826/mergebase` there is **no `CHANGELOG.md`
and no `doc/development/smoke_checklists.md`**, and `doc/development/` holds five entries in total —
the corpus this row sweeps is `#77`'s own creation, in full. Size the row against the rule
(*everything under `doc/` not under `wip/`, plus `CHANGELOG.md`*), never against a file list; the
list is what went stale here, exactly as it did in `agents/validation.md`. **The count is a sweep
input, not a scope statement** — a raw `field` grep also catches `@field` annotations and ordinary
table fields, so re-derive by sense, not by number. Session63 **added** one on 2026-09-01
(`CHANGELOG.md:164`), the day the rule was in force, which is this row's own argument for running
late restated as evidence.

**"Prompt" is the fifth name, and it is this row's to rule** (registered 2026-09-03, owner: *"either
registered as active debt and planned, or described in the step which unifies terminology if it was
not yet executed"* — this row is unexecuted, so it lands here rather than as a second ledger entry
for one goal). **The corpus says *"the prompt opens"*, *"the prompt closes"*, *"while the prompt is
up"* for the widget** — 21 occurrences in `smoke_checklists.md`'s turtle section alone, plus
`internals/examples/turtle.md` and `decisions/input.md`, so it is not one example's habit.

**Three things make this harder than the other four, and all three must be in the executor's hands:**

- **It collides with a documented key.** `prompt` is a `show`/`configure` key meaning **the label**
  (`doc/input_api.md`, *"Label shown next to the field"*). A reader meeting *"the prompt closes"*
  cannot tell whether the label or the widget is meant, which is exactly the failure the other four
  names cause — but here one of the two senses is **API** and cannot be renamed away.
- **Never sweep it by count.** *"Prompt"* appears **113 times** in the persistent corpus and the
  large majority are legitimate: the config key, the console's own prompt line, and the ordinary
  English verb. **The defect is the idiom, not the noun** — *the prompt opens / closes / is up*
  said of the widget. Re-derive by sense, as the `smoke_checklists.md` slice did.
- **The ergonomic argument for keeping it does not survive contact** (owner correction,
  2026-09-03). This bullet first said *"a one-shot prompt"* reads well where *"a one-shot widget"*
  does not — but **the behaviour is not one-shot**: `auto_hide` is a standing mode that closes on
  every submit, which is exactly why `FEAT-02` retired `oneshot` (`decisions/input.md`,
  `D-AUTO-HIDE`: *"`oneshot` names a single occurrence while this is a standing mode"*). The phrase
  is **"an auto-hiding widget"**, and it reads fine. That does not decide the ruling; it removes the
  one thing that made it look close. **Either way it is one ruling, made once** — if *keep*, say so
  in `doc/input_api.md`'s vocabulary section and define which sense is which; if *go*, the
  replacement is *the widget is shown / hidden*.
  *(The correction is worth more than the bullet: I argued for a name using vocabulary this feature
  had already retired, inside the cell whose whole subject is retired vocabulary.)*

**`internals/examples/turtle.md` was found *factually* stale while this note was being written, and
that half is fixed** (2026-09-03): it documented the **pre-`auto_hide`** turtle throughout — the
summary line, the code sample (`after_submit = function() compy.input.hide() end`, and a `show` with
no `auto_hide`), the re-arm paragraph and the points-of-attention bullet. `FEAT-02` migrated the
example and not its document. Corrected against `main.lua`; **its vocabulary sweep is still this
row's**, only the false mechanism was taken.

**`internals/examples/turtle.md` also carries live `field` uses** (*"piled up in the field"*, *"the
field it just opened"*) — inside this row's original four names, and untouched, because the
2026-09-03 slice was bounded to `smoke_checklists.md`. Corpus-wide the four names stand at **83**
`field` occurrences outside `@field` annotations, across `doc/` and `CHANGELOG.md`, counted
2026-09-03. **Size the row against the rule, not this number.**

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

### ✅ FIX-01 — pre-existing citation hygiene (3) — **COMPLETE (session69)**

| id | defect | blast radius |
|---|---|---|
| ~~**FIX-01-01**~~ ✅ | P11's deferred editorial list — **named as a count, never enumerated** | **COMPLETE 2026-09-03 (session69).** Derived: eight W10-batch-3 ids, **three live sites** — four were already paid (R085, R143, R162, and R100's list) and R100's residue is `DEC-02`'s. All three landed: `ddcdd936` (R091+R092), `cd420088` (R150), `5dd9e455` (R164). Enumeration: [`validation/notes/FIX-01-01-enumeration.md`](validation/notes/FIX-01-01-enumeration.md) |
| ~~**FIX-01-02**~~ ✅ | ephemeral citations in the persistent corpus — `wip/` paths, **plus the `FR-1`/`FR-6` namespace** found by the remark triage | **COMPLETE 2026-09-03 (session69).** Re-derived at **20 paths + 7 `FR-n`**, not ~12 — the old count was a `wip/` grep and **eight of the twenty are written relative** (`validation/outcomes/…`, `ROADMAP.md`, `plan.md`), so they never contained the string. **14 paths swept** (`ab8c2415`) and **the 7 `FR-n` spelled out** rather than dropped (`6c96c96f`), which retired two markers with them. **Six handed to `LEDGER-02`** — entries whose *subject* is a wip file, so there is no canonical target; see that section. **Sprint-id citations excluded by owner ruling** the same day → `T-EPHEMERAL-IDS`, swept at `DOC-01-06`. Derivation: [`validation/notes/FIX-01-02-03-rederivation.md`](validation/notes/FIX-01-02-03-rederivation.md) |
| ~~**FIX-01-03**~~ ✅ | session numbers in the persistent corpus | **COMPLETE 2026-09-03 (session69), `5d8ae109`.** 12 sites, not 4 — sessions keep writing their own number into the ledgers they amend, and session69 wrote one of them the same morning. Eleven were subtraction (every site already carried a date); two needed a phrase and one kept its commit id. The deriving grep now returns nothing. Same note |

*(Old `01`→**02**, `02`→**03**, `03`→**01**.)*

### ✅ CHG-01 — CHANGELOG validation and update (4 steps) — **COMPLETE (session68); the gate on `ACC-02` and the slice cut is discharged**

**All four steps done 2026-09-03.** `-02` had been complete since 2026-08-27 and `-01`/`-03`/`-04`
landed this session, in that dependency order: `FIX-02-17` verified the `Removed` list against the
diff and found the sixth global, `FIX-02-05` produced the pre-existing classification `-03` consumes,
and the owner ruled the version question `-04` carries. **Two defects came out of validating rather
than writing** — a bullet asserting the payload shape `FEAT-01-04` had already changed, and a bullet
describing the branch's own interim behaviour as what a user had — and both were found by reading
claims against the tree rather than by reading the file for sense.

**A third was found *after* the tick, and the sprint's honest limit is worth stating.** Answering an
owner question the same evening, a scratch spec printed the project environment and turned up a
**fifth removal** — four evaluator objects reachable at base and withheld now — which neither
`-01`'s claim-by-claim read nor `FIX-02-17`'s set difference could see, because the removal is
written as `project_env[name] = nil` rather than as an absent assignment. The bullet is written and
the entry is in the register. **The row stays ✅ — its four steps ran and their work landed — but
"validated against the diff" means validated by the methods used**, and a third method found a third
thing within hours. `ACC-03`'s cold read is the backstop, and this is the concrete argument for
keeping it late.

**What still touches this file after this sprint**, so nobody reads ✅ as *frozen*: `LEDGER-02-04`
runs the vacuum test over it, `FIX-02` (b) sweeps its vocabulary (*"an active overlay"* is gone but
the sweep is corpus-wide), `ACC-03` reads it cold, `PR-01` ships it in slice `3a` — and **every
further code change owes its own line**, as three did today.

**Owner, 2026-08-26: runs before ACC-02 and before any PR reassembly.** The CHANGELOG ships in slice
`3a` and is the first thing a stakeholder scans for what breaks; sending a cold reviewer or a smoke
sitting at a tree whose CHANGELOG is wrong wastes the pass.

**Its state today:** 22 lines, **the entire file added by this feature**, one `### Changed` section —
with retired vocabulary in its own prose (*"an active **overlay**"*), no `Removed` section, and a
`> REMARK:` **above its own H1**.

| id | step |
|---|---|
| CHG-01-01 ✅ | **validate what is there against the actual diff** — the claims-vs-reality check that caught the PR description. **Three sections validated (session68), one blocked.** `Removed` is complete (`FIX-02-17`, which found the missing sixth global). `Added` and `Changed` were read bullet by bullet against `3256aac..HEAD`: **one bullet was half false** — *"Project input now uses separate highlighter, validator, and on_text_entered callbacks. **Submissions are line arrays.**"* — the second sentence survived `FEAT-01-04`, which made `on_text_entered`'s payload a string, so the file contradicted its own Breaking bullet four entries above. Rewritten at user-facing altitude: what used to be implied by *which global you called* is now three optional keys. The retired **"an active overlay"** went with it (`FIX-02-09` need not hunt for it). Everything else resolved: Shift+Enter is what makes a widget multi-line (`Key.is_enter(k) and not Key.shift()`), `bind_highlighter` is called at widget build, and the `Fixed` bullets are each pinned by a named test. **`Fixed` closed once `-03` delivered** (same day), and it yielded one more: *"Content that is not text is refused with a message you can read"* described the **interim** behaviour as the before — *"silently repaired or dropped"* is what the branch did for a few hours on 2026-09-01, not what a user had. At base a non-string list element was **stored as it came** and corrupted the display from then on. The bullet keeps its place — the base behaviour was real and silent, so the change is one a user can notice — but it now states the behaviour they actually met. **That is the whole shape of this row's remaining risk**, and `LEDGER-02-04`'s *"run the same test over `CHANGELOG.md`"* inherits the answer: the one candidate for an introduced-and-paid line survives on user-visible grounds, not on its entry's provenance |
| CHG-01-02 ✅ | add the **`Removed`** section for the retired globals *(feeder: FIX-02-17)* — **six, not four**: five public plus the debug-only `astv_input`, established by set-difference at `FIX-02-17` (session68). The row's original word *"four"* is one of the three counts that disagreed |
| CHG-01-03 ✅ | absorb pre-existing-resolved debt and behavioural changes, per the owner's ruling *(feeder: FIX-02-05, delivered)*. **Nine entries came back pre-existing and exactly one earned a line**: a raise in a project's `love.update` or pointer handler **vanished silently** — no error window, no console line, the run carrying on — because the error boundary called its message handler with the wrong arity and the report was built from a `nil`, raising inside the handler where `xpcall` swallowed it. Keyboard handlers went down another path and reported correctly, so the same project would show you one crash and hide another. Verified at base myself: `controller.lua:67`, `xpcall(f, user_error_handler, ...)`. **The other eight earn none, and the reasons are the useful part** — three are already lined (the multi-line string, the two spellings, the `xpcall` argument loss), three are invisible to a project (a dead `love.handlers.userinput` push, the `app_state == 'editor'` fork, the string branch's lone `_update_cursor`), and two were **ruled to keep** rather than fixed (`userlove`'s name, the console prompt drawn under a project) — a changelog records what changed, and nothing did |
| CHG-01-04 ✅ | completeness against the breaking changes; settle the **version question** — **RULED by the owner, 2026-09-03: keep `1.0.0-rc`, announce the break in prose.** *"1.0.0-rc + explicit break note."* `CURRENT_SCOPE` opens with a note naming both breaks and saying why the number does not move — nothing before 1.0.0 promises a stable surface, so the announcement belongs where an upgrader reads it rather than in a digit. **All three askers answered, all three markers gone**: the CHANGELOG's remark above its own H1, and the two asking for a concrete availability reference in `internals/user_input.md` and `internals/project_sandbox_env.md`, both now naming `1.0.0-rc20260712`. Debt entry RETIRED, slug dropped, citations swept with it | 

**Write it once.** Three rows feed this file; assembled separately they duplicate and disagree.

**A fourth feeder joined 2026-09-03: `FEAT-03`.** It writes its own `Added` line for `get_text`
(`FEAT-03-04`, the same way `BUG-02` wrote its own), and `CHG-01-01` validates that line with the
rest rather than composing it — which is why `FEAT-03` finishes **before** this sprint rather than
beside it.

**PARTLY DONE by `LEDGER-01-01`** (2026-08-27): `-02` is complete — the `Removed` section exists and
leads with the breaking change, closing `FIX-02-17`. `-01` and `-03` are **partly** done: the file
was written from the PR artifacts and spot-checked, not validated claim-by-claim against the diff.

**What `FIX-02-17`'s verification means for `-01` and `-04`** (session68). The `Removed` section was
right in substance and short by one name — `astv_input`, found by differencing `project_env`'s keys
at `3256aac` against HEAD rather than by grepping for anything. **`-01`'s remaining work is that
method applied to the other three sections**: a claim-by-claim read finds wrong claims, and a set
difference finds *absent* ones, which is the failure the section had. And **`-04` inherits a count
that disagrees three ways** — the version entry said the work removed *four* public globals,
`CHANGELOG.md` named five until this morning, `doc/development/tests.md` names six. The true figure
is **five public plus one debug-only**; the entry is `-04`'s and the correction belongs with the
version question rather than beside it.
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
3. **`T-DEC-NUMBERED` joined them 2026-09-01 and is already dispositioned** — the `DEC-01` row says
   in the same breath that the goal is RETIRED and that the citation resolves to the retirement
   note. Listed anyway, because the cross-check will keep flagging it and a sweep that finds an
   unexplained flag re-does the work: this one needs **nothing**. It is also the worked example for
   §5's rule that *the pass causing an orphan owes the fix* — the fix here was one clause written
   at the moment the slug was retired, not a line for this sweep to carry.

**Check it is clean with the cross-check already written for it** (`LEDGER-01`, above): `comm` the
`^### T-` headings against the roadmap's `T-` citations. A citation missing from the heading side is
a pointer to nothing.

**Two exclusions.** Lessons already materialized in a decision or convention — *verify, then
delete*. And **prose that is the only record of a deviation from pre-feature behaviour**: Decision
11's rot paragraph sits directly above one such record, so a sweep matching on *tone* takes both.
**Match on subjects, never on tone.**

**Scope includes `src/` and `tests/` comments** — where FIX-02-14 hid, and where no doc sweep
reaches.

### ✅ DEC-01 — decisions ledger: names, not numbers — **COMPLETE (session65)**

**Debt goal `T-DEC-NUMBERED` is RETIRED** (`technical_debt/general.md`, under `RETIRED` — the
register drops the slug from a paid entry's heading, so this citation is historical and resolves
to the retirement note rather than to a live goal).

**Landed 2026-09-01**, seven commits `65281671`..`68b7e1fb`, suite 1048 throughout. 31 decisions
carry a `D-` slug declared first in the heading; `Decisions? [0-9]+` returns **zero** across
`src/`, `tests/`, the persistent corpus and `agents/`; the crosswalk from every number the ledger
ever issued is an appendix to the ledger, so it outlives this tree.

**Two method changes, both the owner's, 2026-09-01.** *(a)* **No sentinel wrapping** — we are not
renumbering, so the substitution ran directly, in descending numeric order so `Decision 3` could
not land inside `Decision 33`, with a word-boundary match as the second belt. `DEC-01-02` was
therefore **not executed**, and the completeness burden it carried moved to `DEC-01-01`, where the
owner put it: *inventorize the mentions first and ensure no leftover is there due to newline.*
*(b)* **The conversion map lives in `wip/` for forensics** — resolved as two artifacts, since the
owner's own caveat was that the forensic file may itself become a victim of later changes: the
reasoning and counts in `validation/`, the bare crosswalk in the ledger.

**The sizing was 165 citations across 18 files. It was 554 across 36, and the gap was not drift.**
Three forms were invisible to the pattern that sized it: **18 line-broken citations** with the
number on the next line (the spec knew of 3, all in the ledger; they were spread across five
files), 11 plural mentions, and **8 bare back-references** — a decision cited by number with no
`Decision` word anywhere near it, every one of them in a sentence unpacking a plural. Proof they
were invisible: joining them alone moved the occurrence count 510 → 528.

**All six retired entries were vacuumed, not four** — owner ruling on the one in doubt: Decision 16
recorded the Gate-2 scope ruling that kept pointer out of this pass, and *"if it's not in
stakeholders' verbatim attestations, it's my interim ruling and I reverted it with reason."* Its
technical justification was lifted into `D-ONE-LIFETIME` first (`e9a3501a`), because deleting the
entry would otherwise have removed the only record in the persistent corpus that a ratified
position was reversed. **That lift generalised into `FIX-02-26`** — the owner's standing directive
that a *technical* justification does not live in `wip/`, which the whole *"Ratified deviations"*
table fails.

**Two things it closes that were parked.** Where Decision 20's `keys_pressed` history goes:
into `D-ASK-THE-DEVICE`, *"what it withdraws"*, keeping the two details that still bite — the view
was index-only on the shipping LuaJIT/5.1 runtime, and the consumer that justified exposing it is
served by the device. And the spec's *"one decision the owner owes"* (how the slug is declared) was
already ruled: `agents/rules/ledgers.md` §3 defines the `T-` slug as *"same shape as the decisions
ledger's `D-SLUG` … declared first in the heading with the prose after"*.

**NOT absorbed by `LEDGER-01-02`** (2026-08-27) — I recommended absorbing it before reading it in
full, and it is a different job: this sprint is the numbers→names conversion, not a sectioning. The
split took the structural half and nothing else; all six steps stand.

**Archived retroactively, 2026-09-02.** `DEC-01-04`'s six deletions predate the move-to-archive
mechanic (`ledgers.md` §2, *"Vacuuming is a move, not a deletion"*, owner 2026-09-02) and were
recovered into [`validation/archive/decisions-vacuumed.md`](validation/archive/decisions-vacuumed.md)
at `369b75e9`, together with `D-AUTO-HIDE`'s overruled half. **Nothing this sprint removed is gone**;
it is out of the ledger and out of the release, which was the intent, and still readable while the
working tree exists.

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
| ~~DEC-01-01~~ ✅ | join the line-broken mentions; normalise plural/lower-case | **18 joins, not 3**, plus 11 plurals, 1 lower-case and 8 bare back-references. `65281671` |
| ~~DEC-01-02~~ | ~~wrap every id in sentinels~~ | **NOT EXECUTED** — owner dropped it with the renumbering; the gate moved to `-01` |
| ~~DEC-01-03~~ ✅ | inventory: **31 slugs + 6 removals** | `94ce4960`; forensic map in [`validation/reviews/DEC-01-03-inventory.md`](validation/reviews/DEC-01-03-inventory.md) |
| ~~DEC-01-04~~ ✅ | remove **all six** retired entries | `f30c5a72` (Decision 12's seven code citations rehomed first), `9c8cc631` (the vacuum) |
| ~~DEC-01-05~~ ✅ | substitute slugs | `cac3c739` — 554 substitutions, 36 files, 68 comment blocks reflowed in the same commit |
| ~~DEC-01-06~~ ✅ | read the diff; append the crosswalk to the ledger | `187b62a3`; `68b7e1fb` discharges the tombstone clause in `ledgers.md` §2 |

**Scope as executed:** the ledger, **14** persistent docs, **`src/` + `tests/`**, and **`agents/`**
— the last an owner-approved addition, because `agents/rules/commenting.md`'s four citations are the
*exemplars* teaching what a good citation looks like, and leaving them numbered would have had the
rule governing comment citations demonstrate a form that no longer resolves. **`wip/` stayed out** —
frozen history, and it carries its own dead `D-1…D-10` namespace, which the crosswalk now separates
from this one for good.

**The one thing a reader of `wip/` must know:** every document in this tree, every commit message
before 2026-09-01, and this roadmap's own history cite decisions by number. The crosswalk in
`doc/development/decisions/input.md` is the translation, and it is the half that survives.

---

### ⬜ DEC-02 — vacuum the prose that argues with an overwritten past — **runs after FIX-03, before DOC-01**

**Debt goal: `T-ARGUES-INTERIM`** (`technical_debt/general.md`). **Rule:**
[`agents/rules/ledgers.md`](../../../../agents/rules/ledgers.md), *"What a decision records about
its own past"* — ratified 2026-09-01 out of a `REMARK` the owner had left in the ledger itself.

**`DEC-01` vacuumed the RETIRED block; this vacuums the live entries.** What is left is not dead
*entries* but dead *prose inside entries still in force*: paragraphs re-litigating an interim
version of our own ruling. What was not in a released version is considered never to have existed,
so a ruling reshaped before release leaves nothing to argue with.

**The two shapes, both measured:**

| shape | instance |
|---|---|
| a section arguing with a **withdrawn rationale** | `D-ROUTE-LIFETIME`'s *"Why the original rationale was withdrawn"* — ten lines refuting a justification that never reached a release |
| a **name that lived a fortnight** | `oneshot`, ruled and overruled in a day, never released. **This instance is PAID** (`d0f4e66c`) — `D-AUTO-HIDE` went 132 lines to 77, restated as the single decision *"`auto_hide` replaces `oneshot`"*, and **eleven citations moved with it**, six naming *"the Amendment"* and four *"ruled edge N"*. That is the cost pattern to expect: self-arguing prose teaches the code to cite it as a diff |

**It is not a mechanical sweep, and that is the whole difficulty.** Two things sit inside the same
paragraphs and must survive: **pre-feature baseline facts**, which are provenance saying the release
*restored* behaviour rather than changing it, and **anything stakeholders explicitly ratified**.
`D-ROUTE-LIFETIME` is the worked example of both — the base check inside that section
(`set_default_handlers` called from exactly two sites at `3256aac`) is what must be kept while the
argument around it goes.

**The qualifier is `interim, overwritten`** (owner correction, 2026-09-01), **not `self-arguing`**,
which is too wide and catches the legitimate cases: an entry weighing a live alternative, or
amending an entry still in force, is the ledger doing its job. **The test: would a reader plausibly
propose that alternative again?**

| id | step | note |
|---|---|---|
| DEC-02-01 | enumerate the passages: withdrawn rationales, superseded-in-part narration, and every mention of a name that never shipped | `D-AUTO-HIDE` is done; `D-ROUTE-LIFETIME` is the known remainder. **Re-derive rather than trust it**, and settle the open scope question on `T-ARGUES-INTERIM`: whether the debt register's `RETIRED` section is in scope |
| DEC-02-02 | classify each against the two exclusions — baseline fact, stakeholder-ratified | **the judgement step**; a passage can be part keep, part cut |
| DEC-02-03 | **move** the cut passages to `validation/archive/decisions-vacuumed.md`, preserving the facts identified at `-02` in the live entry | one commit per entry, so the diff reads. **Vacuuming is a move, not a deletion** (`ledgers.md` §2) — `D-AUTO-HIDE`'s overruled half is already there as the worked example |
| DEC-02-04 | remove the `REMARK` at `decisions/input.md` that raised this, **and only now** | owner, 2026-09-01: a marker goes when its defect is solved, not when a sweep reaches it |

**Placement — after `FIX-03`, before `DOC-01`**, the same argument that placed `DOC-01`: `FIX-03`'s
deletions are mechanical (subject absent at base and today) and shrink the floor this one exercises
judgement over, and a cold reviewer at `ACC-02` should read the prose that ships. **It is distinct
from `FIX-03`, not a duplicate:** that sweep matches subjects *absent at base and today*, and a
decision arguing with its own earlier version is about a subject that is very much present — the
route lifetime still exists, it is the withdrawn *version* of the rule that does not. `FIX-03`'s
test cannot see this class.

**Also carries the marker consequence:** the retained `REMARK` is now an exception any pass over
`doc/` markers must honour, so a sweep that takes it before `DEC-02-04` is a defect.

---

### ⬜ LEDGER-02 — vacuum the debt register of what never existed outside — **runs after FIX-02-05, beside DEC-02**

**Debt goal: `T-NEVER-SHIPPED`** (`technical_debt/general.md`). **Rule:**
[`agents/rules/ledgers.md`](../../../../agents/rules/ledgers.md) §3.

**Owner, 2026-09-01: the same principle, the second ledger.** *"I would vacuum debt on the same
principle — introduced-then-paid never existed for the outer world."* `DEC-01-04` vacuumed the
decisions ledger's retired entries and `DEC-02` takes its interim prose; this is the debt register's
turn. What a branch introduced and fixed before release is a record of our own drafting; what
pre-existed and was fixed is the product's history, and is the evidence behind a changelog line.

**It enumerates nothing, and its input now exists.** `FIX-02-05` **ran 2026-09-03** and tested every retired entry against
the PR base to verify its resolution claim, and **the same check answers *did this exist at the
base?*** One pass, one classification, **two consumers** — `CHG-01-03` takes the pre-existing half
into the CHANGELOG, this row takes the other half out of the register. That is the whole reason this
is four steps and not a survey, and it is the hard ordering constraint: **`FIX-02-05` first.**

**Sized on `FIX-02-05`'s classification, 2026-09-03:** **39 introduced-in-branch · 9 pre-existing ·
5 mixed · 3 cannot-tell** over the walked 56. The 2026-09-01 measurement (47 entries, 14/7
self-stated) is superseded — take the evidence document, do not re-derive it. Five further
entries sit outside that snapshot; `LEDGER-02-01` names them.

| id | step | note |
|---|---|---|
| LEDGER-02-01 | take `FIX-02-05`'s base-check classification | **do not re-derive it**; re-deriving is how one check becomes two walks that disagree. The evidence document covers the walked **56**. **Five more sit outside it** — retired while the walk ran or just after, all by session68 — and they are dispositioned in `T-RETIRED-UNVER`'s resolution, not in the evidence document: all five are `INTRODUCED-IN-BRANCH` and the check is not close. Their subjects are `CHANGELOG.md`, `doc/input_api.md`, this register, or `auto_hide`; **all four of those files are absent at `3256aac`**, and `auto_hide` is this feature's. They need no further pass |
| LEDGER-02-02 | **move** the introduced-and-paid entries to `validation/archive/debt-vacuumed.md` | **check inbound citations first — see the note below.** `T-ONESHOT` and `T-ONESHOT-SCOPE` are known members — the arc `D-AUTO-HIDE` was rewritten to drop. A second archive file beside the decisions one, same contract: nothing in it rules anything, and it leaves the release with `wip/` |
| LEDGER-02-03 | **mixed provenance: rewrite to the half that shipped**, archiving the half that did not | the judgement step. `BUG-01-05` is the worked example — a pre-existing bound our own wrappers made reachable on purpose. Keep the entry, state the pre-existing half, drop the drafting note |
| LEDGER-02-04 | run the same test over `CHANGELOG.md` | **partly answered at `CHG-01-01` (session68)** — one bullet was checked and stays, and the reasoning is the row's own: judge a changelog line by whether the **behaviour a user met** changed, not by the provenance of the debt entry behind it. The two can differ, and did. **Expected yield may be zero**, and it is worth the ten minutes: a changelog line for something introduced and removed inside the branch is news about nothing. Stated as a check, not as a fix |

**Why it is not `FIX-03`.** That sweep uses the same base check, and the overlap is real — but it
disposes of **prose narrating a closed arc**, wherever it appears, while this disposes of **whole
ledger entries** under a governance rule about what a register is for. Running them together would
also put `FIX-03` before `FIX-02-05`, which is backwards: this row's input does not exist until that
verification has run.

**What it must not take.** A pre-existing defect's entry, which is `CHG-01-03`'s evidence, and the
pre-existing half of any mixed entry. Deleting either would remove the record that this release
**fixed something users had met** — the opposite of the principle, applied by the same sweep.

**Six ephemeral path citations are handed to this row, not fixed by `FIX-01-02`** (2026-09-03).
`general.md`'s two renumber entries — *"A renumber shipped its crosswalk without the sweep…"* and
*"The `FIX-02` renumber's own citations were never swept"* — cite `ROADMAP.md`, `plan.md` and three
`validation/` documents in their **Where** and **Resolution** fields. They are the one shape the
citation-hygiene row cannot fix: **the wip file is the defect's location**, so there is no canonical
target to repoint at, and rewriting them to hide it would destroy the entry. Both are also textbook
`T-NEVER-SHIPPED` members — a roadmap defect introduced and paid inside the branch. **If this row
archives them the citations leave with them; if it keeps either, that entry owes the repoint.**

**A cited entry is never silently relocated** (found 2026-09-02, `S67-delivery-revalidation.md` F9).
Before moving an entry, grep the **persistent** corpus for citations of its heading: an entry moved
into `validation/archive/` leaves with `wip/77`, so a persistent document citing it is orphaned by
the move. A cited entry is either rewritten in place or its citation is re-homed **in the same
commit** — `agents/rules/roadmap.md` §5, the pass that causes the orphan owes the fix. **One is
already known:** `internals/event_dispatch_layers.md` records two live open pointer questions as
held under *"Pointer delivery is an unstructured broadcast, not a chain"*, an entry sitting under
`## RETIRED`. It reads as pre-existing (the broadcast shipped) and should survive this row on its
own classification — but that classification is `FIX-02-05`'s and is not made yet, so the check is
owed rather than pre-answered.

---

## ⬜ DOC-01 — the documentation compaction sweep — **runs after FIX-03, before ACC-03**

**Restored by the owner, 2026-09-01**, when this pass reported that the compaction step the volume
ruling relies on was scheduled for **comments** only (`agents/rules/commenting.md`, *"Where this is
enforced"*) and that Phase L, the ledger compaction, is retired. Phase L **stays retired and this is
not it**: L was three specific excisions, all still owned elsewhere (`DEC-01-04`, a `REMARK` inside
`FIX-02-07`, Decision 12's demotion). `DOC-01` is the volume pass over the prose corpus that L never
was.

**The method is already written** — `agents/rules/commenting.md`, *"Where this is enforced"*, in the
verbosity paragraph: compaction is **its own substep near the end, taken once, over stabilised
material**.
It *"dries up history and obituaries, intermediate rulings, and second phrasings, keeping only the
reasons."* `P-18-10` is the worked example — `keyboard`'s `input.lua`, 177 comment lines to 101
without losing an argument. This row is that rule applied to prose instead of comments, and the
owner's framing is the test: **verbose docs support ongoing development; the release is what they
stop supporting.**

**Scope is the rule, not a list** (`agents/validation.md`, *"Fixed pointers"*, the persistent-docs-corpus
entry): everything
under `doc/` not under `doc/development/wip/`, plus `CHANGELOG.md`. A file list goes stale — that is
how `FIX-02-09` came to be sized by one file. `wip/77` is **out of scope**: it is deleted or kept
whole by the `PR-01-05` ruling, and compacting something that may be deleted is the one certain
waste here.

| id | step | note |
|---|---|---|
| DOC-01-01 | **size it before working it** — measure the corpus as it stands, per file | the sizes in the finding that opened this row are from 2026-09-01 and will have moved; `technical_debt/input.md` was 2447 lines then |
| DOC-01-02 | **the debt registers** — `technical_debt/input.md` and `general.md` | the largest surface and the most repetitive. An entry keeps its **disposition, its reason, and its provenance**; what goes is the argument's history, the second phrasing, and the intermediate ruling superseded by the one above it |
| DOC-01-03 | **the internals docs** — `internals/`, `decisions/`, `drawing_system.md`, `smoke_checklists.md` | these are read by a developer *working*, not by a reviewer once; compact for redundancy, not for brevity |
| DOC-01-04 | **`doc/input_api.md` and `CHANGELOG.md`** — the two a stakeholder actually reads | **the tightest constraint on the row.** `PR-01-03` gates the guide as reviewable **alone**; compact it for redundancy only, **never for completeness**, and re-run that gate after |
| DOC-01-05 | **citation check over everything this row rewrote** | `agents/rules/roadmap.md` §5 — *the pass that causes an orphan owes the fix*. Rewriting a paragraph breaks section-name citations into it, and `FIX-03-05` will already have run |
| **DOC-01-06** | **the ephemeral-id sweep** — `T-EPHEMERAL-IDS`, citations of live sprint ids in the persistent corpus | **owner ruling, 2026-09-03**, deferred out of `FIX-01-02`. Runs **here** and not at `FIX-03-05`: that row wipes citations of *retired* ids and sits **before** `DEC-02`/`LEDGER-02`, which vacuum entries out of the very ledgers holding most of these — a sweep run first sweeps prose that is about to leave. **Size it from the entry's own command, not from a figure in this cell** (the entry's snapshot was 116 citations plus 2 illustrations, and it moves under its own sweep). **Compaction runs first within this row:** an entry `DOC-01-02` shortens may lose its id without a rewrite. **Ordering against `-05` is unsettled and is decided when this row opens** (S69 delivery review, F7): `-05` is the citation check over everything the row rewrote, and this step rewrites after it — either this runs before `-05`, or `-05` re-runs over what this touched |

| **DOC-01-07** | **`get_text()` stops being experimental** — the one documentation consequence of the proposal block | **owner instruction, 2026-09-03**, on the proposal section committed into `doc/input_api.md` (`1299ed2b`): the *"experimental until somebody needs it"* condition session69 attached has been met, so the qualifier is retracted. **Not compaction and not design** — the status call is the owner's and is already made; this row executes it. Five sites: `doc/input_api.md` (the surface inventory, the `hide()` cross-reference, and the *"`get_text()` is experimental"* paragraph in *"Live changes"*, which goes rather than being softened), the `CHANGELOG.md` `Added` line, and the `T-CONTENT-READ` entry's closing paragraph, which is **past-tensed, not deleted** — it records a ruling that was true when made. Re-derive with `git grep -n 'experimental' -- doc/ CHANGELOG.md ':!doc/development/wip/'`, which returns two more the row does not want: `internals/examples/clock.md`'s stencil block, unrelated, and the proposal block's own line, whose fate is the open question in [`validation/reviews/S70-proposal-block-placement.md`](validation/reviews/S70-proposal-block-placement.md) §5. The count above is a snapshot, not a scope statement |

**One row here is not compaction.** `DOC-01-07` is a status retraction the owner
ruled separately; it sits in this sprint because it is documentation work over the
stabilised corpus and because a second documentation pass for one qualifier would
be a second broom over the same floor.

**Two guards, both learned rather than assumed.**

**A compacted document must still carry why, not only what.** The corpus's value is that it records
reasons a reader cannot re-derive from code — that is the whole argument of `agents/rules/commenting.md`'s
payload rules, and it is what makes this a judgement pass rather than a word count. **Nothing here is
sized by a target length**, and no entry is compacted because it is long.

**Do not compact what is still moving.** This row sits where it does for the same reason `FIX-03`
and `FIX-02-09` do: a sweep run while the writing continues is run twice. If a later row reopens a
subject — a returned `ACC-02` finding, an upstream merge — the prose it writes is **not** retro-fitted
into this pass; `DOC-01` is taken once and what follows it stands as written.

---

## ⬜ ACC-02 — the device passes — **runs after MERGE-01, ahead of the prose rows**

**Split from the old single `ACC-02`, owner 2026-09-02**, and moved ahead of `FIX-03`/`DEC-02`/
`LEDGER-02`/`DOC-01`. The cold review is now `ACC-03`. Crosswalk at the end of this section.

**Why the split rather than moving the row whole.** The old row bundled two activities with
**opposite** ordering requirements. The device passes find *runtime* defects, so they want to run
early — everything downstream of them is prose, and prose is cheap to redo. The cold review reads
the docs, so it wants to run late, on the prose that ships. Moving the row whole would have got one
of the two right and reversed the owner's own 2026-09-01 placement of `DOC-01`. Splitting gets both.

**And the merges now precede it — a ruling made twice, in opposite directions, and this is the
live one.** `ACC-02-01/02/03` smoke `balloons`, `keyboard` and `maze`; `MERGE-01-01/02/03` merge
upstream **into those same repos**, so one of the two orders has to give.

- **2026-08-26, smoke first:** a pass on the pre-merge tree is the **control** for the post-merge
  one, because a later device failure otherwise has two candidate causes — our branch and an
  advanced upstream — and no way to separate them (`validation/plan.md`, superseded in place).
- **2026-09-02, merges first (owner, and in force):** *"we are accelerating now, so no point in
  having two separate sessions of smoke testing and defect fixing just for ceremony. Recon will
  document what changed in the upstreams before the merge; this knowledge will assist
  troubleshooting."*

**The control is bought differently, not abandoned** — that is the part to carry. The first ruling
spent a second owner sitting to keep the causes apart; `REC-01`'s written upstream delta separates
them at desk cost, which is what makes the extra sitting ceremony rather than insurance. **`REC-01`
therefore owes that document before `MERGE-01` runs**, and it is the condition this order stands on.

Runs only once the tree is fixed. Every row costs owner time; re-running them against a tree about
to change is what this ordering exists to prevent.

| id | step | note |
|---|---|---|
| ACC-02-01 | `balloons` smoke | **first** — 5 ahead / 0 behind, the one result recon cannot invalidate |
| ACC-02-02 | `keyboard` smoke | the review could not check `4c`'s timing — run this one carefully |
| ACC-02-03 | `maze` + `draw` smoke | **against `newinput-edge`** — `da9d1c2` is on that branch only. **Track 2 is covered**: rows **B11**, **D8**, **D9** were added to the list on 2026-08-26 for exactly this; `validation/plan.md`, *"`ACC-02-03` — `maze` — carries a coverage gap"*, is why they matter |
| ACC-02-04 | `sapper` smoke | **section C is expected to fail** — P19's accepted defect, described in the list |
| ACC-02-05 | `turtle` smoke | `FEAT-02` put its prompt lifecycle on `auto_hide`, so the game no longer closes the widget itself. In-repo, so **run it beside `ACC-02-04`** |

Lists: [`doc/development/smoke_checklists.md`](../../smoke_checklists.md). **Tag every green pass**
(`TAGS.md`, round 2) so "it passed" names a commit.

**If a pass moves code, the rows after it are unaffected** — that is the whole point of the move.
What it does affect is `ACC-03`'s cold read and the slice cut, both of which come later by design.

**Crosswalk (split + renumber, 2026-09-02).** No `ACC` id appears in `src/` or `tests/`, so
`agents/rules/roadmap.md` §2's renumber branch applies. Earlier prompts, notes and commit messages
carry the old ids.

| was | is | step |
|---|---|---|
| `ACC-02-01` | **`ACC-03-01`** | second cold PR review |
| `ACC-02-02` | **`ACC-02-01`** | `balloons` smoke |
| `ACC-02-03` | **`ACC-02-02`** | `keyboard` smoke |
| `ACC-02-04` | **`ACC-02-03`** | `maze` + `draw` smoke |
| `ACC-02-05` | **`ACC-02-04`** | `sapper` smoke |
| `ACC-02-08` | **`ACC-02-05`** | `turtle` smoke — filed out of order, now in it |
| `ACC-02-06` | **`ACC-03-02`** | slice regeneration, if anything moved |
| `ACC-02-07` | **`ACC-03-03`** | owner's readability review of the slices |

**One example changed reachability and deliberately gets no row (checked 2026-08-31).** The
`BUG-01-09` fix reaches `tixy` — `load_example` calls `compy.input.set_text(body)` with a raw
string, which was a silent no-op for a multi-line body and now writes. It is **inert on shipped
data**: `examples.lua` defines 35 examples and every `code` is `"r = " .. c`, a single line (the
newlines in that file are all in *legends*). The other two example call sites, `tixy/main.lua`'s
second one and `maze/core_editor.lua`, pass `string.lines(…)` and take the untouched table branch.
So there is nothing for a smoke pass to observe, and `tixy` gains no checklist. **What would change
this answer:** an `examples.lua` entry whose `code` spans lines — then the fix is visible and the
example wants a look. Recorded here rather than dropped, so a reviewer who notices the changed
reachability finds the check instead of re-running it.

---

## ⬜ ACC-03 — the cold read — **runs after DOC-01, immediately before PR-01**

**Split from `ACC-02`, owner 2026-09-02.** This is the half that must read **the prose that ships**,
which is `DOC-01`'s placement argument of 2026-09-01 and the reason the split exists rather than a
wholesale move.

**It runs after keyboard time, and that reverses a standing placement** (owner, 2026-09-02). The old
`ACC-02-01` was *"a second cold PR review, over the fixed tree — before the owner touches a
keyboard"*: a desk pass in front of the sitting, so the sitting is not spent on a tree the review
would have condemned. The owner's ground for dropping it: *"It was supposed to de-risk by spotting
bugs, but it can also become wasted effort or misfire. Smoke becomes more important in the same way
as behavioural versus unit testing — the cold review checks internals, smoke validates the surface.
When the planning horizon collapses to one day, postponing smoke for the sake of additional peace of
mind makes no sense."* **A de-risking step whose cost is a sitting loses to one that produces a
result** once the horizon is short — the same reasoning that put the merges ahead of `ACC-02`.

| id | step | note |
|---|---|---|
| ACC-03-01 | **a second cold PR review**, over the finished tree | the tree is fixed *and* the prose is final by the time this runs — the first cold review (`ACC-01-02`) had neither |
| ACC-03-02 | slice regeneration, if anything moved | `ACC-02`'s device passes are the likeliest thing to have moved something |
| ACC-03-03 | owner's readability review of the slices | |

**What it inherits from the reordering:** everything upstream of it can no longer move code except
by its own findings, so a defect it raises is a late defect by construction and is weighed as one.

## ⬜ OP-02 — recover the truncated S68 delivery review — **optional, does not delay the release**

**Owner, 2026-09-03.** The first run of the three-step closing order commissioned an Opus
delivery review of session68; the reviewer was interrupted. The artifact at
[`validation/reviews/S68-delivery-revalidation.md`](validation/reviews/S68-delivery-revalidation.md)
claims **seven findings, none blocking**, and a dispositions table `session69/prompt.md` was told
to execute. The file **ends at F5**. F1–F5 are dispositioned (session69). What is missing is
whatever F6 and F7 were, and the table.

**It is not a gate.** Skip it and the release still ships. Run it when a cold reader has the
time: the cost of not running it is unknown findings, not a blocked PR.

**Do not re-walk F1–F5.** They are executed. The job is the remainder of that commission, from
the same altitude (roadmap integrity, omission, drift from the strategic frame), over
`c610805b..ace9a6b8` (the session proper; wrap and the two review-landing commits are
housekeeping around it).

| id | step | note |
|---|---|---|
| OP-02-01 | re-read session68's outcome and write the missing findings | produce F6/F7 or record that the "seven" was a count the interrupted draft never reached; land a dispositions table. Same artifact path, or a successor in `validation/reviews/` cross-linked from it. **Neither this row nor its worker may spawn sub-agents** — host protection, `agents/validation.md` |

## 🟡 REC-01 — upstream reconnaissance — *discovery, not release* — **PARTIALLY COMPLETE (Session 55)**

**Moved ahead of `ACC-02`, owner 2026-09-02.** Its remaining half is the three example repos, and
`ACC-02` smokes those same repos — merging into them afterwards smokes a tree that then changes.
Everything downstream of `ACC-02` is prose, so this is now the last pair of rows that can move code
without being prompted by a finding.

**And this row now carries the load the old order gave to a second smoke sitting.** The 2026-08-26
ruling ran the smoke first so a post-merge failure had one candidate cause; the acceleration ruling
replaces that with **what this row writes down** — what moved in each upstream, in our surfaces,
before the merge lands. That document is not a by-product of the recon here, it is the reason the
merge may precede the smoke, and a failure in `ACC-02` is read against it.

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

**Moved ahead of `ACC-02`, owner 2026-09-02**, with `REC-01` and for the same reason: `-01`, `-02`
and `-03` change the very repos `ACC-02` smokes. **`MERGE-01-04` is already done**, so what moves is
only the example half — the platform tree is not touched again, and the platform slice cut is
unaffected either way.

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
   `FIX-02-07`;
3. demote Decision 12 → **parked**, the owner disposes it during review.

Retiring L therefore drops nothing.

**Documentation volume is not a defect, and is not weighed before the compaction step (owner,
2026-09-01).** Asked during the session64 revalidation whether `#77`'s documentation is
proportionate — ~100 lines of production change in session63 drew 620 lines of persistent
documentation, `technical_debt/input.md` alone taking +383 in one day onto a register now past
2400 lines — the owner ruled it is **not** a finding: *"we have planned compaction step before
release. in the meantime, verbose docs support ongoing development and troubleshooting."* This is
the doc-corpus statement of the rule `agents/rules/commenting.md` already makes for comments
(*"Do not compact as you go"*, owner 2026-08-12): verbosity mid-development is doing real work, and
compaction is one deliberate pass over stabilised material, not a running discipline. **Do not file
volume as debt, and do not compact opportunistically while the corpus is still moving.**

**Answered the same day: the row was missing, and it is now `DOC-01`.** Raised with the ruling —
`commenting.md` §*"Where this is enforced"* schedules compaction for **comments**, and Phase L, the
**ledger** compaction, is retired above with its three items owned elsewhere, so nothing scheduled a
volume pass over the prose. The owner's disposition was to add one: *"well than please add documents
compaction sweep back to the roadmap."* See `DOC-01`, which runs after `FIX-03` and before `ACC-03`
(the row named at the time was `ACC-02`; the cold read became `ACC-03` in the 2026-09-02 split).
**Phase L is not un-retired** — its retirement reasoning still holds, and `DOC-01` is new work rather
than L restored.

### Phases B, C, D — **dissolved** (owner ruling, 2026-08-26)

They are absent from this roadmap by **ruling**, not by omission. They were a prediction of the
shape of pre-release work; that shape emerged differently, so the placeholders go.

- **B, the intent check** → done by the **cold reviews** (`ACC-01-02`, repeated at `ACC-03-01`) —
  and by a reviewer with no stake, which a self-check could never be.
- **C2, the disposition table** → emerged as the **defect register**.
- **C1 and D** → dissolved outright: *principles are enforced at the row, without abstract
  encoding first.* The parked calls below are that method.

**This settled the gate early.** The collapse ruling was scheduled as step zero of Phase G; it is
done, and G no longer opens with it. **Phase F** goes with them — its "final revalidation" is what
`ACC-03-01` is.

---

## ⬜ PROP-01 — the proposal block — **runs after `PR-01`** (owner ruling, 2026-09-03)

**The stakeholders answered the shipped surface with a design proposal, and the owner placed it
after the PR.** The block lives in `doc/input_api.md` (`## Proposed updates/changes`, committed by
the owner at `1299ed2b`): five DevX amendments, a second minimalistic surface, and a live-discussion
resolution that both surfaces are exposed under `compy.input`. The classification, the two things
the block does not say about itself, and the placement argument are in
[`validation/reviews/S70-proposal-block-placement.md`](validation/reviews/S70-proposal-block-placement.md);
this section is the sequence.

**Why after.** Items 2–6 reopen the public surface, and every remaining row before `PR-01` is sized
against the current one — `ACC-02` smokes it on hardware, `CHG-01` has already written its
changelog, `DEC-02`/`LEDGER-02` vacuum the ledgers that record it, `PR-01` cuts slices from it. This
is the roadmap's own ordering principle applied to the surface itself: *sizing a small row against an
unsettled surface is sizing it twice*. The strategic frame argues the same way from the other end —
a surface under revision is a moving part, where a surface that ships with its successor's questions
**named in the PR description** is not. The cost is honest and was weighed: the proposals come from
the reviewers the PR is for, so this release will be followed by a breaking one.

**Three carve-outs are taken before the PR, and none of them is design work.**

1. **`DOC-01-07`** — `get_text()` stops being experimental. Landed as a row 2026-09-03.
2. **The block itself does not ship inside the guide as it stands** — it carries author handles, a
   `remark:` line, unresolved alternatives, and a pointer to `sync-input-proposal.md`, which is not
   in this repository. `PR-01-02`/`-03` own the destination; the PR description's **open questions**
   section is where a reviewer expects to meet it.
3. **A ruling on Escape** — contract or defect (see `PROP-01-05`). Cheap either way, and it decides
   whether the release documents a data-loss path as intended behaviour.

| id | step | note |
|---|---|---|
| PROP-01-01 | **triage and provenance** — what each item would break against the shipped surface | the classification the rest is sized against. Item 1 is already discharged by `DOC-01-07` |
| PROP-01-02 | **the two-surface shape** — a `compy.ask`-style simple surface exposed beside the current one, same namespace, per the live-discussion resolution | **first, by blast radius.** It decides how much the rest matters: defaults on a low-level surface that a wrapper hides are a different question. *"Details to be figured out"* is the honest state of it, and it is the one item nobody has claimed is small |
| PROP-01-03 | **one payload shape** — every content-bearing callback receives the string | **this reopens a ratified decision.** `FIX-02-01` asked whether `on_text_entered` and `after_submit` are two ways to set one callback and was answered by Decision 37 — *they are told apart by their payload* — which `FEAT-01` then implemented and documented. The proposal calls that distinction the defect. Legitimate, and it is a ledger reopening rather than a tweak, **with a live consumer**: the platform's `serial` API already migrated to the split |
| PROP-01-04 | **`auto_clear`** — submit clears by default | joins `auto_hide`'s family or replaces the pair with better names, which is the block's own alternative. Weigh with `-06`: the two flags and the `show()`/`show{}` distinction are three answers to one question |
| PROP-01-05 | **Escape hides and does not clear** | implementation of whatever the pre-PR ruling decided. Today's behaviour is a *documented contract* (`doc/input_api.md`, *"Asking one question"*; `CHANGELOG.md`), and the register already names the asymmetry it leaves — so this is a reversal, not a repair, unless the ruling says otherwise |
| PROP-01-06 | **`show()` vs `show{...}`** | the one item that **arrived with its own dissent**: *"semantically inobvious"*, and the case frequency unproven. Two alternatives are recorded with it, and the third — read before hiding, restore from a project variable — is what the guide already advises and only works because `get_text()` shipped. Its do-nothing branch is therefore live |
| PROP-01-07 | the guide and the changelog absorb whatever landed | after, not during |

**Synchronous input is a separate product proposal** and is deliberately not in this sprint — the
block's own rationale says so. `sync-input-proposal.md` is cited from the guide and is **not in this
repository**; if it is meant to be here, that is a finding for carve-out 2 rather than a row here.

---

## Parked, with the moment each gets answered

Not open questions to chase — each has a trigger:

| question | answered at |
|---|---|
| highlighter: sentinel, or a `clear_highlighter` member? | **when BUG-01-02 is fixed** |
| the 37 remarks: ruled individually, or swept? | **ANSWERED — swept, by the triage that produced the dispositions; `FIX-02-07` executes them.** (The trigger said `FIX-02-01` and the count said 14; both predate the sprint's renumber and its triage) |
| does "draft" stay (and get defined) or go? | **at FIX-02-20**, with the 08–10 vocabulary cluster |
| is `prompt` sticky or per-show *within* a run? | **ANSWERED 2026-08-27 (owner) — sticky, and the classification was the defect.** `FIX-02-21` ✅, executed by `ARC-02-05`/`-08`; it did not escalate |
| Decision 12 — a ledger entry that says it is not a decision | **owner disposes during review** — needs context, stays in place |
| the slug table | **no review needed** — grep-and-rename if a slug displeases |
| provenance beyond the 3 files | **deferred** — a formal violation does not displace real work |
| ~~where Decision 20's `keys_pressed` history lives after removal~~ | **ANSWERED at `DEC-01-04`** — into `D-ASK-THE-DEVICE`, *"what it withdraws"* |
| ~~which sprint (and KIND) the three owner debt entries are filed into~~ | **ANSWERED 2026-08-30** — two new KINDs, owner-ruled: `OP-01` for the ledger upkeep (operational, no parent decision), `FEAT-01` for the design and implementation |
| does `oneshot` close on cancel as well as submit, and what happens when the project also set `after_submit`? | **at `FEAT-01-01`** — the design ruling, before any code |
| is `maze`'s flag-clearing neutralisation worth rewriting, or `wontfix`? | **at `BUG-01-11`**, whose first step is that weighing |

