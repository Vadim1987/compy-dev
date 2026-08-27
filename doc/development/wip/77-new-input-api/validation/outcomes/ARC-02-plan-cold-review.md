# ARC-02 plan — cold review

**Verdict: approve with changes.** The design is sound and the deletions are real; three things
must change before execution — a second deviation against stakeholder-seen text that the plan
declares does not exist, a nil-widget guard the hidden-`configure` rewrite needs, and a step
ordering that cannot hold as drawn under the suite-green rule.

Reviewer: cold session, 2026-08-27. Did **not** read `sessions/session49/track.md`,
`force-and-configure-intent-recovery.md` or `ARC-01-07-reconfiguration-policies.md` before forming
this view. Afterwards I opened, deliberately and only, three *primary* sources rather than the
session's reasoning: `design/spec.versions/version01.md:168-212` (the frozen stakeholder-seen text,
to check the intent claim in §1 of the plan), `notes/owner-attestation-prompt-field.md` (an owner
ruling, not session reasoning), and `ROADMAP.md:215-250` (to see the plan mirrored into the ledger).
Baseline suite confirmed locally: **979 successes / 0 failures / 0 errors / 10 pending**.

**Read the addendum at the end first if you are the owner:** a draft **Decision 35** appeared in the
working tree *while this review was being written*, and it settles both picks. The findings below
were formed without it and are unchanged by it; the two pick sections are now advisory.

---

## Check 1 first, because it was the highest-value thing to falsify: §2(a) holds

`UserInputModel:clear_input()` (`src/model/input/userInputModel.lua:344-351`) does five things:
`entered = InputText()`, `text_change()`, `clear_selection()`, `_update_cursor(true)`,
`custom_status = nil`, `history:reset_index()`. `set_text` (`:125-145` — the plan cites `:125-140`,
the body actually ends at `:145`) does none of the last three. **The three named effects are
correct and the recommendation to keep `clear_input` stands.**

I checked the one way the claim could still have been wrong — that `set_text('')` might not even
empty the field. It does: `string.lines('')` returns `{''}`
(`src/util/string/string.lua:258-266` → `string.split`'s empty-string branch; confirmed by running
it under `luajit`), so `n_added == 1` and `entered = InputText({''})`. No fourth effect.

**One refinement, in the plan's disfavour.** §6 calls this "the trap in this plan". On the widget
ARC-02 actually touches — the *project* widget — all three effects are close to inert today:

- `custom_status` is written only by `editorController.lua:283`; nothing on the project path sets it.
- history is unreachable from a project (`compy.input` exposes no history call), and
  `userInputModel.lua:418-422`'s own comment calls the project widget "never-history-reading".
- a selection cannot form: the project widget is built `UserInputController(model, true)`
  (`consoleController.lua:203`) — `disable_selection = true` — and `keypressed`'s `selection()`
  gates `hold_selection` on `not self.disable_selection` (`userInputController.lua:673-681`).

So the correct instruction is still "keep `clear_input`" (it costs nothing), but nobody should treat
a green suite after `-03` as evidence that the effects were preserved, and nobody should spend
review time hunting for the observable difference. There is no test naming
`clear_selection`, `custom_status` or `reset_index` anywhere in `tests/` (grep: zero hits).

---

## Findings, most severe first

### F1 — the plan says pick B is the only change against intent. It is not. `show{force=true}` clearing is a second one, and it is unflagged

The frozen, stakeholder-seen spec says of `force`
(`design/spec.versions/version01.md:178-180`):

> *"the singleton is then reconfigured in-place with the new config (content replaced if `text` is
> provided, **preserved otherwise**), still with no cancel chain."*

The plan restores the first half of that sentence (`re_show` today applies `text` and nothing else)
and **reverses the second half**: under §1's `reset_content`, a forced show with no `text` clears.
`input_widget_control_spec.lua:151-160` pins today's behaviour explicitly — *"force with NO text: a
reconfiguration that changes nothing — content survives"* — and it is green.

§4 states that pick B "is the one item in the plan that is a change against **intent** rather than
against machinery invented in this cycle". That is false as written, and it is the sentence a
future reader will rely on when auditing what this sprint traded away.

