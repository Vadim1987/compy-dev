# P-20-02 — cold revalidation of session39's tail (prompt of record)

Commissioned by session43, 2026-08-16. Worker: Sonnet, model passed explicitly,
**read-only**. Deliverable:
`doc/development/wip/77-new-input-api/validation/outcomes/S43-P-20-02-session39-revalidation.md`.

## Why this exists

Session42 landed a harmony change whose "proof" was a test fixture modelling a
mechanism the system does not have; the defect shipped silently
(`../notes/S43-harmony-p13-timing-finding.md`). An authorship audit
(`../notes/S43-agent-authorship-audit.md`) then found that **session39 changed
hands mid-flight**: it was run by one agent through commit `a1842a2f`, and
finished by another. The handover fell between *commissioning* a cold review of
the maze migration and *acting on its finding* — the worst possible place, since
the acting half was done by an agent that did not do the analysis.

You are checking the tail's work. Assume nothing on the report's word.

## Scope — exactly these

Platform repo `/repo`: `faedac15`, `c3b74959`, `56c0c26f`, `230cb32e` (P-17-16),
`f45a2588` (track), `5b6eebc0` (wrap + report).
Nested repo `/repo/src/examples/maze` (its own git repo): `da9d1c2`
*"fix(input): preserve Shift+Escape modifier variants"*.

Out of scope: everything at or before `a1842a2f`, and sessions 38/40/41/42.

## What to check

1. **The finding → ruling → code chain.** Read the cold review
   `../reviews/S39-P17-cold-review.md` for what it actually found about
   Shift+Escape, then session39's `track.md` for the owner's ruling on it, then
   `da9d1c2` for what landed. Does the code implement the ruling — not more, not
   less? The report claims "all variants visible for the author" and names held
   Alt, Ctrl, and Ctrl+Alt: verify each against the emitted programs.
2. **Player-visible behaviour.** The finding was a *narrowing* — something that
   worked before and would not after. Confirm the narrowing is actually closed,
   and that closing it did not narrow something else. Compare against the maze
   upstream where the assessment (`../reviews/S39-maze-upstream-input-assessment.md`)
   states what upstream did.
3. **The wrap's factual claims.** `5b6eebc0` and session39's `report.md` assert:
   maze suite 42/0/0; platform suite 946/0/0/10; "P-17 code work is complete
   through P-17-16". Re-run what can be re-run (`busted tests` in `/repo`; the
   maze repo's own suite) and state measured numbers. Note: the platform suite is
   **947** today because session42 added a case — that is expected, not a finding.
4. **Was the tail reviewed at all?** The bulk of session39 was reviewed cold
   (`S39-P17-cold-review.md`). Determine whether anything reviewed the work that
   came *after* that review. If nothing did, say so plainly — that is the single
   most useful thing you can report.
5. **Revalidation checklist** — apply `agents/rules/revalidation.md` §Checklist
   (intent reconstruction, intent-vs-outcome coherence, consistency, integrity,
   gap, artifact checks) to the tail's documentary output: the plan rows it
   closed, the track entries, and the report.

## How to work

- **The `lua-lsp` MCP server is available** (defs / refs / diagnostics / rename
  over a real AST of the `/repo` workspace). Use grep to find candidates, then
  the LSP to resolve a symbol, prove "who calls this", and check a claim about
  where something is defined. LSP refs can be incomplete in Lua — cross-check
  with grep when completeness matters. (If you edit any `.lua`, `sleep 1` before
  querying refs/diagnostics so the server re-indexes. You should not be editing.)
- **Read-only.** Do not modify, commit, or push anything in `/repo` or in any
  nested repo. Do not touch the owner's untracked scratch (`claude.sh`,
  `worklog.md`, `src/STEPS.md`, `doc/tall_blocks.md`, `repos.txt`,
  `input-pr-slices.tar.gz`).
- **Verify in code, not in prose.** Every claim you make cites a file and line,
  or a commit. Where a document and the code disagree, the code wins and the
  disagreement is itself a finding.
- Distinguish **severity**: S1 = broken or player-visible regression; S2 = rule
  or contract violation; S3 = documentation/bookkeeping drift.

## Deliverable

Write the report to the path above. Structure: verdict first (sound / unsound,
with the one-line reason), then findings by severity with file:line evidence,
then what you verified clean, then what you could not check and why. Do not pad;
a short accurate report beats a long hedged one.
