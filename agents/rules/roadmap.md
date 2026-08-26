# Roadmap representation — how planned work is shown, numbered and ordered

_Owner-ruled across session46 (2026-08-26), materialised from what that session learned the hard
way. These are rules about the **shape** of a plan, not about its content._

## 1. One roadmap, nested — never a second ledger

**The roadmap is a single document with nested structure**: stages, sprints inside them, rows inside
those. Sprints are **sections**, not separate documents with their own lives.

**Why this is a rule and not a preference.** This project once spun a triage table out into its own
document and worked it as a parallel plan. It acquired its own numbering, its own status, and its
own sense of being unfinished, and for weeks the honest answer to *"where are we?"* required knowing
**which of two timelines you were standing in**. The owner's verdict: *"switching across timelines
is idiosyncratic."* It ended only when the spinoff was declared closed and its remainder promoted
back up.

- A detailed **reasoning** document per sprint is fine and encouraged — it holds evidence,
  verdicts, hazards. It is **not** a second plan: it carries no ordering and no status of its own.
- The roadmap holds **the order and the state**; detail documents hold **the why**. A reader
  navigating asks the roadmap; a reader executing opens the detail.
- If a section starts growing its own schedule, that is the failure mode arriving. Fold it back.

## 2. Numbering follows execution order

**Ids are renumbered so that numeric order *is* execution order.** A roadmap where `07` runs before
`03` costs a lookup on every read, forever, to save one edit once.

**Renumber deliberately and rarely** — ideally once, when the order settles, before execution
starts. Every renumber ships a **crosswalk** (old → new), because commit messages, notes and
prompts written earlier keep the old ids.

**The renumber-vs-rename test, which decides more than it looks like it does:**

> **Does the id appear in code?**
>
> - **No** → renumbering is cheap. Ids live in a handful of planning documents; sweep them, ship the
>   crosswalk, done.
> - **Yes** → **do not renumber. Use names.** A missed citation under renumbering still resolves —
>   to *the wrong thing* — and reads as authoritative. Under naming the same miss dangles visibly
>   and greps out. Naming also removes the gap left by a deleted entry, so the problem dissolves
>   instead of recurring after every removal.

This is why the planning ids in this feature were renumbered freely while the decisions ledger,
with 165 citations in `src/` and `tests/`, was converted to mnemonic names instead.

## 3. Order by blast radius, not by severity

**Rows that can change the shape of the work go first.** Lead with anything that:

- **may reveal more defects** — a verification task with unknown yield;
- **may escalate into a design decision** — the fix is a choice, not a patch;
- **may cause regressions through deep change** — the fix lands somewhere everything runs through;
- has an **unknown** radius at all.

Narrow mechanical rows follow. **Sizing a small row against an unsettled surface is sizing it
twice**, and a design decision taken late invalidates work already done under the old assumption.

Severity is a *property of the defect*; blast radius is a property of **fixing** it, and only the
second one orders work. A nit whose fix touches a shared serialiser outranks a major whose fix is
one line.

## 4. Id conventions

```
KIND-<sprint>-<task>          e.g. BUG-01-03, FIX-02-11, ACC-01-02
```

- **KIND** — uppercase, short, says what *class* of work it is (`BUG` code misbehaves, `FIX`
  docs/process, `ACC` acceptance, `DEC` a ledger operation, `CHG` a changelog pass, `REC`
  reconnaissance, `MERGE`, `PR`). The kind is meaningful: it tells a reader whether a row needs a
  keyboard, a ruling, or an editor.
- **sprint** — two digits. A second sprint of the same kind is `-02`, never a new letter.
- **task** — two digits, ordered per rule 2.
- **Phases inserted into an existing lettered sequence take a name, not a letter** (`DI`, `TF`,
  `R`, `U`) — sequence letters are load-bearing across documents already written.

## 5. Two habits that keep a roadmap honest

**A parked question carries the moment it gets answered.** Not "open question" — *"answered when
BUG-01-02 is fixed"*. An open question with no trigger is the kind that rots, and a roadmap full of
them stops being a sequence.

**Omission is not a ruling.** If a planned step disappears from the roadmap, it was either ruled
away — in which case *say so, with the reasoning* — or it drifted away, which is the thing plans
exist to prevent. Session46 dropped three phases from a roadmap before anyone had ruled on them; the
owner noticed, and the fix was to record the ruling, not to quietly restore them.
