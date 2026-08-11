# session36 — track

## 2026-08-10 — boot

- Booted per `agents/validation.md` → `agents/sessions.md`. **Fresh start**: session36 held only
  `prompt.md`, no `track.md` / `report.md` (sessions §2 row 1). Track opened now.
- HEAD `7c08230c` "docs(session35): wrap — report, session36 prompt, repointed pointer", branch
  `feature/77-newapi-analysis-s20260615`. Working tree: **no tracked modifications** — only the
  known untracked scratch (`claude.sh`, `src/STEPS.md`, `input-pr-slices.tar.gz`,
  `doc/tall_blocks.md`, `doc/development/wip/{clarification,personal-notes,pull-26}/`) and the
  three nested example repos.
- **Baseline confirmed: `busted tests` → 942 / 0 / 0 / 10.** Matches the prompt; the 10 pending are
  the sanctioned count (3 routing-grid + 7 reserved-combo outlines), not drift.
- Read in full: `agents/validation.md`, `agents/sessions.md`, this prompt, session35's `report.md`
  and `track.md`, the step itself (`S27-triage-and-plan.md` §11.4.3) and the §4 P14a–e / P9b / P10
  rows.
- **Mode: execution** (P14e, the examples reconciliation). A design question appearing is a reason
  to stop and raise it, not to decide it.
- Task restated to the owner before any work, at their request — awaiting their go.

## 2026-08-10 — owner adjusts the frame before the go: the sweep becomes a step

Owner: *"we'll have to rewrite examples to onboard them into the new API. But I agree with
starting small and sweeping later. So add another step (for sweeping) into the sprint plan, and
it will read from the tech debt ledger section you fill in this step."*

- **Not a rescope of P14e** — the reconciliation stays exactly as specified. What changes is the
  destination of everything it declines: an enumerated register section, and a planned step
  (**P16**) that reads it. The cap now has somewhere to point.
- Written as a §4 row + **§15.2 OPERATIVE** + §15.1 dated record. `775502b4`.
- **Ordering deliberately left OPEN, not assumed:** the owner's *"very likely the next step
  after"* collides with the ruling that put P9b after the examples step, since P16 edits the same
  file the heal rewrites. Flagged in the row and the step for a ruling before it starts.

## 2026-08-10 — EXECUTION: P14e, five commits across three repos

Mode named at boot and held: execution. No design call arose.

- `keyboard` (detached, `05cedec`) — **the proxy was the seam and the enumeration held**: three
  branches now ask `Key`, and the nine reads through `INPUT.shift/.ctrl/.alt` needed no edit.
  `modHeld` deleted; `helpHeld` asks the keyboard for `h` (last rung, legitimately — `Key` has no
  answer for a non-modifier); header prose and the capslock reasoning brought in line.
- **An uncommitted half-reword of that capslock comment was already in the repo's tree.** It is
  the same concern as the step's prose work, so it was completed rather than reverted, and named
  in the commit. Flagged to the owner rather than silently absorbed.
