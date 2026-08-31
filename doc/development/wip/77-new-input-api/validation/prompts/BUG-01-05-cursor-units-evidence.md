# Sub-agent prompt of record — `BUG-01-05` / `T-CURSOR-BYTES` evidence gathering

**Spawned:** session60, 2026-08-31 · **Model:** Sonnet · **Mode:** research only, no edits.

**Why delegated:** the debt entry is vague — it names neither function, only "the cursor-setting
path". The unit disagreement has to be located and characterised before the design call can be
made, and locating it is mechanical.

---

## Prompt as issued

(Reproduced verbatim below; deliverable at
`validation/outcomes/BUG-01-05-cursor-units-evidence.md`.)

You are a research worker in the LÖVE2D project at `/repo` (cwd, a git repo). **Gather evidence
only — make NO edits to any file except the one deliverable named at the end.** Do not run `git
commit`. Do not fix anything you find.

### Tools

- **`lua-lsp` MCP server is available** — `definition`, `references`, `hover`, `diagnostics` over a
  real AST of `/repo`. Grep to find candidates, then LSP to resolve a symbol and to answer "who
  calls this". Lua is dynamically typed, so LSP refs can be incomplete — **cross-check every
  reference list with grep** and report disagreements.
- `busted tests` runs the suite (mock_love, no display). Baseline **1028 / 0 / 0 / 10**. Read-only
  runs are fine. You may also write a THROWAWAY probe script under
  `/tmp/claude-1000/-repo/*/scratchpad/` if it settles a question — never inside `/repo`.
- The codebase is UTF-8 aware in places: `string.ulen`, `utf8.len`, `sanitize_utf8` all exist.

### The claim to test

`T-CURSOR-BYTES` (`doc/development/technical_debt/input.md`, ACTIVE) says only:

> Two functions disagree on the unit a cursor position is counted in — one clamps **bytes**, the
> other measures **characters** at the boundary. Which is right has not been decided.
> Where: the cursor-setting path in `userInputController.lua` / `userInputModel.lua`.

It names neither function. **Your first job is to find them.**

### What to establish — answer each, with file:line evidence

1. **Name the two functions.** Find every place a cursor column is clamped, compared against a
   length, or converted, in `src/controller/userInputController.lua` and
   `src/model/input/userInputModel.lua`. For each: does it use `#s` / `string.len` /
   `string.sub` (BYTES) or `string.ulen` / `utf8.len` / `utf8.offset` (CHARACTERS)? Quote the
   lines. Build a small table: site → unit → what it does.
2. **Which is the "boundary event"?** The entry says one measures characters "at the boundary".
   Identify what boundary is meant — most likely the project-facing `compy.input` surface, or a
   callback that reports a cursor position outward. Say which, with the line.
3. **Is the disagreement observable?** Construct the concrete reproduction: a specific multi-byte
   string, a specific `set_cursor` call, and what the user sees vs what they asked for. **Run it**
   (probe script or a scratch busted spec under the scratchpad, NOT in `/repo/tests`) and report
   the actual observed output, not a prediction. If it turns out NOT to be observable through the
   public surface, say so plainly and show why — that is a legitimate and important answer.
4. **What does the public contract promise?** Read `doc/input_api.md` on `set_cursor` /
   `get_cursor` and on out-of-range clamping, and `doc/development/internals/user_input.md`,
   *"Cursor manipulation and \"reset\""*. Quote what is promised about units. Does either document
   commit to bytes or characters, or is it silent?
5. **What do the existing tests pin?** `tests/input/cursor_spec.lua`,
   `tests/input/input_cursor_text_spec.lua`, and any other spec touching cursors. Name the `it(…)`
   descriptions that bear on units. **Is any existing test asserting a byte count that a
   character-based fix would break?** This is the single most important question for sizing.
6. **How does the rest of the model count?** Does typing/inserting/deleting move the cursor in
   characters or bytes? Does the *view* (rendering, `VisibleContent`) count in characters or
   bytes? A fix has to agree with whichever the rest of the system already uses — establish that
   majority, with citations.
7. **Base check.** The PR base is `3256aac`. Use `git show 3256aac:<path>`. For each of the two
   sites in (1): does it exist at base, in the same unit? State plainly whether this feature
   introduced the disagreement, widened it, or inherited it unchanged. Report this prominently —
   it is the same question that reframed two earlier rows.
8. **Blast radius.** If the byte site were changed to count characters, what else calls it and
   could regress? Enumerate concretely from the call sites, not in the abstract.

### Rules

- **Verify in code, and prefer a run to a reading where a run is possible.** The debt entry is a
  hypothesis to test, not a fact to restate. Verdicts in this workspace have been overturned by
  someone re-reading the code.
- Say "uncertain" where you are, and say what would settle it. Do not guess.
- Factual report only — no recommendation, no fix design. The design call is not yours.

### Deliverable

Write to **`doc/development/wip/77-new-input-api/validation/outcomes/BUG-01-05-cursor-units-evidence.md`**
— one section per numbered question, `file:line` citations throughout, the probe's actual output
pasted in for (3), and a closing **"Corrections to the debt entry"** section. The file is the
durable artifact; your chat reply is secondary.
