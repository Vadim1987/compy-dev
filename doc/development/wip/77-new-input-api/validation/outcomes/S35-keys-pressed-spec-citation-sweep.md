# S35 — citation sweep after `keys_pressed_spec.lua` is renamed and emptied

Read-only sweep for P14c. Scope: `src/`, `tests/`, `doc/`, `agents/`, and other tracked
directories, excluding `doc/development/wip/` and the three nested example repos
(`src/examples/{balloons,maze,keyboard}`). Ground truth is the repo at HEAD
(`e3d94104` — "test(input): the spec file loses its namesake, and becomes what it now
is" — at the time this sweep's evidence was gathered; a later, wip/-only tracking
commit landed after and is out of this sweep's scope by the prompt's own rule).

**Note on process:** an early, exploratory grep pass transiently appeared to show
`keys_pressed_spec.lua` still cited in `doc/development/tests.md`,
`doc/development/internals/event_dispatch_layers.md`, and
`tests/helpers/input_session.lua`. A second, careful pass (targeted greps, `Read`, and
`git log -p` on those exact files) found all three already corrected, in the *same*
commit that did the rename (`e3d94104`), whose message explicitly says: *"A
completeness sweep for further references is running; anything it finds lands as its
own commit"* — i.e. that commit anticipated this exact task and pre-fixed the three
citations it could see from the diff itself. The discrepancy between the two passes is
attributed to a concurrent commit landing on the tree mid-sweep (this session shares
the working tree with the orchestrating session); this report is based on the later,
verified-stable reads, cross-checked with `git log -p` against the actual commit that
introduced each fix.

## Findings

| # | Location | Text | Fact falsified | Suggested correction |
|---|---|---|---|---|
| 1 | `.claude/settings.local.json:28` | `"Bash(cp tests/input/keys_pressed_spec.lua /tmp/kp_backup.lua)"` | Fact 1 — names the file at its old path, which no longer exists (`git mv` to `tests/input/input_combo_serialisation_spec.lua`) | Update the path to `tests/input/input_combo_serialisation_spec.lua`, or drop the stale permission entry if the one-off backup it was for is no longer needed |
| 2 | `.claude/settings.local.json:114` | `"Bash(busted tests/input/keys_pressed_spec.lua)"` | Fact 1 — same: the path this permission grants no longer resolves to a file | Update to `"Bash(busted tests/input/input_combo_serialisation_spec.lua)"` |

