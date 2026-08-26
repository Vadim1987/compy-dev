# DEC-01 — de-noising the decisions ledger

**Owner request, 2026-08-26**, revised the same day. Specification only; nothing executed. **Runs
before the next slice cut**, so the ledger a reviewer reads is the clean one.

> ## SUPERSEDED APPROACH — renumbering (kept below, do not execute)
>
> The first specification removed the tombstones and renumbered the survivors to a gapless 1–29,
> using the owner's sentinel-wrapping algorithm. **The owner then proposed abandoning numbers
> altogether and calling decisions by name.** That is the better answer and it is now the plan;
> the renumbering spec is retained below because its survey, its hazards and its gate all still
> apply to a name migration, which is the same sweep with a different target.

## Recommended: names, not numbers (owner proposal, 2026-08-26)

**Endorsed, and the safety argument is the decisive one — not the tidiness one.**

**A missed citation fails safely under naming and dangerously under renumbering.** This is the
whole case:

| | a citation the sweep misses |
|---|---|
| **renumbering** | still reads `Decision 8`, which **still exists and now means something else** — silently wrong, and reads as authoritative |
| **naming** | still reads `Decision 8` when no numbers exist — **visibly dangling**, and greppable |

Renumbering makes the failure mode invisible; naming makes it loud. With **165 citations in `src/`
and `tests/`** to sweep, that difference decides it.

**It also dissolves two problems rather than solving them.** A removed decision's name is simply
not reused — there is no gap to explain and nothing to renumber. And inserting a decision disturbs
nothing, so the ids stop drifting **permanently**, rather than being re-flattened after every
removal. Renumbering is a cost paid *every time*; naming is paid **once**.

### Two facts that make it cheap, and one that constrains it

**Every heading already carries a name.** `## Decision 8 — per-event combo tables and canonical
combo serialisation`. The names are not invented, they are **promoted** — a lookup-and-substitute
job, not an authoring one.

**Citation sites are mostly bare, though.** In `src/` and `tests/` they read `Decision 30`,
`(Decision 21`, `Decision 11's teardown` — the owner's *"corpus and comments already kinda
annotate them"* holds for **headings**, not for citations. So the sweep must supply the name at
each site; it cannot just delete the number.

**The constraint — full names will not fit inline.** Measured:

| | |
|---|---|
| heading names | min 25, **median 52**, max 98 chars |
| `src`/`tests` lines already carrying a citation | **median 59**, max 66 — against a **64-char hard limit** |

Substituting a 52-character name into a 59-character line is not close. **So citation uses a short
kebab slug, not the full name**, and the full name stays as the heading's prose.

### The one decision the owner owes

**How the slug is declared.** Recommended:

```markdown
## combo-tables — per-event combo tables and canonical combo serialisation
```

— slug first, prose after. Citations then read `(see combo-tables)`, about 20 characters, which
fits comfortably and **says what it is about at the point of use**, which `Decision 8` never did.
That is the real win beyond safety: a reader no longer has to leave the code to learn what the
citation means.

The alternative — keep the prose heading and declare the slug on its own line — is also workable
and keeps headings reading as sentences, at the cost of one more line per entry and a slug that is
not visible in a table of contents.

### The slug convention (owner, 2026-08-26): `D-MNEMONIC`

Short uppercase mnemonics on a `D-` prefix — the owner's `D-BE-GOOD` / `D-NO-HARM` shape.

**Why the prefix earns its two characters:** it makes the whole class greppable (`grep -rn
'\bD-[A-Z]'`), and it **cannot be confused with the dead `D-1…D-10` design namespace** in `wip/`,
which is digits where these are letters. One regex separates them for the rest of time.

**Budget the length.** `Decision 8` is 10 characters and `Decision 21` is 11; the slugs below
average ~14. That is **+3 to +4 characters at every citation site**, against lines with a median of
59 and a max of 66 in a 64-char limit — so **some citation lines will need reflowing**, and a few
already exceed the limit today. Slugs are therefore capped at **16 characters**. Reflow the affected
lines in the same commit as the substitution for that file, never later.

### DEC-01-03 — the inventory, drafted

**29 survivors, 4 removals.** Proposed slugs; the owner edits freely — this exists to be argued
with, not approved silently.

