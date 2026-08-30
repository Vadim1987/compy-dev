# FEAT-01 — cold peer review

**Verdict: approve with comments.**

The two features do what Decisions 36 and 37 say, in every edge I could
construct, with one exception (Finding 1) that the rulings do not cover. The
production change is three lines plus a config-key entry, the tests discriminate
against the plausible wrong implementations, and every consumer of the moved
payload — in `src/`, in `tests/`, and in both nested repos — was migrated. The
comments below are one narrow silent-failure case, one migration note the
decision itself promised and the CHANGELOG did not carry, and a set of live
documents outside the sprint's blast list that the payload split made false.

Reviewer's own verification, all re-run here rather than taken from a document:

- `busted tests` from `/repo`, PUC Lua: **1020 successes / 0 failures / 0 errors
  / 10 pending** — matches the claim, and no eleventh pending.
- Test arithmetic reconciles: 1011 + 8 (`114cbdb5`, seven `oneshot` cases in
  `tests/input/input_widget_callbacks_spec.lua` + one `configure` refusal in
  `tests/input/input_widget_control_spec.lua`) + 1 (`d0d7bc37`, the payload case)
  = 1020, exactly as `7a16e03f` states.
- The reversed edge's factual ground is **true** (see "The reversed edge" below).
- `lua-language-server` diagnostics on `src/controller/userInputController.lua`
  and `src/controller/consoleController.lua`: clean.
- No line added by the diff exceeds 64 characters.
- Working tree clean; no nested example repo was staged as a gitlink.

I did not open `sessions/session57/`, `FEAT-01-ledger-executability.md`, or
`FEAT-01-01-oneshot-ruling-sheet.md`, and did not need any of them: Decision 36's
ruled-edge section, Decision 37, `doc/input_api.md` and the code were sufficient
to judge every claim. That is a point in the work's favour.

---

## Finding 1 — a `oneshot` prompt opened from inside the submit chain is closed immediately, silently

**Severity: medium. Confidence: certain on the behaviour (reproduced); a
judgement call on whether it is a defect or an accepted consequence.**

**What is wrong.** `submit_flow` reads `self.oneshot` *after* the project's
callbacks have run (`src/controller/userInputController.lua:469`), and
`open_widget` re-seats `self.oneshot` from the new config
(`src/controller/userInputController.lua:332`). So if a submit callback takes the
widget down and opens a **second** `oneshot` prompt — the obvious way to ask a
follow-up question — the trailing `if self.oneshot then self:hide() end` reads the
*new* session's flag and closes the *new* widget before its user has typed
anything.

**Evidence.** Reproduced against the real project route with the standard
fixture (probe spec, not committed; re-runnable from any path since `.busted`
takes a file argument):

```lua
local input = F.activate_project()
input.show({ text = 'a', oneshot = true, on_text_entered = function()
  if second then return end
  second = true
  input.hide()
  input.show({ prompt = 'second', oneshot = true })
end })
F.session.press('return')
-- F.is_widget_visible() == false     <-- the second prompt is gone
```

Three variants run:

| chain | result |
|---|---|
| second `show` **with** `oneshot`, from `on_text_entered` | widget **closed** — the follow-up question never appears |
| second `show` **without** `oneshot`, from `on_text_entered` | widget stays up (correct — the unconditional re-seat cleared the flag) |
| second `show` **with** `oneshot`, from `after_submit` | widget **closed** |

**How it fails in practice.** A project asks "Your name?" with `oneshot`, and in
`on_text_entered` asks "Your age?" the same way. The second prompt flashes and
vanishes: no warning, no error, no callback fires. The project author's most
likely conclusion is that the second `show` did not run. There is no callback
position from which a second `oneshot` prompt survives — the close is the last
thing in the flow — so the workaround is to defer the second `show` to a later
frame, or to omit `oneshot` from it, and the guide says neither.

**In the work's defence,** the hand-written `after_submit = function() hide() end`
that Decision 36 defines `oneshot` as sugar for behaves identically here, so the
equivalence the decision leans on is *preserved*. The difference is visibility: in
the hand-written version the offending `hide()` is a line of the project's own
code, and a chained re-show placed after it in the same callback works. With
`oneshot` the close is invisible and unreachable.

