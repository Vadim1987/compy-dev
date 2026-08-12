# P-17-00 — worker prompt of record: the maze input inventory (cold, mechanical)

**Spawned by:** session39, 2026-08-12. **Model: Sonnet, passed explicitly.**
**Deliverable path (write it yourself):**
`doc/development/wip/77-new-input-api/validation/outcomes/P-17-00-adoption-inventory.md`

---

## What you are doing

`src/examples/maze` is a nested repository, currently on branch **`newinput-edge`** at `b8cc436`.
It is a **source root that emits two Compy programs** (`maze` and `draw`) via `.compy/build` — read
`BUILD.md` first, it explains the layout in a page.

Your job is a **complete, mechanical inventory of every place this repo touches keyboard or pointer
input**, classified against a checklist. **You are not deciding anything.** No verdicts, no
recommendations, no "should". The parent does the judgement; a site you classify wrongly is
recoverable, a site you fail to *find* is not — so **completeness is the deliverable**.

## The instrument

**`doc/development/conventions/input_adoption.md`** — a question-and-action checklist, Q1 through
Q10, plus "Rules of restraint". Read it in full before you start. For each site you find, name the
question(s) whose **shape** it matches. If a site matches no question, say so — that is a real and
useful answer, not a failure.

Supporting reference, for *what the platform offers* only: `doc/input_api.md`. Quote it where a
replacement surface exists; do not paraphrase its guarantees from memory.

## Method

1. **Find the surface exhaustively.** Grep is the opening move, and one pass is not enough. At
   minimum sweep for: `love.keypressed`, `love.keyreleased`, `love.textinput`, `love.mouse*`,
   `love.touch*`, `love.wheelmoved`, `love.focus`, `love.keyboard.*`, `love.mouse.*`; then for the
   *shapes* the checklist names — tables or booleans mirroring key state, `*_was_down` companions,
   `isDown` folds over `lshift`/`rshift` and friends, per-tick polls that compare against a previous
   value, dispatch tables keyed by key name, anything reading `love.state`.
   **Then sweep again from the other end**: read the files that *dispatch* (`controls.lua`,
   `core_editor.lua`, `maze_main.lua`, `draw_main.lua`, `menu.lua`, `draw_menu.lua`, `maze_plan.lua`,
   `macro.lua`) top to bottom, because an indirection (`ctrl_pressed`, `ctrl_update`, `CMD_HANDLERS`,
   `SYSTEM_KEYS`) hides a site from every grep pattern you would think of.
2. **Follow the indirections and record them.** `ctrl_pressed` / `ctrl_update` are assigned in
   several places and called in two; a reader needs the *set* of possible values, per program.
   The `lua-lsp` MCP server (definitions / references over a real AST of `/repo`) is the right tool
   the moment you have a concrete symbol — grep finds candidates, the LSP proves who calls what.
3. **Report per program.** A file may be CORE (shipped into both `maze/` and `draw/`), MAZE-only or
   DRAW-only — `.compy/build` says which. **Say which for every file you cite**, because a change in
   a CORE file lands in two programs.

## The deliverable's shape

A table of contents, then **one entry per site**, each with:

- **Location** — `file:line`, and its build class (CORE / MAZE / DRAW).
- **The code** — quoted, a few lines, enough to recognise without opening the file.
- **What it does** — one or two sentences, mechanical, no evaluation.
- **Checklist match** — the `input_adoption.md` question number(s) whose shape it matches, or
  "none".
- **What the platform offers** — the `compy.input` / `Key` surface that addresses that shape, cited
  from `doc/input_api.md`. If nothing does, say "nothing documented".
- **Reachability** — which control mode / screen / level track can actually reach this code. Read
  `levels.lua`'s `TRACKS` and the `controls = …` fields, and `draw_main.lua`'s screens. Do not guess.

Close with two short sections:

- **Counts** — sites per checklist question, per program. Recompute them from your own table; do not
  carry a number from anywhere else.
- **Anything the checklist has no question for** — input-shaped code that matched nothing. This is
  where a genuinely new observation would live.

## Rules

- **Read-only, and this one is serious.** Touch no `.lua` file. Touch no git state: no commits, no
  staging, **no checkouts, no branch switches** in `/repo` or in any nested repo under
  `src/examples/`. `maze` was moved to `newinput-edge` deliberately this session; moving it destroys
  work. Read the working tree directly (it is already on the right branch) — you do not need `git`
  at all except to confirm the branch with `git -C src/examples/maze branch --show-current`.
- **Do not read** `P-17-01-practice-catalogue.md`, `S39-maze-upstream-input-assessment.md`, or
  `P-17-00-shape-and-plan.md`. You are the cold pass; those are the warm ones, and the point of
  running you separately is that the checklist gets its say before the sprint's own history does.
- **Do not pad and do not speculate.** If reachability is unclear from the code, write "unclear from
  code" rather than a guess.
- **Every claim about behaviour is about code you have read.** Nothing here runs the game.
- Plain Markdown, lines wrapped at ~98 columns, no emoji. Write the file yourself, then report a
  short digest.
