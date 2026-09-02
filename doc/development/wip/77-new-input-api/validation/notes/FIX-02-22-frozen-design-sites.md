---
description: FIX-02-22's frozen-tree half — the full site inventory, and a recommendation NOT to amend design/
status: RULED 2026-09-02 — `design/` is not amended; see §0
audience: owner
authored: llm
session: 67
date: 2026-09-02
---

# `FIX-02-22` — the frozen `design/` sites, proposed rather than edited

`agents/validation.md` marks `design/` **read, never edit**, and amending it is owner-gated. The
row's disposition is *"fix the documents"*; the persistent-corpus half is done
(`decisions/input.md`, commit `f3a41997`) and the guide now states the rule
(`doc/input_api.md`, `86f73731`). This note is the frozen half, for a ruling.

**The recommendation is to leave `design/` alone.** The reasoning is in §3 and it inverts the row's
implied disposition, so it is stated as a proposal, not applied.

## 0. Owner ruling, 2026-09-02 — `design/` is not amended, on better grounds than §3's

The owner reached the same disposition by a different and stronger route: **§3 argues about where
prose should live; the owner asked whether the rule was ever any good.**

> *"neither of existing known scenarios relies on hiding and restoring widget with exactly same
> text/cursor. If it's ever needed, this could be done in calling project… so we optimized towards
> most common case. Adding support of not-yet-needed and fairly exotic case as first-class scenario
> would complicate the API. So the requirement as originally written is likely useless and
> batch-approved. Therefore it was retired and it's fine."*

Three consequences, all applied:

1. **The requirement is retired, not violated.** The deviation is deliberate and now argued in the
   persistent ledger — `D-CFG-BOUNDARY`, *"Third, content is not preserved across `hide` → `show`
   either"*. That is where a reader who outlives `wip/77` meets it.
2. **`design/spec/M2.md` is out of scope entirely** (owner): it is a historical spec subslice, the
   period's analogue of today's roadmap rows, not a statement of the shipped contract. §1 keeps it
   listed as inventory only.
3. **`design/` is untouched.** Both routes agree, so nothing here is edited.

**The premise was checked in code, and it holds with one gap the ruling now names.** No in-tree
scenario wants restoration: the only two `hide()` call sites (`maze_main.lua:126`,
`draw_main.lua:233`) both abandon the prompt for a menu and want the clearing. The escape hatch is
**half available** — `get_cursor()` exists, and there is **no content getter** on `compy.input`, so
a project cannot save the text today. The ruling states that plainly and names the cheap repair (a
read-only getter) rather than leaving it to be found.

## 1. The inventory is larger than the row says — five sites, and two different claims

The row names two: `design/spec.md:155` and `design/spec.versions/version01.md:191-194`. Sweeping
the frozen tree by sense rather than by the row's list finds **five**, carrying **two** claims. The
second claim is not what the row was filed about, and it is the one already ruled on.

### Claim A — *"`hide()` preserves content for the next `show()`"* (the row's subject)

| site | text |
|---|---|
| `design/spec.md:155` | *"No cancel chain. Content preserved for the next `show()` without `text`."* |
| `design/spec.versions/version01.md:194-195` | *"Input content is preserved (subsequent `show()` will display it unless `text` is provided)."* |
| **`design/spec/M2.md:33`** | *"deactivates without firing the cancel chain; content preserved"* — **not named by the row** |

### Claim B — *"a forced `show` without `text` preserves content"*

| site | text |
|---|---|
| `design/spec.md:149` | *"`force = true` reconfigures in-place (content replaced iff `text` given)"* |
| `design/spec.versions/version01.md:179-180` | *"content replaced if `text` is provided, preserved otherwise"* |
| `design/spec.versions/version01.md:534-535` | *"content replaced if `text` is specified, otherwise preserved"* |
| `design/spec/M2.md:31-32` | *"reconfigures in-place (content replaced if `text` given, else preserved)"* |

Claim B was **reversed deliberately** by `D-CFG-BOUNDARY` statement 4, and
`decisions/input.md:1478-1480` records the reversal **quoting version01's wording verbatim** —
*"which is what the spec approved in round 2 said"*. So the frozen tree and the live ledger already
disagree on the record, on purpose, and the ledger says why.

## 2. What is actually true, since the row states it loosely

The row says *"the code clears it"*. `hide()` does not:

- **`hide()` preserves.** It sets `shown = false` and nils `love.state.user_input`, nothing else
  (`userInputController.lua:375-379`). Pinned: *"a typed character while hidden does not mutate
  it"* — `show{text='keep'}` → `hide()` → type → still `'keep'`.
- **The next `show()` clears.** `open_widget` → `reset_content` → `cfg.text == nil` →
  `model:clear_input()` (`:312-318`, `:330-331`). Pinned: *"a fresh activation with no text is
  empty"*.

So the false half of Claim A is *"for the next `show()`"*, not *"preserved"*. A correction that
simply negated the sentence would itself be wrong.

**`design/spec.md` already contradicts itself twice over:** `:150` says *"Fresh activation with no
`text` starts empty"* and `:224` says it again — five lines above `:155` and sixty-nine below it.

## 3. The recommendation — do not amend `design/`

**A frozen spec is a record of what was ratified, and the value of the record is that it still says
what was ratified.** Three arguments, in order of weight:

1. **Amending it deletes the evidence that a deviation happened.** The rule this phase runs under is
   that a behaviour change is never documented in the commit message alone — it lands in a document
   a reader has open. For Claim B that document already exists and is exact:
   `D-CFG-BOUNDARY` quotes the round-2 sentence and says statement 4 reverses it, with the
   stakeholder's own words as the ground. Rewriting `version01.md:179` to match today would leave
   that decision quoting a sentence that no longer exists anywhere — the citation-that-does-not-
   resolve failure, inflicted deliberately.
2. **Nobody troubleshoots from `design/`.** The half of this row that was worth doing today is the
   half a pass reads: `smoke_checklists.md` and `doc/input_api.md` are what the owner has in hand at
   a sitting, and `decisions/input.md` is what a reviewer opens. `design/` is a frozen input that
   **dies with `wip/77`** — the ruling on deleting the tree is itself still open, and this prose
   cannot outlive it.
3. **`version01.md` is by name a version.** It is the round-2 reviewed text. Editing a document
   whose filename asserts it is a snapshot is a category error independent of what it says.

**If the owner wants the reader protected anyway,** the cheaper instrument is one line at the top of
`design/spec.md` — *this is the ratified input; where it and `doc/development/decisions/` disagree,
the ledger wins* — which is true of the whole tree, needs no per-site surgery, and is a single
owner-gated edit rather than five. That is the fallback, not the recommendation.

## 4. What is left open by taking this route

Nothing in the persistent corpus. The claim is corrected where it is read (`decisions/input.md`,
`doc/input_api.md`), and the frozen sites keep the record of what was approved. **If the owner rules
the other way**, the edit is five sites and two claims, not two sites and one — §1 is the list.

## 5. Two records in the implementation archive, deliberately untouched

`implementation/reviews/M2-01.md:50` and `implementation/prompts/M2.md:72` carry Claim A too. Both
are **dated records** — a review verdict and a prompt of record — and `agents/sessions.md` makes a
booted prompt immutable. They are named here so a later sweep does not read them as missed.
