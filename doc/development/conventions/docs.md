---
description: Front matter every doc under doc/ carries — what the fields mean, what they replace, and how provenance is recorded
status: active
audience: developer
authored: llm
reviewed: none
---

# Documentation Conventions

Owner ruling, 2026-07-31. Before it, provenance lived in an HTML comment
(`<!-- authored By LLM; human-approved NOT YET -->`) carried by 58 files, while
one file carried YAML front matter and the three most load-bearing documents
carried neither. This replaces both with one block.

## The block

Every document under `doc/` opens with YAML front matter — the
Jekyll/Hugo/Obsidian convention, which is what the block above is; there is no
governing standard beyond it, so these fields are ours:

```yaml
---
description: one line, what the document is for
status: active | draft | superseded
audience: developer | project author | stakeholder
authored: llm | human | mixed
reviewed: none | <name>, <YYYY-MM-DD>
---
```

- **description** — one line. It is what a reader sees in an index or a search
  result, so write what the document is *for*, not what it is called.
- **status** — `superseded` documents keep a pointer to their successor in the
  body, they are not deleted.
- **audience** — who it is written for. `project author` means someone writing
  a project that runs inside Compy; `stakeholder` means someone reviewing what
  was built without reading the code.
- **authored** — who wrote the prose. `mixed` is honest and common.
- **reviewed** — `none` until a human has actually read it end to end, then the
  reviewer and the date. This is the field the old comment's
  "human-approved NOT YET" was carrying; it is not a formality, and it does not
  update itself.

## Rules

- The block is the **only** place provenance is recorded. Do not re-add the
  HTML comment.
- `reviewed:` is changed by the reviewer, not by the author and not by an
  agent — an agent may add the field with `none`, never fill it in.
- A renamed heading breaks every citation pointing at it. When you rename one,
  grep `src/`, `tests/` and `doc/` for the old anchor and repoint it in the
  same commit.
- Cite canonical docs (`doc/…`), never a feature's ephemeral working tree
  (`doc/development/wip/…`), and cite a **named section** rather than a
  paragraph number.
- **An ephemeral *id* is a citation too** (owner ruling, 2026-09-03). A bare
  `FIX-02-05` or `BUG-01-11` is not a path, but it resolves only inside the
  working tree that names it, so it dangles the day that tree is deleted — the
  same failure as a `wip/` link, with nothing to grep for. A persistent document
  says **what was decided or done and when**; the sprint id that carried it
  belongs in the working tree, or spelled out (*"the pass that base-checked the
  retired entries, 2026-09-02"*) where the reader needs the referent.

## Vocabulary: "de-facto behaviour" has a boundary (owner ruling, 2026-08-11)

**"De-facto behaviour" names what preceded a feature and is being canonicalised by it.** It must
**never** describe behaviour the feature itself introduced.

A *decision* is a choice made during a feature's design or development. Behaviour that predates
the feature and is merely being written down is **documentation of de-facto behaviour** — it may
well deserve a place in an internals guide, and it does **not** deserve a ledger entry, because
nothing was decided.

**Why the rule is written down rather than assumed.** The confusion is characteristic of an
assistant reading the current tree: a shape that has been in the code for twenty minutes reads
exactly like a shape that has been there for a year, and calling the former *de-facto* turns a
choice the team made — and could revisit — into an inherited fact nobody owns. The test is
mechanical and cheap: **compare against the pre-feature base.** If the behaviour is there, it is
de-facto; if it arrived with the work, it is a decision, however obvious it now looks.