This is not a reason to change the design. The owner's attestation
(`notes/owner-attestation-prompt-field.md`, item 4 — *"new `show()` must clear it"*) supports
clearing, and `FIX-02-22` already rules "fix the documents" for the sibling hide/show case. It *is*
a reason to (a) add this to the deviation record alongside pick B, (b) say in `-04`'s commit
message that a stakeholder-seen sentence is being reversed, and (c) extend `FIX-02-22`'s document
list — `version01.md` is frozen and must not be edited, so the record goes in the workspace and in
`internals/user_input.md`.

### F2 — the hidden-`configure` rewrite needs a nil-widget guard, or it breaks a green NFR spec

The plan's pick-B argument rests on "a hidden `configure{prompt = …}` applies straight away". Today
the hidden branch never touches the widget: `build_widget_api`'s `configure` returns early into
`stash_hidden_configure` (`consoleController.lua:819-822`), and that function is inert when there is
no store (`:716-717`). Writing directly means calling `get_widget():configure(...)`, and
`get_widget` is `function() return love.state.user_input_controller end` (`:877`), which is **nil
between runs** (`destroy_input_widget`, `:215-218`).

`tests/input/input_nfr_mechanism_spec.lua:117-125` asserts exactly that case does not raise:

```lua
love.state.user_input_controller = nil
input.configure({ prompt = 'who?' })
input.show({ text = 'hi' })
```

`api_show` already guards (`if ui then ui:show(next_cfg) end`, `:735`); the new `configure` path must
do the same. Second half of the same trap: `stash_hidden_configure` also calls
`merge_callback_keys` (`:715`), which is what makes a hidden `configure{validator = …}` persist —
pinned by `input_widget_control_spec.lua:330-341`. Deleting `stash_hidden_configure` must keep that
merge on the path, not just on the active one.

### F3 — `-02` cannot be its own commit, and `-08` cannot be a trailing sweep. Here is the exact spec list

`agents/validation.md:119` is unconditional: *"Suite green at every commit — the count is stated in
the message"*. A commit that adds failing tests violates it, so `-02` is a *practice* ("see it
fail"), not a commit; each breaking test lands in the commit that makes it pass. Likewise `-08`:
every spec below is green today and stops being green the moment its step lands, so the spec edit is
part of that step's commit, not a later sweep. The plan half-says this ("expect this to be partly
absorbed") — it should say it fully, with the list:

| step | spec that breaks | why |
|---|---|---|
| `-03` | **none** | `-03` is behaviour-neutral: today `open_widget` clears when `text` is absent and `apply_config` sets it when present (`userInputController.lua:303-307`); `reset_content` is the same two branches, and the text-before-highlighter order is preserved. Do not expect a red test here |
| `-04` | `input_widget_control_spec.lua:154` *"force without text leaves content intact"* | asserts the opposite of the new rule (see F1) |
| `-05` | `input_widget_control_spec.lua:310` *"applies text and cursor on the next show"* (also asserts `warned == 0`) | breaks under **both** picks |
| `-05` | `input_nfr_mechanism_spec.lua:104-112` *"the pending draft resolves to the current widget"* | reads `other.pending.prompt` directly; breaks under **both** picks, since `prompt` stops being stashed either way |
| `-05` (A(ii) only) | `input_widget_control_spec.lua:286` *"leaves text/cursor untouched … even mixed with a live field"* | `configure{text=…}` would now raise |
| `-05` (A(ii) only) | `input_widget_control_spec.lua:348` *"hidden-configured text does not leak into a later show"* | same |
| `-05` (A(ii) only) | `input_route_lifecycle_spec.lua:236-247` *"discards a draft stashed by a hidden configure"* | calls `first.configure({ text = 'secret', prompt = 'A> ' })`; the *property* it guards (a store cannot cross runs) survives structurally via widget lifetime, but the case must be rewritten |

