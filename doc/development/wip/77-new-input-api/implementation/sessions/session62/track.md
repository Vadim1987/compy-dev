# session62 — track

## Boot (2026-08-31)

- Fresh start: no prior `track.md`/`report.md` in `session62/` → first incarnation.
- HEAD `30308ed6` (docs(session61): wrap …). Working tree: only the known untracked scratch
  (`broken-busted/`, `claude.sh`, `input-pr-slices.tar.gz`, `repos.txt`, `src/STEPS.md`,
  `worklog.md`, the three nested example repos). No tracked modifications.
- Suite: **1032 / 0 / 0 / 10** — matches the prompt's baseline. Go.
- Boot reading done: `agents/sessions.md`, `agents/validation.md`, session62 prompt,
  session61 report, `agents/architecture_assistance.md`,
  `internals/project_sandbox_env.md`, `internals/event_dispatch_layers.md`.
- Mode on entry: **architecture assistance** (cognitive; evidence → judgment → owner ruling).
- Task is owner-brought and deliberately unscoped: the **project environment lifecycle**.
  Not pre-deciding the question; preparing to discuss it well.

## Session-limit interruption + resume (2026-08-31)

- Died after writing the note + sub-agent prompt; nothing committed, no code touched. Resumed clean.

## The owner's topic — the project owner's env inquiry

- Owner cited a project-owner inquiry verbatim: console `_G` vs running program is "an unintuitive,
  difficult to maintain and not even properly specified mess". Three expectations (R1 dofile
  transparent + callbacks restored; R2 `run()` from a well-defined default; R3 a project that does
  not hold the callbacks leaves its symbols to the console). Asks what else to require before a
  formal ticket. Called "super-important and pretty urgent".
- Saved verbatim: `validation/notes/owner-inquiry-console-env-lifecycle.md`.
- Commissioned a **Sonnet** code map (prompt of record in `validation/prompts/`, deliverable
  `validation/outcomes/session62-env-lifecycle-code-map.md`) — running while I did judgment work.
- Own verification first-hand (facts that drove the analysis):
  - console `dofile` passes NO env → `project_dofile` skips `setfenv` → chunk runs in the global env
    (`consoleController.lua:991-995,394-409`; `project.lua:109-113`; `util/lua.lua:17-29`).
    **R1 is largely today's behaviour, unwritten** — minus any callback restore.
  - project env descends from a boot-time deep clone of the console env (`:40-41,1117,1217-1220`),
    so R2 holds today by accident of timing, not by rule.
  - **two `compy` namespaces** — console (`:1090`) and project template (`:1192`), each with its own
    `compy.input` surface (`get_compy_input` not memoised, `:941`); the route dispatches only on the
    project one (`controller.lua:228-231`).
  - `compy.input.show()` with no widget is a **silent no-op** (`:749-757`) while `set_text`/
    `set_cursor` warn — deviation from warn-don't-swallow → candidate BUG row (C4).
- Analysis written: `validation/reviews/env-lifecycle-inquiry-assessment.md` — essence, the
  one-env/two-env/overlay fork, four `#77` intersections (C1–C4), blast radius (doc-only for `#77`),
  sequencing, roadmap disposition (**hand over, do not absorb**), and 14 pre-ticket questions.
- Nothing filed on the roadmap, nothing committed — all of it is for the owner's ruling.

## Code map landed — one correction to my own brief (2026-08-31)

- Sonnet map delivered (`validation/outcomes/session62-env-lifecycle-code-map.md`). Its
  load-bearing claims re-verified by me in code before use; the rest not relied on.
- **CORRECTION:** I told the owner "R2 is already satisfied by accident of timing". Wrong for the
  common case. `_reset_executor_env` has ONE caller — `close_project` (`:1428`). So `run()` on the
  already-open project resets NOTHING (`run_project` takes `get_project_env()` as-is, `:320`);
  `run("another")` goes through `open_project`→`close_project` and IS clean; `Ctrl+Alt+R` is
  stop+run and is NOT (`:1286-1289`). R2 fails exactly where a user iterates.
