# `FEAT-02` — delivery-level revalidation

**Session:** session59 · **Date:** 2026-08-31 · **HEAD at review:** `e6a506f6`
**Suite:** 1023 / 0 / 0 / 10 — baseline confirmed by running it, not by reading it.
**Instrument:** `agents/rules/revalidation.md`, pointed where `session59/prompt.md` directs.

**This is deliberately not a code review.** The cold peer review
([`../outcomes/FEAT-02-peer-review.md`](../outcomes/FEAT-02-peer-review.md), Opus, *approve with
comments*, six findings, fixed in `23e4a05a`) already walked the implementation, the tests and the
diff, mutating the source to check the cases discriminate. Nothing below re-derives whether
`configure_core` is correct. The question here is one level up: **was it delivered as planned, is
anything forgotten, is anything drifting.**

**Verdict: the sprint delivered all five rows with their conditions intact.** Six findings, none of
which overturns the work. One is load-bearing for the sprints that come next; two are ordinary
corpus rot; three are nits.

> **All six corrections applied on the owner's instruction, 2026-08-31** — one commit each,
> suite green at every one. See §7 for the resolution table. The findings below are left in the
> present tense as they were written, so the report still reads as the evidence for the fixes.

---

## 1. Intent

`FEAT-02` was to move one key out of the `show`-only category and rename it: `oneshot` →
`auto_hide`, project-owned, settable at `show` **and** `configure`, `false` to unset, **persistent
until replaced** — a mode rather than a one-off — with the ledger amended before the code moved,
and the persistence *ruled* in the decisions and *said* in the guide.

## 2. Delivery against the ledger — five rows, five conditions, all met

Each row's notes cell carries conditions. Walked individually against what landed:

| row | its condition | verdict |
|---|---|---|
| **`-01`** | amend **two** things in Decision 36 (edge 1 *and* the first ground), plus Decision 35's boundary note; **the amended text must state the persistence** | **met.** Edge 1 kept verbatim and marked `SUPERSEDED` (`decisions/input.md:1507`) with an *Amendment* stating what replaces it; the familiarity ground corrected in place, restoration argument preserved (`:1477-1486`, `:1542-1550`); Decision 35's category now gives **two reasons** for the remaining three and says neither is "it describes this session" (`:1381-1387`); persistence ruled explicitly as its own clause (`:1557-1562`) |
| **`-02`** | rename the key | **met**, and token-only — the rename commit `fe076244` touches 8 files and is +52/−51, i.e. no behaviour rode along |
| **`-03`** | project-owned, both calls, set-if-given, `false` unsets, persistent; **"must not smuggle in a clearing step"** | **met, and the negative condition holds.** `auto_hide` left `SHOW_ONLY_KEYS`, joined the new `WIDGET_KEYS` (`consoleController.lua:616`), and is seated in `configure_core` (`userInputController.lua:292`). `self.auto_hide` is written in exactly one place and read in exactly one (`:478`) — **there is no reset, no clear, no consumption anywhere in the tree.** The old unconditional seat in `open_widget` was deleted rather than moved |
| **`-04`** | guide says the teardown-path edge **and** the persistence, bluntly | **met.** `input_api.md:266` leads with *"It stays on until you turn it off"*, gives the disarm on both calls (`:271-274`), and the teardown path gets the owner's own shape — disarm on that `show`, or run it after the widget is down (`:299-301`) |
| **`-05`** | two named cases invert; CHANGELOG | **met.** Both inverted as filed (`configure raises…` → `configure arms…`; `it is spent by its own show` → `it persists into a later bare show`), and the CHANGELOG says **mode, not one-off** (`CHANGELOG.md:29-31`) |

No row is marked done on a dropped condition.

## 3. Suite arithmetic — reconciles exactly

