# Commenting rules

_Owner-authored (2026-08-07); restated for agent use in session27 — content
unchanged, structure and worked examples added._

> The authority on **what a comment may contain**. Load it before writing or
> reviewing comments, and whenever you are about to explain in prose something
> the code could say itself. Formatting mechanics (own line, never inline;
> 64-char limit) live in [`../rules.md`](../rules.md) and still apply.

**META-RULE: a comment should not exist if it does not bear any valuable
information.** Everything below is that rule, made checkable.

## The gate — apply to every comment you write, keep, or review

Ask in order. The first "yes" decides.

1. **Is it derivable from the code as it stands?** → delete it.
2. **Would a better name carry it?** → rename the function, variable or test,
   then delete it. A comment is not a repair for a name.
3. **Does it carry one of the four payloads below?** → keep it, at minimal
   viable size.
4. Otherwise → delete it.

A comment that survives the gate is not thereby the right *length*. Run it past
the size rule as well.

## The four payloads — the only things worth a comment

1. **Intent or constraint** that is not obvious from the code and not
   expressible through naming: why this order, why this bound, what breaks if
   it changes.
2. **Non-local context** — a concept, contract or decision that lives
   elsewhere (another module, a design decision, a doc section). The comment
   carries the pointer **plus the one thing the reader needs here**; it does not
   reproduce what it points at. See "A reference is not an annotation" below.
3. **Availability** — `supported since <version>`, `deprecated since
   <version>`.
4. **An interim development marker** — temporary by construction, see below.

## Size

- **Minimal viable, never below readability.** Prefer a clause to a sentence, a
  sentence to a paragraph.
- **A comment as long as or longer than the code it describes is a symptom,
  not a style.** Either the code cannot express itself (fix the code) or it is
  doing too much (split it). Where the code is genuinely irreducible — a
  platform quirk, a numeric tolerance — one line saying so is the fix.
- **No literary prose.** No restating a point in a second phrasing, no
  scene-setting, no rhetorical question followed by its own answer. Bloat that
  adds no information fails the meta-rule regardless of how well it reads.

## What a comment must not do

- **Say what the code does *not* do.** Every piece of code fails to do
  infinitely many things. Admissible only when a competent reader could
  plausibly conclude otherwise *and* no change of naming or structure prevents
  the confusion — and then it states the confusion, not a list of absences.

  **An absence is waste; a prohibition is a payload** (owner ruling,
  2026-08-25). *"This does not check X"* describes what happens to be missing —
  the code already says that, and it says it more reliably. *"X must never be
  checked here"* is a **constraint on every future edit**, which is payload 1
  and cannot be read off the code at all: the next author's reasonable-looking
  addition is exactly what it forbids. Write the rule, not the gap:

  ```lua
  -- WASTE: an absence. The code below already shows it.
  -- Straight to the console, with no widget test in front of it.

  -- PAYLOAD: a prohibition the next edit could violate.
  -- Widget visibility is state on the widget, never a routing
  -- condition (decisions/input.md, Decision 1).
  ```
- **Narrate history** — "this used to…", "we removed…", "previously the
  handler…" — outside an interim marker. Git holds history.
- **Restate the identifier in prose.** `-- the handler that handles the event`
  next to `handle_event` is noise.
- **Comment on itself** — "the following section explains…", "note that…".

## Citations

A comment that points at a doc must stay resolvable after the feature's scratch
is deleted:

- cite a **canonical doc** under `doc/` — never a path under
  `doc/development/wip/…`, which rots on deletion;
- **never write an unreachable LINK from inside an example repository** (owner
  ruling 2026-08-12, **refined 2026-08-12**). `src/examples/*` are separate
  repositories with their own remotes and their own PRs. **What is prohibited
  is a pointer to a file that repo does not contain** — a `doc/…` path, which
  cannot be followed from a tree that does not have it, and which ships a
  dangling reference into a third party's file. The same goes for
  platform-internal identifiers: a decision number means nothing there.
  **What is tolerable is naming the platform guide and its section** —
  *"Compy Input API, 'Submit lifecycle'"* rather than
  `doc/input_api.md, "Submit lifecycle"` — **and only where it is really
  needed**, i.e. where the comment would otherwise have to restate a contract
  the platform owns. A name a reader can search for is not a broken link; a
  path they cannot open is. Prefer saying the thing in place, briefly; the
  durable argument still belongs in the platform's own docs. This outranks
  the clause above, which was written for platform sources;
