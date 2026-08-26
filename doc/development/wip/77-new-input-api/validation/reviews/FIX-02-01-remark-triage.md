# FIX-02-01 — triage of the surviving `> REMARK:` blocks in the persistent docs

**Triage only, nothing fixed** (owner, 2026-08-26).

> **COUNT CORRECTED TWICE — the real figure is 37 blocks across 12 files.** First reported as 10,
> then 14, now 37. **Both earlier counts came from piping `grep` to `head`** — the same mistake
> made twice in one session, recorded here rather than quietly fixed, because it is the mechanism
> that hid the defect in the first place and it will hide the next one.

| file | blocks | |
|---|---|---|
| `doc/development/decisions/input.md` | 12 | triaged in detail below |
| **`doc/development/internals/user_input.md`** | **11** | **the A-doc — `validation.md`: *"stakeholders are pointed at it from the PR"*** |
| `doc/development/tests.md` | 2 | triaged below |
| `doc/development/internals/project_sandbox_env.md` | 2 | **untriaged** |
| `doc/development/internals/event_dispatch_layers.md` | 2 | **untriaged** |
| `doc/development/internals/examples/repl.md` | 2 | **untriaged** |
| `CHANGELOG.md` | 1 | **above the H1** — see CHG-01 |
| `doc/development/technical_debt/general.md` | 1 | **untriaged** |
| `doc/development/internals/examples/{tixy,balloons,turtle,guess}.md` | 1 each | **untriaged** |

**All twelve ship** — in slice `3a` or Set 1. **23 of the 37 are not yet triaged**; the detail below
covers `decisions/input.md` and `tests.md` only.

**The gate's blind spot is wider than `doc/`.** It greps `src/` and `tests/`, so it misses
*everything else in the tree* — including `CHANGELOG.md` at the repo root, which no `doc/` sweep
reaches either. Widening it to `doc/` alone would still have missed the CHANGELOG.

## Why these survived, precisely

They are **not** un-inventoried. Every one was captured by the TF2 review pass (`9cc0ef50`,
2026-08-07) and appears in the 187 — the `doc/` section of `S27-remark-inventory.md` runs
**R080–R109** plus **R166**, and several already carry a triage verdict (R080's is recorded in
`S27-triage-and-plan.md`: *"S1, and I recommend declining for this release"*).

**So TF2 did its job on the content. What failed was the removal pass, and then the check.** Most
of the `doc/` blocks were taken out; these 14 were not, and nothing caught it because **the marker
gate greps `src/` and `tests/` only**. P11 reported the gate clean and was *correct* — `doc/` was
never in its scope. The gate's scope was the defect, not the report.

**That is also why "nothing remains" was said and was wrong.** The statement was true of the gate
and false of the corpus. Widening the gate to `doc/` is the standing half of this row, and it is
worth doing whatever is decided about the 14 below.

## The verdict, up front

**None is stale.** Every target these remarks complain about still exists in the shipping text —
verified by grep, counts below. One is a design question already ruled; the other thirteen are
live and unaddressed.

| disposition | count |
|---|---|
| design question, **already ruled** — record the ruling, drop the block | 1 |
| **live**, editorial — the prose still says what the remark objects to | 11 |
| **live**, rule-shaped — an owner principle stated twice, applies file-wide | 2 |

---

## The one already ruled

### R080 — `decisions/input.md:109` — "why treat the widget specially?"

> *"any real reason to treat widget specially? … I see no reason to treat widget separately — and
> if we discard decision 5, codebase change would be minimal and won't change any behaviour"*

**Already dispositioned in `S27-triage-and-plan.md`:** split from R086, classified **S1**, with the
recommendation to **decline for this release**. The triage also notes the block's own confusion —
its text is attached to Decision 2 but reasons about discarding Decision 5.

**Action: none to the design.** Record the standing ruling where the reader can see it and remove
the block. **This is not a re-opening**, and the ruling is the owner's to reaffirm or revisit.

---

## Live and substantive — take these first

### `decisions/input.md:153` — an internal contradiction, still present

> *"this contradicts with formula few paragraphs before (supposedly stale) that says widget state
> is 'checked at the end of chain, and bypassed if not shown' — which was fully unnecessary
> complication hopefully dissolved since then"*

**Verified: both phrases are still in the file** — `"checked at the end"` ×1 and `"bypassed if not
shown"` ×1. So a shipping decisions ledger states the widget's hidden-check two incompatible ways.
**Highest value of the fourteen**: it is not a wording preference, it is a document contradicting
itself about a load-bearing behaviour, in the file a stakeholder reads to understand what was
decided.