- Two persistent-corpus defects in `internals/console.md`: base_env is NOT protected
  (`table.protect`'s proxy discarded, `:1329-1332` + `util/table.lua:72-74`) and the base_env
  rationale is **inverted** (doc says reset-on-stop / restart-clean; code is reset-on-close only).
  The protect no-op is a SECOND SITE of an already-filed `general.md` entry.
- Also: `evacuate_required` is top-level-only (`:1443-1457`); a project's `love` is a boot-time
  clone never refreshed, so its `love.state.app_state` is frozen at 'ready'.
- Assessment updated in place (Part 0.7, new Part 0b, §1.1, Q7, §2.4 item 3). Correction marked as
  a correction in the document rather than silently rewritten.

## Owner reached C1 from the dofile side (2026-08-31)

- Owner: under R1, does a dofile'd file mean "no compy.input, no project-style dispatch" at the
  console — or do we build a console surface + dispatch?
- Verified: console `compy.input` exists (`:1090-1091`) but is inert twice over — no widget outside
  a run (ARC-01), and no chain at all (`ConsoleController:keypressed` `:1516` runs its own narrow
  dispatch; the shared chain is BACKLOG'd as Decision 1's convergence, scoped out on filing). Plus
  C3: the console's surface is a different object from the project's, so a `shortcuts` write there
  is never dispatched on.
- My line, offered for the project owner to confirm: **a console extension extends the vocabulary,
  not the interaction** — derived from their own model (R1 and R3 both restore the callbacks, so the
  category is non-interactive by construction). Counter-argument against building the console chain:
  the console IS already an input surface (REPL line, own controller `:49-52`), so a widget outside a
  run means two fields, two cursors, both claiming Enter; and console shortcuts have no run boundary
  to bound their lifetime. Also the scope-expansion flag from the replanning checklist.
- Recommended payment instead of a subsystem: memoise `get_compy_input` (one surface per process,
  closes C3) + warn-not-no-op with no widget (closes C4).
- Materialized as §2.2b in the assessment; new **Q15** — the largest sizing question, since the
  interactive reading makes the ticket depend on Decision 1's convergence.

## Owner rules Q15: the INTERACTIVE reading (2026-08-31)

- Owner reads `dofile` as "run an example's main.lua and have it work" — conventions, dispatch,
  single/double-click included. My §2.2b line ("vocabulary, not interaction") is REJECTED; kept in
  the doc as the argument weighed, superseded by §2.2c.
- **R1 self-contradicts under this reading**: main.lua returns immediately, so "restore callbacks
  upon return" kills the example on frame 1. Restore must bind to the program's END. With that fix
  the three bullets collapse to: *dofile and run are one lifecycle differing only in which env the
  program runs in*.
- **Correction of my own sizing claim**: this does NOT need Decision 1's console/editor convergence.
  The program takes the PROJECT route. Click synthesis is route-agnostic (counted at
  `controller.lua:947-951`, derived + emitted through the gateway at `:547-563`).
- Real dependency: run lifecycle becomes env-parameterized. Four items — `occupy_input` hardwired to
  `get_project_env().compy` (`:229`) makes C3 a guaranteed failure → memoise `get_compy_input` is a
  PREREQUISITE; widget seam moves; `save_user_handlers` survives (diffs vs `Controller._defaults`,
  `:1050-1065`) with a raw-unwrapped window; program-control verbs + loader env.
- Accepted-trade to name in the ticket: console-env execution runs in the real `_G` and can clobber
  console symbols.

## Four behaviour questions answered from code (2026-08-31)

- New note `validation/notes/console-env-observable-behaviours.md`: compy at the console (yes, base
  AND now; two instances — **base provenance**, `:461`/`:627`), `love.draw` typed at console (screen
  taken, re-wrapped by the update loop, `user_draw`/app_state NOT updated, only Ctrl+Shift+R is a
  universal way back), keyboard events (console handler replaced, called unwrapped, RESERVED combos
  survive), project-open changes nothing for the REPL env (`evaluate_input` switches only on
  `inspect`, while `get_effective_env` switches on running+inspect — the two disagree).
- `dofile` is doubly gated on an open project and resolves through the project mount (base-identical).
  Two by-products: `_G.o_dofile` is an ungated raw dofile on the console env with NO reader in `src/`
  (undocumented capability / likely dead), and `project_dofile` returns `true, chunk()` rather than
  the chunk's returns — a deviation from Lua's `dofile` to fix or ratify.
- Reasoned-not-run flag recorded: `reset()` from `ready` may leave `app_state = 'project_open'`.

## The pivot, and the spec draft (2026-08-31)

- Thread moved from "env lifecycle" to a genuine architecture pivot: **eliminate the project sandbox
  env**; console and project share one env, cleared to defaults in defined situations.
- Asked whether that undermines #77's premise. **Verdict: no** — #77's boundary is route +
  lifecycle state, not env identity. Exactly ONE line couples dispatch to the env
  (`controller.lua:229`, `get_project_env().compy`). What is lost: framework globals exposed to a
  careless project (already partial — leaves/devices are shared today). What gets simpler: is_shown's
  rationale, the piercing practice, the frozen `love` clone, base_env/pre_env, the
  evaluate_input-vs-get_effective_env disagreement, and `inspect` becomes trivially true.
- Owner then proposed **one shared dispatcher, `love.<event>` as the hook slot, eliminating PIC**.
  Verified: PIC is 200 lines and its `dispatch` is deliberately a free function "so any adopter can
  reuse it" — the move is anticipated by the code. seed_hooks + Decision 10 disappear; the canvas +
  error boundary needs a new home. Three forced sub-decisions: containment (the boundary RELOCATES
  as chain membership, it cannot dissolve — else unconsumed keys reach a hidden REPL), focus between
  two widgets, return-value semantics + the pointer asymmetry. First proposal in the thread that
  supersedes SHIPPED surface (`compy.input.hooks`, Decision 10) — successor direction, breaking,
  `serial` is a live consumer.
- Owner's three primitives: shared env / disarm / factory reset. Verified (2) already exists,
  unnamed, welded into stop: release_keyboard_route + set_default_handlers + clear_user_handlers
  (→reset_compy_input). Corrected the owner's framing twice: run() must ALSO factory-reset at the
  START (else R2 is dropped) → `run(p) ≡ reset; open; dofile('main.lua')`; and error handling stops
  being a difference if wrapping attaches to the install path. Named the missing fourth concern:
  there is a disarm and no arm, so **"running" becomes a derived predicate** — the codebase already
  does this in miniature (`user_is_blocking`/`user_is_interactive`).
- **Spec draft written**: `validation/reviews/env-and-dispatch-spec-draft.md` — stakeholder-level,
  shape not implementation. Flags the hooks-vs-`love.*` question as the ONE decision that belongs
  BEFORE release (documented surface, one external consumer).
- **Owner overruled my §3.1**: no guard on the `love.*` surface. Assignment stays free; the one rule
  is *don't touch `love.handlers`* (which is exactly what keeps the reserved keys — and therefore
  disarm — reachable). Rewrote §3.1: no proxy/shadow env/capture table; instead a **normalization
  sweep at the end of a load**, because a directly-assigned frame callback displaces the framework's
  loop and kills click synthesis for the program itself, and raw handlers escape the error boundary.
- Corpus discipline (owner): keep ALL of this under `wip/`. Nothing persistent touched; verified by
  `git status` — six new untracked files, zero tracked modifications.