- cite a **named section**, never "paragraph 3" or a line number;
- when you rename or remove a heading, **grep `src/` and `tests/` for the old
  name**. A citation that no longer resolves is worse than none, because it
  still reads as authoritative. One heading rename in this feature left 31
  dangling citations, two of them naming a retired design model.

## A reference is not an annotation (owner ruling, 2026-08-25)

**Compaction must not turn comments into an index of reference ids.** A comment
reduced to `-- Decision 21` or `-- see input_api.md, "Held keys"` has been
deleted, not compacted: it tells the reader that something governs this code
without telling them **what**, so the only way to find out is to leave the file.
A reader skimming for orientation gets nothing, and an assistant reading the
module in isolation gets nothing.

**The rule.** Every citation carries **at least a clause of its own** — the
claim, constraint or reason that applies *here*. The reference is where the
argument lives for whoever digs deeper; the clause is what makes digging
optional.

```lua
-- BAD: an index entry. What is true here?
-- (doc/development/decisions/input.md, Decision 33)
local reservation = RESERVED.keypressed[combo_string(k)]

-- GOOD: the claim, then where it is argued.
-- A reservation matches its modifier set exactly, so an
-- unnamed modifier misses (decisions/input.md, Decision 33).
local reservation = RESERVED.keypressed[combo_string(k)]
```

This does not license restating the source. One clause, not a précis: if the
comment is long enough to argue the point, the argument belongs in the doc and
the comment belongs shorter. The size rule still governs — this rule sets the
**floor**, the size rule sets the ceiling, and a comment lives between them.

## Interim comments — allowed while the tree is in motion, gone at release

While code is being moved, prototyped or deleted, comments that carry
requirement and decision ids, "this moved to X", "kept until Y lands", or a
reviewer's open question hold the logical integrity of a tree that is changing
under its own feet. They are legitimate and useful. Two conditions, both
mandatory:

1. **Marked.** Prefix `INTERIM:` — a single greppable token, deliberately
   distinct from `TODO`. Review remarks (`REMARK:`) count as interim comments
   and are subject to the same gate.
2. **Removed completely before release.** Not thinned, not "mostly" — the
   release check is

   ```
   grep -rnE 'INTERIM|REMARK|^[[:space:]]*--(->|>)' src/ tests/
   ```

   returning nothing. Each marker is either resolved into a payload-carrying
   comment, or acted on and deleted, or promoted to a durable record (see next).

   **Three alternatives, and no exclusions — each part is there for a reason
   found the hard way:**

   - **No colons.** Two markers once hid from the colon-only pattern by being
     spelled `REMARK` without one. A gate that cannot see a marker is worse
     than no gate.
   - **The arrow form** (`-->`, `--->` opening a comment) — a reviewer writing
     in the margin does not always type `REMARK:`, and this is what they type
     instead. One such comment was live in `controller.lua` for the whole
     feature, invisible to every sweep.
   - **Case-sensitive.** Markers are uppercase by convention; that is what
     makes them tokens rather than words. Matching case-insensitively drags in
     ordinary English — "she remarked" in a prose corpus, "the interim help
     chord" in an example's comment — and one such phrase belongs to another
     author, so the gate could never reach zero while it stood. Case
     sensitivity removes the false positives without hiding a single real
     marker, and with them the need for any exclusion list.

**`INTERIM:` is not `TODO`.** A `TODO` is a durable backlog item: it survives
release, and once it is substantial it belongs in
`doc/development/technical_debt/` rather than in the source. An `INTERIM:` is
scaffolding, and scaffolding that ships is a defect.

## Where this is enforced

Comment cleanup is a **pre-PR gate**, not an ongoing chore: run it once the
code has stabilised and before the delivery slices are assembled — see
[`../validation.md`](../validation.md), "Comment References". Doing it earlier
wastes the interim markers that are still load-bearing; doing it later ships
them.

**And the same holds for verbosity, not only for markers** (owner, 2026-08-12).
Mid-development, a verbose comment is doing real work: it orients the next
reader — human or assistant — in a codebase that is fragile and still moving,
where the reasoning is not yet settled enough to be obvious from the code.
**Do not compact as you go.** Compaction is its own substep near the end of a
step, taken once, over stabilised code: it dries up history and obituaries,
intermediate rulings, and second phrasings, keeping only the reasons. `P-18-10`
is the worked example — one dedicated pass that took `keyboard`'s `input.lua`
from 177 comment lines to 101 without losing an argument.
