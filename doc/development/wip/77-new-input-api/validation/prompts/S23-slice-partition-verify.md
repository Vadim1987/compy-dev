# S23 sub-agent prompt — TF2 navigation slice partition verification (Sonnet, read-only)

**Materialized prompt of record** (validation.md hygiene c). Worker: Sonnet.
Scope: **verification only — make NO edits to any file except your one
outcome file. Do NOT regenerate the slices** (regeneration is owner-gated
and belongs to a later phase).

## Context you do not inherit

You are a sub-agent in the LÖVE2D project at `/repo` (cwd). You do **not**
inherit the repo's CLAUDE.md or the parent session's context, so:

- **MCP-LSP is available** (`lua-lsp`: defs / refs / diagnostics over a real
  AST of `/repo`) if you need to resolve a Lua symbol. This task is mostly
  git/file arithmetic, so you may not need it.
- Local workspace commands (`git`, `grep`, `awk`, …) are pre-approved.
  **Read-only git only**: `log`, `show`, `diff`, `ls-files`, `apply
  --check`. Never commit, never `apply` for real, never touch `.git`
  internals.

## Background

Session22 produced a fresh batch of **review-navigation slices** (patch
files) under `doc/development/wip/77-new-input-api/implementation/pr-slices/`,
committed as `4c002e8`. They are a **navigation aid for a human code
review**, not the final PR assembly — final regeneration happens later.

The generation procedure is
`doc/development/wip/77-new-input-api/implementation/pr-assembly-guide.md`
§1 ("Regenerate the slices"): `BASE=3256aac` is fixed, `TIP` is the tree
tip at generation time. Read that guide first — it defines the exact
exclusion rules (notably that `doc/development/wip/**` content is excluded
from the reviewable set).

Relevant commits after the slices were generated:
- `16546af` — owner's **Dockerfile-only** commit, unrelated to the feature.
- `a4197db`, `2942147` — session22 bookkeeping under `wip/77` (excluded by
  the wip rule anyway).

Session22 claimed: **eight slices covering all 89 WIP-excluded changed
files exactly once.**

## Your task

1. **Reconstruct the reviewable file set.** From `git diff --name-status
   3256aac..HEAD`, apply the guide's exclusion rules to produce the set of
   changed files a reviewer should see. Report its size. Then produce the
   same set for `3256aac..4c002e8` (the tip the slices were generated
   from) and **diff the two sets**, so the parent knows exactly what the
   slices do and do not cover at the current tip.
2. **Verify the partition.** Parse the slice patches in `pr-slices/`
   (report how many there are and their names). Extract the file paths each
   slice touches. Verify **completeness** (every file in the set of §1 for
   `4c002e8` appears in some slice) and **disjointness** (no file appears
   in two slices). Report any file in a slice that is *not* in the expected
   set, too.
3. **Confirm the arithmetic** of the "89 files / 8 slices" claim, or state
   the true numbers.
4. **Applicability spot-check.** For each slice, run `git apply --check
   --stat` against the correct base (per the guide's ordering) and report
   whether it would apply cleanly. If the guide's ordering makes a
   cumulative check impractical, say so and check what you can — do not
   invent a result. **Never apply for real.**
5. **Staleness delta.** State in one paragraph, in plain terms, what a
   reviewer reading these slices at the current HEAD would *miss* or see
   *stale*, given §1's set difference and the `16546af` Dockerfile commit.

## Deliverable

Write your report to
`/repo/doc/development/wip/77-new-input-api/validation/outcomes/S23-slice-partition-verify.md`.

Structure: one section per numbered task, each opening with a one-line
verdict (CLEAN / FINDINGS: n), with the concrete file lists and counts
(use collapsed lists where long, but never omit a discrepancy). Close with
an overall verdict and an explicit list of anything you could not verify.
**Do not fix anything you find.** State plainly if a check came out clean;
do not manufacture findings to look thorough.
