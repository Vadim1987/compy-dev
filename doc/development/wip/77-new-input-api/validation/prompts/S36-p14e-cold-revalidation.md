# Commission — cold revalidation of the examples reconciliation (P14e), session36

**Model:** Sonnet (passed explicitly at spawn). **Mode:** read-only review. **Deliverable:**
`doc/development/wip/77-new-input-api/validation/outcomes/S36-p14e-cold-revalidation.md`.

You are reviewing work you did not do, in a repo you have not seen. Nothing in the author's
commit messages, track or plan notes is evidence — those are **the author's claims**. The code,
the docs as they stand, and `git show` are evidence. Where a claim and the code disagree, the
code wins and the disagreement is a finding.

## What you are checking

One step of a larger sprint: **the examples reconciliation**. Its mandate and its whole
enumerated content are in
`doc/development/wip/77-new-input-api/validation/reviews/S27-triage-and-plan.md` **§11.4.3**
(read it in full; the §4 table row for `P14e` is a summary of it). Read also the sprint's frame
in `agents/validation.md` ("The strategic frame") — the feature must not grow moving parts
beyond the stakeholder ask.

Four questions, in this order:

1. **Did it do what the step says?** Every site the step enumerates — per detached repo and per
   in-repo example — is either changed as specified or explicitly recorded as needing nothing.
   Name anything the step required that did not happen.
2. **Did it do anything the step does NOT authorise?** The mandate is deliberately narrow: only
   **held-state reads**, triggered by two named changes (the removal of the framework's tracked
   held-key set, and the guide's recommendation ladder). An example with no held-state read is
   "clean and closed", **not searched**. A blanket example sweep was ruled out by the owner.
   Anything swept in beyond that is a finding, however sensible it looks. Check especially that
   no `REMARK:`/`INTERIM:` marker anywhere was touched (they belong to a later pass) and that no
   unrelated working-tree change of the owner's was absorbed.
3. **Is what landed appropriate and internally consistent?** Does each converted site actually
   preserve behaviour, or does it change it — and if it changes it, is the change stated in the
   workspace (a doc, or a code comment), not merely in the commit? Do the code, the project guide
   (`doc/input_api.md`), the internals docs (`doc/development/internals/examples/`) and the debt
   register agree with each other about what the examples now do?
4. **Is the deferred work honestly recorded?** The step caps itself: conversions that are not
   small and obviously behaviour-preserving are declined to the debt register. Check
   `doc/development/technical_debt/input.md`, §"Examples are not onboarded onto the new input
   API" — is each entry real (does the site exist, at that line, in that shape), and is anything
   the author actually changed missing from it or wrongly listed in it?

## The commits under review

In the platform repo, `7c08230c..HEAD`:
`775502b4`, `5c3ca84b`, `cc434f9b`, `5d342bbe`, `3e8d6a5c`, `deaefba4`, `f71f5630`, `bd3ad646`,
`855b4ef5`.

**Two of the examples are separate repositories with their own history**, and their commits are
NOT in the platform repo's log — you must review them in place:

- `src/examples/keyboard` → commit `05cedec` (`cd src/examples/keyboard && git show 05cedec`)
- `src/examples/maze` → commit `a045fdb`
- `src/examples/balloons` → the step says nothing to do; verify that independently.

## Facts you need, which the tree will not tell you by itself

- **The platform used to keep a table of held keys and match combos against it. It no longer
  exists** — the matcher asks the keyboard directly, and the modifier set is closed to
  ctrl/alt/shift. `compy.input.keys_pressed` is gone. That change landed in earlier commits and
  is NOT under review; its consequences for the examples are.
- **The recommendation ladder** (`doc/input_api.md`, "Held keys") is: shortcuts and combos first;
  `Key.*` in project code is permitted but a symptom; `love.keyboard.isDown` is the last resort,
  legitimate where `Key` has no answer — i.e. for a key that is not a modifier.
- `Key` is a global (`src/util/key.lua`) reachable inside a project sandbox. Verify that claim
  rather than assuming it.
- **`held` has three unrelated meanings in this tree** — the dissolved set, the device mocks, and
  a text-selection drag state. Do not sweep on the word.

## How to work

- **Write your report to the deliverable path NOW, before you finish reviewing, and update it as
  you go.** A previous reviewer died to an infrastructure failure holding a full pass of findings
  and nothing on disk. Partial-but-saved beats complete-but-lost.
- **The `lua-lsp` MCP server is available** (definitions / references / diagnostics over a real
  AST of `/repo`). Use it to resolve a symbol or prove who calls what. **It is not sufficient
  alone**: it misses occurrences routed through metatable `__index` on string keys, which this
  very example uses — grep is the completeness backstop, and the two are cross-checked.
- `busted tests` runs the platform suite (expect **942 successes / 0 failures / 0 errors / 10
  pending**; the 10 pending are sanctioned, not drift). The three detached example repos have
  **no suite at all** — reasoning and reading are the only tools there.
- **Do not change any file.** This is a read-only review. Do not commit, and never push anything.

## What the report must contain

- A **verdict**: sound / sound-with-findings / unsound, stated plainly at the top.
- Findings, each with: the file and line, what the author claimed, what the code shows, and why
  it matters. Rank them; a stylistic quibble is not a finding.
- **What you could NOT determine**, said plainly. A clean verdict is worth something only if the
  limits of the check are stated — e.g. anything needing the app to be driven by hand.