`2c6fe978`'s test diff is **−3 / +5 `it(…)` = net +2**, and 1021 + 2 = **1023**, which is what the
suite reports today. The claim decomposes as filed: two replaced in place, one renamed in place
(`a forced follow-up show survives the close` → `a disarming forced follow-up survives the close`),
two genuinely added. **Every one of the eighteen commits states its count**; the two that changed
code explain the delta. Pending is still 10, so no eleventh.

## 4. Findings

### F1 — `doc/development/tests.md` is the third document that rotted (the one the prompt predicted)

**Where:** `doc/development/tests.md:96`, §*Manual smoke — what no suite here can reach*.

> The nested example repositories (`src/examples/{keyboard,maze,balloons}`) have **no test suite**
> … Their gate is a human, and the checklists they are gated on live in `smoke_checklists.md`.

`smoke_checklists.md` now holds **five** lists, and **two of them are in-repo** — `sapper` and, as
of `FEAT-02`, `turtle`. The sentence tells a reader that manual smoke is a *detached-repo* concern,
which is exactly the reason someone would not go looking for a `turtle` list. `tests.md` is in the
persistent corpus and **the sprint did not touch it at all**.

**Attribution, stated fairly:** the sentence went stale first at `sapper` (2026-08-13), not here —
it was written 2026-08-12 (`f5364e33`) and enumerated the three detached repos that existed then.
`FEAT-02` widened it rather than caused it. But `FEAT-02` is the pass that added a list, and
`smoke_checklists.md`'s own front matter maintains the index correctly (`:10-24`), so the
divergence is now between two documents that describe the same thing.

**Proposed correction (one sentence):** rewrite `:96-98` so the scope is *examples whose input
mechanism this feature changed*, tracked or detached, and let `smoke_checklists.md` remain the
enumerating authority rather than repeating the list.

### F2 — `FIX-02-20`'s site inventory now actively hides work from the sprint that will run it

**This is the finding that matters**, because `FIX-02-20` is in the next cluster and is sized
against this tree.

**Where:** `ROADMAP.md:703-704`.

> `tests/input/input_widget_control_spec.lua` — also used as fixture *text*, which is noise when
> grepping the term and **should not be counted as a citation**.

`FEAT-02` added, in that exact file, a **test description**:

```lua
tests/input/input_widget_control_spec.lua:175:  it('disarming at configure keeps the draft', …
```

An `it(…)` description is BDD contract text — by this feature's own standard (the `FEAT-02-05`
repair, which caught a rule about to be re-filed in a test) **the most durable place there is**. A
reader who trusts the inventory note will discount hits in that file as fixture noise and miss it.

The inventory is dated **2026-08-26** and predates two sprints. Beyond the test description,
`FEAT-02` added "draft" to three corpus files the inventory does not list at all —
`decisions/input.md` (2, in Decision 36's Amendment), `technical_debt/input.md` (2, in
`T-ONESHOT-SCOPE`) and a further `input_api.md` instance (`:272`). Current spread: `input_api.md` 3,
`decisions/input.md` 5, `technical_debt/input.md` 3, `src/` 3, `tests/` 13.

**Nobody did anything wrong** — "draft" is the right word for what the sentences say, and
`FIX-02-20` exists precisely because the ruling has not been made. The defect is that the row's
**sizing note was not updated by the pass that widened it**, and one clause in it is now false.

**Proposed correction:** amend `FIX-02-20`'s inventory — strike the "noise, not a citation" clause
for `input_widget_control_spec.lua` (name the description instead), add the three corpus files, and
date the inventory *2026-08-30* so its next reader knows what it covers.

### F3 — a test comment cites a ruling this sprint superseded, and cites it by roadmap id

**Where:** `tests/input/input_widget_callbacks_spec.lua:511-515`.

> The four edges were ruled at FEAT-01-01 before any of this was written.

Two problems, and `fe076244` **rewrote this comment** at the rename without noticing either:

