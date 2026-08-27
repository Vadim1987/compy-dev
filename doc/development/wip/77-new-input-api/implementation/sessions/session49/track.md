# session49 track

## 2026-08-27 — boot

- Fresh start: no prior `track.md`/`report.md` in session49/ → re-entrance guardrail says fresh.
- Read: `agents/validation.md`, `agents/sessions.md`, `session49/prompt.md`, `session48/report.md`
  (predecessor handover; its track deliberately skipped per prompt — and per the cold-read mandate).
- HEAD `c70a7032` (docs(session48): wrap). Working tree: only the known untracked scratch
  (`claude.sh`, `input-pr-slices.tar.gz`, `repos.txt`, `src/STEPS.md`, `src/examples/{balloons,
  keyboard,maze}`, `worklog.md`) — matches the known-anomalies list. No modified tracked files.
- Baseline `busted tests` → **979 successes / 0 failures / 0 errors / 10 pending**. Matches the
  prompt's authoritative number (validation.md's 970 line is the stale fallback).
- Mandate: **ARC-01-07** — why two reconfiguration policies coexist in `apply_config`, and is
  `prompt` on the right side. Mode: **research + analysis**, cold. Stop at a finding, bring to owner.
- Cold-read discipline: NOT reading the ARC-01 row's execution detail or session48's track before
  forming my own view of `apply_config`.
- Told the owner the task before starting work, as asked.

## 2026-08-27 — owner reframes the question (behavioural, not internal)

- Owner: the question is NOT about `apply_config`'s internals. It is: the stakeholder asked for a
  distinction of the shape "field X settable via both show/configure, others only via configure"
  (owner remembers the *shape*, warns the real ruling may be the opposite); prompt config, which
  the stakeholder never mentioned, was bolted on top without analysis. Wanted: **was the initial
  requirement balanced, what motivated it, is the resulting API predictable or surprising?**
- Scope named by the owner: original requirements + `doc/input_api.md` + the relevant widget /
  `compy.input` methods. Deliberately narrow — I stayed inside it.

## 2026-08-27 — findings

- **PR base `3256aac` checked first** (standing caution, and it did frame everything):
  `custom_label` = constructor arg 4 of a widget built **per input call**; `input_text(prompt, init)`
  → prompt and text were two args of ONE call, behaving identically. **`configure` does not exist at
  base at all.** So neither the split nor prompt's stickiness is inherited — both are ours.
- Stakeholder asked exactly ONE distinction on this axis: D-2 (show-while-active blocked, `force`
  opts in). Its axis is **call state**, not **field**. No per-field rule was ever requested.
- `prompt` is in `PER_SHOW_KEYS` (consoleController, "spent by the show() that reads them") but
  implemented set-if-given in `apply_config` → sticky for the widget's life. Declared in one group,
  implemented in the other. `doc/input_api.md` "Callback assignments" lists what persists and
  **omits prompt** — the doc contradicts the code.
- Origin of the bolt-on located precisely: `decisions-record.md:107-114` introduces `configure()`
  for NFR-1 and cites *"updating a label mid-run"* as its motivating example — the field the
  stakeholder never asked for is the poster child of the surface they never asked for.
- 10 probes through `F.compy_input()` confirmed the matrix; scratch specs run then deleted, source +
  output preserved in `validation/notes/ARC-01-07-behaviour-probes.md`. Suite 979 before and after.
- Non-obvious one nobody had named: **`show{force=true, highlighter=X}` on an active widget neither
  applies nor refuses X — it defers it to the NEXT activation** via `merge_callback_keys`. A closed
  config table (unknown keys raise) silently accepting a known key it will honour later.
- `text` carries three policies in one function: absent→clear (fresh), absent→keep (force),
  present→ignored (configure-while-active).
- `BUG-01-02` generalises: nothing set-if-given can be unset, and that includes `prompt` (only
  `prompt=''` clears a label — works, undocumented, asymmetric with every other field).
- Verdict: sticky-callbacks half is intentional + justified; the per-field split as a whole is not;
  **`prompt` is on the wrong side**. Finding →
  `validation/reviews/ARC-01-07-reconfiguration-policies.md`, with 4 owner options ordered by blast
  radius. STOPPED there per prompt — this is a ruling, not an implementation detail.

## 2026-08-27 — owner attestation overturns half the verdict

