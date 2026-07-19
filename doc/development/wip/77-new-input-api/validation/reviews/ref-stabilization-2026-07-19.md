# Phase-A tactical amendment — reference stabilization before TF (2026-07-19)

_Session14 (Opus), owner-directed in-session. **Tactical amendment of Phase A** that emerged
mid-phase — NOT a strategic plan change (owner, 2026-07-19). It changes no phase order, gate, or
mandate: it neither resolves nor removes the ~25 non-doc-A "Phase C evidence" refs, it only (1)
disambiguates persistent-doc paths and (2) expands opaque interim refs with short annotations so the
Phase-TF manual test-fidelity review is more reliable. Evidence is preserved throughout._

## Trigger

Owner review of the DI3 output (the doc-A citation retarget) surfaced two reference-legibility
gaps that the owner wants closed **before Phase TF** (TF reviews *what each test is for and why*, so
opaque/ambiguous comment refs block it). Owner directive: **stabilize comment references from
tests/code first; no TF yet.**

## Decision 1 — normalize persistent-doc citations to repo-root-relative (mechanical)

**Problem:** the established citation form is bare (`decisions/input.md`), which is filesystem-correct
*inside* `doc/development/` but resolves to nothing from a test/src file. 210 bare refs across 11
files (5 test, 6 src) are ambiguous this way; 10 are already root-relative (`doc/development/...`).

**Ruling (owner):** normalize **all** tests/src persistent-doc citations to **repo-root-relative**
`doc/development/<subdir>/<file>.md` — unambiguous from anywhere, greppable to a real file. Scope =
all ~210, not just DI3's, so the convention doesn't split. The corpus's own internal cross-refs stay
bare (filesystem-correct there). Comment-only; suite stays 815/0/0/4.

## Decision 2 — interim/ephemeral refs: KEEP as evidence, ENRICH for legibility (not resolve)

The ~25 non-doc-A refs (milestone marks `M#`/`0.1.0-m#`; review-doc `A5`/`A8`/`M2-human-review.md`/
`M6-02`/`M4-0-04.md`; ratified-model/scope `E30`/`Scope item 10(a)`/`spec §10`/`R11`) **stay Phase-C
evidence — not resolved/replaced** (plan-consistent; owner: the plan justifies keeping them).

**Enrichment (owner):** an opaque ref like `AC-153, paragraph 1` tells a TF reviewer nothing. Each
such ref gets a **minimal inline gloss of its meaning** (a named section / one-line decode),
**without dropping the evidential reference**. Sonnet reads the referenced ephemeral doc (still
present under `wip/77`) to write the gloss. **Scope (owner): all opaque interim refs** — review-doc,
milestone marks, and ratified-model/scope families alike — since the TF-legibility rationale (manual
review needs to know *what each test is for*) applies to every opaque ref equally. Where the
referenced fact also has a persistent home, the gloss may add a `doc/development/...` pointer
alongside (additive, never replacing the evidential ref).

## Marker convention (owner, 2026-07-19)

`{badspecref: X}` and `{jargon: Y}` are the **owner's ad-hoc annotation markers**, not a codebase
system: `{badspecref:}` flags a **bad/ephemeral reference the owner spotted** — precisely the refs
this session fixes (persistent) or annotates (ephemeral); `{jargon:}` flags a **weird term**. Rules:
- **`{badspecref:}` refs are our targets.** For an ephemeral ref kept as evidence, the `{badspecref:}`
  wrapper **stays** (it honestly marks the ref as non-corpus / will-dangle-when-`wip/77`-deleted) and
  we **add** an inline meaning gloss beside it — additive, never replacing. This matches DI3's own
  choice (it re-wrapped `reviews/M4-0-04.md finding 1` in its own `{badspecref:}` when splitting it
  from a doc-A clause).
- **`{jargon:}` tags: DO NOT TOUCH this session.** They are a **Phase-TF** task (terms may need
  explanation when the owner reviews test intent) — carried forward, not addressed here.

## What is NOT done (guardrails)

- Doc A (`notes/input-contracts.md`) stays frozen/unedited; `design/` frozen.
- Review-doc **open questions are not resolved** into the corpus (that would need owner rulings —
  deferred, per plan). Enrichment only decodes the existing ref; it does not migrate facts.
- No TF work begins until the owner declares reference stabilization done.

## Sequencing

1. Normalize (Sonnet, mechanical) → commit. 2. Enrich interim refs (Sonnet, reads ephemeral docs) →
commit. New persistent-doc pointers introduced by enrichment are written root-relative from the
start. Suite green after each unit.