Two consequences worth naming in the plan. First, `input_nfr_mechanism_spec.lua:104` is one of the
**two** witnesses for the resolve-per-access NFR (`callbacks` is the other, `:94-102`); deleting it
leaves that NFR on a single case — acceptable, but it should be a decision, not a side effect.
Second, `internals/user_input.md:698` cites the pending draft as part of that same NFR argument.

### F4 — §3's "unfiled sibling" is wrong as stated: a forced `show` does not defer the callbacks, only the highlighter

`merge_callback_keys` writes `callbacks[k] = cfg[k]` into `state.callbacks`
(`consoleController.lua:680-687`), and `state.callbacks` resolves through `widget_store`
(`:664-672`) to the widget's **own** `callbacks` table (`userInputController.lua:42`) — the same
table `run_callback` reads at submit time (`:406-410`). So `validator`, `on_text_entered` and
`on_limit_reached` passed to a forced `show` are applied **live, today**.

`highlighter` is the exception, and only because it is consumed from a different place: the widget
reads `ev.highlighter` off the evaluator (`userInputModel.lua:384`), and only `apply_config` writes
there (`userInputController.lua:262-264`). `callbacks.highlighter` is a store nothing reads back
except the next `api_show`'s merge. So a forced `show{highlighter = …}` genuinely lands at the next
activation.

`-02`'s test list happens to name `highlighter`, so the tests are right; the *claim* is not, and it
is repeated verbatim in `ROADMAP.md:284` (*"defers `highlighter`/`validator`/the widget outputs"*).
Correct both, or a later reader will file a bug that does not exist.

### F5 — pick B understates itself: `prompt`'s retention changes meaning too

The plan argues the retention sentence "stays true for every field `configure` still accepts". For
`prompt` it stays *approximately* true and changes semantics: today the stash is **one-shot** —
`consume_pending` nils each key as it spends it (`consoleController.lua:697-703`), and
`internals/user_input.md:800-802` says so in as many words (*"That application is one-shot"*). Under
the plan, a hidden `configure{prompt}` writes `model.custom_label` permanently, so it survives every
later bare `show`, not one.

That is the behaviour the owner ruled wanted (attestation item 3, label as decoration surface), so
it is right — but it is a third line for the deviation record, not something the "stays true"
sentence covers. Nothing in-tree observes the one-shot property for `prompt` (only
`input_widget_control_spec.lua:348` does, and for `text`), so it will not be caught by the suite.

### F6 — pick A(i) as written is internally inconsistent and cannot be chosen in that form

§3 says under A(i) *"`pending` shrinks to `text`/`cursor`"*. If `configure` warns-and-refuses
`text`/`cursor`, there is nothing left to stash and `pending` dies under A(i) too. `pending` only
survives if the refusal applies to the **active** case and the **hidden** case still stashes — i.e.
`configure` keeps giving two different answers for one key depending on shownness, which is the
split this row exists to remove. Before the owner can pick, A(i) has to be re-specified as *"warn in
both states; `pending` deletes anyway"*.

### F7 — `-07`'s doc surface is larger than "the balloons rationale", and one item in it is a gate

`internals/user_input.md:783-818` is ~35 lines that go stale at `-04`/`-05`: the whole
"While hidden, `configure` …" paragraph (retained/one-shot/run-scoped), and the closing paragraph
that describes `force` as *"replaces only the `text` subset in place and ignores every other
field"* — which becomes the exact opposite. Plus `:698` (pending draft, NFR argument) and
`:770-782` (`show(config)`, which names `apply_config`). The plan names this doc only for the
balloons rationale.

Separately: `-07` folds in ratifying `false` as the uniform unset (the `BUG-01-02` disposition).
That is a **public-contract** call on a row the ledger currently marks "design escalation"; it
belongs behind an owner gate like `-01`, not inside a documentation commit.

### F8 — a small gap in A(ii)'s mechanics

A(ii) promises *"a message naming where they belong"*. `bad_key_message`
(`consoleController.lua:627-634`) has two branches: lifecycle → "assign it on
`compy.input.callbacks`", everything else → "unknown config key". A `show`-only category has to be
added, and `force` should join it — today `configure{force = true}` raises with *"unknown config
key 'force'"*, which is misleading for a key Decision 15 explicitly documents as show-only
(`decisions/input.md:577-578`). `input_widget_control_spec.lua:112-119` only asserts `has_error`, so
improving the message is free.

