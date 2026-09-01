# DEC-01-03 — the conversion inventory: numbers → `D-` slugs

**Session65, 2026-09-01.** The map from the decisions ledger's numbers to the names that replace
them, plus the disposition of every retired entry. It supersedes the drafted table in
[`DEC-01-ledger-denoising-spec.md`](DEC-01-ledger-denoising-spec.md), which predates four decisions
and two retirements.

**Two homes on purpose** (owner, 2026-09-01). This file is the **forensic** record — it keeps the
old numbers, the counts, the evidence and the reasoning, and it dies with `wip/77`. `DEC-01-06`
appends a **crosswalk** to the ledger itself: old number → name, one table, no reasoning. That one
outlives the tree, because a reader hitting `Decision 21` in a commit message from August needs the
mapping where the decisions are. The owner has flagged that this file may itself become a victim of
later changes; the ledger appendix is the answer to that, not a duplicate of it.

---

## 1. Sizing, re-derived

The row and the spec were both sized by earlier sessions. Measured at `65281671`:

| quantity | roadmap / spec | measured |
|---|---|---|
| `Decision N` citations in `src/` + `tests/` | 165, 18 files | **222, 20 files** |
| persistent doc files citing a number | ~10 | **14** |
| decision headings | 33 | **37** — 31 ACTIVE, 6 RETIRED |
| slugs to mint / entries to dispose | 29 + 4 | **31 + 6** |
| line-broken mentions | 3, ledger only | **18, across five files** |

**Occurrences in scope after `DEC-01-01`: 554.** The arithmetic of that step: 510 found by a
`Decision N` grep, plus the **18** line-broken citations no such grep could see (→ 528), plus the
26 the plural expansion made explicit (→ 554). The middle term is the one that matters — those 18
were the sites most likely to survive the whole operation silently, which is exactly what the spec
predicted of the three it knew about.

**Scope is `src/`, `tests/`, `doc/` outside `wip/`, and `agents/`.** The last is an addition to the
row's stated scope: `agents/rules/commenting.md` (4) and `agents/validation.md` (1) cite decisions
by number and are not under `wip/`, so they would dangle. The three nested example repos cite none —
checked, not assumed.

## 2. The heading format — already ruled, no owner decision owed

The spec left one question open: how the slug is declared. **It is answered by a standing rule the
spec did not have.** `agents/rules/ledgers.md` §3 defines the debt register's `T-` slug as *"same
shape as the decisions ledger's `D-SLUG` — uppercase mnemonic, 16 characters at most, **declared
first in the heading with the prose after**"*. The convention was written naming this ledger as its
model, so the format is settled:

```markdown
## D-COMBO-TABLES — per-event combo tables and canonical combo serialisation
```

The word *Decision* leaves the headings with the numbers. That is what makes the terminal gate
(`grep -c 'Decision [0-9]'` = 0) reachable rather than approximate.

**Namespace checked clean:** no `D-[A-Z]` token exists anywhere in scope today except the rule's own
description of the convention, and the dead `D-1…D-10` design namespace does not leak out of `wip/`.
One regex separates them for good: letters here, digits there.

## 3. The ACTIVE 31 — the conversion map

Slugs marked **new** are minted here; the rest are the spec's draft, checked against each heading as
it reads today. *Cites* counts `src/` + `tests/` only — the sweep's risky half.

