# P-17-01 — worker prompt of record: the practice catalogue

**Spawned by:** session39 (validation phase), 2026-08-12. **Model: Sonnet, passed explicitly.**
**Deliverable path (write it yourself, do not only report in chat):**
`doc/development/wip/77-new-input-api/validation/reviews/P-17-01-practice-catalogue.md`

---

## What this is for

The sprint is about to adopt the new input API in `src/examples/maze`, which its authors have
reworked so deeply that our previous migration no longer applies. Before that analysis starts, the
owner asked for **a catalogue of practices already established elsewhere in this sprint**, so the
analysis does not re-derive them from scratch.

**The owner's framing, verbatim, and it governs your tone:** these materials *"serve merely as a
catalogue of practices that **may** be used for maze… or not."*

So: **you are writing a catalogue, not a recommendation.** You are not analysing maze. You are not
proposing changes to maze. You are extracting *what was learned* and *what shape of code it applies
to*, so that someone reading maze's code later can recognise a shape and look up what is already
known about it.

## Sources — read these, and only these

**(1) What we did to maze's old base.** Four commits in the nested repo `src/examples/maze`, on
branch `newinput` (do NOT check it out — read with `git -C src/examples/maze show <sha>`):
`790ac19`, `d2ce7a0`, `aeabb73`, `a045fdb`. **Their commit messages are the payload** — they carry
reasoning that exists nowhere else. Note `aeabb73` is the owner's own review commit and adds two
`REMARK:` markers.

**(2) What the `keyboard` step (P-18) learned.** In
`doc/development/wip/77-new-input-api/validation/reviews/`:

- `P-18-00-keyboard-deepfix-design.md` — especially §1.1, §1.2, §2.2, §2.3, §7.1, §9
- `P-18-00-triage-and-plan.md` — especially §0 (two owner calibrations), §5 (four rulings), §§6-11
  (the execution record and the four review batches)
- `S37-P18-revalidation.md`, `S38-P18-final-revalidation.md`,
  `S38-P18-final-revalidation-2.md`, `S38-P18-final-revalidation-3.md`, `S38-P18-narrow-review.md`
  — five cold reviews. **These are where the traps are**, more than the plans.

**(3) The standing checklist, for vocabulary only** —
`doc/development/conventions/input_adoption.md` (Q1–Q10 + "Rules of restraint"). Use its question
numbers as the catalogue's index where a practice maps onto one. **Do not restate its content**; it
is a live document and the analysis will use it directly.

**Do not read** `S39-maze-upstream-input-assessment.md` or `P-17-00-shape-and-plan.md`. They are
about maze, and this task must stay a catalogue of *prior* practice rather than an answer to the
question maze poses.

## What to produce

One document, ~150–250 lines, structured as **entries**. Each entry:

- **A name** — short, memorable, stated as the practice or the trap, not as a file name.
- **Where it came from** — the document/section or commit, cited so it can be reopened.
- **The shape it applies to** — what the code *looks like*, concretely enough that a reader
  scanning an unfamiliar file could recognise it. This is the most useful field; spend your words
  here.
- **What was decided, and by whom** — separate **owner rulings** (binding, cite them as such) from
  **assistant findings** (evidence, overturnable). If a decision was later reversed, say so and give
  both.
- **What it cost when it was got wrong** — only where the record actually shows a cost. This is what
  makes a catalogue worth reading; do not invent one.

Group the entries under three headings:

1. **Owner rulings that generalise** — e.g. the game's rules are not ours; adoption is the point of
   the sprint; a deviation lives in the workspace; no example-repo comment may cite a platform doc.
2. **Mechanism practices** — the substantive input-shaped lessons (delivery order, held state, repeat
   filtering, polls versus events, release channels, combo registration, claim/release).
3. **Process traps** — what repeatedly went wrong in execution (counts in documents, a worker's
   report versus the tree, comment-and-document pairs, `git add -A`, measuring versus reasoning).

Close with a short section: **"What this catalogue does NOT establish"** — practices that were
`keyboard`-specific and should not be carried by analogy. Be explicit; this is the section that
protects maze from being read through keyboard's eyes.

## Rules you must follow

- **Read-only. Touch no `.lua` file, no git state, no branch.** Do not commit anything. Do not check
  out any branch in `src/examples/*` — those are separate repositories with their own remotes, and
  one of them (`maze`) was just moved deliberately.
- **Verify a claim before you carry it.** These documents contain claims that were later corrected —
  several by the reviews themselves. If two sources disagree, say so in the entry rather than picking
  one silently. **Where a claim is about code, check the code.**
- **The `lua-lsp` MCP server is available to you** — defs / refs / diagnostics / hover over a real
  AST of the `/repo` workspace. Grep to find candidates, then use the LSP to resolve a symbol
  precisely or to prove who calls what. Use it whenever you are unsure where something is defined;
  string search gives guesses, the LSP gives facts. (If you ever edit a `.lua` file — you should not
  here — `sleep 1` before querying, the server re-indexes.)
- **Do not pad.** An entry with nothing behind it is worse than a missing entry. If a section has
  three real entries, it has three.
- **Write the file yourself** at the deliverable path above, then report a short digest. The file is
  the artifact; a final chat message is lost when context rolls.