### F9 — discovered defect, reported not fixed: `set_text` silently ignores a multi-line *string*

`userInputModel.lua:126-134`: for a string argument, `self.entered` is assigned **only** when
`#string.lines(text) == 1`. For `"a\nb"` nothing is assigned; the call then runs `text_change`,
`init_visible` and `jump_end` over the *old* content. On the activation path `cfg.text ~= nil`
suppresses the clear (`:304-306`), so `show{text = "a\nb"}` leaves the previous draft in place.
`doc/input_api.md:58` documents `text` as *"a string or list of line strings"*. In-tree examples
sidestep it by passing tables (`maze/core_editor.lua:62`: `text = string.lines(text)`).

ARC-02 does not cause this and `reset_content` preserves it, but the sprint's own contract
("`show` is a full re-setup; absent `text` ⇒ empty") makes it a louder contradiction, and `-02`'s
test author is likely to trip over it while writing the "clears with no text" case. It deserves a
`BUG` row. **Read from source, not executed.**

---

## What I checked and found correct

- **§2(a).** Verified in full above, including the one way it could have been wrong.
- **§2(b).** `UserInputModel:reset(history)` does exist at `userInputModel.lua:354-359`, and it
  calls `clear_input`. The naming-collision warning is accurate and correctly marked non-blocking.
- **Containment of the deletions.** LSP references plus grep agree: `re_show` has exactly **one**
  caller (`userInputController.lua:331`), `apply_config` exactly **two** (`:307`, `:362`),
  `open_widget` one (`:332`), all in-file. `UserInputController:show` / `:configure` have exactly
  two production callers, both in `consoleController.lua` (`:735`, `:824`); the only other caller in
  the tree is the fixture (`tests/helpers/input_fixture.lua:249`) and two direct `c:show(...)` uses
  on a bare controller (`input_widget_callbacks_spec.lua:964`, `:975`), none of them re-showing over
  an active widget. **No unaccounted caller.**
- **`state.pending` is not project-visible.** `build_input_surface` (`consoleController.lua:560-571`)
  resolves only `shortcuts` / `hooks` / `fn` / `callbacks` / `methods`, so `compy.input.pending` is
  `nil` today. Deleting the store is invisible to projects — which is the strongest single argument
  for A(ii) and the plan does not make it.
- **`pending` has no other reader.** Grep over `src/` finds it only at
  `userInputController.lua:52` and in `consoleController.lua`'s five sites; over `tests/` only at
  `input_nfr_mechanism_spec.lua:110-111` (the unrelated `pending()` busted helper aside).
- **"`force` has no consumers in-tree."** Confirmed: every `force` hit under `src/examples/` is
  prose about a force field in the keyboard example. Tests are indeed the only guard.
- **Pick B loses no in-tree capability.** The only two `configure` calls in `src/examples` pass
  `prompt` alone — `balloons/terminal.lua:23` (continuous session, widget shown once at
  `terminal_init`) and `maze/core_editor.lua:69` (guarded by `is_shown()`, with the text set through
  `set_text` on the next line). Neither passes `text` or `cursor`; neither depends on the stash.
- **`BUG-01-08`'s shapes do raise today.** `open_widget` guards `cfg.cursor ~= nil` and then indexes
  it (`:308-310`), feeding `set_cursor_pos` (`:169-175`), whose first act is
  `math.max(1, math.min(line, n))`. `{}`, `{1}`, `{nil, 2}` reach `math.min` with `nil`; a scalar or
  `false` fails at the index. **Read from source, not executed.**
- **Decision 15's text.** `decisions/input.md:568-603` reads as the plan describes; the scope
  paragraph (`:590-595`) lists exactly three warn-cases and `configure{text}` is not among them —
  see the pick-A discussion, this matters.
- **Baseline.** 979 / 0 / 0 / 10, matching the plan's stated figure.

---

## The two picks

### Pick A — the strongest case for **warning**, then my recommendation

