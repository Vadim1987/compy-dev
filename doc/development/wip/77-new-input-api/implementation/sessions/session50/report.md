# session50 report — `ARC-02` executed: `show` composes `configure`

Booted to execute `ARC-02`'s nine steps. All nine landed, plus one production fix found
mid-flight. **Ten commits, suite green at every one (979 → 990), nothing pushed.**

## What was built

The configuration boundary Decision 35 ruled, in the shape it ruled:

> **Content is the user's and `show`'s alone. Everything the project sets is applied by both
> calls, set-if-given, until replaced. `show` is `configure` plus the content baseline plus
> activation.**

| step | commit | what |
|---|---|---|
| `-01` | `b325826d` | the gate — `text`/`cursor` join `force` as `show`-only keys in Decision 15 |
| `-03` | `ef20466a` | `apply_config` → `configure_core` + `reset_content`; the `live` filter deletes |
| `-04` | `af1e8ec6` | `re_show` deletes; a forced `show` is a full re-setup |
| `-05` | `7b927249` | `configure` refuses `text`/`cursor`; `state.pending` deletes entirely |
| — | `191e28c3` | **production fix** — `show`'s config raise pointed inside the framework |
| `-06` | `cad0bb25` | the highlighter gets one home (`BUG-01-10`) |
| `-07` | `3bade47a` | malformed cursors refused, not a crash (`BUG-01-08`) |
| `-08` | `e4748e60` | docs, the deviation record, `CHANGELOG` |
| `-09` | `ddfe8be0` | spec + citation sweep |
| — | `ee59ccdc` | roadmap/ledger closure |

`-02` ran as a **practice, not a commit**: every breaking test was written first and *seen to
fail*, then landed with the step that made it pass. That is what the cold review's F3 required
and it held for all eleven.

**Closed:** `BUG-01-06` (+ its highlighter sibling), `BUG-01-08`, `BUG-01-10`, `BUG-01-02`
(ratified, no code), `FIX-02-21`, `FIX-02-12`, and the debt goal `T-CFG-BOUNDARY`. Debt register
10 ACTIVE → 5.

**Deleted:** `re_show`, `state.pending`, `consume_pending`, `stash_hidden_configure`, the widget's
`pending` field, one `WIDGET_STORES` member, the `live` filter table, `PER_SHOW_KEYS`. Production
is +81/−69 non-comment lines — an `ARC` row that actually deleted.

## Owner rulings taken in-session

- **`ARC-02-01` is an addition, not an amendment** — on the cold review's argument that Decision 15
  already raises for `force` as a `show`-only key, and its warn list never named `configure{text}`.
  This made the gate materially cheaper than the plan assumed.
- Consequent to that, **Decision 35's own "What this amends" was re-titled and re-argued**. Ratified
  text, edited on the ruling: leaving it would have had the two entries contradicting each other.

## Two design calls I made, which were not ruled anywhere

`BUG-01-08`'s debt row said the fix "gates a design rule" without setting one. I decided and
flagged rather than blocking:

- **Malformed cursor shapes raise** (`{}`, `{1}`, `{nil, 2}`, scalar, string) with a framework
  message naming `{line, col}` — rather than defaulting to line 1 / col 1. Guessing what `{1}`
  means is "more elaborate, not more predictable".
- **`cursor = false` is unset**, extending Decision 35 statement 3's uniform-unset rule to a
  user-owned field, so `computed or false` stays safe.

Out-of-range numbers still **clamp** — that distinction is preserved deliberately and is what
`doc/input_api.md` promises. Both calls are cheap to reverse.

## Non-obvious points for the successor

- **The `-06` ruling had a trap the ruling text could not see.** "The evaluator stops holding a
  copy" cannot be implemented as a forwarding closure: `UserInputModel:highlight` branches on the
  **truth** of `ev.highlighter`, so a forwarder is permanently truthy and silently replaces the
  validation-colouring fallback. It is metatable **resolution** instead. The breaking test's own
  failure output — `{ {} }` — *was* that fallback, which is how the trap surfaced as evidence
  rather than as a guess.
- **`bind_highlighter` is bound only where the evaluator is the widget's own.** Console and editor
  share theirs and it carries a *language* highlighter. Probed rather than argued: after a direct
  assignment, widget A resolves the fn, a fresh widget resolves `nil`, the console keeps its Lua
  highlighter. The fixture calls the same production method, not a local equivalent.
- **`show`'s error level was wrong and nobody had noticed.** `check_keys` raises at a fixed level
  while the two entry points sat at different call depths, so `show` reported a line inside
  `consoleController` — violating Decision 15's own Consequence. Fixed by levelling the depth
  (`configure` lifted into `api_configure`) rather than passing a per-caller level: equal depth is
  a property the two functions have by sitting together, a level argument is a number every future
  caller must get right. **Found by probing the message, not by reading the code.**
- **`clear_input()` is not `set_text('')`** still holds and is now written into `reset_content`'s
  comment, so the next simplification pass does not collapse the two branches.
- **`BUG-01-09` was deliberately left.** The roadmap says it "belongs with `ARC-02-03`", but it is
  not one of the nine steps and `reset_content` preserves the behaviour exactly. Its debt entry
  now says so, and it is the last unfixed defect on the primary call path.
- **Filed, not fixed:** `CONFIG_CALLBACKS` and `CALLBACK_KEYS` now hold identical contents in two
  modules, maintained separately. BACKLOG — no defect today, and unifying crosses a module
  boundary this sprint had no business in.

## Two mistakes, kept because the shape recurs

- **`git add -A src/`** swept the three nested example repos in as gitlinks, plus `src/STEPS.md`.
  Caught on `git show --stat`, fixed by `git rm --cached` + amend. **Stage explicit paths.**
- **A section-cut script ate `## BACKLOG`.** Retiring the *last* entry in a section, the cut ran
  past the section header because it only stopped at the next `### `. Caught by `grep -n "^## "`
  immediately after, reverted with `git checkout --`, redone with a boundary that also stops at
  `## `. **Verify section headers survive any scripted section surgery.**
- Related, and the reason neither became a finding: **my first citation checker reported all 13
  cited doc sections as dangling** — obviously wrong, since it flagged a heading I had just
  edited. Fixed the checker before believing its output. Same shape as session49's loose-grep
  trap, in the opposite direction: a checker that is too *strict* lies as readily as one that is
  too loose.

## Suite arithmetic

979 → 981 (`-04`) → 984 (`-05`) → 985 (`-06`) → 986 (trace fix) → 990 (`-07`). The documentation
steps added none. **The 10 pending never moved.**