**What I would do** — the parent should choose, and I do not think this should
block:

- **Cheapest:** one bullet in `doc/input_api.md`'s "Asking one question" edge list
  saying the close belongs to the submit, not to the widget, so a second
  `oneshot` prompt opened from a submit callback is closed with the first.
- **Or** make "spent by the `show` that carried it" literally true by binding the
  close to the session that armed it (e.g. a session counter bumped in
  `open_widget`, captured at the top of `submit_flow`). Note that capturing the
  *flag* alone at the top does **not** fix it — the trailing `hide()` still lands
  on whatever widget is up. That is two or three lines of new state, and the
  sprint's own restraint frame argues against it for a case this narrow.

Decision 36 rules four edges and this is not among them, so this is a gap in the
ruling as much as in the code.

## Finding 2 — the CHANGELOG's migration note omits the behaviour change Decision 37 says belongs in it

**Severity: low-medium. Confidence: certain.**

**What is wrong.** Decision 37's last bullet
(`doc/development/decisions/input.md:1566-1569`) says of the three `lines[1]`
consumers: *"For those three the payloads are only identical while the input is
one line … it is a behaviour change on three shipped examples and **belongs in the
migration note**."* The migration note that shipped (`CHANGELOG.md`, `Changed`,
lines 60-71) tells the reader that a joining callback needs no change and that an
indexing callback must drop the index and will otherwise fail silently. It does
not say that **dropping the index is not behaviour-preserving**: after the split,
a callback that read `lines[1]` and now reads `text` receives the whole
multi-line submission where it used to receive the first line.

**How it fails in practice.** A migrating project author does exactly what the
note says — deletes `[1]` — and their multi-line path changes meaning without any
signal. In-tree this is visible in the two shipped examples that index:
`src/examples/guess/main.lua:54` now runs `tonumber("1\n2")` → `nil` → `check`
returns early, and `src/examples/turtle/main.lua:93` now runs
`actions["fd\nrt"]` → `nil` → `eval` no-ops. Both were previously acting on the
first line. Neither raises; both silently do nothing. That is arguably the latent
bug being fixed, as the decision says — but it is precisely why it belongs in the
note, and the note is the one place a migrating author reads.

**Fix:** one sentence in the CHANGELOG `Changed` entry. `doc/input_api.md` needs
nothing — a new author reading it is told the payload is one string and never
learns the old shape.

## Finding 3 — live documents outside the sprint's blast list now describe the old payload

**Severity: low-medium. Confidence: certain on the staleness; a judgement call on
whether these documents are in FEAT-01's scope.**

The sprint updated `doc/input_api.md` and
`doc/development/internals/user_input.md`. It did not update the per-example
internals narratives, which quote the example sources verbatim and were correct
before this sprint:

| file | line | now false |
|---|---|---|
| `doc/development/internals/examples/repl.md` | 21, 29, 41 | quotes `on_text_entered = function(lines) print(string.unlines(lines)) end` — the exact code `17ed2c09` deleted; prose says "receives submitted line strings" |
| `doc/development/internals/examples/guess.md` | 25, 29 | quotes `function(lines) check(tonumber(lines[1]))` |
| `doc/development/internals/examples/turtle.md` | 33-34 | quotes `function(lines) eval(lines[1])` |
| `doc/development/internals/examples/tixy.md` | 61 | "consumes submitted line strings" |
| `doc/development/internals/examples/balloons.md` | 23 | "`deliver(lines)` forwards each submitted line set" — the joining `deliver` that `6d6c6e3` removed |
| `doc/development/internals/examples/valid.md` | 36 | quotes `function(lines) print(string.unlines(lines))` (this one was **already** drifted before the sprint — its source read `lines[1]` at `02cc51f9` — so it is only half this sprint's) |

Sharper than the narratives, because a human executes it:
`doc/development/smoke_checklists.md:336-345`, section **"B — submit delivers
lines, not a command string"**, tells the tester *"The API hands `on_text_entered`
an **array of lines**; the game's handlers index by a single string. The join
happens in `terminal.lua`."* All three sentences are now false: the API hands a
string, and `6d6c6e3` deleted that join. A tester following B1's hint
("if a correct answer scores as wrong, the join is the suspect") is sent to code
that no longer exists.

The sprint's own standard is the argument for fixing these: the `maze` commit
(`d2be028`) says *"a false comment about the framework's own contract is worse
than none"* and spends a commit on one comment. The same reasoning covers six
documents that state the contract wrongly.

## Finding 4 — Decision 5 still states the old payload, unannotated, in the file Decision 37 lives in

**Severity: low. Confidence: certain on the fact; low on whether the project
treats non-retired decisions as amendable.**

`doc/development/decisions/input.md:241` (inside **Decision 5**, which is ACTIVE,
not retired) reads: *"`on_text_entered(lines)` — fires at submit, with assembled
line strings."* And the file's own showcase, "The ergonomics payoff" at line 630,
still writes `on_text_entered = function(lines) greet(string.unlines(lines)) end`.
Decision 37, 1300 lines below, says the opposite. The file's convention is that a
superseded decision says so in its heading; here a live decision contradicts a
later live one with no pointer either way. A one-clause annotation on line 241
("payload changed by Decision 37") and a refresh of the line-630 sample would
close it. The sample still *works* — `unlines` is idempotent over a string — which
is why nothing caught it.

## Finding 5 — three ROADMAP rows have a cell too many, so the text after "*Original filing:*" does not render

**Severity: cosmetic. Confidence: high on GFM behaviour, moderate on whether this
matters here.**

`doc/development/wip/77-new-input-api/ROADMAP.md` rows `FEAT-01-01`,
`FEAT-01-07` and `FIX-02-01` were rewritten to keep the original filing after the
new ruling text, and the join is a literal `|`: `… *Original filing:* | **owner-gated,
and the design questions are real** …`. The table header has three columns, so
GitHub-flavoured Markdown **discards** the fourth cell — the whole original filing
is invisible in any rendered view, though it survives in the raw file that agents
read. If preserving it was the point, the separator should be something inline
(an em-dash, or `<br>`).

---

## What I checked and found nothing wrong with

Stated explicitly so the parent knows where the budget went.

**`oneshot` against Decision 36's four ruled edges** — all correct in code, not
just in tests:

- *Show-only, spent by its `show`.* `oneshot` is in `SHOW_ONLY_KEYS`
  (`src/controller/consoleController.lua:599-604`), and `check_keys` iterates
  `pairs(cfg)`, so even `configure{oneshot = false}` raises — consistent with
  `force`. The flag is seated **unconditionally** at
  `userInputController.lua:332`, not set-if-given, which is what makes a later
  bare `show()` clear it; the `it is spent by its own show` test genuinely fails if
  that line is made conditional. A `show` refused for want of `force` leaves the
  flag alone, which is right — a refused `show` applies nothing.
- *Submit only.* `cancel_flow` is untouched.
- *Composes with `after_submit`, closing last.* Verified by position and by test.
- *Clean submit only.* See below.

**The reversed edge — the claim about where the error boundary sits is true.**
`with_canvas_and_errors` (`src/controller/controller.lua:161-169`) is installed on
`love[k]` at `:237-241`, with a comment at `:232-234` saying "route IS the
boundary … not around each participant". `run_callback`
(`userInputController.lua:432-436`) calls the project's function directly, with no
`pcall`. So a raise in `on_text_entered` already unwinds past `after_submit`
today, and honouring the original recommendation really would have required a
protected call inside `submit_flow`. The test pins this against the error channel
(`love.state.app_state == 'snapshot'`) rather than against "no crash", which is
the right assertion — a silently skipped callback would pass a `has_no.errors`
check.

**No consumer left reading the old shape.** `grep -rn "on_text_entered" /repo
--include=*.lua` returns only the framework, the type annotations, the specs, and
the seven examples; all seven are migrated, including `maze` (`d2be028`) and
`balloons` (`6d6c6e3`) in their own repos. No test indexes a payload
(`grep "lines\[1\]\|t\[1\]"` over `tests/` finds nothing in the input specs), so
there is no test passing vacuously off `("abc")[1] == nil`. `string.join`
(`src/util/string/string.lua:271-289`) returns its argument unchanged for a
string, so the four joining consumers were genuinely safe before they were
rewired.

**Test honesty.** The `oneshot` positives (`closes on submit`, `composes …
closing last`, `spent by its own show`) and the `configure` refusal all fail if
the production lines are reverted; the payload case uses **multi-line** content,
so a split that never happened cannot pass it. Three of the eight
(`does not close on cancel`, `rejecting validator leaves it open`, `raised
callback leaves it open`) would also pass in a world with no `oneshot` at all —
that is inherent to pinning a *negative* edge, they are paired with the positive
and the control case, and two of the three still discriminate against the
plausible wrong builds (hiding before the callbacks; wrapping the chain in a
`pcall`). I would not ask for changes here.

**Scope and restraint.** Three production lines, one config-key entry, one type
annotation. `oneshot` adds one field to the widget, and the payload split adds
nothing. Neither introduces a new concept, a new dispatch path, or a new
lifecycle. This is within the stakeholder ask, and the `FEAT-01-06` convention
text is careful to say it is not enforced, which keeps it from becoming a moving
part.

**Commit hygiene.** One concern per commit throughout; the ruling, the build, the
docs and the example rewire are separate; the breaking change carries `!` and a
migration paragraph; every commit states the suite and the numbers reconcile
(1011 → 1019 → 1020). The behaviour changes are recorded in Decisions 36/37, the
CHANGELOG and the guide, not only in commit messages — except the multi-line
consequence of Finding 2.

**One observation, not a finding.** No shipped example uses `oneshot`, so it
lands with no end-to-end exercise — only mock-love unit tests. Decision 36 rules
that counting examples is the wrong measure for *justifying* the flag, which I
accept, but `src/examples/turtle` is the one place in the tree that writes the
boilerplate `oneshot` replaces (`main.lua:76-79`, `after_submit = hide` plus an
echo-guard re-arm), and converting it would demonstrate the composition edge in
running code. `FEAT-01-07` was scoped to the joiners, so this is out of scope
rather than missed; I note it in case a later row wants it.

---

## Parent verification addendum — session57, 2026-08-30

Every finding was re-verified in code before being acted on. **All five stand**; one needed
narrowing, and one was answered with documentation rather than the code fix the reviewer costed.

| # | verdict | action |
|---|---|---|
| 1 | **stands, narrowed** | the review's repro omitted `force = true`. A plain follow-up `show` from inside the chain is **refused with a warning** (Decision 3) and never happens, so the case is a *forced* re-show. Re-probed both ways: forced follow-up **with** `oneshot` → closed; **without** → survives. Documented in the guide and at the call site (`9eebbe3a`); **the code fix is put to the owner, not taken** |
| 2 | stands | the CHANGELOG's migration note now says dropping `lines[1]` is not behaviour-preserving either, and why that difference is also silent (`a113de70`) |
| 3 | stands | all seven documents fixed — the six per-example internals notes and `smoke_checklists.md` §B, whose three sentences a human executes (`a113de70`) |
| 4 | stands | Decision 5 carries an amendment pointer; its ruled text is left alone. The file's two stale showcases are corrected (`a113de70`) |
| 5 | stands | three rows fixed; the pre-existing `ARC-01-07` row was checked and is **correct** — only this sprint's rows had the extra column (`a113de70`) |

**Why finding 1 is not fixed in code.** Reading the flag *after* the callbacks is what lets a forced
follow-up survive at all; capturing it before would close that one too. The current placement is
therefore strictly the better of the two cheap options, and the remaining case needs a per-session
token — state added to a surface whose value is that it has none. That is a judgement about scope on
a just-ratified surface, so it is the owner's. The new test pins the property any fix would keep and
deliberately does **not** pin the case a fix would change; mutation-checked, capturing the flag early
fails exactly that case and nothing else.

**On the review itself.** It did not open the three withheld documents and did not need them, which
is evidence for the ledger's self-sufficiency — the question `FEAT-01-03` was opened to answer. Its
best work was finding 3: seven live documents outside the sprint's own blast list, including one a
human runs by hand.