- Owner: `prompt` was ruled into FR-1 **by them**, against a real balloons defect (no mid-run label
  change). Label surviving bare `show()` is **wanted** — decoration surface, project-owned. `text`
  clearing is affirmed — user-owned. Separate unset machinery for a hypothetical = overkill.
- Materialized verbatim: `validation/notes/owner-attestation-prompt-field.md`.
- **My "prompt is on the wrong side" verdict is withdrawn.** It was inferred from provenance +
  declared grouping + docs; with the ruling those three are evidence that *the intent was never
  written down*, not evidence of misplacement. Behaviourally prompt is on the right side.
- Checked balloons in-tree — corroborates and exceeds the claim: `terminal_write` →
  `configure{prompt=msg}` is the game's **entire text-output channel**, called every draw. Nuance:
  balloons shows the widget ONCE and never re-shows, so it exercises live-update, **not** stickiness
  across bare show(). Two behaviours, two different arguments in the attestation.
- Option 2 (prompt per-show) declined. Option 4 (unset sentinel) de-scoped → BUG-01-02 gets ruled on
  the highlighter's own merits, narrower than I framed it.
- Survives untouched: doc persistence list omits prompt; `PER_SHOW_KEYS` comment says "spent by the
  show() that reads them" — false for prompt; **the `force` deferral** (independent of prompt, still
  the least predictable thing here, still open).
- The attestation yields the rule the design never wrote: *content resets; everything the project
  sets persists until replaced.* One policy + one stated exception — reframes the whole row from
  "two coexisting policies" to "an unstated rule". Review amended in part, §7 supersedes §5/§6.
- Behavioural note on the owner: they overturned my premise by supplying authorship history I had no
  way to read from artifacts (a ruling they made, not recorded in the requirements' rationale). The
  provenance-from-absence inference is the weak move to watch — third time this phase a verdict fell
  to someone checking.

## 2026-08-27 — roadmap filings + the five follow-up questions

- Owner asked me to file balloons' prompt re-push as a modest defect → **BUG-01-07** (new row).
  Checked it before filing: `ui_draw_hint` is NOT per-frame (only `ui_set_hint` calls it) — I had
  said "every draw" earlier, wrong; it is per state transition. The real shape is a **shadow copy**
  of the widget's label (`ui_messages.hint`) re-pushed on each transition, a pre-feature fossil,
  plus two vestigial args (`flushed`; the `true` at `ui_set_hint(..., true)`) and a stale NOTE.
  `SPLASH_HINT_START` never reaches the widget but the same text is on the splash graphic — so no
  visible loss. Filed at that honesty level, not louder.
- **FIX-02-21 was already the same question**, filed 2026-08-26 with the two readings spelled out and
  waiting for the owner to pick. They picked reading 1 today. Row updated: no longer escalates to a
  BUG, work is comment + list membership + two doc sentences.
- **BUG-01-06 already covers the prompt-drop half** of the force path. The *deferral* half (callbacks
  absorbed into sticky store, applied at the NEXT activation) was NOT filed anywhere — added to that
  row as a sibling to rule on together.
- **BUG-01-02 narrowed decisively.** Verified in code why the owner's cheap answer (document `''` /
  a no-op function instead of building a sentinel) works for prompt/validator/outputs but NOT for
  the highlighter: absent highlighter → `ev:validation_hl(text)` (`userInputModel.lua:392-400`),
  which carries `parse_err` — the channel that shows the VALIDATOR's error in the field. The
  user-highlighter branch has no `parse_err` key at all, so a no-op highlighter silently kills
  validation error display for the documented `LineValidators` case. **No user-space value can
  reproduce absent.** That is the row's whole difficulty, now stated.
- ARC-01-07 closed with a written reason; ARC-01 marked COMPLETE (header, one-line sequence,
  "where things stand").
- Answer to "why two entry points" that the analysis converged on and I had not seen before: `show`
  and `configure` are separated by **whose data they touch** — `force` is permission to destroy the
  USER's in-progress text; `configure` changes the PROJECT's surface and never touches content.
  Same axis as the attestation's rule. The spec (`design/spec.md:148-151`) says force "reconfigures
  in-place", which is a THIRD thing and matches neither — frozen-design drift, noted not edited.

## 2026-08-27 — force: intent recovered from the reviewed spec

