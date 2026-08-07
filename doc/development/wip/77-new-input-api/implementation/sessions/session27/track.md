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

## Sub-agents

- **S27-inventory** (Sonnet, read-only, background): verbatim extraction of every
  owner remark, main repo + three nested repos, into
  `validation/outcomes/S27-remark-inventory.md`. Prompt of record:
  `validation/prompts/S27-inventory-agent.md`. Severity/triage deliberately NOT
  delegated — that is this session's judgment work.
