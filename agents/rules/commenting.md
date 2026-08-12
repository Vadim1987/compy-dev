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
   elsewhere (another module, a design decision, a doc section). The comment's
   job is the pointer, not a summary of what it points at.
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
- **never cite a platform doc from inside an example repository** (owner ruling,
  2026-08-12). `src/examples/*` are separate repositories with their own
  remotes and their own PRs: a `doc/…` path cannot be followed from a tree
  that does not contain it, and shipping one into a third party's file is an
  integrity problem, not a broken link. The same goes for platform-internal
  identifiers — a decision number means nothing there. Say the thing in
  place, briefly, or leave it out; the durable argument belongs in the
  platform's own docs, which that repo's reader never sees. This outranks
  the clause above, which was written for platform sources;
- cite a **named section**, never "paragraph 3" or a line number;
- when you rename or remove a heading, **grep `src/` and `tests/` for the old
  name**. A citation that no longer resolves is worse than none, because it
  still reads as authoritative. One heading rename in this feature left 31
  dangling citations, two of them naming a retired design model.

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
   release check is `grep -rn 'INTERIM:\|REMARK:' src/ tests/` returning
   nothing. Each marker is either resolved into a payload-carrying comment, or
   acted on and deleted, or promoted to a durable record (see next).

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