1. **It no longer resolves to what it meant.** One of those four edges — edge 1, the `show`-only
   ruling — was *superseded by this very sprint*, hours later. A reader sent to `FEAT-01-01`'s
   ruling sheet reads a retired edge as live. This is failure mode two in
   `agents/rules/roadmap.md` §5, *a citation that still resolves, to a heading that no longer means
   what it did*, and §5's *"the pass that causes the orphan is the pass that owes the fix"* puts it
   on `FEAT-02`.
2. **It is a `wip/77` id cited from code.** `agents/validation.md` §*Comment References* requires
   comments to cite canonical `doc/…` and a **named section**, never the feature's ephemeral tree —
   and `agents/rules/roadmap.md` §2's renumber-vs-rename test says the same thing for ids in code.
   `FEAT-02` renumbered its **own** rows the day before, so the hazard is not hypothetical.
   `ROADMAP.md:511` asserts *"No `FEAT-02` id appears in `src/`"* — true, and carefully scoped; a
   `FEAT-01` id in `tests/` is the sibling case it does not cover.

**Proposed correction:** replace the sentence with the canonical citation the comment already
half-carries — *"the edges are ruled in `decisions/input.md`, Decision 36, as amended"* — which
survives both `wip/77`'s deletion and any renumber. **This is the only finding that touches a
tracked file under the comment gate**, so it should land before slice regeneration regardless.

### F4 — the debt entry on duplicated key lists did not notice its own Revisit trigger

**Where (as at review time — the entry has since moved; see §7):** `technical_debt/input.md:160-173`,
*"The config-key list is duplicated across two
modules"*, whose **Revisit** reads *"when either list next changes — that is the moment the
duplication costs something."*

`FEAT-02` did not change `CONFIG_CALLBACKS` or `CALLBACK_KEYS`, so the entry is **not false**. But
it created `WIDGET_KEYS = { 'prompt', 'auto_hide' }` in `consoleController.lua` paired with an
explicit `if cfg.auto_hide` branch in `userInputController.lua`'s `configure_core` — the *same*
accept-here / apply-there split, now in a **second** pair of places and for a **non-callback** key.
The entry's stated failure ("the surface would accept the key and the widget would ignore it") is
now reachable through a list the entry does not name.

**Proposed correction:** widen the entry's **State** to name the `WIDGET_KEYS` ↔ `configure_core`
pair. Not a fix — the discovered-debt rule says report, and the entry already says why it stands.

### F5 — the guide's one list of *what persists* omits the key whose headline is that it persists

**Where:** `doc/input_api.md:349-353`, §*Callback assignments*.

> These entries may also be supplied in `show` or `configure` and persist until replaced:
> `on_text_entered`, `on_limit_reached`, `validator`, and `highlighter`. **`prompt` is not a
> callback, but it persists the same way** — set it once and it stays until you set it again.

`auto_hide` is now a second non-callback key in precisely that position, and the section already
sets the precedent of naming the exception. **Low severity, stated as such:** the guide says the
persistence correctly in three other places (`:111`, `:128-131`, `:266`), so a reader is not misled,
only under-served at the one heading that enumerates it.

**Proposed correction:** add `auto_hide` to the `prompt` sentence. One clause.

### F6 — the roadmap's DONE line drops the last row's commit

**Where:** `ROADMAP.md:452-457`. `-01` through `-04` each carry their hash; `-05` gets *"keeps the
CHANGELOG and the ledger upkeep"* in the present tense and **no hash**, though it landed as
`6d0aa9af`. Nit, but the line is the sprint's audit trail and it stops one row short.

## 5. Checks that came back clean — recorded so they are not re-run

- **Residual `oneshot`.** The in-tree survivors are **exactly** the legitimate set the session
  prompt named and no others: the profiler (7 sites), one pending reserved-combo test, vendored
  metalua, and the two comments in `userInputView.lua` / `userInputModel.lua` that say *"oneshot is
  gone"* about the **base's model argument** — renaming those would make them false. The three
  `doc/mermaid/*` hits are the deliberate deferral (`T-MERMAID-MODEL` / `FIX-02-24`).