- The three detached repos had **no git identity configured**; set locally to match their own
  history (the owner's, as every prior commit there).
- `maze` (`a045fdb`) — `is_shift_down()` → `Key.shift()`. The combo form (Shift+Escape vs Escape)
  is the top rung and was declined to the register: it moves `escape` out of `SYSTEM_KEYS`.
- `turtle` + `clock` (`5c3ca84b`) — **the step named one clock site; the local helper had two.**
  Deleting it for the named one would have broken `k == "r" and shift()`. Caught by grepping
  after the edit, which is the only gate an example has.
- `sapper` (`cc434f9b`) — the four-site cascade became two consuming class shortcuts on the
  derived single-click channel. Verified before writing: the shortcut is called with the payload
  only (`(x, y)`), the derived channels have no trigger so the class key is the only form, and a
  consuming shortcut stops the hook. Both accepted deviations stated in the commit.
- Suite **942 / 0 / 0 / 10** at every commit — no platform code touched.

## 2026-08-10 — the smoke gate was toothless, and the negative control is what found it

- First pass: five examples "ran clean under `love src play`". **They produced no output at all**
  — including the framework's own startup lines, which a failed load *had* printed earlier.
- **Negative control**: a scratch copy of sapper with a deliberately illegal combo registration
  printed nothing either. So the gate had no signal: LÖVE's stdout is block-buffered and
  `timeout`'s kill discards it.
- Under `stdbuf -oL` the bad registration raises visibly (*"bad combo '*'"*), and the five were
  re-run under it — all load and run. **Written into the step**, because a successor smoking an
  example without line-buffering is reading an empty file and calling it clean.
- The keyboard example cannot be driven past its menu here (no key injection; harmony needs a
  seeded project dir). Its proxy and `helpHeld` were exercised by loading the **real files**
  against a fake device instead. The interactive checklist is still owed by a human.

## 2026-08-10 — two findings outside the mandate

- **`doc/input_api.md` still listed `gui` among the modifiers** after Decision 31 closed the set —
  in the stakeholder-facing guide, in the one sentence a project author acts on. Own commit
  `5d342bbe`; found by reading the sentence for its normalisation rule while converting sapper.
- **`turtle` binds Ctrl+Escape**, which the gateway reserves and quits on **without consuming**
  (`controller.lua` keyreleased) — so the project's handler fires on the press and the framework
  quits on the release. Filed in the register as a question of deletion, not of rung. Checked in
  code rather than assumed: an earlier draft of the entry said "may never have fired", which the
  non-consuming gate makes wrong.

## 2026-08-10 — owner directive: a deviation in a commit message is not documented

Owner, on reviewing the landed work: *"do not store deviations in commit messages -- they should
be documented somewhere inside workspace/codebase -- at least as comments in code, if no doc
fits."*

- **The point, restated:** a commit message is not part of the workspace a reader has open.
  Necessary, not sufficient.
- Sapper's two accepted differences were the only ones living solely in a commit. They now sit in
  `internals/examples/sapper.md` §"Click handling" — the doc that fits — with the short form in
  the code beside the registrations, pointing there (`f71f5630`). The stale summary line and the
  index row went with them: the doc still advertised `love.mousepressed`.
- Also fixed while there: turtle's internals doc **quoted a poll the example no longer makes**,
  and put `shift+r` on the wrong channel (`bd3ad646`).
- Everything else this session already lived in the workspace — the turtle Ctrl+Escape finding in
  the debt register, the smoke-buffering lesson in the step, the `gui` correction in the guide.
- Written into `agents/validation.md` under commit granularity as a standing rule, so it outlives
  this session.

## 2026-08-10 — cold revalidation of this session: sound, with one entry of mine widening the register

Owner commissioned it. Sonnet, model passed explicitly, read-only, told plainly that the commit
messages, the plan and this track are the author's **claims** and not evidence. Prompt
`../../../validation/prompts/S36-p14e-cold-revalidation.md`, report
`../../../validation/outcomes/S36-p14e-cold-revalidation.md`.

- **Verdict: sound-with-findings.** Every enumerated site checked against the tree rather than
  the prose; the three detached repos reviewed in place; `balloons` independently re-verified
  clean. Suite 942 / 0 / 0 / 10. No `REMARK:`/`INTERIM:` marker touched, no working-tree residue
  in any of the four repos, LSP diagnostics clean on the touched in-repo files.
- **It re-derived sapper's two deviations from the platform code** — `find_shortcut` and the
  gateway's `mousereleased`/`keyreleased` — rather than accepting the commit's account, and
  confirmed both. All eight register citations checked file:line against the live tree.
- **Its finding, and it is right:** `maze/macro.lua`'s shift mirror is set from the **event's own
  key name** against a static table — it reads no device and never touched the framework's set,
  so it is outside the mandate's two-named-changes trigger. Documentation-only widening, but the
  register read as if it arrived the same way as the rest. **Annotated in place** to say it is
  listed by adjacency, so the sweep that reads it is not misled about its provenance.
- Its second finding is honest about its own limit: the uncommitted half-reword I completed in
  the keyboard repo cannot be confirmed from git alone. Nothing contradicts it; there is no
  artifact of the prior state to diff against, which is the nature of an uncommitted change.
- **What it could not determine:** the smoke claims — the same display and injection constraints
  that limited me. It said so rather than implying coverage it did not have.

## 2026-08-10 — owner redefines the sweep: it splits three ways, and the heal is absorbed

Prompted by what `maze` turned out to hold. Owner: *"in-repo and balloons get common sweeping
step (if design-heavy decisions surface in any example, it gets its own deferred step). keyboard
and maze each get their own 'deepfix' step with separate planning, and keyboard's one absorbs
'healing textinput'."*

- **Assessed before writing, not after.** It is better than the single step it replaces, for
  three reasons now in §15.1b: the register's eight sites do not have one weight; the split
  **dissolves** the ordering collision I had flagged rather than sequencing around it (the
  contested file is the keyboard example's, which leaves the sweep entirely); and the detached
  repos' gate — running the app by hand, no suite — is what their own planning pass costs.
- **One caveat contested into the plan rather than left implicit:** the heal is the sprint's
  **blocking** defect and onboarding is optional, so absorbing the first into the second must
  move the session boundary, not the priority. §15.4 requires the heal to land **first inside
  the step and committable alone**, and forbids reopening its ratified design
  (`internals/examples/keyboard.md`). Stated in the §4 row too.
- Written as three §4 rows (**P16** common sweep, **P17** maze deepfix, **P18** keyboard deepfix)
  with operative sections §15.2–§15.4, and §15.1b as the dated record. **P9b's row is amended,
  not deleted** — tombstone discipline: it keeps the heal's history, its dependency record and
  the pointer to its design, and now says where the work happens.
- The old *"ordering NOT ruled"* flag is struck in place with the reason it no longer applies.
- The register's revisit line updated to match the split, without naming wip ids — it is a
  persistent document and outlives them.

## 2026-08-10 — owner corrects the split twice, and overrules my caveat

- **Escalation belongs to the sweep only.** `keyboard` and `maze` **already are** the escalation
  — each has its own step because design-heavy work was found in it — so a rule sending them to
  their own deferred step is circular. Scoped to P16's own examples, with that reason stated.
- **My caveat is overruled, and the owner's argument is the sprint's own.** I had required the
  heal to land first inside P18, committable alone, with its design not reopened. Owner: *P9b and
  P18 target the same shared code, it would be weird to run them independently if both can change
  the internal architecture of keyboard; the healing design is not set in stone yet and could be
  revised prior to update.*
  - **Sequencing them inside the step re-creates what the absorption removes** — land the heal,
    then restructure the same file — which is the churn the ordering rulings exist to prevent.
    §13.1's *"fixing D against outdated logic is conceptually wrong"* was about this very file.
  - **The design of record is an input, not a mandate.** It was written before the onboarding
    facts existed; my rule would have forbidden exactly the revision those facts might warrant.
  - **What survives is scheduling between steps, not inside one:** P18 blocks the sprint's
    closure, so it precedes the optional P16/P17. Kept on that basis, not as an internal order.
- Struck in place, not rewritten away: the caveat paragraph in §15.1b and the clause in P9b's
  row carry the overruled text visibly with the reason.

## 2026-08-10 — owner challenges "no marker was touched", and the challenge lands

Their point: during a platform change, some markers should be *about* that change and worth
updating synchronously. Checked rather than answered — four are, out of ~360.

- **What "no marker touched" actually measured.** Both cold reviewers checked for **scope creep**
  (no marker swept into an unrelated commit). Neither was asked whether a marker became
  *answerable* or *false* because of the change. Different question, and nobody had put it.
- **The worst case is mine.** `internals/examples/sapper.md`'s remark asked *"why not set
  mousepressed via hooks or shortcuts?"* — literally the conversion I made — and **I rewrote the
  paragraph three lines below it and left it standing**, so the document asked for what the same
  section describes as done. **Retired** (owner's go), with the principle it carried written into
  the prose: registrations only, the captured `love.*` path stays supported and is demonstrated
  on purpose by `turtle`.
- **Two more are live and were wired into their steps rather than answered here** (owner's go):
  `maze/main.lua`'s *"can we try using shortcuts/hooks and callbacks more actively?"* — the
  onboarding question in the owner's own words — into **P17**; and
  `keyboard/input.lua`'s *"WHY WOULD WE DO IT AND WHY USE custom 'INPUT' at all?"* into **P18**,
  with the reason it is newly answerable: the proxy is now three branches returning `Key.*`, so
  deleting it is a concrete option rather than a question about a framework surface.
- **A fourth stays where it is:** `internals/user_input.md:14` (pointer shortcuts must exist and
  be checked, modifier combo built without a trigger) — the mechanism sapper's conversion runs
  on, so the remark is now demonstrably right and the line it flags is likely already false.
  Docs step's, not this one's; recorded so it is met rather than grepped.
- Markers in `src/`+`tests/` still **27**; nothing else was touched.

## 2026-08-10 — the owner's question about helpHeld turns into a rule and a missing abstraction

Owner asked why `helpHeld` polls rather than binding `alt+h` on press and release. Analysed
before answering, and the answer generalised.

- **The trap, verified in the matcher:** a combo serialises from its trigger plus the modifiers
  held **at that instant**. Release `h` first → `'alt+h'`, binding fires. Release **Alt** first →
  the modifier's own release is refused by `find_shortcut` (`Key.is_mod`), and the later `h`
  release serialises as plain `'h'` — the `'alt+h'` binding is missed and **the overlay sticks**.
  **No second binding closes it**: a modifier's own press/release has no expressible combo at all
  (Decision 21). Focus loss leaks the same way. The poll self-heals from both.
- **Owner's rule, and it is the general form of that:** *combos serve an atomic transition — a
  one-off shot, stateless in itself; they must not toggle a long-lived state that depends on the
  combo still being held.*
- **THE GUIDE TEACHES THE TRAP.** §"Shortcuts that set a flag" binds bare `'space'` on both
  channels; press Space, then Ctrl, then release Space → the release is `'ctrl+space'` and the
  clearing binding misses. Milder than the modifier case only because a class binding *could*
  catch it. **Filed as a new P10 member — a defect in a teaching passage, not wording.**
- **Owner's forward sketch, recorded in the persistent register:** an abstraction for *"this
  chord is held"* — evaluated on update, **two callbacks (on/off)** at the transitions of a
  condition rather than one callback on an event channel. Same syntax as shortcuts, different
  integration. Would replace held-state `if` cascades and serves *"Ctrl held during a drag"*.
  **Explicitly not this release** — new surface, against a mandate to simplify.
- **`INPUT` is ruled for dissolution** (owner intent): it is a pure alias for `Key` now. Ten
  mechanical sites, written into P18 — with the note that `INPUT.upRecent` is the one genuinely
  own member and that **the heal may delete it anyway**, since the ratified design subtracts it.
  So the dissolution is sequenced *with* the heal, not before it.
- Also answered plainly why `helpHeld` kept `INPUT.alt` while gaining a direct `isDown('h')`:
  consistency with the nine other proxy reads, which the step forbade opening — a file-level
  judgement, and the mixed-looking expression is its real cost.

## 2026-08-10 — upRecent traced end to end, into P18's material

Owner asked what it is for, then asked to confirm it serves nothing else.

- **What it is:** a per-key table of the frame a key was last released, covering the release
  boundary of the Alt scene's glyph judging — `textinput` carries no `isrepeat`, so the example
  claims one glyph per press, and a final repeat arriving just after keyup would otherwise read
  as a fresh press. One-frame deadband per key; its cost is that a very fast re-tap is dropped
  too, which the design note's checklist already names.
- **Reach verified, not assumed:** one writer, one reader, one caller of that reader, no dynamic
  `INPUT[...]` access anywhere. `upRecent` is a **raw field**, so `__index` never fires for it —
  which is why grep, not the LSP, is what settles this file.
- **Why it matters to the step:** the apparatus is self-contained, which is what makes the heal's
  plan to subtract it wholesale credible; and it is the only non-alias member of the proxy, so
  the proxy dissolution rides with the heal rather than ahead of it.

## 2026-08-10 — Decision 30 challenged by the owner, examined cold, and it stands

Owner's challenge: the decision rested on *"nothing uses it"*, which is false — the biggest
input-heavy example read that surface, and had **independently grown a model of the same shape**,
which they read as a symptom that such a model was needed. Commissioned cold rather than answered
by me, since I authored the commits that depend on the answer. Prompt
`../../../validation/prompts/S36-decision30-standing.md`, report
`../../../validation/outcomes/S36-decision30-standing.md`.

- **Verdict: survives, with qualifications.** Two corrections matter more than the verdict.
- **The ledger never made the premise.** Decision 30 says *"the tracked set was never a
  requirement — no stakeholder requirement asks for it"* (`decisions/input.md:1247`, verified).
  Narrower than *"nothing uses it"*, and still true. The recorded rationale therefore does not
  lose its ground. (What the owner believed at the time is theirs to judge; the ledger is a
  separate question and this note is only about the ledger.)
- **The dependency was known when the decision was ruled, not discovered now.** Session31's track
  shows the same session commissioned a per-example census and called the keyboard example *"the
  real casualty"*. So this is a **known cost re-raised**, which changes what the challenge is.
- **The convergence evidence cuts the other way, traced in the example's own history:** the mirror
  existed for repeat/edge detection, that inference is what made the Alt scene deaf on hardware,
  and **the fix reached for no held-state at all** — it introduced a per-key claimed flag. What
  remains is the convenience need, which a stateless poll answers.
- **My own framing was overstated** and the reviewer said so: I carried the owner's *"nothing uses
  it"* into the commission as the decision's premise without checking the decision's text first.
  Verified after the fact; the correction is theirs, the error mine.
- **Reversal is dearer than I told the owner** — not "~16 commits mid-flight": the dissolution is
  fully executed, `keys_pressed` matches zero files in `src/`+`tests/`, and a nested repo's own
  history has moved on.
- **Its forward caveat, now written into the register** (owner's go): if the `compy.input.keys`
  proposal is dropped or deferred indefinitely, the convergence evidence stops being addressed
  and Decision 30's standing should be re-examined then. Recorded as a **condition on the
  proposal**, in the persistent corpus, because reviews are transient.

## 2026-08-10 — sapper's provenance, and an unverified rationale I propagated

Owner did not recognise `single`/`doppel` and suspected an agent had invented them. Checked.

- **Both are original**, from `918c87f6 aldum <aldum@artixlinux.org>, 2026-03-06, "feat: add
  sapper"` — a single 710-line commit adding the file whole. **So is the four-site modifier
  cascade**, `Key.*` calls included. The feature-era change to those lines before mine was only
  the registration surface (`function compy.singleclick` → `compy.input.hooks.singleclick`).
- **No pre-import history exists in this tree**, so the owner's recollection that their original
  click machinery was straightforward and gained modifier dependencies on import cannot be
  checked against the repo — said plainly rather than resolved.
- **MY ERROR, and it is the kind this session keeps finding.** The *"alternative input for touch
  devices with no double-click"* rationale exists **only** in `internals/examples/sapper.md`, a
  doc whose own header says *authored By LLM; human-approved NOT YET*. **`touch` appears nowhere
  in sapper's source.** I repeated that inference today while rewriting that very section, and it
  quietly softened my deviation analysis — "it's for touch" makes losing Shift+right-click sound
  cheaper. Corrected: the section now states the variants' behaviour and says the reason is not
  recorded.
- **Consequence for the PR:** sapper is a second example owned by someone else with no suite, and
  my conversion accepted two behaviour changes in it. The person who would notice is its author.
  Raised with the owner.

## 2026-08-10 — the owner supplies sapper's rationale; the conversion is reverted and escalated

Owner: *"on touch devices single click is often accidental and double click may be unreliable, so
he added a mousepressed path that triggers both effects on shift+touch and ctrl+touch."*

- **This makes my conversion a regression, not a deviation.** The press path exists to bypass
  click synthesis; I moved it onto that synthesis — button 1, on release, after the window,
  **dropped on drift**, and a finger drifts. The commit stated the mechanics correctly and still
  missed the point of the code. **The lesson is not "check the docs"** — the rationale was in no
  doc; it existed only with the author.
- **Owner's proposed correct shape, checked in the platform before agreeing:** press path as a
  class shortcut on `mousepressed` (that channel HAS a trigger, so the class key is a correct
  fallback and reproduces *any button, at press time* exactly), plus a **swallow** on the derived
  channel. The swallow is genuinely required: **consuming a press does not stop the derived
  click** — the gateway counts clicks in its own `mousereleased` handler, before and regardless
  of project consumption.
- **The hole I raised and the owner accepted:** derived clicks sample their modifiers **at
  synthesis time**, so releasing the modifier inside the double-click window makes the echo
  arrive unmodified, miss the swallow and act twice. Closing it needs a mirrored flag (the
  pattern we remove) or a platform change (out of mandate).
- **Ruled: revert (`f61ada67`), record, escalate.** Against aldum's import the file now differs
  only in the two registration lines the feature changed API-wide. Docs put back to describe the
  code that exists; the rationale is written into the internals doc so it stops living only in
  one person's head.
- **P19, the sapper deepfix — and the escalation rule fired on its first day.** P16's rule sends a
  design-heavy example to its own step; sapper is in-repo and would otherwise have been swept.
  The step is told the platform-fix branch is **release-shaped and gets promoted**, not done there.
- **Third time this session an LLM-authored doc supplied a confident wrong claim** (the "touch
  devices" line I repeated came from a doc marked *human-approved NOT YET*). Here the doc was
  right in substance and I had just deleted it as unsourced — so the pattern cuts both ways:
  unverified is unverified, whether it turns out true or false.

## 2026-08-11 — owner states five usage principles; proposal written, assessment attached

Owner expanded the sapper correction into a general set of principles for *using* the input API,
to be discussed here, reviewed cold by Fable, promoted to the persistent docs if they survive,
and then used to **replan — possibly reverting done work and discarding upcoming steps**. Written
to `../../../validation/reviews/S36-input-usage-principles.md` with strict provenance: §1 theirs,
§2 mine, §3 consequences.

- **P2 (mirrored shortcuts are an antipattern) is the load-bearing one** and it is already paid
  for: three defects found *before* it was written are instances of it — the `alt+h` pair, the
  guide's own `'space'` flag example, and sapper's derived-echo swallow.
- **Contests raised, six of substance.** Separator `-` collides with the hyphen key AND with the
  API's own `+` vocabulary; **the same string would mean different things on two surfaces**
  (shortcut `'shift+*'` is exclusive, a permissive query would not be) — recommended keeping `*`
  exclusive in both; *"nothing held"* is the commonest query and the ugliest to spell;
  **`compy.input.keys` is already claimed by yesterday's held-state-table proposal** and the two
  must reconcile (recommend module wins, table dropped — the query subsumes it and has no
  silent-nil); `pressed` reads as an event where `held` would not; P3 needs the release-channel
  miss stated, and its relation to `fn.ignore_repeat`.
- **The consequence nobody had stated: P5.1 dissolves sapper without touching its timing.** Four
  chains become four queries, the press path stays exactly where it is, no behaviour change at
  all — strictly better than both options weighed yesterday. Available only because the diagnosis
  moved from *"the call is a symptom"* to *"the chain is the symptom"*.
- **Biggest open question, flagged as unruled:** the principles are documentation, but P5.1 is
  **code** — new API surface, which the strategic frame obliges us to justify in the PR
  description or defer past this release.

## 2026-08-11 — owner corrects my sprawl objection; the real objection is coupling

- **Conceded: `Key.pressed('!ctrl','!alt','!shift')` is NOT sprawl.** It is one call. P5's
  complaint was chained conditions across call sites and physical state consulted at depth, not
  verbosity — I conflated the two.
- **What survives is stronger than what I withdrew:** enumerating the negations asserts *"these
  are all the modifiers there are"*, hard-coding framework set membership into project code — the
  fold reinvented one level up. **True today, false eight days ago:** Decision 31 closed the set
  and removed `gui`, so the same call written before that ruling would have been silently
  incomplete. `'shift+*'` never has this problem because it delegates membership to the matcher.
  So the case for an exclusivity token is **correctness, not brevity**.
- Owner offered further labels (`'!*'`, `'nothing'`, `'![mod]'`, `'![a-z]'`) if a call site needs
  them. Recorded with one caution: exclusivity is one cheap concept, key-classes are a different
  one that grows a **query mini-language** — a moving part the frame asks us to justify, needing a
  defined vocabulary and an answer for non-Latin layouts. Recommend shipping exclusivity,
  deferring classes.
- **Fable is mid-review of this document**, so the amendment was sent to it directly rather than
  left to be missed — it is judging the exclusivity question and was about to weigh a contest I
  had already dropped.

## 2026-08-11 — Fable reports: principles ratify, the primitive does not, and my sapper claim dies

Report `../../../validation/reviews/S36-fable-principles-review.md`, prompt in `../prompts/`.

- **Principles P1–P4 + P5.2: RATIFY**, with one required addition — they partially **reverse**
  Decision 30 point 3 (`Key.*` in project code "is a smell"), so that needs an **amendment stated
  in the ledger**, not silent supersession. It tried and failed to construct counterexamples (a
  safe mirrored pair, a legitimate continuous-state shortcut) against the real matcher.
- **P5.1: DO NOT ratify this release.** Ship the diagnosis as prose, defer the code. Its precedent
  is the owner's own *"not this release"* on the sibling `compy.input.keys` proposal one day
  earlier, on the same mandate; *"it is cheap"* and *"better than the table"* are true but
  orthogonal to the axis that ruling turned on.
- **Exclusivity: agrees with permissive default + `*`**, on the coupling argument.
- **MY ERROR, and it is the load-bearing finding.** §2.3 claimed the query respelling *"dissolves
  sapper's problem… no synthesis-time hole, no behaviour change at all"*. Self-contradictory: a
  pure respelling cannot both preserve behaviour and remove a defect that is part of it.
  **Retracted.**
- **Verified while retracting, and it is worse than I claimed: the hole is in the SHIPPED example.**
  Shift-click flags at press; the derived click lands 0.4 s later (`click_delay`); release Shift
  inside that window and it arrives unmodified, passes the hook's own guard, and runs again — and
  `actionFlag` **toggles**, so the cell un-flags. **Shift-click appears to do nothing.** Live,
  user-visible, predates the feature. Recorded in the register and in P19.
- **Other corrections of mine it named:** `any_mod` lives on `Controller`, not `Key`, so "expose
  it" means moving it; and I gave equal weight to two live defects and one illustrative doc
  example when arguing P2's evidence.
- **A finding neither of us had:** `tests/mock.lua`'s `isDown` is a plain table lookup and
  **never raises**, so the loud-failure property P5.1's safety rests on **would not be exercised
  by the suite at all** — only by the real engine. Same for `love.mouse.isDown`, which does not
  raise on an out-of-range button, so pass-through would not fail loudly for mouse tokens.