| old | slug | what it says |
|---|---|---|
| 1 | `D-ROUTE-OWNS` | routing is route-centric, not widget-centric |
| 2 | `D-CHAIN-OF-3` | a three-component chain with truthy-consume |
| 3 | `D-WIDGET-AT-BOOT` | a boot-provisioned widget per surface |
| 4 | `D-NO-POLLING` | callbacks replace polling |
| 5 | `D-TWO-SURFACES` | two directions, two surfaces; the limit signal travels the output side |
| 6 | `D-NO-FW-TIER` | submit and cancel are widget-owned, not a framework tier |
| 7 | `D-FROZEN-SHELL` | freeze the container and sub-table identities; leaves writable |
| 8 | `D-COMBO-TABLES` | per-event combo tables and canonical serialisation |
| 9 | `D-ISREPEAT` | uniform signatures and `isrepeat` threading |
| 10 | `D-HOOKS-SEEDED` | one `hooks[event]` table, seeded once at activation |
| 11 | `D-ROUTE-LIFETIME` | held by an open project, released at its stop |
| 12 | `D-INSPECT-ROUTE` | `inspect` is a mode-to-route line — **see the note below** |
| ~~13~~ | — | **REMOVE** — superseded by 30 |
| 14 | `D-DEFACTO-KEPT` | reverse-engineered behaviour is preserved and formalised |
| 15 | `D-UNKNOWN-RAISES` | unrecognised show/configure configuration raises |
| ~~16~~ | — | **REMOVE** — superseded by 25 and 27 |
| 17 | `D-BEHAVIOUR-TEST` | behavioural evidence is the default test evidence |
| 18 | `D-ONE-STATE-ASK` | the widget answers one state question, `is_shown()` |
| ~~20~~ | — | **REMOVE** — superseded by 30 |
| 21 | `D-COMBO-SHAPE` | modifiers plus one trigger, or a class |
| 22 | `D-IGNORE-REPEAT` | `compy.input.fn.ignore_repeat` |
| 23 | `D-NO-LOG-NOISE` | an unhandled event is not logged |
| 24 | `D-STOP-AND-SIDE` | `fn.stop_here` and `.side_run` |
| 25 | `D-ONE-LIFETIME` | one route, one chain, one lifetime for every channel |
| 26 | `D-LOVE-ARGS` | every consumer receives LÖVE's own argument list |
| 27 | `D-BUTTON-TRIGGER` | one combo vocabulary, with the button as a trigger |
| 28 | `D-STOP-IS-FW` | stopping is the framework's; the project's hook runs inside it |
| ~~29~~ | — | **REMOVE** — superseded by 30 |
| 30 | `D-ASK-THE-DEVICE` | modifier state is read from the device; `keys_pressed` dissolved |
| 31 | `D-THREE-MODS` | the modifier set is closed: `ctrl`, `alt`, `shift` |
| 32 | `D-USAGE-SHAPE` | how the API is meant to be used |
| 33 | `D-EXACT-RESERVE` | a reservation matches its modifier set exactly |
| 34 | `D-RESERVE-TABLE` | reservations are combo strings in a privileged table |

**19 does not exist** — the ledger already had a gap, which is precisely the condition naming makes
permanent and harmless.

**A fifth removal candidate, for the owner.** Decision 12's own heading says *"`inspect` is a
mode-to-route line — **NOT A DECISION, de-facto behaviour**"*. By the convention document's own rule
(*behaviour that predates the feature and is merely written down does not deserve a ledger entry*)
it should not be in the ledger at all — it belongs in an internals guide. **Ruling wanted:** remove
it as a fifth, or keep it with the disclaimer. It is listed above with a slug so the count works
either way.

### What carries over unchanged from the renumbering spec

Everything below still applies, because a name migration is the same sweep aimed differently:

- **The gate at step 2.** Wrap first, prove no bare `Decisions?` survives anywhere in scope, and
  only then substitute. Completeness is established *before* anything is rewritten.
- **The 3 line-broken mentions**, joined as their own commit first.
- **Case and plural variants** — `Decisions 25 and 27`, lower-case `decision 5`.
- **`wip/` is out of scope** — frozen history, plus its own dead `D-1…D-10` namespace.
- **The crosswalk is a deliverable**, appended to the ledger: old number → name. It is needed
  *more* under naming, since commit messages and `wip/` cite numbers that will exist nowhere.
- **The four tombstones still go**, and Decision 20's body is still the last full description of
  `compy.input.keys_pressed` — decide per entry whether that history moves into a successor.

**One thing gets simpler:** step 5 no longer renames one id at a time to avoid collisions. Names do
not collide with numbers, so the substitution can be done in one pass per file once the wrap is
proven complete.

---

# Retained: the superseded renumbering specification

## The survey

| | count |
|---|---|
| decision headings in the ledger | **33** |
| highest number in use | **34** (so the sequence already has a gap) |
| tombstoned headings (`SUPERSEDED`) | **4** — Decisions **13, 16, 20, 29** |
| `Decision N` mentions inside the ledger | 117 |
| `Decision N` citations in `src/` + `tests/` | **165**, across 18 files |
| `Decision N` citations in the persistent docs | ~10 files |
| `Decision N` citations in `wip/` | 1328 — **out of scope, see below** |

**Result of the operation:** 33 entries minus 4 tombstones = **29**, renumbered to a gapless
**1–29**.

## The hazard that governs the whole job

**A missed citation does not dangle — it silently points at a different, existing decision.** This
is the opposite of the usual rename failure and it is worse: a dangling reference is visibly broken,
whereas a citation that now names Decision 13 when it meant the old Decision 16 reads as
authoritative and is wrong. It is the session45 lesson (*a dangling citation is worse than none*)
with the stakes raised.