- **Key-list completeness.** `auto_hide` is present in every enumeration that should carry it:
  `input_api.md` ×4 (`:111`, `:128`, `:133`, `:162`), `internals/user_input.md` ×2 (`:794` show,
  `:806` configure), Decision 35's ownership table (`:1379`), and `src/types.lua:197` with the
  configure-subtraction comment naming it (`:244-247`). Decision 15 names the show-only three and is
  consistent post-move.
- **Section citations survive the rename.** All 38 `doc/input_api.md` citations from `src/` and
  `tests/` resolve against current headings — including the three that point at *"Asking one
  question"*, which survive because they were written as a **prefix** rather than quoting the
  `— oneshot` suffix. Worth keeping as a habit; it is why the rename cost zero citations.
- **Ledger coherence.** `T-ONESHOT-SCOPE` retired with an accurate resolution; `T-ONESHOT` retired
  **and** carrying an explicit *"read the paragraph above as history, not as behaviour"* rider;
  `T-MERMAID-MODEL` opened with a Revisit trigger that resolves (`FIX-02-24`). All 25 roadmap ids
  cited from the persistent corpus and code resolve in `ROADMAP.md`. `FIX-02-24` and `ACC-02-08` are
  both numbered out of execution order and **both carry the note licensing it**, citing
  `FIX-02-20`'s reasoning at `:688`, which exists and says what they claim.
- **Comment gate.** `grep -rnE 'INTERIM|REMARK|^[[:space:]]*--(->|>)' src/ tests/` returns **nothing**
  (excluding the nested example repos). No `wip/` path is cited from any `.lua` file.
- **Scope discipline — all three extras belong, and the judgement is stated either way.**
  `T-MERMAID-MODEL` + `FIX-02-24` were **found in passing and reported, not fixed**, which is
  `agents/development.md`'s discovered-debt rule executed correctly. The `turtle` conversion and its
  smoke checklist were **owner-directed**, and both are load-bearing rather than decorative: turtle
  is the only in-tree consumer of the key, so it is the sprint's only executable demonstration, and
  its prompt lifecycle moving to the framework is the same class of change that earned `sapper` a
  list. Nothing widened without a reason on the record.
- **Vocabulary.** "arm / disarm" is **not** minted here — it is pre-existing tree vocabulary
  (`re-arm` for guards and hints across `src/examples/`, `technical_debt/input.md`,
  `smoke_checklists.md`, and `input_api.md:749`), so applying it to `auto_hide` reuses a word the
  corpus already carries. "mode" and "widget property" are the owner's own words from the ruling.
  The only vocabulary exposure is "draft" — **F2**, and it was already a filed row.

## 6. Not touched, deliberately

The parked finding stands as the prompt left it: `ROADMAP.md`'s status table cites `FIX-02-01` for a
`doc/`-markers concern with no row anywhere. Not this session's, and not acted on. For the owner's
sizing when they do rule on it: the concern is real and currently **25 `REMARK:` blocks** across
three persistent-corpus documents — `decisions/input.md` (12), `internals/user_input.md` (11),
`tests.md` (2).

---

## 7. Resolution — all six applied, 2026-08-31

The owner ruled *"apply them all"*. One concern per commit, suite **1023 / 0 / 0 / 10** at each.

| # | commit | what changed |
|---|---|---|
| **F3** | `61dc75fe` | `input_widget_callbacks_spec.lua:511` now cites **Decision 36 as amended** instead of `FEAT-01-01`. Done first: it was the only finding in tracked code and the only one under the comment gate. **`src/` and `tests/` now carry zero `wip/77` roadmap ids** |
| **F2** | `712b9ec5` | `FIX-02-20`'s inventory: the *"fixture noise, not a citation"* clause is replaced by the real citation it was hiding (`input_widget_control_spec.lua:175`, a test **description**), the three unnamed corpus files are added, the spread is re-counted, and it is re-dated with an instruction to re-count rather than trust the numbers |
| **F1** | `0b260e1b` | `tests.md`'s manual-smoke paragraph no longer enumerates the detached repos. It scopes by *examples whose input mechanism changed*, points at `smoke_checklists.md` as the list of lists, and says not to re-enumerate — the duplicate copy is what rotted twice |
| **F5** | `160cf9f8` | the guide's *Callback assignments* names `prompt` **and `auto_hide`** as the non-callbacks that persist |
| **F4** | `e3636668`, then `265b714d` | the debt entry first gained the `WIDGET_KEYS` ↔ `configure_core` pair; then, on the owner's ruling, was **promoted BACKLOG → ACTIVE as `T-KEYSET-SPLIT` with a roadmap row (`FIX-02-25`)** — see §8 |
| **F6** | `53d56f6a` | `FEAT-02`'s DONE line gives `-05` its commit (`6d0aa9af`) |

