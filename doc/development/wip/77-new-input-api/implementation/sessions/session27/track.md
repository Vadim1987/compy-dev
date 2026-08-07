# session27 — track

## 2026-08-07 — boot

- Booted per `agents/validation.md` + `agents/sessions.md`. Fresh start: no
  prior `track.md`/`report.md` in session27 → §2 "fresh start".
- HEAD `77fa43b1` "TF2: Human feedback written as prompt", branch
  `feature/77-newapi-analysis-s20260615`. Owner has committed three times since
  the session26 wrap (`89ae831d`): `9cc0ef50` (inline code-review remarks across
  40 files), `5f3078f3` (smoke-test results), `77fa43b1` (this commission).
- Tree state: only the known untracked scratch + three nested example repos.
  Nested repos each carry a fresh owner commit ("human(TF2): code review").
- **Baseline is a FINDING, not a go-signal: `busted tests` → 921 / 2 / 0 / 3**,
  expected 923 / 0 / 0 / 3. Both failures in
  `tests/input/input_cursor_text_spec.lua` (@61, @87), introduced by the owner's
  own edit in `9cc0ef50`: two-return `input.get_cursor()` rewritten as
  `assert.same({2,3}, input.get_cursor())`, which compares the table against the
  *first* return only. Owner's remark commit, so the fix is part of the remark
  triage, not a regression of ours. To raise with owner before touching.
- Commission of record: `validation/prompts/S27-human-commission.md` (referenced
  from the prompt as `validation/reviews/S27-human-c0mmission.md` — wrong dir and
  typo; the prompt is immutable, noting the correct path here instead).
- Remark inventory scale, first count: 193 `REMARK` hits outside `wip/` across
  41 files (src 6, tests 16, doc 14, CHANGELOG, plus the three nested repos).

## 2026-08-07 — owner's answers to the two boot questions

- Broken assertions: **fix as part of remark triage**. Owner's intent was
  readability (one-line assertion, not three-line ceremony); syntax was the
  slip, not the idea.
- Smoke-test findings in the nested repos are **in scope** this session.
- **Triage must classify by severity.** Expect questions and architectural
  contests, not just cleanups. Owner names the shape of what is still open:
  *full unification of pointer / keyboard / singleclick routing, and
  unification of signature* — final architectural tweaks that change the shape
  of the solution slightly without breaking the converged architecture. Some
  things the owner believed agreed (e.g. **shortcuts for mouse pointers**) are
  reportedly not in the code.
- **Cold sub-agents must review the triage and the plan quality before
  implementation.** Escalate to the owner only what advisors cannot settle.

## 2026-08-07 — work landed

- `c6a0778f` test fix: `assert.same({ l, c }, { input.get_cursor() })` — the
  owner's one-liner dropped the collecting braces on the right, so it compared
  the table against the FIRST return. Suite back to **923 / 0 / 0 / 3**. Third
  (unbroken) three-line row converted too, so the file reads one way.
- `f772c7de` `agents/rules/commenting.md` rewritten operationally (gate → four
  payloads → size rule → prohibitions → citations → `INTERIM:` marker + release
  check), plugged into `validation.md` (authority pointer + comment gate before
  slice regeneration) and `rules.md`. Chose `INTERIM:` over `TODO` because the
  tree already carries 115 durable `TODO`s that are backlog, not scaffolding.
- `b7205200` assembly guide: Set-3 letters re-lettered to apply order
  (docs 3a, tests 3b, code 3c–3f, examples 3g) across guide + commit messages +
  patch filenames; Set 4 turned into `4a-balloons` / `4b-maze` / `4c-keyboard`
  diff-cut patches with a verification recipe, replacing the `format-patch`
  one-liner that contradicted §5's own ruling.