**Therefore the gate is at step 1, not at the end.** Once every occurrence is wrapped in a sentinel,
the rest is mechanical and safe. So:

> **After wrapping, `grep -rnE '(^|[^-])\bDecisions?\b' <scope>` must return only sentinel-wrapped
> hits. A single bare occurrence stops the job.**

Verifying completeness *before* renaming is what makes the remaining steps unable to go wrong.

## Three hazards the algorithm does not address by itself

### 1. Line-broken mentions — the owner anticipated this, and it is real

**3 confirmed in the ledger**, where the wrap put the number on the next line:

```
… the chain reports not-consumed (Decision
30) …
```

`decisions/input.md` lines **117**, **230**, **1444**. Exact matching cannot see these, and they are
the ones most likely to survive the whole operation silently.

**Handle first, as its own committed step:** join them so no `Decision` ends a line, verify with
`grep -cE 'Decision$'` returning **0** across scope, and commit *that* before wrapping starts. A
reflow that happens during a rename is a diff nobody can read.

### 2. Case and plural variants

- **Plural:** `SUPERSEDED by Decisions 25 and 27` — one mention, two ids.
- **Lower-case prose:** `decision 5` ×4 and `decision 2` ×3, which an exact `Decision N` match
  misses entirely.

Normalise both before wrapping, or wrap patterns that cover them.

### 3. `wip/` is a different namespace and must NOT be renumbered

Two reasons, and they compound:

- **`wip/` is frozen history.** Renumbering the reasoning trail would make it describe a debate that
  never happened under those numbers.
- **`wip/` also carries `D-1`…`D-10`**, a *separate* design-time id scheme living only in
  `design/spec.md` and its neighbours — **1328 hits, none of them in the persistent corpus or in
  code.** It dies with the tree. Do not conflate the two namespaces; do not sweep either.

**Consequence:** during the transition, `wip/` cites old numbers. That is acceptable and expected —
it is why step 3's inventory matters.

## The inventory is a deliverable, not a worksheet

The owner's step 3 produces the crosswalk, and it must **outlive the operation**: commit messages,
`wip/`, and any stakeholder note written before today all cite old numbers.

**It belongs in the ledger itself, as an appendix** — the persistent corpus is the only place that
survives `wip/77` deletion, and a reader hitting an old number needs the mapping where the decisions
are, not in a scratch tree. One table: old id → new id, or old id → *removed, superseded by <new
id>*.

## The steps

| id | step | gate |
|---|---|---|
| **DEC-01-01** | Join the 3 line-broken mentions; normalise plural and lower-case variants | `grep -cE 'Decision$'` = **0**; no bare `decision N` | 
| **DEC-01-02** | Wrap every live id `Decision N` → `DEC-Decision N-DEC`, every tombstoned id → `TOMB-Decision N-T` | **the governing gate above**: no unwrapped `Decisions?` anywhere in scope |
| **DEC-01-03** | Build the inventory: 33 ids, disposition (keep / remove), new number | reviewed before any deletion |
| **DEC-01-04** | Remove the 4 tombstoned entries | `grep -c 'TOMB-'` = **0** — no surviving mention, including in `src/`, `tests/` and the persistent docs |
| **DEC-01-05** | Rename one at a time, `DEC-Decision <old>-DEC` → `NEW-Decision <new>-NEW` | after each: the old id appears nowhere unwrapped |
| **DEC-01-06** | Strip `NEW-` / `-NEW`; read the diff | 29 headings, gapless 1–29; suite green; **inventory appended to the ledger** |

**Scope for every step:** `doc/development/decisions/input.md`, the persistent docs that cite it
(~10 files), and **`src/` + `tests/` (165 citations)** — code comments cite these ids and are the
easiest scope to forget.

## What DEC-01-04 must check before deleting

The 4 tombstones are **13, 16, 20, 29**, and three of them are superseded *by Decision 30* — which
is itself being renumbered. Before removal, confirm each entry's content is genuinely carried by its
successor and not merely pointed at. **Decision 20's body, for instance, is the last full
description of `compy.input.keys_pressed`**, a member that no longer exists; deleting it removes the
record of why it went. If that history is worth keeping, it belongs in the successor's *Why*, not in
a tombstone — decide per entry, in the inventory, not during the sweep.

## One contested point, stated and not blocking

**Renumbering is optional; removing tombstones is not.** Deleting the 4 and leaving gaps at 13, 16,
20 and 29 costs nothing and carries no risk, because a gap is self-evidently a gap. Renumbering buys
a gapless sequence at the price of touching 165 code citations, where a miss is silent and points at
the wrong decision.

**The owner has asked for the renumbering and the algorithm is sound**, so this specifies it in
full. The judgement is recorded only so the trade is visible: **if the job has to be cut short, cut
the renumbering and keep the removal** — the de-noising the owner wants comes mostly from the four
deletions, and the renumbering is polish on top.