- Owner: force needs thinking through; can we recover stakeholder intent on forced vs non-forced
  show, and first vs subsequent calls? Did they assume show alone would be the config surface? Would
  visible/invisible be a better split? Core intent stated: **do not override the stakeholder ruling,
  but recommend a better shape and delete accidental complexity within it.**
- **Recovered, and it is exact.** The round-2 stakeholder was responding to a spec paragraph
  (`spec.versions/version01.md:174-186`) that read *"`force = true`: the singleton is then
  reconfigured in-place with the new config (content replaced if `text` is provided, preserved
  otherwise)"*. Their instruction — *"offer a flag for 'I know what I'm doing — override the existing
  one'"* — gates THAT. So force = full re-setup over a live session.
- **The implementation kept the parenthetical and dropped the main clause.** Spec narrows *content*;
  code narrows *everything but content*. Not a weaker flag — the complement of it. That single
  inversion explains why force is weaker than configure and why BUG-01-06 + the deferral exist.
- **`configure` was in the spec they reviewed** (`version01.md:200`), and that spec told them in as
  many words to use it for live prompt/validator/highlighter changes. They quoted a sentence from
  two paragraphs away and objected to `keys_pressed` — so they read it. **Seen and unobjected**, in
  the same round they tightened `show`. Answers "is configure earned": need ratified (owner's
  balloons ruling), two-entry-point shape is ours.
- **Visible/invisible split: rejected, decisively.** The label is visible, so prompt would be
  show-only, so mid-run relabelling would need show{force} = full re-setup = wipes the player's
  half-typed command. It breaks balloons, the use case that created configure. Also the line is not
  crisp (highlighter is visibly colouring; the validator is invisible but its errors are displayed).
  The working cut is the owner's own: **ownership, not visibility.**
- `force` has **zero consumers in-tree** (no example uses it) → changing its semantics is cheap.
- **Found on the way, filed as FIX-02-22:** three documents say a hidden widget keeps its content
  (`spec.md:155` — contradicting its own §3 five lines up; the round-2 reviewed text; and
  **Decision 3 in the PERSISTENT ledger**, amended last session). Code clears, suite pins it,
  **turtle depends on it in a comment**. Disposition: fix the documents. FR-3/FR-4 are not violated —
  they are about not tearing the widget down, which still holds.
- Roadmap: FIX-02-12 and FIX-02-21 are NOT duplicates but are **one edit** (same paragraph) —
  cross-linked rather than merged. FIX-02-22 co-located with FIX-02-13 by cross-reference, kept at
  the numeric end so rule 2's ordering is not broken for one insert. BUG-01-06 annotated as
  *may dissolve*.

## 2026-08-27 — owner proposes show() = configure() + guard + activate

- Owner's question: are configure and show{force} identical bar visibility, so should show simply
  invoke configure (force gate before, activation after)?
- **Decomposition right, differentiator wrong.** On an ALREADY-ACTIVE widget activation is a no-op,
  so the two differ by exactly one thing: show resets the USER's content baseline, configure never
  touches it. Visibility is the incidental difference; content is the essential one. That is the
  ownership rule expressed as code.
- **The enabling move is the one this whole row started from: take `text` OUT of `apply_config`.**
  That function holds two policies precisely because `text` (user-owned exception) lives inside the
  project-owned set-if-given rule, with its other half (`clear_input`) one level up in open_widget.
  Move content onto the activation path → apply_config becomes single-policy and IS the configure
  core; show composes it. The original ARC-01-07 question dissolves structurally instead of being
  documented around.
- Three things then delete themselves: `re_show`'s branch (→ open_widget); `configure`'s hand-built
  `live` filter table (exists only to keep text out of apply_config); `prompt`'s slot in
  `state.pending` (project-owned + sticky ⇒ just write it; only text/cursor need pending).
- Verified containment: apply_config / re_show / open_widget are file-local with no callers outside
  `userInputController.lua` (apply_config: exactly two, both in-file).
- Does NOT decompose, and is a real call: hidden `configure{text=…}` — stash for the next show
  (today, documented) vs warn+refuse like `set_text` does when hidden. Refusing deletes the last of
  `pending` but is a documented behaviour change; belongs with FIX-02-22's disposition.
- Materialized as §6 of `validation/reviews/force-and-configure-intent-recovery.md`.

## 2026-08-27 — owner challenges "behaviour change against what?"; empty values probed