The plan recommends raising and argues one analogy. Here is the other side, made as well as I can:

1. **The Decision 15 premise does not cover these keys without help.** The decision's own rationale
   is *"a key outside it can only be an authoring error"* (`:582-583`). `text` and `cursor` are not
   outside it — they are documented as accepted, with a defined effect, in the project guide
   (`input_api.md:86-91`) and in the internals doc (`:783-818`). A project author writing
   `configure{text = …}` today is using a documented feature, not making a typo. That is precisely
   why A(ii) needs `-01`, and a rule that needs its premise amended to fit the case is weaker than
   one that already fits.
2. **A raise is fatal, and `configure` is called from gameplay code.** Decision 15's Consequence
   (`:597-601`): raised from a `love.*` handler it **suspends the run**. `balloons/terminal.lua:23`
   calls `configure` as its entire text-output channel. Turning a previously-working call into a
   suspended run is a much larger blast radius than a log line, for a key whose only sin is being
   passed to the wrong entry point of the same surface.
3. **A(i) is already a strict improvement, and needs no gate.** Today `configure{text = …}` on an
   active session is **silent** — `UserInputController:configure` builds `live` without `text`
   (`:357-364`) and nobody warns; `input_widget_control_spec.lua:286` asserts the values are
   unchanged and never asserts a warn. Silence is what Decision 3 (warn-don't-swallow) exists
   against. A(i) fixes that, ships inside this sprint with no owner-gated dependency, and removes
   `-01` from the critical path.
4. **A(i) keeps pick B off the table.** The stakeholder-seen retention sentence survives untouched,
   so the sprint carries one intent deviation (F1) instead of three.

**And the argument that beats all of that, which the plan did not use.** Decision 15 already raises
for a key that belongs to another call: *"`force` is a `show`-only key and raises from `configure`"*
(`:577-578`). Under this design `text`/`cursor` become members of exactly that existing category.
That is a far better precedent than `LIFECYCLE_KEYS` (which were never accepted anywhere in a config
table, whereas `force` is a legitimate key at the other entry point — the same shape as `text`).
It also means **`-01` may be an addition, not an amendment**: the scope paragraph never claimed
`configure{text}` warns; it lists three cases and this is not one of them. Telling the owner that
lowers the gate's cost materially.

**Recommendation: A(ii)**, with `-01` framed as *"`text`/`cursor` join `force` as `show`-only keys"*
citing `:577-578`, and with F8's message branch. Argument 2 is the real cost and it is bounded: no
in-tree project passes `text`/`cursor` to `configure`, and the surface is pre-release. If the owner
declines the gate, take the **re-specified** A(i) from F6 ("warn in both states, delete `pending`
anyway") — not the version in §3, which does not hold together.

### Pick B — a real argument, not a rationalisation, but stated too cleanly

The capability claim is **true and I verified it**: nothing in `src/examples` stashes through
`configure`, `compy.input.pending` was never project-visible, and the replacement (`show{text = …}`
or a project-local) is what every example already does. A project cannot even observe the
difference except by calling `configure{text}` while hidden and then a bare `show`.

Where it is too clean: the sentence *"stays true for every field `configure` still accepts"* is
true of *applicability* and false of *semantics* — `prompt`'s retention goes from one-shot to
permanent (F5), and both the guide (`input_api.md:90-91`) and the internals doc (`:800-802`) will
need rewriting for the field that is being kept, not only for the two being removed. That is a
smaller gap than the plan's §4 implies, and it does not change the answer.

**Recommendation: proceed with B, tied to A(ii)**, with the deviation record naming **three**
items rather than one: (1) `configure` refuses `text`/`cursor`; (2) a hidden `configure{prompt}`
becomes permanent rather than one-shot; (3) `show{force = true}` with no `text` now clears
(F1 — the item the plan currently says does not exist).

---

## Where I ran out of confidence

- **I executed nothing.** No step was implemented, no spec was run beyond the untouched baseline.
  Every "this spec breaks" in F3 is derived by reading the spec against the proposed code, and every
  raise (F2, `BUG-01-08`, F9) is read from source, not observed.
- **I did not verify the raise-reaching-a-project claim.** §6's warning is right in principle —
  `with_canvas_and_errors` xpcalls the walk — but I did not read that function or check what a
  pick-A(ii) raise from inside a `love.*` handler actually leaves in `love.state.suspend_msg` /
  `app_state`. If `-02` asserts a raise reaching a project, that mechanism still needs establishing
  by whoever writes the test.
- **I did not audit `-06` (`BUG-01-08`) beyond confirming the raises happen.** Whether it belongs in
  this sprint at all is a scope question I answer below with low confidence.
- **Scope, one sprint or two — my read, not a strong one.** `-01`…`-05` plus the spec moves are one
  coherent unit (one boundary, one behaviour, deletions that only make sense together). `-06` is
  argument-shape validation with no relationship to the `configure` boundary, and `-07` bundles a
  documentation pass with a public-contract ratification (`false` as unset). I would split both out
  — `-06` as its own `FIX` row, `-07`'s ratification behind a gate with the docs following it —
  which makes ARC-02 one sprint rather than one-and-a-half. I did not find anything the plan cannot
  avoid touching that it left out, apart from the doc surface in F7 and the spec list in F3.
- **I did not read the two predecessor reviews or the session track.** Where the plan's claims came
  from them, I re-derived them from code (F4 is the one that did not survive that). If any of my
  findings contradicts something those documents establish, they have context I deliberately do not.

---

## Addendum — a draft Decision 35 is already in the working tree (uncommitted)

Found at the end of this review, while confirming I had touched no file but this one.
`git status` reports `doc/development/decisions/input.md` as **modified**, +69 lines, adding
**Decision 35 — the configuration boundary: the user's content is `show`'s alone**. It was *not*
present in the tree state I was handed at the start of the session. I did not write it, and I have
not touched it.

It is `ARC-02-01`'s gate, already drafted, and it settles both picks:

- **Pick A → A(ii).** Statement 2: `text`/`cursor` at `configure` are *"keys that belong to another
  call and are refused as such — the treatment the lifecycle callbacks already get"*, and the
  amendment paragraph moves them explicitly to the raise side of Decision 15's scope. My pick-A
  section is therefore advisory; the case for warning is recorded there for the audit trail, and my
  own recommendation agrees with the ruling. The one thing worth carrying over is F8 and the
  `force`-precedent framing (`decisions/input.md:577-578`) — the draft leans on the lifecycle
  analogy, and the `force` clause is the closer one.
- **Pick B → the stash goes.** *"A hidden `configure` no longer retains `text`/`cursor` for the next
  `show`."* The deviation record is still required (owner directive, 2026-08-10) and should carry
  the three items in my pick-B recommendation.
- **F1 is partly answered, and still needs recording.** Statement 1 rules *"`text` absent is an
  empty field"* and statement 4 makes `show{force = true}` a full re-setup, so the clearing
  behaviour is now ruled rather than merely planned. What the draft does not say is that this
  reverses a *stakeholder-seen* sentence (`version01.md:178-180`, "preserved otherwise") and
  invalidates a green spec (`input_widget_control_spec.lua:154`). Both belong in the deviation
  record and in `-04`'s commit message.
- **F5 is confirmed as a real change, not a nuance.** The draft says *"The retained `prompt` is
  unaffected — it is project-owned, applies immediately, and is still there at the next `show`"* —
  i.e. it ratifies the one-shot → permanent shift I flagged, without naming it as a shift. One
  sentence in `internals/user_input.md` (`:800-802`, *"That application is one-shot"*) becomes false
  and must change with it.
- **New, and outside this plan:** the draft's closing paragraph recommends `compy.input.reset()`
  *"for a later release, not part of this one"*, which matches the plan's §6 scope-creep guard.
  Nothing to do, but `ROADMAP.md`'s "Not in scope" line for ARC-02 should cite the decision now that
  the recommendation lives in the ledger rather than only in a predecessor review.

Everything else in this review — F2, F3, F4, F6 (now moot), F7, F8, F9 — is untouched by the draft:
it rules the *behaviour*, and my findings are about the *execution* of it.