| old | slug | heading prose | cites |
|---|---|---|---|
| 1 | `D-ROUTE-OWNS` | routing is route-centric, not widget-centric | 19 |
| 2 | `D-CHAIN-OF-3` | a three-component chain with truthy-consume | 18 |
| 3 | `D-WIDGET-AT-BOOT` | a boot-provisioned widget per surface, not per-session construction | 16 |
| 4 | `D-NO-POLLING` | callbacks replace polling | 0 |
| 5 | `D-TWO-SURFACES` | two directions, two surfaces; the limit signal travels the output side | 15 |
| 6 | `D-NO-FW-TIER` | submit and cancel are widget-owned flows, not a framework tier | 20 |
| 7 | `D-FROZEN-SHELL` | freeze the container and its sub-table identities; leaves are writable | 11 |
| 8 | `D-COMBO-TABLES` | per-event combo tables and canonical combo serialisation | 15 |
| 10 | `D-HOOKS-SEEDED` | one `hooks[event]` table, seeded once at activation | 17 |
| 11 | `D-ROUTE-LIFETIME` | the route is held by an open project, released at its stop | 25 |
| 14 | `D-DEFACTO-KEPT` | de-facto contracts: reverse-engineered behaviour is preserved and formalised | 1 |
| 15 | `D-UNKNOWN-RAISES` | unrecognised show/configure configuration raises | 8 |
| 17 | `D-BEHAVIOUR-TEST` | behavioural evidence is the default test evidence | 1 |
| 18 | `D-ONE-STATE-ASK` | the widget answers one state question, `is_shown()` | 1 |
| 21 | `D-COMBO-SHAPE` | a combo names modifiers plus one trigger, or a class | 8 |
| 22 | `D-IGNORE-REPEAT` | `compy.input.fn.ignore_repeat` | 2 |
| 23 | `D-NO-LOG-NOISE` | an unhandled event is not logged | 2 |
| 24 | `D-STOP-AND-SIDE` | `compy.input.fn.stop_here` and `.side_run` | 2 |
| 25 | `D-ONE-LIFETIME` | one route, one chain, one lifetime for every input channel | 0 |
| 26 | `D-LOVE-ARGS` | every consumer receives LÖVE's own argument list | 2 |
| 27 | `D-BUTTON-TRIGGER` | one combo vocabulary, with the button as a trigger | 0 |
| 28 | `D-STOP-IS-FW` | stopping is the framework's; the project's hook runs inside it | 0 |
| 30 | `D-ASK-THE-DEVICE` | modifier state is read from the device; `keys_pressed` is dissolved | 3 |
| 31 | `D-THREE-MODS` | the modifier set is closed, and it is `ctrl`, `alt`, `shift` | 1 |
| 32 | `D-USAGE-SHAPE` | how the input API is meant to be used | 0 |
| 33 | `D-EXACT-RESERVE` | a framework reservation matches its modifier set exactly | 1 |
| 34 | `D-RESERVE-TABLE` | the gate's reservations are combo strings in a privileged table | 2 |
| 35 | `D-CFG-BOUNDARY` **new** | the configuration boundary: the user's content is `show`'s alone | 20 |
| 36 | `D-AUTO-HIDE` **new** | `auto_hide`: a widget that closes itself on submit | 12 |
| 37 | `D-PAYLOAD-SPLIT` **new** | the submit callbacks are told apart by their payload | 2 |
| 38 | `D-CONTENT-NORM` **new** | content is normalised so the cursor address is unambiguous | 3 |

**19 does not exist** — the ledger already had a gap. Naming makes that permanent and harmless,
which is the shape of the whole argument.

**The four new slugs, and why each reads as it does.** `D-CFG-BOUNDARY` deliberately mirrors the
debt goal `T-CFG-BOUNDARY` that the `ARC-02` sprint was fulfilling, so the decision and the debt it
paid share one word. `D-AUTO-HIDE` names the key, which is what a reader of the citation site is
looking at. `D-PAYLOAD-SPLIT` takes the roadmap's own name for the change rather than
`D-SUBMIT-PAYLOAD`, which sits exactly on the 16-character cap. `D-CONTENT-NORM` says what is
normalised; the *why* (an unambiguous cursor address) is the heading's job and does not fit a slug.

**All 31 are within the 16-character cap.** The longest are `D-WIDGET-AT-BOOT`, `D-ROUTE-LIFETIME`,
`D-UNKNOWN-RAISES`, `D-BEHAVIOUR-TEST`, `D-BUTTON-TRIGGER` and `D-ASK-THE-DEVICE`, all exactly 16.

## 4. The RETIRED six — dispositions for `DEC-01-04`

The gate is `agents/rules/ledgers.md` §2: **only entries that were not the stakeholder's may be
vacuumed**, and citations must still resolve. Under naming a removed entry dangles visibly and greps
out, so the second condition is satisfied structurally — which is why the removal is safe to run
here rather than after the substitution, as the owner ruled on 2026-08-27.

**One measurement decides most of this.** Of the six, **only Decision 12 is cited from `src/` or
`tests/`** — seven times, exactly as its own body claims. The other five have **zero** code
citations; they are cited only from within the ledger.

