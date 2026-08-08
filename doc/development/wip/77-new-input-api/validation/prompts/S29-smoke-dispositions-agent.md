# S29 — sub-agent prompt of record: revalidate the SM1–SM5 smoke-finding dispositions

Spawned: 2026-08-08, session29, part 1 step 3. Model: **Sonnet** (explicit).
**Read-only.**

---

## Context you do not have

`/repo` is a LÖVE2D project (Lua 5.1; `busted tests` runs the suite under a
`mock_love` harness, no display). It is finishing a new input API for a PR.
Branch `feature/77-newapi-analysis-s20260615`, HEAD `e1e5e740`. The PR base is
`3256aac`. Suite: **955 / 0 / 0 / 3**.

The owner smoke-tested the feature by hand and reported five findings, SM1–SM5.
Session28 diagnosed all five **from the code, without running the app** — that
was the owner's explicit instruction, not a shortcut. Its conclusions are in:

**`doc/development/wip/77-new-input-api/validation/notes/S28-smoke-findings.md`**

Read it in full; it is the document under review. Supporting material:
`../outcomes/S28-smoke-analysis.md` (the sub-agent analysis it draws on),
`../reviews/S26-TF2-smoketest-results.txt` (the owner's original report).

**Your question throughout is narrow and answerable: does the code say what the
note says it says?** The note's reasoning is code-only, so it is checkable by
reading code — that is the whole point of this pass. You are not being asked
whether the rulings were wise, or to run the app (you cannot).

Three of the five dispositions are *decisions not to change anything*. A wrong
factual premise under a no-change ruling is the most expensive thing you can
find here, because nothing downstream will ever re-examine it.

## What to check, per finding

**SM1 — paint, right-click does nothing. Ruled not a defect.** Premises to
verify in code: paint binds only `hooks.singleclick` and `hooks.doubleclick`
and no `mousepressed`; the framework's click timer counts **left-button
releases only**; `btn` in `setColor`/`useCanvas` is an action selector (1
foreground / 2 background) that paint's own handler bodies write as literals,
*not* a value the framework passes in; the right button *is* used on the drag
path via `love.mouse.isDown`. Also the base claim: `git show
3256aac:src/examples/paint/main.lua` — did right-click do nothing there too?
And confirm the debt entry the note says it filed actually exists in
`doc/development/technical_debt/input.md` and says what the note claims.

**SM2 — sapper, an inert console prompt under the game. Ruled keep.** Premises:
sapper defines no `love.draw`; the gateway replaces the console draw path *only*
when a project supplies its own `love.draw`; `ConsoleView:draw` paints the input
strip whenever the screen mode is not `editor`. Plus the note's own
unprovability claim — that the input fixture stubs the `view.view` module
wholesale, so `ConsoleView:draw` is exercised by **no row** in the suite. Check
that last one properly; it is the note's second reason for not acting.

**SM3a — maze nav glyphs after a project→project transition. Left open.** The
only claim to check is the negative one: **there is no explicit font or
graphics-state reset between two consecutive project runs**, on the path from
`stop_project_run` to the next run's start. If such a reset *does* exist
somewhere, the note's "unresolved" framing is wrong and a scheduled runtime
check would be aimed at the wrong place. Confirm nothing was changed for this
finding.

**SM3b — maze, "Ctrl dims the screen". Ruled explained, no change.** Premise:
the dim overlay is Shift-gated by design in maze's own `macro.lua`
(`SHIFT_KEYS`, `handle_key`, `release_shift`), no path ties it to Ctrl, and
nothing in the platform dims anything. Verify **both halves** — the example's
gating *and* the claim about the platform, which is the easier one to assert
without checking.

**SM4 — keyboard, Ctrl+Alt+arrow. Ruled not a platform defect; a row added.**
The row is `tests/input/input_events_spec.lua`, "a two-modifier combo fires on
the real chord" (commit `73dae3f5`). The note states plainly that it **passed
before it was written** — a pin, not a proof — and that its reach was
mutation-checked by reordering `mod_order` in `src/util/key.lua` so that
registration canonicalises modifiers in a different order than dispatch emits
them. **Re-run that mutation yourself** (rules below) and report what actually
fails. Also check the note's characterisation of the neighbouring rows: that
none of them binds an exact two-modifier chord, which is why nothing could
previously catch the asymmetry.

**SM5 — keyboard, subgame 4 accepts no glyph. Fixed in the nested repo**
(`src/examples/keyboard`, commit `3a9d48c` in *that* repo, not this one).
Premises: `inputStale` dropped a `textinput` whose producing key was still held;
on desktop LÖVE `keypressed` arrives before `textinput`, so a key is *always*
held at its own first character; the key-cap renderer reads the held set live at
draw time, which is why Shift still appeared to work. Read the fix as it stands
in the repo today and judge whether the claimed mechanism ("a glyph is claimed,
one per press, released at keyup — reads the same in both orders") actually
holds in **both** delivery orders, including the case where `textinput` arrives
after its own `keyreleased`. Also check the note's claim that the platform
documents no ordering guarantee (`doc/development/internals/user_input.md`,
"Data flow").

**Context you need for SM5 so you do not report a false conflict:** this fix is
*known to be interim*. A later owner design supersedes it and will delete the
claim mechanism entirely — `doc/development/internals/examples/keyboard.md`.
Do not flag the supersession as a finding. Do report if the fix as it stands is
wrong *on its own terms*.

## Mutation-check rules (for SM4)

- Copy the file to `/tmp` **first**; restore from that copy.
- **Never** `git checkout --`, `git restore`, `git stash`, or any branch
  operation — a session on this feature destroyed its own uncommitted work that
  way.
- After restoring, confirm with `git diff --stat` and re-run `busted tests` →
  955 / 0 / 0 / 3.
- Report the exact mutation, exactly which rows failed (titles), and the restore
  confirmation. If a *different* row fails than the note claims, that is a
  finding.

## Rules

- **Read-only**, apart from the one SM4 mutation, restored immediately, and your
  deliverable. No `git add`, no `git commit`, **no `git push`**, no
  `git checkout --`, no stash, no branch switch.
- **The nested example repos** (`src/examples/balloons`, `src/examples/keyboard`,
  `src/examples/maze`, and `src/examples/paint` if present) are separate git
  repositories with their own remotes. You **must read** inside them for SM1,
  SM3a, SM3b and SM5 — that is expected and fine. You must **not** run any git
  write command inside them, and never `git push` from anywhere.
- The tree permanently carries the owner's untracked scratch (`claude.sh`,
  `src/STEPS.md`, `input-pr-slices.tar.gz`, `doc/tall_blocks.md`, some
  `doc/development/wip/` subdirs). Expected; leave it alone.
- **The `lua-lsp` MCP server is available** (definition / references /
  diagnostics / hover over a real AST of `/repo`). Useful for resolving a
  symbol or proving who calls what. Be aware, from this session's experience:
  its `references` query does **not** disambiguate methods by receiver type, so
  for a method name shared across several tables it returns a blend and grep is
  the tool that answers. Cross-check the two rather than trusting either alone.
  `sleep 1` after any `.lua` write before querying it.
- End with `git status --porcelain` and `git diff --stat`; record both. The tree
  must end byte-identical apart from your deliverable.
- **Report what is, including nothing-found.** Give the command and its output,
  or file:line — not a conclusion. Confirming that the note is accurate is a
  good result; do not manufacture findings. If a claim is *partly* right, say
  exactly which part fails.

## Deliverable

Write to
**`doc/development/wip/77-new-input-api/validation/reviews/S29-smoke-dispositions-revalidation.md`**.

One section per finding (SM1, SM2, SM3a, SM3b, SM4, SM5), each with
**CONFIRMED / FINDING / UNCLEAR** per premise — not one verdict for the whole
finding, since a disposition can rest on four premises of which one is wrong.
Then three closing lines:

1. Do any of the three **no-change** rulings (SM1, SM2, SM3b) rest on a premise
   the code does not support?
2. Is SM5's fix correct on its own terms, in both delivery orders?
3. What did you verify that came back clean, so the next reader knows the shape
   of your pass?

Your chat reply should be a short digest: per-finding verdicts, findings, and
the three closing lines.
