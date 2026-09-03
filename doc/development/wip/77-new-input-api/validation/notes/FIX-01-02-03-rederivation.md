---
description: FIX-01-02 and FIX-01-03 re-derived at HEAD — four classes, and the fourth is a sizing question for the owner
status: active
audience: developer
authored: llm
session: 69
date: 2026-09-03
---

# `FIX-01-02` / `FIX-01-03` — what the persistent corpus actually cites

Both rows carried counts from earlier passes (`~12 sites` and `4 sites`).
Neither survives re-derivation, and the interesting part is not that they grew
— the prompt predicted that — but that the grep splits into **four classes with
three different owners**.

**Corpus** = everything under `doc/` that is not under `doc/development/wip/`,
plus `src/`, `tests/`, `CHANGELOG.md`. Derived at HEAD 2026-09-03.

## A — ephemeral **paths** (20 sites, 4 files) — `FIX-01-02`, uncontested

The convention names this one directly (`conventions/docs.md`, *Rules*: *"cite
canonical docs (`doc/…`), never a feature's ephemeral working tree"*).

| file | sites |
|---|---|
| `decisions/input.md` | `:1777`, `:1853` — both to `validation/archive/decisions-vacuumed.md` |
| `smoke_checklists.md` | `:8`, `:37`, `:165`, `:177`, `:287`, `:559` |
| `technical_debt/general.md` | `:96`, `:154`, `:354`, `:414`, `:416`, `:417`, `:418`, `:436`, `:443`, `:459` |
| `technical_debt/input.md` | `:1557`, `:2046` |

**The earlier `~12` undercounted by construction, not by drift:** it was derived
from a `wip/` grep, and eight of these twenty are written **relative**
(`validation/outcomes/…`, `ROADMAP.md`, `plan.md`) and never contained the
string. *A path citation does not have to spell the path.*

**Five of the twenty are not repointing work.** `general.md:414`–`:443` are debt
entries whose **subject is a file inside `wip/`** — a defect in the roadmap, a
duplicate table in `plan.md`. Repointing them is meaningless; they are
`LEDGER-02`'s call (*introduced-then-paid never existed for the outer world*),
and this row should hand them over rather than invent a canonical target.

## B — session numbers (12 sites, 3 files) — `FIX-01-03`, uncontested

`decisions/input.md:747`, `:1163`, `:1164`; `technical_debt/general.md:459`;
`technical_debt/input.md:407`, `:1515`, `:1756`, `:1779`, `:1792`, `:1809`,
`:1818`, `:2626`.

Was **4** when counted. It is 12 because sessions kept writing their own number
into the ledgers they amended — including **this session**, at
`technical_debt/input.md:1515`. The row's subject grows from the same act that
would close it, which is `FIX-01-01`'s lesson repeating.

Each carries a date already, so the fix is subtraction, not translation.

## C — the `FR-n` namespace (7 sites, 2 files) — `FIX-01-02`, uncontested

`decisions/input.md:194`, `:203` (FR-3/FR-4); `internals/user_input.md:199`,
`:200` (FR-1), `:413`, `:415`, `:424` (FR-6). Two of the seven are the owner's
own `REMARK`s asking for exactly this, so answering them retires the markers
too.

These are development-time requirement ids from a document the release does not
ship. The ask on the remark is not "delete the reference" but **"explain the
essence to a cold reader"** — the requirement text has to be inlined, not
dropped.

## D — roadmap and sprint ids (**119 occurrences**) — **not sized by any row**

`FIX-02-05` (11), `FEAT-02` (11), `BUG-02-01` (11), `FIX-02-01` (6),
`LEDGER-02` (4) and ~50 more, spread over `technical_debt/input.md` (53),
`technical_debt/general.md` (41), `decisions/input.md` (12),
`smoke_checklists.md` (11), and one each in `internals/user_input.md` and
`internals/examples/turtle.md`.

**This class is a question, not a task, and it is the owner's.** Three reasons
it is not simply "the rest of `FIX-01-02`":

1. **No rule covers it.** `conventions/docs.md` bans ephemeral **paths**. A bare
   `FIX-02-05` is not a path; it is a token that happens to resolve only inside
   `wip/`. Sweeping it is an *extension* of the rule, and extending a rule to
   ten times the row's size is the "solutions that significantly expand
   commitment scope" flag in `agents/validation.md`.
2. **It is not the same defect as `FIX-03-05`.** That row wipes citations of
   **retired** ids. These are citations of **live** ones — correct today,
   dangling the moment `wip/77` is deleted. Related, differently owned.
3. **Measuring it now measures the wrong tree.** `LEDGER-02` and `DEC-02` vacuum
   entries out of these very ledgers, and a vacuumed entry takes its ids with
   it. A sweep run before them sweeps prose that is about to leave.

**Recommendation:** leave D out of `FIX-01`, close `FIX-01-02` and `-03` on A/B/C,
and let the owner decide between (i) a rule in `conventions/docs.md` that
extends the citation ban to ephemeral **ids**, swept once after `LEDGER-02` and
`DEC-02` — the sweep `FIX-03` is already positioned for; or (ii) accepting id
citations as historical bookkeeping in the ledgers, on the argument that a
ledger entry naming the sprint that paid it is a **record**, not a pointer, and
a reader who cannot resolve `FIX-02-05` has lost nothing they needed.

Either answer is cheap **now** and expensive after the slices are cut.