- Owner's criterion: a change against **our own within-cycle machinery** is not a concern unless it
  blasts half the system; what counts is base and stakeholder intent. Correct, and it retires my
  `force` caveat — force does not exist at base, restoring it MATCHES intent, and re_show has zero
  consumers. I overstated it as a behaviour change. Owner also notes the stakeholder already ruled
  show-force = re-setup; agreed, §1's recovery is exactly that.
- **The same criterion settles the OTHER open call against my tidier option:** the reviewed spec says
  of configure *"Safe to call when hidden (takes effect on next show())"*
  (`spec.versions/version01.md:205-208`). The stash is stakeholder-seen. So refusing hidden
  `configure{text}` would contradict intent, not just our machinery. **Keep the stash.** `pending`
  shrinks to text/cursor but does not disappear.
- **Empty values probed — and one result overturns something I told the owner an hour ago.**
  `highlighter = false` turns the highlighter off EXACTLY: `apply_config` guards `~= nil` so `false`
  is stored, and every consumer guards on **truthiness** (`if ev.highlighter then`), so a stored
  `false` takes the same branch as absent. Same for `validator = false` (rejecting validator lifted,
  verified) and the output callbacks. **BUG-01-02's machinery debate is over — the unset already
  exists.** My earlier "no user-space value reproduces absent" reasoned about nil and missed
  truthiness. Roadmap row corrected in place, with the correction stated rather than quietly edited.
- `prompt = false` → falls back to the evaluator default label; `prompt = ''` → empty label. Two
  distinct, both useful. `text = ''` converges with absent — the ideal.
- **New defect, BUG-01-08:** `show{cursor = {}}`, `{1}`, `{nil,2}` and `set_cursor(nil,nil)` all raise
  a raw Lua error — `set_cursor_pos` (`:169-175`) does `math.min(line, n)` unguarded. Public path,
  crashes the project, and the config table is otherwise strictly validated while the doc promises
  clamping. **Base-checked: ours** — `set_cursor_pos` does not exist at 3256aac.
- Stakeholder record is **silent on empty values** — unruled area, so rule it rather than discover
  it. Decision 14 (formalise de-facto contracts) and NFR-3 (Lua idiom) both point at ratifying
  `false` = "no such thing" rather than changing anything.

## 2026-08-27 — owner's four-part proposal (a/b/c/d), assessed

- Verdict: consistent with intent and better than what is there; four qualifications.
- **(a)** show cannot be ONLY configure+activate — configure leaves unnamed flags alone, but show
  must reset the USER's content (owner's own ruling; turtle depends on it in a comment). So:
  force gate → reset_content → configure → cursor → activate. Alternative: show normalises
  `cfg.text` to `''` and (a) stays literally true — cosmetic; explicit line reads as the rule.
  **Do NOT default `cursor`** in that normalisation: probed, `show{text='hello'}` lands the caret at
  (1,6), the end — defaulting to {1,1} would be a behaviour change vs today AND base.
- **(b)** yes. Two adjustments: hidden `configure{prompt}` should APPLY not stash (project-owned,
  lives on the widget, needs no session → pending shrinks to text/cursor); active `configure{text}`
  should WARN not silently drop (reviewed spec says "no effect", a warning is still no effect plus a
  diagnostic). Hidden `configure{text}` stash STAYS — stakeholder-promised.
- **(c)** true for functions + prompt (verified). **`cursor` raises today**: `cursor = 1` AND
  `cursor = false` both die at `:309` indexing `cfg.cursor[1]`. So the proposal's own example does
  not work — BUG-01-08 widened, and it now GATES the rule (cannot document a scalar unset that
  raises). **`text` has no unset distinct from empty** — absent already clears. `text = false`
  doesn't raise but is off-contract; don't document it.
  Wart to document: `false` = off, `nil` = leave alone → a computed nil silently means leave-alone.
  Idiom: `highlighter = computed or false`.
- **(d)** yes, but the owner's justification is not the strongest one available. Probed `clear()`:
  it empties content and KEEPS label + highlighter. So **clear() resets what the USER owns; reset()
  would reset what the PROJECT owns** — the ownership rule with a verb on each side. That is
  principled, and it settles that reset() must NOT clear content (else clear() is redundant).
  Cautions: (1) strategic frame — new public method needs a justification-table line, and the honest
  justification is the symmetry, NOT defensive cleanup, which ARC-01 already dissolved; (2) do the
  lifecycle callbacks (before_/after_submit/cancel) fall to reset()? They are not settable via
  show/configure, so "configure with defaults" leaves them standing — defensible but must be stated
  or the name over-promises.