**Two of the six were fixed by deleting a duplicate rather than updating it** (F1's example list,
and F2's inventory clause). Both had rotted because a set was written down in two places and only
one was maintained — the same shape, found twice in one pass. Worth watching for in the defect
sprints, which touch several documents that restate each other.

**Nothing in `FEAT-02`'s delivery was reopened.** All six were rot in the *surroundings* — index
paragraphs, sizing notes, a citation — which is what a delivery-level pass is for and what a code
review would not have caught.

---

## 8. F4, reopened at design level and promoted — `T-KEYSET-SPLIT` / `FIX-02-25`

**Owner ruling, 2026-08-31.** F4 was filed as *reported, not fixed*, and the owner rejected the
framing rather than the finding: **a slug is added when debt is planned for fixing**, so the
question is binary — fix before release or not — and the test is whether it is a code-quality
defect: a source of drift, a readability problem, or something that would raise questions on PR
review. If yes, it moves BACKLOG → ACTIVE, takes a slug, and gets a row.

**Judged yes, and the entry was rewritten rather than moved**, because reading the code closely
showed it described one defect where there are two of different strength:

- **`CALLBACK_KEYS` ↔ `CONFIG_CALLBACKS` — a real list duplication.** Same four strings, both
  loopable, no shared source, each backing a different job: the first the sticky `state.callbacks`
  store the surface merges from (`merge_callback_keys`), the second assignment onto the widget's own
  `self.callbacks`.
- **`WIDGET_KEYS` ↔ `configure_core` — membership duplication, not list duplication.** `prompt` and
  `auto_hide` reach **different destinations** (`model.custom_label`, `self.auto_hide`), so they
  cannot be looped and there is no list to share — only the fact that both calls take them. **F4's
  own wording implied a symmetry that is not there**, which was harmless in a findings report and
  would not have been once the entry read as a work order.

**The defect that justifies the promotion is the silent one-directional failure:** a key added to
the accept side alone is taken by the surface and ignored by the widget, with no raise — the config
table is strictly validated (Decision 15) against a set that does not know what the widget
implements. Same family as `FIX-02-08`/`-09`: one fact stated twice with nothing reconciling the
statements. And it has already drifted in the way that counts — not the values, which have never
diverged, but the shape: `FEAT-02` added an entry on each side and the old entry's *"revisit when
either list changes"* trigger did not fire. **A trigger that depends on someone remembering to look
is what failed here**, which is the argument for a row over a Revisit line.

**Scoped deliberately as *pin the agreement with a test*, not *unify the lists*.** Unifying means
one module importing the other's list across the surface/widget boundary the architecture keeps
separate — larger than the defect, and it would read worse on review than the duplication does. The
refactor is named in the entry as the thing not being done. **No agreement test exists today**
(verified: every key is covered behaviourally and individually; nothing asserts the set is closed),
so the row's work is a few lines, no behaviour change, and it converts an invisible coupling into an
executable one.

**Release scope:** ACTIVE means *resolved before this release ships*, and the row is explicit that
it is **not functional and does not block the release** — it is fixed before the PR because the
question it answers is a reviewer's, not a user's. The test itself is left to the sprint that runs
`FIX-02-25`.