| old | cites (code / ledger) | provenance | recommendation |
|---|---|---|---|
| 9 | 0 / 1 | ours — a signature-uniformity ruling superseded in full by 26 | **remove** |
| 12 | **7** / 4 | ours, and its own heading says *NOT A DECISION* | **remove the entry, rehome the content** — see below |
| 13 | 0 / 4 | ours — the read-only held-key view, superseded by 30 | **remove** |
| 16 | 0 / 1 | **contested — see below** | **owner ruling wanted** |
| 20 | 0 / 6 | ours — an owner ruling of 2026-08-03 | **remove, after rehoming the `keys_pressed` description** |
| 29 | 0 / 3 | ours — superseded in full by 30 | **remove** |

### Decision 12 — the one with code citations, and the one that was never a decision

Its body already states its own disposition: *"The narrative belongs to `internals/user_input.md`;
this entry exists for the citations."* The entry is kept alive by seven comments and by nothing
else, and the reason it gives — *decisions are cited by number* — **is the thing this sprint is
abolishing.** Once citations carry names, the entry has no remaining job.

**Recommended:** move the behaviour paragraph into `internals/user_input.md` (where the entry itself
says it belongs), delete the ledger entry, and re-point the seven comments at that section by name.
They are `main.lua:362`, `controller.lua:630`, `input_route_lifecycle_spec.lua` at `:20`, `:36`,
`:427` and `:445`, and `input_widget_control_spec.lua:821` — the two in `controller.lua` and
`input_widget_control_spec.lua` both about the suspended project's widget staying unhonoured.
**This is the only one of the six that costs work beyond a deletion**, and it is the one
where leaving the entry standing would preserve a heading that says it is not a decision inside a
ledger of decisions.

### Decision 16 — the one with a stakeholder claim

**It traces to a stakeholder gate, and that is why it is not mine to sweep.** Its content is the
**Gate-2 closing ruling of 2026-07-06** — *"no further architectural simplification/unification is
pursued in this pass"* — recorded in the frozen design at `design.md:114-118` and `roadmap.md:29-31`,
both of which name the console/editor migration as *"the designated venue for the next round, with
stakeholder input"*.

The retirement note splits the ruling in two and only one half is superseded:

- the **event axis** was unified after all — `hooks.singleclick` / `hooks.doubleclick` are ordinary
  events (25) and every pointer channel runs the same dispatch (27);
- **routing** across console, editor and project is **still deferred**, and that live half is
  Decision 1's, not this entry's.

So the question for the owner is not *is it retired* — it is — but **whether a scope ruling made at
a stakeholder gate is a record that stays even when superseded**. My reading is that it stays, on
§2's plain words, and that the cost of keeping it is one heading. **Recommended: keep, and rewrite
the heading to say which half was superseded**, since a reader taking *"unification is deferred"*
from the heading alone gets the wrong half — the retirement note already says so and the heading
still does not.

### Decision 20 — the content that must not go with it

`DEC-01-04`'s standing question. Decision 20's body is **the last full description of
`compy.input.keys_pressed`**, a member that no longer exists: the read-through/write-raise contract,
the placement argument, and the note that iteration is inert on the shipping LuaJIT runtime.
Deleting the entry deletes the record of what the member was and why it went.

**Recommended:** the history moves into `D-ASK-THE-DEVICE` (old 30), which is what dissolved it, as
a short *"what it replaced"* paragraph — not into a successor's *Why*, because 30's *why* is about
the device, not about the member. The `examples/keyboard` consumer story that settled it is the part
worth keeping; the placement argument is not, since the placement no longer exists.

## 5. What is left for the owner

1. **Decision 16 — keep as stakeholder record, or vacuum?** Recommendation above: keep, with a
   corrected heading. It is the only one of the six where §2's stakeholder condition bites.
2. **Any slug that displeases.** The four new ones are the ones with no prior review. Renaming any
   of them is a grep-and-substitute over this table before `DEC-01-05` runs, and costs nothing
   while the substitution has not started.
3. **The `agents/` extension to scope** — 5 citations that would otherwise dangle. Stated because
   the row's scope line does not mention it.

Nothing here is executed. `DEC-01-04` acts on §4, `DEC-01-05` on §3.