- Materialized as §8 of `validation/reviews/force-and-configure-intent-recovery.md`.

## 2026-08-27 — ARC-02 planned; cold review spawned

- Owner settled the design: configure runs everything except user input and REFUSES text/cursor;
  text/cursor are show's alone; text normalised to empty in show; all other flags non-nil-only in
  both calls. Asked for: plan (code+docs+tests), materialize, roadmap, then a cold reviewer.
- **Two corrections found while planning, both before writing a line of code:**
  - **`clear_input()` ≠ `set_text('')`.** clear_input (`userInputModel.lua:344-351`) also runs
    `clear_selection()`, `custom_status = nil`, `history:reset_index()`; set_text (`:125-140`) does
    none of them. So "normalise text to ''" is a CONTRACT statement, not a literal default — routing
    an absent text through set_text('') would leave a stale selection, stale custom status and an
    unreset history index on a fresh show. reset_content keeps two branches.
  - **`UserInputModel:reset(history)` already exists** (`:354`) — name collision to know about
    before (d)'s `compy.input.reset()` gets built. Not blocking, different layer.
- **Pick A surfaced (mine to raise, owner's to settle):** "refusing" text/cursor at configure is
  warn (Decision 15's runtime-state branch, no ledger touch) OR raise as a key-belonging-elsewhere
  (the LIFECYCLE_KEYS treatment that already exists — recommended, uniform, deletes `pending`
  outright, but AMENDS Decision 15's scope paragraph → owner-gated gate step first).
- **Pick B:** under A(ii) the hidden-configure stash goes. That IS against stakeholder-seen text
  (reviewed spec: "safe to call when hidden (takes effect on next show())"; and doc/input_api.md
  says so too). Argument that it is not a broken promise: the sentence stays true for every field
  configure still ACCEPTS, and no capability is lost (pass text to show, or hold a local). Flagged
  as the one item needing a deviation record per the 2026-08-10 directive.
- Plan: `validation/reviews/ARC-02-configure-boundary-plan.md`, 8 steps, tests-first, risks stated.
  Roadmap: new **ARC-02** sprint section + one-line sequence updated. Closes/dissolves BUG-01-06 (+
  sibling), BUG-01-08, FIX-02-21, FIX-02-12; drops BUG-01-02 out of design-escalation.
  `reset()` deliberately OUT of scope — a public addition inside a deletion sprint is how surfaces grow.
- Cold review spawned: **Opus, explicit model**, prompt of record at
  `validation/prompts/ARC-02-plan-cold-review.md`, deliverable
  `validation/outcomes/ARC-02-plan-cold-review.md`. Told it what NOT to read (this track, the two
  predecessor reviews) until it has its own view — the point of a cold spawn.

## 2026-08-27 — owner settles both picks; design recorded as Decision 35

- **Pick A → raise. Pick B → the stash goes.** Owner's grounds on B are better than mine and replace
  it: (1) **provenance ranking** — deviating from what was *package-approved* is safer than from what
  was *explicitly requested*, and the stash sentence is the former; (2) **the promise was redundant
  when made** — text/cursor for a widget about to come up are set by the show() that brings it up,
  before it is visible, so the stash never bought a capability. Any richer deferral is a project-side
  local. My "the sentence stays true for the fields configure still accepts" was the narrower,
  weaker version of that and is superseded.
- Read as: A(ii) is chosen, since B only follows from it. Stated in the plan so it can be corrected.
- **Decision 35 written** into `doc/development/decisions/input.md` — the PERSISTENT ledger, so shape
  + rationale outlive wip/77, and it doubles as the deviation record (2026-08-10 directive
  satisfied: not a commit message). Framed as the owner asked — a specific shape ruled with
  rationale (separation of user-owned vs project-owned concerns, least astonishment, DRY, KISS), NOT
  as an argument with the ephemeral past. Amends Decision 15's scope paragraph; ARC-02-01 executes
  that amendment.
- **reset() recommended, not built.** Recorded in Decision 35's closing section with the two
  constraints on whoever builds it (must not clear content — that is clear()'s job; must state
  whether the lifecycle callbacks fall to it). Persistent-corpus placement is deliberate: a
  recommendation left in the wip plan dies with the plan.
- Cold review of the plan still running; its findings bear on the STEPS, not on the settled shape.