**Scope caveat on both findings:** `.claude/settings.local.json` is **untracked**
(`git ls-files` does not list it; confirmed via `git status --porcelain .claude/` —
empty). The prompt scopes the sweep to "`src/`, `tests/`, `doc/`, `agents/`, and any
other **tracked** directory," so strictly this file is outside the sweep's stated
scope. It is reported anyway under the standing rule ("a dangling citation is worse
than none") because it is a live, currently-broken reference to the old path — if
either permission string were invoked literally today, the underlying command would
fail (`No such file or directory`). If the parent agrees it's out of scope, both rows
can be dropped without affecting the rest of this report.

No other findings. The whole-repo sweep (grep, case-insensitive, stem-level, plus `git
grep` on tracked files only, plus LSP cross-check) turned up nothing else that fact 1,
2, 3, or 4 falsifies.

## Checked and already correct

- **`doc/development/tests.md:45`** (coverage-map row) — previously read `..., the
  `input_*_spec.lua` contract suite (`#input`; see Input Contract Suite below),
  `keys_pressed_spec` |`; now reads `..., the `input_*_spec.lua` contract suite
  (`#input`; see Input Contract Suite below) |` — fixed in `e3d94104`. Verified via
  `git show e3d94104 -- doc/development/tests.md` and a fresh `grep -n keys_pressed`
  (no hits).
- **`doc/development/tests.md:68`** (Input Contract Suite narrative paragraph) — never
  named `keys_pressed_spec.lua` or `input_combo_serialisation_spec.lua`; confirmed via
  `git show 9cc0ef50:doc/development/tests.md` (the commit before the rename) that the
  old file was listed only in the separate coverage-map row (finding above), not in
  this enumeration — so nothing here is falsified by the rename. (Whether the new
  `input_combo_serialisation_spec.lua`, which does carry the `#input` tag, *should* be
  added to this enumeration is a separate curation question, not something any of the
  four facts falsifies — flagged only for the parent's awareness, not as a finding.)
- **`doc/development/internals/event_dispatch_layers.md:53`** — previously "Tests
  reproduce this startup wiring directly: `tests/input/keys_pressed_spec.lua` and
  `tests/helpers/input_session.lua`."; now cites only `tests/helpers/input_session.lua`
  — fixed in `e3d94104`, verified via `git show e3d94104 -p` and a fresh
  `grep -n keys_pressed` (only one unrelated hit, line 39, `Controller.keys_pressed`
  bookkeeping — a still-valid reference to the still-existing production field, not a
  test citation; correctly out of scope per the task's own carve-out for fact 4).
- **`tests/helpers/input_session.lua:6`** — previously "Built on the
  `keys_pressed_spec` raw-handler pattern; NOT an `EditorSession` generalisation
  ..."; now reads "NOT an `EditorSession` generalisation (that helper bypasses the
  love handlers and drives `EditorController` directly)." — fixed in `e3d94104`.
- **Four deleted test-case descriptions** ("adds key on keypressed", "removes key on
  keyreleased", "tracks multiple held keys", "keeps lr/l/r variants distinct") — zero
  occurrences anywhere in tracked, in-scope files (`git grep` across the four exact
  strings, whole repo minus `wip/` and examples).
- **`setup_callback_handlers` citations** — every remaining occurrence points to a
  genuinely current caller: `src/main.lua:385`, `src/controller/controller.lua:780`
  (definition), `tests/helpers/input_session.lua:46,49` (its own real call),
  `tests/input/input_shortcuts_click_spec.lua:77` (its own real call),
  `doc/development/internals/event_dispatch_layers.md` (describes the production
  mechanism, cites no test file for it beyond the already-fixed line 53), and
  `doc/development/technical_debt/general.md:50` (describes production code). None
  cite the deleted/renamed spec file as an example.
- **`kp_handler` / `kr_handler`** — zero occurrences anywhere in the tracked tree;
  these were local to the deleted preamble and did not leak into any other file's
  prose or code.
- **"held-key set" / "held key set" / "pressed-keys table" prose** — all surviving
  occurrences (`doc/development/decisions/input.md`,
  `doc/development/technical_debt/input.md`, `src/controller/controller.lua:393`) are
  about the *design* of the still-existing production field/decision history, not
  citations to the deleted tests — correctly out of scope per the task's explicit
  carve-out (a reference to the field in production code, or to the *decision* about
  it, is not a finding; only a reference to the *tests* that covered it would be).
- **`compy.input.keys_pressed` / `Controller.keys_pressed` mentions generally** —
  swept across `doc/development/decisions/input.md`,
  `doc/development/technical_debt/input.md`,
  `doc/development/internals/user_input.md`, `doc/input_api.md:366`,
  `src/controller/*.lua`, `src/types.lua`, `tests/helpers/input_fixture.lua`,
  `tests/input/input_widget_callbacks_spec.lua` — every one describes the field or a
  `PENDING`/decision marker about its future removal (P14d, not this step); none
  claims a test suite currently asserts on the four deleted cases or on the
  deleted file's startup-wiring role.
- **`input_events_spec` / `input_nfr_mechanism_spec` cross-references** (in
  `doc/development/tests.md:54,68,70`, and sibling spec files' own comments) — all
  describe current, still-true structure (which surface each file covers, the NFR/
  mechanism-guard split); none claims held-key lifecycle coverage that fact 4 removed.
- **`agents/`** — no occurrences of `keys_pressed`, `held-key`, or `held key` at all.
- **`input_combo_serialisation_spec.lua`** itself (the renamed survivor) — matches the
  three facts exactly: no `setup_callback_handlers` call, no `love.handlers`
  installation, no `kp_handler`/`kr_handler`; calls `Controller.combo_string` directly
  (confirmed by reading the file in full).

## What I could not determine

- **LSP index staleness.** `mcp__lua-lsp__references` for both `setup_callback_handlers`
  and `keys_pressed` still returns entries for the now-deleted
  `tests/input/keys_pressed_spec.lua` (10 references reported, file unreadable — it
  doesn't exist) and stale line numbers/content for
  `tests/input/input_nfr_mechanism_spec.lua` that do not match the file's current
  content (a direct `grep -n keys_pressed` on that file today returns zero hits, while
  the LSP reported six `keys_pressed` occurrences at specific lines). The LSP also
  surfaced two phantom shadow paths
  (`tests/helpers/input_session.lua.tmp.13.58987d911ad4`,
  `tests/input/input_nfr_mechanism_spec.lua.tmp.13.5ca242889ba6`) that do not exist on
  disk (`find` confirms). This looks like server-side index/cache lag rather than a
  repo-content issue — I did not have a way to force a reindex from this session, and
  per the brief I could not wait past a single `sleep 1`. Treat the LSP results for
  these two symbols as unreliable until it reindexes; the grep-verified filesystem
  state is what this report is based on.
- **Unrelated test-count drift**, noticed in passing, not investigated further because
  it is not something any of the four listed facts falsifies: `doc/development/tests.md:82`
  still states `busted tests` reports "861 successes / 0 failures / 0 errors / 3
  pending," while commit `e3d94104`'s own message reports "Suite green: 940 / 0 / 0 /
  3." A 79-test gap is far larger than anything the four facts here could produce (a
  handful of deleted cases), so this predates and is independent of this step —
  flagged for the parent's awareness only, not included as a Finding.