- Nested repos ahead of their remotes: balloons 4, maze 3, keyboard 9 (each +1
  for the owner's `human(TF2)` review commit). Keyboard's local branch is
  `newinput` with no upstream set — its base is `origin/dsent/dev`.

## 2026-08-07 — triage and P0

- `81423c1f` inventory (187 ids) + triage with severity + 12 workstreams +
  execution plan. Coverage of all ids verified by script: 187 listed, 187
  unique, none missing, none duplicated.
- Severity scale: S0 defect / S1 shape-changing / S2 structural / S3 doc states
  something false / S4 editorial / S5 question. S3 gates the PR because the
  strategic frame makes `doc/input_api.md` the deliverable.
- Two things settled while triaging, both in code: `before_submit` is called
  and its return **discarded** while `before_cancel`'s vetoes
  (`userInputController.lua:414` vs `:431`); and `doc/input_api.md`'s argument
  that pointer shortcuts are impossible ("a combo needs a key to name") is
  **wrong** — `combo_string('*', keys)` already builds a triggerless combo for
  the `alt+*` wildcard, so the machinery exists.
- `12b9a39c` P0 evidence note. Three findings, all base-checked:
  - `handlers.userinput` dead, orphaned by **this feature** (both
    `love.event.push('userinput')` sites existed at `3256aac` and were removed
    here) — session26's `wrap_handler` shape again.
  - `always_shown()` + the whole `shown` flag are this feature's invention;
    base UIC had `is_oneshot()` and no flag at all. **Re-rated S1 and merged
    with R080** — both ask whether "shown" is the right primitive.
  - The reconfigure row is **green and blind**, proven by mutation: removing
    the `after_submit` re-show leaves 15/15 passing. Fourth instance of the
    pattern on this feature.
- Owner rulings needed before P2 (P1 gate): pointer combo vocabulary (button in
  combo vs modifier-only; which channels), `before_exit` veto (R181, I
  recommend no), R080+R044 together, and whether Decision 9 is deleted or
  rewritten.

## 2026-08-07 — cold reviews, then execution

- Two cold reviewers (fact-check: Sonnet; plan quality: Fable), both read-only,
  both without sight of my reasoning. Neither raised a structural objection;
  both found real errors. All corrections re-verified in code before accepting.
  Revision log is §5 of the triage doc; commit `e90b45c1`.
- Corrections against me worth remembering: **R135 was wrong** (the doc's
  evaluator-objects sentence is precise, not stale — a validator is a predicate,
  an `Evaluator` has `:apply()`); **`submit()`/`cancel()` do not exist**, the
  flows are `submit_flow`/`cancel_flow` and a *different* `cancel()` skips the
  veto entirely; **`before_exit` is called unguarded**, so a raise there aborts
  every teardown step after it (R127 is live, not just undocumented).
- The find that would have bitten: **179 comments cite decisions by number** —
  69 in `src/`, 110 in `tests/`. Deleting decision sections would renumber and
  silently invalidate an unknown subset. Decision 11 already precedents the
  tombstone. Constraint now written into the plan.
- **P1 gate resolved without escalating.** The owner's standing instruction was
  to escalate only what advisors cannot settle. Each open question was settled:
  W2's button vocabulary by the owner's own R115 ("combo constructed from
  modifier keys pressed, no trigger key"); `before_exit` veto by the unguarded
  teardown; R080 by two independent confirmations; Decision 9 by the tombstone
  rule. The mandate for W1–W4 is the owner's own message naming signature
  unification and pointer/keyboard/singleclick routing as required.

### Execution so far

- `c4f5a92f` **P2/W1** — `keys_pressed` dropped from the payload. Hooks,
  shortcuts and the widget now get LÖVE's leading arguments: `(k, isr)`, `(t)`,
  `(k)`. `before_submit`/`before_cancel` lose the argument too. Two rows: the
  pair, and a discriminating "passes no third argument" — without it, dropping
  the middle argument and dropping nothing look identical.
  `ignore_repeat` re-cut. 923 → 924.
- `5de5a6d` (keyboard repo) — `appKeypressed(k, isr)`. Committed with an
  explicit `-c user.name/email` rather than writing config into the owner's
  nested repo, which had no identity set.
- `069b93e9` **P3/W3** — one `_bindable` list, clicks included. Second fix
  needed to make it bite: `project_handler` demanded a console default exist
  before accepting a project's handler, and derived channels have none, so
  `love.singleclick` seeded nothing. Guard now asks the real question.
  924 → 925.
- `15679f9d` **P5/W5** — `before_submit` vetoes. Two rows: the veto and its
  control (a falsey return must NOT veto — otherwise a broken submit passes the
  veto row). 925 → 927.

Remaining: P4 (pointer shortcut tier), P6 (W4 dispatch/wiring collapse), P7–P11.

## Sub-agents

- **S27-inventory** (Sonnet, read-only, background): verbatim extraction of every
  owner remark, main repo + three nested repos, into
  `validation/outcomes/S27-remark-inventory.md`. Prompt of record:
  `validation/prompts/S27-inventory-agent.md`. Severity/triage deliberately NOT
  delegated — that is this session's judgment work.