### `decisions/input.md:327` — the combo-table rationale is inverted

> *"'combo-tables' are reproduced without explanation. Instead the solution was to support
> combo-tables at all (to avoid stuffing all event-handling logic in a single hook and enable
> modularity). The way combo tables are assembled and checked is downstream tactical decision …
> the full block has to be rewritten"*

Not editorial: the remark says the entry documents the *mechanism* while omitting the *reason*, and
that the reason is the modularity argument. A decisions ledger that records how without why is the
failure that ledger exists to prevent.

### `decisions/input.md:398` — Decision 10 reframed

> *"reframe as 'new api has more appropriate place for hooks — so we silently re-wire old
> project-installed callbacks there — encouraging new usage but not disabling old one, if it's
> ever needed for pedagogical purposes"*

A reframing of intent, and the pedagogical clause is a stakeholder-facing rationale the current
text does not carry.

---

## Live, editorial — the prose still says what is objected to

Each verified as still present:

| line | objection | target still in file |
|---|---|---|
| 140 | *"de-facto SDL articat" is vague and its relevance unclear* | **yes** (×2) |
| 188 | *"input events" conflates inbound events with submission; rewrite the Decision 4 opening* | yes |
| 208 | *use **callbacks**, not "widget outputs", which are defined nowhere* | **yes** (×2) |
| 222 | *conflating them is not generally a trap — drop the false rationalisation, just say we distinguish* | yes |
| 223 | *too much self-invented explanation, including the 'student' passage* | **yes** (×2) |
| 512 | *Decision 14's first phrase is historically inaccurate — the decision itself stands* | yes |
| `tests.md` 65 | *ephemeral archeology; describe the current state, not where it lived mid-implementation* | yes |
| `tests.md` 66 | *actualize file/tag/line references — and first ask whether they are needed at all* | yes |

`tests.md:66` carries a verification task, not only an edit: the references must be **checked**
before being kept or dropped.

---

## Live, rule-shaped — one principle, stated twice

### `decisions/input.md:429` and `:749`

> *"clean up self-arguing with past decisions that were then reshaped before release. What was not
> in released version is considered as never existing (except few bits explicitly ratified by
> stakeholders)"*
>
> *"historical references (when exactly was something decided) bear no value, strip them"*

**`:429` is also Phase L's item 2** — *"remove Decision 11's withdrawn-rationale audit trail"* —
arriving from a second source. Retiring Phase L therefore loses nothing: the item is this row.

**A trap in how `:429` gets executed.** The passage it sits on contains **two paragraphs, and only
one should go.**

- *"Why the original rationale was withdrawn"* — **remove.** It quotes and argues against a draft
  justification that never shipped, which is exactly what the owner's rule retires.
- *"Changed baseline behaviour"*, immediately after — **KEEP.** It records a real deviation from
  **pre-feature** behaviour: a running project without its own keyboard handler used to leave the
  console callback installed, so unhandled input accumulated in the hidden console and Enter could
  evaluate it. That is the plan's own "deviation from pre-feature functionality" category, and
  sweeping the block wholesale would take it.

**One fact inside the removed paragraph is worth not losing**, though it need not stay here: the
keyboard/pointer asymmetry was **introduced by this feature, not inherited** — `release_keyboard_route`
did not exist at the PR base. That is precisely the error `conventions/docs.md`'s *"de-facto
behaviour has a boundary"* rule was written to prevent, so the lesson is already generalised; only
the instance is being deleted.

**These are not two local edits — they are one owner principle applying to the whole file**, and
they overlap the parent plan's existing row to excise decisions that were established and then
collapsed within this feature. Treat them together with that row, or the file gets swept twice by
two rules that disagree at the edges.

**A caution before anything is stripped.** The ledger's supersession markers are *not* the target
here. Decisions 13, 20 and 29 correctly carry `SUPERSEDED by Decision 30` in their headings, and
16, 12 and 11 carry their own — **that is the ledger working**, and their `keys_pressed` mentions
(16 in the file) are legitimate historical record, not references to a live member. I checked
specifically because the same retired name was the PR description's blocker; here it is properly
tombstoned. **Do not let "strip the history" delete the supersession trail.**

---

## Recommended order

1. **Widen the marker gate to `doc/`** — independent of everything below, and the reason this
   recurs.
2. **`:153`**, the self-contradiction — a shipping doc that disagrees with itself.
3. **`:327`**, **`:398`** — substance, not wording.
4. **The 8 editorial rows** — one pass, cheap.
5. **`:429` + `:749`** — with the parent plan's collapsed-decisions row, not separately.
6. **R080** — record the standing ruling, drop the block. Owner's to reaffirm.
