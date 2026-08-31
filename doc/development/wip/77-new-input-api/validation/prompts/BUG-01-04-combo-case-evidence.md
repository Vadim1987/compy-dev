# Sub-agent prompt of record — `BUG-01-04` / `T-COMBO-CASE` evidence gathering

**Spawned:** session60, 2026-08-31 · **Model:** Sonnet · **Mode:** research only, no edits.

---

## Prompt as issued

You are a research worker in the LÖVE2D project at `/repo` (cwd, a git repo). **Gather evidence
only — make NO edits to any file except the one deliverable named at the end.** Do not run `git
commit`. Do not "fix" anything you find.

### Tools you must know about

- **`lua-lsp` MCP server is available** — `definition`, `references`, `hover`, `diagnostics` over a
  real AST of the `/repo` workspace. This is the correctness tool for Lua. Use grep to find
  *candidates*, then the LSP to resolve a concrete symbol, and above all to answer **"who calls
  this"** (`references`). Lua is dynamically typed, so LSP refs can be incomplete — **cross-check
  every reference list with grep** and report any disagreement between the two.
- Tests run with `busted tests` (uses mock_love, no display needed). Current baseline is
  **1025 successes / 0 failures / 0 errors / 10 pending**. You may run the suite read-only.
- After any `.lua` edit anywhere, `sleep 1` before querying the LSP — but you are not editing, so
  this should not arise.

### The defect

`T-COMBO-CASE` (`doc/development/technical_debt/input.md`, ACTIVE section) claims:

> `combo_string` (`src/controller/controller.lua`) does not normalise the case of a **textinput**
> token, while the registration side — `Key.new_handler_table`'s `__newindex` in
> `src/util/key.lua`, via `normalize_combo` — lower-cases. So with `shift` held and `I` typed,
> dispatch looks up `shift+I` while the handler is stored under `shift+i`. The slot is
> **unreachable**: the handler can be written but can never fire. Bare lower-case tokens are
> unaffected.

The claim was measured 2026-08-03 and the tree has moved a great deal since.

### What to establish — answer each, with file:line evidence

1. **Is the defect still real, exactly as described?** Read `combo_string` and every normalising
   path on the registration side. Quote the actual lines. If the shapes have changed, say what
   they are now.
2. **Both directions.** Registration lower-cases — does it lower-case the *whole* combo string, or
   only the modifiers, or only the terminal token? Same question for dispatch. Give the exact
   transformation each side applies.
3. **Does this affect `keypressed` combos too, or only `textinput` combos?** LÖVE `keypressed`
   scancodes/keyconstants are already lower-case by convention; `textinput` delivers the actual
   typed character, which is where an upper-case token can arise. Confirm or refute that split in
   the code.
4. **Who calls `combo_string`** — the full call-site list (LSP `references` + grep backstop). For
   each, say whether the token reaching it can be upper-case.
5. **Is there a reservation / global-shortcut path that also builds or matches combo strings?**
   The framework reserves some combos; check whether that path shares the normalisation or has its
   own.
6. **Existing test coverage.** What does `tests/input/input_combo_serialisation_spec.lua` (and any
   other spec touching combos) already pin about case? Name the `it(…)` descriptions. Is there any
   test that would *break* if dispatch started lower-casing the textinput token?
7. **Base check — is this ours or pre-existing?** The PR base is `3256aac`. Use
   `git show 3256aac:<path>` to compare `combo_string` and the registration normalisation against
   the base. Say plainly: did this feature introduce the asymmetry, widen it, or inherit it
   unchanged? This matters more than anything else on the list — report it prominently.
8. **Blast radius of the obvious fix.** If dispatch lower-cased the textinput token to match
   registration, what else runs through that code path and could regress? Enumerate concretely;
   do not speculate in the abstract.
9. **Any consumer in-tree**, including the nested example repos under `src/examples/` (balloons,
   maze, keyboard, turtle, tixy, pong), that registers a textinput combo at all — upper-case or
   not. `git grep` is fine here.

### Rules

- **Verify in code. Never report a claim you have not read the line for.** The debt entry above is
  a hypothesis to test, not a fact to restate — a previous verdict in this workspace was overturned
  exactly by someone re-reading the code.
- Where you are uncertain, say "uncertain" and say what would settle it. Do not guess.
- Keep it factual. You are not being asked for a recommendation or a fix design.

### Deliverable

Write your report to **`doc/development/wip/77-new-input-api/validation/outcomes/BUG-01-04-combo-case-evidence.md`**
— one section per numbered question above, `file:line` citations throughout, and a short
**"Corrections to the debt entry"** section at the end listing anything the entry gets wrong.
That file is the durable artifact; your chat reply is secondary, so put everything in the file.
