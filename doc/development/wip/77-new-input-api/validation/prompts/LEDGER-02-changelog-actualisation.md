# Sub-agent prompt of record — LEDGER-02: actualise the changelog and give it CURRENT_SCOPE

**Spawned session49, 2026-08-27. Model: Sonnet (explicit)** — derivation from artifacts that already
exist, not fresh judgment about what the feature did. **Absorbs the roadmap's `CHG-01` sprint and
`FIX-02-17`** (owner ruling, 2026-08-27).

---

`/repo/CHANGELOG.md` is 22 lines and badly behind the work. It carries the owner's own note at the
top: *"too shy for major changes done — rewired dispatching, unblocked event-handling, new topology
with shortcuts/hooks… many documentation and technical debt added. And version is 1.0.0-rc…"*.

You are fixing that, and giving the file the structure it will keep from now on.

## The structure the owner wants

- A section **`## CURRENT_SCOPE`** holding everything not yet released. On a release it is emptied
  and its content moves down into a section named for the version just shipped.
- Below it, the released versions, newest first.
- Say this protocol in a short note near the top of the file, so the next person maintaining it does
  not have to infer it.

Replace the existing `## Unreleased` heading with `## CURRENT_SCOPE`, carrying its content forward.

## Where the content comes from — read these, do not re-derive from the raw diff

The branch is `feature/77-newapi-analysis-s20260615`; the PR base is commit `3256aac`. The diff is
enormous and you must **not** try to summarise it commit by commit. The work of deciding what is
user-facing has already been done, in these artifacts:

- `/repo/doc/development/wip/77-new-input-api/implementation/pr-description.md`
- `/repo/doc/development/wip/77-new-input-api/implementation/pr-commit-messages.md`
- `/repo/doc/input_api.md` — the project-facing guide; anything a project author must now do
  differently is in here, especially its "Migration from the legacy globals" section.
- `/repo/doc/development/decisions/input.md` — for *why* a change was made, when a line needs it.

Use those as your source. Spot-check against the code when a claim looks doubtful, and say in your
report which claims you checked.

## What a good entry looks like here

Keep the existing file's voice: plain, user-facing, one change per bullet, no internal vocabulary a
project author would not recognise. The existing bullets under `Unreleased` are the model — read them
first and match them.

- **Group under `### Added` / `### Changed` / `### Removed` / `### Fixed`** — the file already uses
  `### Changed`.
- **The breaking change must be stated plainly and prominently.** The legacy text-input globals —
  `input_text`, `input_code`, `validated_input`, `user_input` — are **gone**, with no compatibility
  shim; this was a deliberate stakeholder ruling, not an oversight. Its absence from the changelog is
  the specific defect the roadmap filed as `FIX-02-17`. A reader upgrading must meet it immediately.
- **Write about the surface, not the refactor.** "Dispatching was rewired" means nothing to a project
  author; "keyboard events now reach a project while an input widget is open" does. The owner's note
  names four things worth covering at that altitude: the rewired dispatching, unblocked event
  handling, the new shortcuts/hooks topology, and the volume of new documentation.
- **Do not invent a version number and do not date anything.** Everything you write goes under
  `CURRENT_SCOPE`. The release that empties it has not happened.

## House rules

- **Do not commit, do not push, do not stage anything.** Edit `CHANGELOG.md`, write your report, stop.
- **Do not touch any other file.** In particular not `ROADMAP.md`, not the technical-debt register,
  not `doc/development/decisions/input.md` — other agents are working on those.
- **Leave the owner's `REMARK:` line at the top alone.** It is their working-tree annotation; it is
  not yours to sweep, and another pass removes those deliberately.
- If you read `.lua` to check a claim, the **`lua-lsp` MCP server** is available (definitions,
  references, diagnostics over a real AST of `/repo`). Grep to find candidates, then the LSP to
  resolve a symbol or answer "who calls this"; grep again as the completeness backstop, because Lua
  is dynamically typed and LSP references can be incomplete.
- `| head` on a counting grep lies, and so does a loose pattern.
- **Anything you cannot source, do not write.** A changelog that overstates is worse than one that is
  short: this file is what a stakeholder reads to decide whether to upgrade.

## Deliverable

Write
`/repo/doc/development/wip/77-new-input-api/validation/outcomes/LEDGER-02-changelog-actualisation.md`:

1. The entries you added, each with where you sourced it.
2. Claims you **could not** source well enough to write, and what you would need to settle them.
3. Anything you found that looks like a defect or a contradiction between the artifacts — report,
   do not fix.
4. Whether, in your judgement, the file now answers "what changed for me?" for a project author who
   has read nothing else. Say so plainly if it does not.
