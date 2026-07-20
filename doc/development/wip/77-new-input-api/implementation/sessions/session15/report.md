# session15 — report

**Task:** TF1 (split the input contract suite) + an owner-driven TF2 amendment and a
redesign side-product. Under `agents/validation.md` flow, `plan.md` mandate.

## Outcome

**TF1 — complete.** The 2317-LoC monolith `tests/input/input_contracts_spec.lua` (19 flat
inner describes) became **9 cognitive spec files** under `tests/input/`, behaviour-preserving:
suite stays **815/0/0/4**, tags preserved, 4 pendings preserved, every file standalone-green.
- Precursor (`8f35589`): fixture build moved into guarded `F.setup()` + symmetric
  `F.teardown()`, hooks wired; `project_open_liveness` consumer's describe-body `F.cc` read
  relocated into `before_each`. Rationale re-grounded by a Fable consult — busted 2.3.0 already
  insulates `_G`/`package.loaded` per file, so the owner's stated collision premise was a
  busted-1-era model; the refactor's real payoff is **standalone-runnability**, the gate that
  proves the split has no hidden cross-describe coupling.
- Split (`48191a3`): executed by Sonnet, independently verified. Caught + repaired a fidelity
  miss (7 owner file-head REVIEW remarks dropped in header condensation → carried verbatim into
  a `SUITE-LEVEL REVIEW NOTES` block atop `input_routing_spec`). Docs updated (`tests.md`,
  `technical_debt/input.md`).

**TF1 amendment — readability sub-describes (`6dabe62`).** Owner hand-nested
`input_cursor_text_spec` into method-named describes and asked to mirror it. I mapped the flat
`it` lists (map: `validation/reviews/TF1-subgrouping-map.md`); Sonnet carved **23 nested
groups** across 4 files (events 7 on the author's own `-- ----` seams, widgets_callbacks 8,
reconfigure 4, route_lifecycle 4). Contiguous-only, no reorder, no hooks on nested describes,
prefix-trimmed labels only where clean. Verified: 815/0/0/4, per-file it/pending unchanged,
`git diff -w` shows only wrappers/indent/label-trims. Two files left flat and two left
already-nested per owner ruling.

**TF2 — in progress (`34cf318`, wip).** Owner's inline human-review annotations committed
across cursor_text/events/nfr_forward (notes only; suite green). TF2 still to be completed
against the **current** implementation; the post-TF2 plan may change (below).

**Redesign side-product (`b35eb9c`) — feeds Phase B.** The review surfaced the same tensions
repeatedly; owner sketched a reshaping. Distilled to two notes under `validation/notes/`:
`input-api-redesign-proposal.md` and `input-api-redesign-evaluation.md`. See those files — not
inlined here.

## Non-obvious points

- **busted 2 insulates per file** (`busted/init.lua:63` `envmode='insulate'`;
  `context.lua` save/restore of `_G`+`package.loaded`). Cross-file `_G.love` clobbering does
  **not** occur. Corollary debt: `keys_pressed_spec.lua:48-50` stale "other specs replace
  `_G.love` during collection" comment is falsified — a `{badspecref: A8}` Phase-C item, left
  untouched (out of scope).
- **The redesign is deliberately NOT in TF2's scope.** TF2 reviews the suite against what is
  *built*; the pivot is a Phase-B (scaffolding-suspect) candidate. Kept separate on purpose so
  review of the shipped form isn't contaminated by proposed changes to it.
- **Highest-stakes open question for the redesign:** the Decision-6 seam — "widget owns
  Enter/Esc" is only safe if *controller (UIC)* owns detect+propagate while the parent context
  owns lifecycle. Blur it to the model and the old dismiss-limitation returns. Flagged for Fable.

## Verification of record
Suite from the committed tree: `815 successes / 0 failures / 0 errors / 4 pending`. Owner
working-tree items (`docker/compose.yml`, vim `.swp`, and the standing untracked scratch)
left untouched throughout.
