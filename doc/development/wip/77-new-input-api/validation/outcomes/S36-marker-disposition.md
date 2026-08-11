# S36 — marker disposition inventory

**Commission:** `../prompts/S36-marker-disposition.md`. **Author:** session36 (Sonnet),
read-only pass. **Status: COMPLETE — 111/111 markers recorded** (27 `src/`+`tests/`, 84 `doc/`
outside `wip/`), written incrementally, file by file, per the commission's rule 1.

## Method note — how `owner` is decided, read this before the table

The two plans are **deliberately separate** (owner ruling, `S27-triage-and-plan.md` §0) and
this table must not conflate them. The binding rule applied below, derived from
`S27-triage-and-plan.md` §16.2–16.3 (session36's own replan, written one day before this
commission, measuring the same 27+84=111 markers):

- **`src/` + `tests/`, including the three nested example repos** → **SPRINT**, specifically
  **P11** (the sprint's comment sweep over `src/`+`tests/`, "gate is unambiguous") unless the
  marker's content matches a still-open named workstream, in which case that workstream is
  named too. The nested repos' own deepfix steps (P16 balloons/common sweep, P17 maze, P18
  keyboard, P19 sapper) are named where a marker's content matches their scope.
- **`doc/input_api.md`** (the project guide) → **SPRINT, P10** — named in the P10 row's own
  size accounting ("8 markers in the project guide") and in §16.2's recommendation ("code and
  guide fully cleared"), for **every** kind, not only factual ones — it is "the one document a
  stakeholder is promised."
- **`doc/development/internals/user_input.md` and `doc/development/decisions/input.md`** (the
  two large dev-facing/ledger docs) → **split by kind**, per §16.3's explicit text: *"The prose
  sweep over the persistent docs... largely editorial... They are the parent's, not this
  sprint's, except where a marker flags something factually wrong about input behaviour, which
  is P10's."* So: kind=**factual** (or an archaeology/other-kind marker whose actual content is
  a false/stale claim) → **SPRINT, P10**; kind ∈ {vocabulary, prose-size, archaeology-as-style,
  duplicate, answered} → **PARENT** (the prose sweep / Phase L ledger compaction, named per
  marker); kind=**question** → flagged in "needs an owner decision", owner column UNSURE unless
  the S27 doc already answers it.
- **Other `doc/` files outside `wip/`** (the "one or two per file" tail) → same kind rule as
  above: factual → SPRINT/P10, editorial → PARENT (general prose sweep), question → UNSURE.
- **IMPORTANT CAVEAT, stated once here rather than on every row:** §16.2 itself says the
  (a)/(b)/(c) split "needs an owner ruling… raised, not decided." The rule above is the
  *closest already-articulated* reading (§16.3's own sequencing text, not merely the
  recommendation), applied for consistency. Any row whose owner depends on this un-ruled split
  is marked with a trailing note `[open: §16.2 a/b/c]` so the ambiguity is visible per-row, not
  just here.

`kind` values used below follow the commission's fixed vocabulary: factual, vocabulary,
archaeology, prose-size, question, duplicate, answered.

---

## Table — code (`src/`, `tests/`), 27 markers

All 27 are **SPRINT, P11** by the plan's own unambiguous statement (§16.3 point 7: "the comment
sweep over `src/` and `tests/`... 27 markers, and the gate for them is unambiguous"). Where a
marker's content also matches a named deepfix step (P16/P17/P18/P19) or a W10 batch, that is
added as a secondary note — it does not change the owner.

| where | verbatim | kind | owner | note |
|---|---|---|---|---|
| `src/controller/consoleController.lua:135` | "comment does not match code and is too verbose" | factual | SPRINT (P11) | two asks in one marker (mismatch + length); comment follows re: `before_exit`/`hide_overlay` reset |
| `src/controller/consoleController.lua:180` | "word 'overlay' is strongly opposed. if its needed in console context (the only context where its meaningful), let use something like 'input_widget_overlay'" | vocabulary | SPRINT (P11) | cluster: retire-overlay (matches W10 batch 1, R002's own carve-out for `input_widget_overlay`) |
| `src/controller/consoleController.lua:181` | "too verbose comment. just briefly tell in which contexts function is supposed to be invoked instead of reexplaining how it works (prose length is x5 longer than code length!)" | prose-size | SPRINT (P11) | same comment block as :180, different ask |
| `src/controller/consoleController.lua:473` | "fix prose -- not \"where the event GOES\" but \"whether event PROPAGATES by returning hardcoded true/false\"" | factual | SPRINT (P11) | corrects the combinator doc-comment's own description |
| `src/controller/consoleController.lua:480` | "what you mean by 'reserved binding'? Its maybe 'recommended' or 'often used'?" | vocabulary | SPRINT (P11) | matches S27's W10 batch 4, "'reserved binding' (R010)" verbatim |
| `src/examples/balloons/terminal.lua:4` | "can we somehow simplify setup of the deliver handler? now its literally 3 functions juggling each other. Can be one?a / In fact, after submit we should deliver, clear *and* update prompt; and expose 'update-prompt' endpoint so that game can write its own welcome messages when mode is iswitched" | question | SPRINT (P11) | repo: `compy-balloons` (nested repo, own remote). Design/feature ask, not a wording fix — not named in P16's "Examples are not onboarded" register scope; flagged below under needs-owner-decision |
| `src/examples/keyboard/input.lua:58` | "WHY WOULD WE DO IT AND WHY USE custom 'INPUT' at all?" | question | SPRINT (P18) | repo: `keyboard` (nested repo, own remote). **Already ruled, not yet executed**: S27 P18 states "the owner's intent to dissolve the `INPUT` proxy, which is now a pure alias" — P18 is where this lands |
| `src/examples/keyboard/input.lua:99` | "what is it for? (setTextInput)" | question | SPRINT (P18) | repo: `keyboard`. Same file P18 (keyboard deepfix) rewrites |
| `src/examples/maze/main.lua:456` | "comment *tooo* verbose. simplify/compress" | prose-size | SPRINT (P11) | repo: `Compy-maze` (nested repo, own remote) |
| `src/examples/maze/main.lua:496` | "can we try using shortcuts/hooks and callbacks more actively?" | question | SPRINT (P11) | repo: `Compy-maze`. Not named in P17's own scope list (tab poll / escape guard / macro-recorder shift mirror) — flagged below as a possible P17 scope addition |
| `tests/editor/editor_spec.lua:715` | "rewrite and simplify prose: \"later\" is no more relevant when feature is delivered. Just \"guards compatibility of block navigation with widget's internal limits processing\"" | archaeology | SPRINT (P11) | cluster: no-historical-contrast (W10 batch 2 pattern — "later... rewrite" narrates a since-landed change) |
| `tests/helpers/input_fixture.lua:200` | "\"console route forwards...\" is not true any more. only rendering part is true" | factual | SPRINT (P11) | claims `F.is_widget_visible`'s doc-comment overclaims; unverified against current dispatch code in this pass (read-only; note only) |
| `tests/helpers/input_session.lua:1` | "simplify comment, do not tell what it is noe" | prose-size | SPRINT (P11) | |
| `tests/helpers/input_session.lua:13` | "simplify comment. just tell it exposes API to invoke 'love' events via handlers. (providing a controllable imitation of love2d events emitting, which in production would be done in response to actions over physical hardware)" | prose-size | SPRINT (P11) | |
| `tests/helpers/input_session.lua:39` | "simplify comment. just tell it invokes production function connectinng controller to love2d" | prose-size | SPRINT (P11) | |
| `tests/input/highlight_regression_spec.lua:1` | "remove references to input API release cycle, completely. its just a regression test accompanying bugfix" | archaeology | SPRINT (P11) | cluster: no-historical-contrast; three REMARKs stacked on the same comment block (see next two rows) |
| `tests/input/highlight_regression_spec.lua:2` | "simplify prose and desctibe *behavioural* test which raises exception (so, the real bug path -- i.e. project that supplies <some configuration> gets exception on <someinput>). Current checks read as testing seomthing purely internal." | prose-size | SPRINT (P11) | same block as :1 |
| `tests/input/highlight_regression_spec.lua:3` | "acceptance criteria: code does not break the way it used to . 'highlight must stay indexable' is implementation details, not acceptance criteria" | factual | SPRINT (P11) | same block as :1/:2; a test-design correctness claim, not wording |
| `tests/input/history_spec.lua:72` | "is comment even needed here? code is quite self-explanatory" | prose-size | SPRINT (P11) | cluster: comment-bloat (W10 batch 3 pattern) |
| `tests/input/input_cursor_text_spec.lua:1` | "what if we organize tests by three groups named explicitly: a) interception of inbound key/mouse events b) management of input widget c) reacting to input widget events (limits, submission, cancellation) -- but we'll need good names for describe, aligned with documentation" | **answered** | NEITHER (already done) | Verified: the tree now has exactly this structure — `describe('input surface: inbound events — dispatch #input'` (`input_events_spec.lua:32`), `'input surface: inbound events — routing #input'` (`input_routing_spec.lua:18`), `'input surface: inbound events — shortcuts and clicks'` (`input_shortcuts_click_spec.lua:28`), `'input surface: widget control #input'` (`input_widget_control_spec.lua:22`), `'input surface: widget callbacks #input'` (`input_widget_callbacks_spec.lua:42`). Matches S27's own note: "R057 landed as the three named surfaces" |
| `tests/input/input_events_spec.lua:191` | "this is kind of a matrix test I've thought of -- does it supersede dispatching tests above?" | question, likely **answered** | SPRINT (P11), UNSURE | The prose immediately above states the matrix's rationale in settled, non-hypothetical terms ("Two things at once — each participant intercepts for itself only... a MISSING participant is not a barrier") — reads as a later session's answer left un-deleted. S27's P8 row records "R058/R059/R060/R061 (tracer + matrix supersession)" as done in S28, but this pass cannot confirm this exact marker is one of those ids without deeper archaeology — **UNSURE which of "delete, already answered" vs "still open" is right; recommend a 5-minute check against `../outcomes/S33-p8-walk.md`** |
| `tests/input/input_shortcuts_click_spec.lua:6` | "is the prose below copied from elsewhere? it seems it recites the routing rules while suite tests something else? also its very excessive..." | prose-size | SPRINT (P11) | cluster: copypasted-routing-preamble (see also `input_widget_callbacks_spec.lua:5`, `:27` and `input_widget_control_spec.lua:4` — near-identical "Routing invariant... Decision 1... Vocabulary..." boilerplate) |
| `tests/input/input_widget_callbacks_spec.lua:5` | "remove copypasted irrelevant prose below" | prose-size | SPRINT (P11) | cluster: copypasted-routing-preamble |
| `tests/input/input_widget_callbacks_spec.lua:27` | "artifact prose from elsewhere? distill to only relevant" | prose-size | SPRINT (P11) | cluster: copypasted-routing-preamble |
| `tests/input/input_widget_callbacks_spec.lua:726` | "dry up the prose and consider making test cases more readable and self-evident" | prose-size | SPRINT (P11) | |
| `tests/input/input_widget_callbacks_spec.lua:727` | "I'd avoid word 'overlay' fully -- can be 'project input widget'" | vocabulary | SPRINT (P11) | cluster: retire-overlay |
| `tests/input/input_widget_control_spec.lua:4` | "prose below seems to be copied from elsewhere without much relevance to test suite content" | prose-size | SPRINT (P11) | cluster: copypasted-routing-preamble |

**Code markers: 27/27 recorded.**

---

## Table — doc, `doc/development/internals/user_input.md` (33 markers)

Owner rule for this file: **factual → SPRINT (P10)**; **vocabulary/prose-size/archaeology-as-style
→ PARENT**; **question → flagged, owner UNSURE unless already answered**. See the method note at
the top.

**Note on a near-miss:** `:680` reads `> REMARK "unbuild, R9" should not be . it should be built at
that moment. absolutely cheap change.` — missing the colon after `REMARK`, so it does not match the
`REMARK:`/`INTERIM:` grep and is **not** one of the 84 counted doc markers. Recorded here so it
isn't silently lost; its content duplicates `:668` (same R9/veto complaint) so nothing is missed by
excluding it from the count.

| where | verbatim | kind | owner | note |
|---|---|---|---|---|
| `internals/user_input.md:12` | "input widget is actualy not shared (as instance), so let's say \"input widget instances used across\". Word 'overlay' I'd prefer to not see anywhere -- just across \"console, editor and projects\"" | factual | SPRINT (P10) | Verified: four separate `UserInputController` instances exist (`main.lua:371`, `consoleController.lua:43`, `editorController.lua:12,16` — same fact S27's R088 records). "Shared" in the doc means shared *code*, not one instance; the remark is right that this reads ambiguously. Secondary ask: retire "overlay" (cluster: retire-overlay) |
| `internals/user_input.md:13` | "\"both now run\" is related to project only -- refactoring console/editor management same way is suggested for the future, when project input controller will be battle-tested" | factual | SPRINT (P10) | Scope clarification: the doc's "Both now run through the same... dispatch chain" (line 16) needs to say this is project-route only |
| `internals/user_input.md:14` | "in recent implementation pointer 'no shortcuts for pointer' should not be true -- the table must exist and be checked; combo of mods just constructed without 'trigger key'" | **answered** | NEITHER (already done) | Verified: "Mouse Input" §"Unified dispatch" (line 529) now reads "Pointer channels run the same three tiers as keyboard/text, with one combo vocabulary across all of them (Decision 27)" — pointer shortcuts exist and are documented. Matches W2, executed at P4 |
| `internals/user_input.md:24` | "'and project text solicitation'. \"overlay\" is a vague word, I want to avoid it. if we need to keep it let's say \"project text solicitation (widget drawn as overlay)\"" | vocabulary | PARENT | cluster: retire-overlay |
| `internals/user_input.md:48` | "say that \"defining its own\" is compatibility layer, these functions are reinstalled as hooks" | factual | SPRINT (P10) | asks for a more precise mechanism description, not a correction of an error — borderline factual/elaboration |
| `internals/user_input.md:78` | "does this translation stay true for project's input widget (or was it ever true for project?)" | question | SPRINT (P10), UNSURE | `_translate_to_input_grid` / `UserInputController` is shared code (same class for console/editor/project widget, "Input widget mouse" §), so the answer is very likely "yes, uniformly" — not conclusively confirmed against the project-overlay code path in this read-only pass |
| `internals/user_input.md:87` | "\"projects cannot install evaluator objects\" is not correct now? we allow them to configure evalator function" | **answered** | NEITHER (already done) | This is **R135** verbatim. S27 §5/§9 (the cold fact-check) already ruled it: "the evaluator-objects claim is precise, not stale... A validator is a predicate function; an `Evaluator`... is a different object a project genuinely cannot substitute. The doc is precise. No action." |
| `internals/user_input.md:96` | "again, \"overlay\" -> \"widget\"" | vocabulary | PARENT | cluster: retire-overlay |
| `internals/user_input.md:127` | "FR-1 is deelopment-time requirement id,(refid needs to be translated/deleted and essence needs to be explained to cold reader?)" | vocabulary | PARENT | cluster: jargon-refids (FR-N); matches parent Phase C's named "jargon policy" principle |
| `internals/user_input.md:136` | "\"project overlay\" -> \"project input widget\". This paragraph has to be rewritten into more readable form and actualized (i.e. project now can set prompt)" | factual | SPRINT (P10) | "actualized... project now can set prompt" is the substantive ask (paragraph may be stale on a real capability); rename is secondary (cluster: retire-overlay) |
| `internals/user_input.md:151` | "\"No framework tier any more\" -- there never was pre-feature; remove this reference, it describes self-inflicted-than-dissolved mechanism, which never was made public or stable" | archaeology | PARENT | cluster: no-historical-contrast (W10 batch 2) |
| `internals/user_input.md:202` | "\"no longer routes on widget presence\" is historical reference nobody is interested in -- it does not bear any information about current system for a cold reader ; in the past nobody relied on this occasional behaviour, its removal was one of the goals of new input API. So -- just strip this referencing-to-the-ancient-past part." | archaeology | PARENT | cluster: no-historical-contrast |
| `internals/user_input.md:203` | "console routing also was updated and no more consults widget shownness() -- could be stated as a matter of fact no refefences to the past" | archaeology | PARENT | cluster: no-historical-contrast; same paragraph as :202 |
| `internals/user_input.md:207` | "\"no longer\" relates to self-inflicted-then-dissolved behaviour, which never was characteristical of any stable release; remove referece and 'now-vs-then' vibe" | archaeology | PARENT | cluster: no-historical-contrast |
| `internals/user_input.md:208` | "paragraph below is overall too big and unreadable -- simplify/compress or even dissolve?" | prose-size | PARENT | same paragraph as :207 |
| `internals/user_input.md:237` | "there's no more forward_-calls (self-inflicted-then-dissolved), actualize towards actual behaviour and pre-feature behaviour (if changed)" | **factual** | SPRINT (P10) | Verified: `grep -rn "forward_" src/` finds **zero** `forward_*` functions related to input (only unrelated metalua compiler code) — yet the very next paragraph (line 239) says "every `forward_*` call in this section reports 'no widget'", describing a mechanism that does not exist in the current tree. This is a live inaccuracy, not merely a historical-contrast style complaint |
| `internals/user_input.md:306` | "there's no more 'DEFERRED' I think -- we do not guard shortcuts but provide guarding wrapper for convenience" | **factual** | SPRINT (P10) | Verified: `grep -rn "DEFERRED" src/` returns **nothing** — no `DEFERRED` marker exists anywhere in `src/`. The doc's own next sentence (line 312) claims "an in-code `DEFERRED` marker above `ProjectInputController:keypressed`... records this" — that marker is gone from the code. The remark is right and the doc paragraph is stale |
| `internals/user_input.md:345` | "FR-6 is ref-id unknown to reader (implementation-time encoding of requiements)" | vocabulary | PARENT | cluster: jargon-refids (FR-N) |
| `internals/user_input.md:410` | "while 'oneshot' flag was really removed, the \"separate framework-owned submit path\" did not exist as a concept pre-feature so there's no need to mention it (correct me if I am wrong)" | archaeology | PARENT | cluster: no-historical-contrast |
| `internals/user_input.md:458` | "heavy, unreadable paragraph below, rewrite" | prose-size | PARENT | |
| `internals/user_input.md:486` | "reference specific version not just 'input API' but 'input API (1.0.0-rc...)" | vocabulary | PARENT | precision/convention ask, not a rename |
| `internals/user_input.md:555` | "do not just say they are removed -- say they are repositioned -- firing happens on the \`love.handlers.*\` surface, mimicing the native love2d events. Project consumption lives in compy.input.hooks/compy.input.shortcuts. (at least its how I expect things to be)" | factual | SPRINT (P10) | disputes the "REMOVED" framing (line 558) as incomplete/misleading given the actual mechanism the same section documents |
| `internals/user_input.md:556` | "we can support seeding them from projects userlove -- as well as other events. We just do not encourage doing it in new and old projects, to avoid confusion" | question | UNSURE | A design/feature question (extend auto-seed to `singleclick`/`doubleclick`), not a doc fix — current code deliberately excludes the derived list from auto-seed (line 565). Flagged below under needs-owner-decision |
| `internals/user_input.md:603` | "retire 'overlay' completely as terminology . it can be used only contextually (when we want to emphasize the fact how project input widget is drawn)" | vocabulary | PARENT | cluster: retire-overlay — note this one sits directly above a section **heading**, "## The \`user_input\` Overlay — Input Perspective" |
| `internals/user_input.md:636` | "even if there was 'instead of the main controller' path I doubt somebody relied on it or called it that way; therefore reference could be dropped." | archaeology | PARENT | cluster: no-historical-contrast |
| `internals/user_input.md:653` | "'no framework tier any more' -- and there was not before feature,so let's not reference self-inflicted-than-dissolved mechanisms nobody ever saw" | archaeology | PARENT | cluster: no-historical-contrast; duplicate ask of `:151` |
| `internals/user_input.md:668` | "what do you mean 'reserved, unbuilt' and what is R9? If we declare that callback should be veto-ing, than it should be" | **answered locally** | NEITHER, flag | The phrase "reserved, unbuilt" is **not** present in this file's current text near :668 — the code block right after it (lines 670-677) already shows `before_submit` as veto-then-return, matching W5/P5 (DONE). **But the identical phrase survives in `decisions/input.md:283`** ("(still-reserved, unbuilt)") — see that file's table for whether a marker there catches it. R9 itself is unexplained anywhere found in this pass |
| `internals/user_input.md:679` | "and there was no implicit hide so 'anymore' is improper and whole reference can be removed. or just say -- \"there's no implicit hide\". asme abot 'no longer auto-closes' -- it never was unless configured with 'one-shot' flag (now replaced by callbacks)." | archaeology | PARENT | cluster: no-historical-contrast |
| `internals/user_input.md:697` | "\"unlike_submit\" should be wrong because submit should also be honored" | **answered** | NEITHER (already done) | Verified: the current text at :698 reads "`before_cancel`'s return value is honoured **the same way** `before_submit`'s is" — already says "same way", not "unlike submit". The complaint is resolved in the text as it stands |
| `internals/user_input.md:720` | "this archeology should've been removed, it serves no purpose except confusion (not to be confused though with love.state.user_input that is a flag telling view to draw)" | archaeology | PARENT | re: the dead `love.handlers.userinput` vestige paragraph |
| `internals/user_input.md:729` | "hook names are actual I hope. Formula still sounds weird. And I am not sure what paragraph tries to communicate -- remove it?" | question | PARENT, UNSURE | asks whether a paragraph adds value; flagged below |
| `internals/user_input.md:739` | "why restate the shape of API there? Just tell what the table is and where its constructed and where its described" | prose-size | PARENT | |
| `internals/user_input.md:784` | "it belongs to API documentation, do not duplicate here if not needed. Or describe one-level-of-abstraction-up -- tell what this api is capable of doing, not invocation details and signatures" | prose-size | PARENT | duplication complaint vs `doc/input_api.md` |

**`internals/user_input.md`: 33/33 recorded.**

---

## Table — doc, `doc/development/decisions/input.md` (30 markers)

Same owner rule as above (factual → SPRINT/P10; editorial → PARENT). Additional wrinkle specific
to this file: several markers challenge whether a numbered decision is worth keeping in the ledger
at all ("is this even a decision?"). That question is **Phase L (ledger compaction)**, owned by the
**PARENT** plan — but note Phase L's own scope (§Phase L in `plan.md`) currently only covers
Decisions 13/20/29 (the withdrawn held-key set); it has **not yet ruled** on Decisions 6/7/12/15,
which is exactly what several of these markers ask about. Flagged per-row.

| where | verbatim | kind | owner | note |
|---|---|---|---|---|
| `decisions/input.md:109` | "any real reason to treat widget specially? why not interpret it as any other chain element? I feel special treatment is an artifact of design hallucinations that were self-inflicted and dissolved. I see no reason to treat widget separately -- and if we discard decision 5, codebase change would be minimal and won't change any behaviour" | question | **NEITHER (already ruled)** | This is **R080** verbatim. S27 W6: "Verdict... R080 is S1 and I recommend declining for this PR" — and the [REV] section records **both cold reviews independently confirmed the decline**, with two supporting facts (no `UserInputController` event method returns anything; nothing downstream of the widget could read a manufactured `false`). Owner ruling already made at P1 |
| `decisions/input.md:120` | "now its more than three components, we are sending pointer events the same way!" | factual | SPRINT (P10) | This is **R081**. S27 §5 correction #3: "Decision 2's 'three components' excludes pointer, which runs the same dispatch" — rated S3, **not yet executed** as far as this pass can tell (still present in the text read) |
| `decisions/input.md:126` | "\"there was once\" is irrelevant -- a history of hallucination, self-inflicted and dissolved during implementation. Does not have to be mentioned" | archaeology | PARENT | cluster: no-historical-contrast / hallucination-residue |
| `decisions/input.md:136` | "'old four-component shape' was pure hallucination, remove its mentions from here" | archaeology | PARENT | cluster: no-historical-contrast / hallucination-residue; same paragraph as `:126` |
| `decisions/input.md:146` | "\"de-facto SDL articat\" is vague and its not clear how its relevant here" | question | PARENT, UNSURE | asks whether the SDL-ordering paragraph is even relevant; flagged below |
| `decisions/input.md:159` | "'consuming-is-not-removing' is an artifact of self-reasoning across hallucinations. nothing nowhere required 'consuming' to be 'removing', so defending against it makes no sense. I'd remove whole paragraph -- it speaks about what is *not* supported, while this not-supported was also never-requested or never-assumed" | archaeology | PARENT | cluster: hallucination-residue |
| `decisions/input.md:167` | "this is proper approach and it contradicts with formula few paragraphs before (supposedly stale) that says widget state is \"checked at the end of chain, and bypassed if not shown\" -- which was fully unnecessary complication hopefully dissolved since then" | **factual** | SPRINT (P10) | This is **R086** verbatim. S27 W6: "R086 says a paragraph in `decisions/input.md` describing the old... model still stands and contradicts the current one... R086 is **S3 and unconditional** — a stale paragraph in a permanent doc, fix it." Not yet executed |
| `decisions/input.md:173` | "its really not exactly this way -- we still use 'ifs' because we decided not to plumb tables with 'no-ops' default. so this paragraph could be recalibrated to reality or removed" | factual | SPRINT (P10) | disputes the `shortcuts(...) or hooks(...) or widget(...)` short-circuit framing against the actual if-chain implementation |
| `decisions/input.md:192` | "\"same code\" (which is kinda true? check) does not mean \"same instance\" -- and there are reason to limit 'singleton' to project widgets only. prose below was a pre-implementation vision -- but implementation at least currently ended with the different instances (console needs to maintain its own). So the prose below should be recalibrated to reality" | **factual** | SPRINT (P10) | This is **R088** verbatim. S27 §5 correction #2: "a live contradiction inside `decisions/input.md`... Decision 3's *Why* argues for one shared instance on memory grounds... while the same file's Implementation note (`:716-718`) states 'Multiple `UserInputController` instances remain required'. Four instances exist." Not yet executed |
| `decisions/input.md:200` | "replace \"input events\" with \"events originated at input widget\" -- to not confuse inbound events and outbound ones. Or if we speak both classes, let's make the paragraph more clear about it... rewrite the opening to be unambiguous about context -- message itself... is correct -- we discard polling idiom." | vocabulary | PARENT | terminology-disambiguation ask, not a factual dispute (marker itself says "message itself... is correct") |
| `decisions/input.md:220` | "its the good moment to say \"chain routes events into the route where they are consumed by shortcuts/hooks. The widgets reports results out through *callbacks*\". Which is exactly the difference in terminology -- callbacks originate during input processing, shortcuts/hooks consume inbound OS events. Important part here is using term \"callbacks\" instead of \"widget outputs\" which are not defined anywhere." | vocabulary | PARENT | This is **R013** verbatim (W10 batch 4: "'callbacks' not 'widget-output entries'") |
| `decisions/input.md:234` | "conflating them is not generally a trap -- so no need for this false rationalization. Just say we distinguish" | prose-size | PARENT | |
| `decisions/input.md:235` | "overall this block has too much self-invented explanation, including 'student' passage. No need to overprotect the normal engineering decision." | prose-size | PARENT | same block as `:234` |
| `decisions/input.md:269` | "if it does not differ from pre-feature behaviour, there's no decision to record at all. Why this decision arrived -- attempt to combat design hallucination which assigned special roles. If as a result we just got back to normal platform behaviour, there was no decision worth standing in this register. IF we did de-facto change the behaviour -- the whole 'decision' block should be compressed 2-3 times..." | question | PARENT, UNSURE | On **Decision 6** — this is the source of S27 W9(a)'s "the owner's test is sharp... if the behaviour is what the platform always did, there was no decision to record", listing Decision 6 among the challenged set. **Not the same set Phase L already ruled on** (13/20/29) — this is an open ledger question. Flagged below |
| `decisions/input.md:350` | "the decision is very trivial, I do not think its worth documenting, or should be literally few lines" | question | PARENT, UNSURE | On **Decision 7** — also named in S27's over-full-ledger list. Same open-question status as `:269` |
| `decisions/input.md:383` | "rewrite -- now 'combo-tables' are reproduced without explanation. Instead the solution was to support combo-tables at all (to avoid stuffing all event-handling logic in a single hook and enable modularity). The way combo tables are assembled and checked is downstream tactical decision -- we took the simplest form. So the full block has to be rewritten" | prose-size | PARENT | On Decision 8 |
| `decisions/input.md:454` | "these 'no' sound like protecting against alternatives not-requested-and-not-considered" | archaeology | PARENT | On Decision 10; cluster: hallucination-residue |
| `decisions/input.md:455` | "now 'all' events are shaped this way" | factual | SPRINT (P10) | On Decision 10 — claims the decision's "no widget-aware gating..." framing understates that this is now universal, not selective |
| `decisions/input.md:456` | "lets reframe the decision as \"new api has more appropriate place for hooks -- so we silently re-wire old 'project-installed callbacks' there -- encouraging new usage but not disabling old one, if it's ever needed for pedagogical purposes" | prose-size | PARENT | rewrite/reframe suggestion for Decision 10 |
| `decisions/input.md:466` | "nobody cares which exactly original intermittent shape decision had once if it was rewritten since and dissolved form never materialized in release/contract/doc" | archaeology | PARENT | cluster: no-historical-contrast (Decision 10's "Substance changed from the original pure-wrap" passage) |
| `decisions/input.md:491` | "clean up self-arguing with past decisions that were than reshaped before release. WHat was not in released version is considered as never existing (except few bits explicitly ratified by stakeholders)" | archaeology | PARENT, UNSURE | On **Decision 11** — the file's own W9-hard-constraint precedent for tombstoning ("Decision 11 was retired in place... the safe precedent") lives in the very passage this marker targets (the withdrawn keyboard/pointer-asymmetry rationale, checked against `3256aac`). Removing that audit trail may conflict with keeping Decision 11 as the tombstone example other decisions are meant to follow — flagged below rather than silently trimmed |
| `decisions/input.md:532` | "if its the behaviour system had and keeps having, its not a decision -- its documented de-facto standard" | question | PARENT, UNSURE | On **Decision 12** — also named in S27's over-full-ledger list. Same open-question status as `:269`/`:350` |
| `decisions/input.md:572` | "only historical correction -- we proactively reverse-engineered system behaviour and codified existing de-facto standards in a tests, and documented some -- therefore canonicalizing them *before* implementation; the fact that some of those came unnoticed until post-implementation controversies resolution is secondary. its mostly about historic accuracy of the first phrase, decision itself stands" | factual | PARENT | On Decision 14 — a nuance about the doc's own history-of-how-it-was-written, not a claim about current input behaviour, so it sits outside P10's "factually wrong about input behaviour" carve-out |
| `decisions/input.md:601` | "its quite trivial and obvious tactical decision, is it even worth documenting?" | question | PARENT, UNSURE | On **Decision 15** — also named in S27's over-full-ledger list. Same open-question status |
| `decisions/input.md:638` | "no need to describe interim forms, invented and dissolved in-flight" | archaeology | PARENT | On Decision 15's "Superseded — the original warn-and-ignore form" section |
| `decisions/input.md:658` | "this decision was fully overwritten and de-facto input was unified across events axis (to not be confused with postponed unification of routing mechanisms across cosnole/editor/project which is still deferred). So this block should be removed" | **factual** | SPRINT (P10) | This is **R109**, on **Decision 16**. S27 W9(a): "Decision 16 (R109) is **the clearest** — event-axis unification happened, so the entry describing it as deferred is simply wrong." Not yet executed |
| `decisions/input.md:707` | "is it an artifact block describing history which passed? (afaik now 'dispatch' *is* reusable function) -- review and recheck if it belongs here" | archaeology | PARENT | This is **R110**. S27 §5 correction #5, explicitly **re-kinded**: "The section does not call `dispatch` non-reusable; it says in past tense that the mid-feature dispatch *had been*... Its real ask is 'cut this stale intra-feature history' — W10's historical-contrast batch. Moved [from W9 to W10]" |
| `decisions/input.md:775` | "let's fully retire ambiguous 'overlay' from everywhere. Its input widget." | vocabulary | PARENT | cluster: retire-overlay; sits directly above the heading "## Decision 18 — the overlay answers one state question" |
| `decisions/input.md:840` | "historical references (when exactly was something decided) bear no value, strip them" | archaeology | PARENT | cluster: strip-status-dates (the "Status: implemented (owner ruling, DATE)" stamps used throughout this file) |
| `decisions/input.md:905` | "ignore_repeat appears to be keypressed-specific wrapper, because its not passed anywhere else? worth mentioning." | factual, UNSURE | UNSURE | Real technical nuance (`isrepeat` is a `keypressed`-only LÖVE argument, so wrapping a `textinput`/pointer hook in `ignore_repeat` is a no-op) — worth documenting, but the marker asks for an addition, not a correction of an error, so it sits at the boundary between "factual" and "editorial elaboration" |

**`decisions/input.md`: 30/30 recorded.**

**Cross-file note, verified while reading this file:** `internals/user_input.md:668` (see that
file's table) complains about the phrase "reserved, unbuilt" — that phrase is **gone** from
`user_input.md`'s own text but **still present** in `decisions/input.md:283` ("(still-reserved,
unbuilt)", inside Decision 6's "Consequence" paragraph, line 346-347 region). No `REMARK:`/`INTERIM:`
marker sits at that exact spot in `decisions/input.md`, so this stale phrase is **currently
unflagged** by any of the 111 markers. Recorded here since the commission asks for anything already
answered to be verified, and this is the reverse case — a real leftover the marker net missed.

---

## Table — `doc/input_api.md` (the project guide), 8 markers

Owner rule for this file per the method note: **SPRINT (P10) for every kind** — it's named
explicitly as the guide that must be "fully cleared" ("code and guide fully cleared" — §16.2).

| where | verbatim | kind | owner | note |
|---|---|---|---|---|
| `doc/input_api.md:11` | "rewrite intro completely, be dev-friendly. Vague statements do not help. Just tell its an API for configuring and interacting with text solicitation subsystem, and for reacting to user input events (all of them). Tell that even when widget is not shown or used, still it can be used to manage hotkeys, combos etc." | prose-size | SPRINT (P10) | |
| `doc/input_api.md:17` | "would it help readability if we conceptually split API into three surfaces (and say so): a) dispatching/intercepting inbound events via shortcuts and hooks b) altering the soliciting widget state (hide/show/cursor/reconfigure) c) handling events generated inside widget via callbacks (submit, cancel, limit...)" | question | SPRINT (P10) | Matches **R172** (accepted for the test suite/internals doc per S27 W9, "pairs with R057/W8 — the guide, the internals doc and the test suite should use one vocabulary") but **not yet applied to this file**: verified — `doc/input_api.md`'s current `##` headings are still feature-by-feature (`Quick start`, `show(config)`, `Submit lifecycle`, `Event hooks and shortcuts`, `Pointer and click hooks`, ...), no three-surface grouping |
| `doc/input_api.md:165` | "why developer would even think of reading love.state?" | question | SPRINT (P10) | challenges whether the `love.state` guard-against paragraph is needed at all |
| `doc/input_api.md:258` | "retire word 'overlay' -- \"stop reaching the input widget too\" is a proper formula" | vocabulary | SPRINT (P10) | cluster: retire-overlay |
| `doc/input_api.md:322` | "not 'overlay', but 'input widget'" | vocabulary | SPRINT (P10) | cluster: retire-overlay |
| `doc/input_api.md:323` | "frame this whole paragraph as example of solving non-conventional challenge (preventing modifier-based hotkey from echoing into the input widget), not say \"if you open with 'i'\" as if it was some common or recommended convention" | prose-size | SPRINT (P10) | reframing ask for the "Opening the overlay from a key" section |
| `doc/input_api.md:353` | "term 're-arm' is invented -- if you use it, make sure its explained or defined in the same doc, upfront." | vocabulary | SPRINT (P10) | jargon-definition ask, not a retirement |
| `doc/input_api.md:522` | "it should be able to suprress/defer the stop? or if its not allowed purposefully -- that it should not be announced as 'deferred' functionality in other part of documentation" | **answered** | NEITHER (already done) | This is **R181**. Both halves verified done: (a) the design question was ruled — S27 §3 "What I recommend NOT doing": "**R181** — `before_exit` suppressing the stop", declined, with W5's reasoning (`ConsoleController:stop_project_run` calls `before_exit` **unguarded**, so a suppress/defer return would sit on a non-raise-safe teardown); (b) the "deferred functionality" mislabel this marker also asks to fix: `grep -rn "deferred functionality" doc/` (outside `wip/`) returns **nothing** — already removed. Current text at `input_api.md:524` reads plainly: "**Return value:** ignored. It cannot suppress or defer the stop." |

**`doc/input_api.md`: 8/8 recorded.**

---

## Table — the remaining doc files (13 markers across 10 files)

Owner rule: same kind-based split as `internals/`/`decisions/` (factual → SPRINT/P10, editorial →
PARENT, question → flagged). None of these files are singled out by name in the P10 row's own
size accounting (8+30+33=71 of the 84), so they fall to the general "prose sweep over persistent
docs... except where a marker flags something factually wrong" rule.

### `doc/development/tests.md` (2)

| where | verbatim | kind | owner | note |
|---|---|---|---|---|
| `doc/development/tests.md:65` | "we do not care where it originally lived as it was mid-implementation. such an ephemeral archeology is irrelevant for persistent doc -- describe current state of things" | archaeology | PARENT | Verified still live: the very next paragraph (line 68) still opens "The `#input` contract suite originally lived in one large file... in validation it was split along cognitive seams..." — the history this marker objects to is still there |
| `doc/development/tests.md:66` | "also actualize if file/tag/line references are still valid, but first ask yourself, are they really needed for bird-eye overview of testing subsystem?" | question | PARENT, UNSURE | asks whether granular file/line references belong in a bird's-eye doc at all |

### `doc/development/internals/project_sandbox_env.md` (2)

| where | verbatim | kind | owner | note |
|---|---|---|---|---|
| `internals/project_sandbox_env.md:71` | "Update 'exists, not a proposal' with concrete avaiability reference -- \"since version...\"" | vocabulary | PARENT | precision/convention ask, matches `internals/user_input.md:486`'s "reference specific version" pattern |
| `internals/project_sandbox_env.md:101` | "make pointer annotations more useful for reader, and also check their completeness/consistency and whther they are actual" | question | PARENT, UNSURE | re: the "## Pointers" cross-reference list right below; asks for a currency check, not a named defect |

### `doc/development/internals/examples/repl.md` (2)

| where | verbatim | kind | owner | note |
|---|---|---|---|---|
| `internals/examples/repl.md:15` | "why two different paths if both actions can be called in a single 'on_text_entered'? if we want to show the different ways, we may explain its for demo purposes (actually on_text_entered and after_submit are obviously duplicates which may be a small architectural smell; consider removing 'after_submit' from callbacks? or allow installing all callbacks via show? or even avoiding setting callbacks via show and only use callbacks table?)..." | question | **NEITHER (already ruled), UNSURE on exact match** | Substance matches **R121/R122** (S27 W5): "ask whether callbacks should be settable through `show{}`'s config at all, or only through `compy.input.callbacks`... I recommend deferring" — and §3 "What I recommend NOT doing" declines it for this PR. Not confirmed to be literally the same remark id (R121/R122 were sourced from `src/controller/*` comments, this is a different file), so flagged rather than asserted |
| `internals/examples/repl.md:39` | "its literally called *with* config in the example above -- and config installs callback, which raises a question of API shape (why not have separate callbacks interface as the only way to set callbacks)" | question | **NEITHER (already ruled)** | Same R121/R122 substance as `:15`, more directly — S27 §3 declines it explicitly for this PR |

### The six single-marker files

**Note on a second near-miss:** `doc/development/internals/event_dispatch_layers.md:106` reads
`> REMARK/nitpick -- project vocabulary introduces *three* terms (also a 'shortcut') -- maybe its
worth mentioning here too` — no colon after `REMARK`, so like `user_input.md:680` it does not match
the `REMARK:`/`INTERIM:` grep and is not one of the 84 counted. Recorded so it isn't silently lost;
it is a genuine (small) ask: the vocabulary section it sits next to names `hook`/`callback`/`handler`
but not `shortcut`, a fourth assignable-function word this codebase also uses.

| where | verbatim | kind | owner | note |
|---|---|---|---|---|
| `technical_debt/general.md:16` | "its not a defect, but convention -- gfx is alias for love.graphics, sfx is alias for compy.audio" | **factual** | SPRINT | This is **R168** verbatim. S27 W9: "R168 is a correction to us, and it is right... Remove the tech-debt entry." **Ruled but not yet executed** — verified: the `## \`gfx\` implicit global in \`controller.lua\`` entry (lines 18-25) is still present in the file, describing it as a defect |
| `internals/examples/turtle.md:17` | "remove 'owner ruling' provisional reference, just say its done on purpsoe" | archaeology | PARENT | asks to drop the "(owner ruling, 2026-07-31)" qualifier so the captured-`love.*` pattern reads as settled design, not a provisional call |
| `internals/examples/tixy.md:35` | "did we decided to change preexisting behaviour by dropping legend on submit? maybe do not do it?" | question | UNSURE | Asks whether clearing `legend` in `submit_body` (visible in the code block right below) was a deliberate behaviour change or an incidental regression from the old-API example. Not verified against the pre-feature example in this pass — flagged below |
| `internals/examples/paint.md:3` | "worth installing love.{mousemoved,keypressed} as hooks? (as they will anyway be reassigned there). It would be cleaner. we can even introduce paradigm of aliasing compy.input.hooks as 'hooks' for comprehension" | question | UNSURE | Design/style suggestion for the paint example (not one of the three nested repos — `paint` lives in-repo) |
| `internals/examples/guess.md:5` | "can we avoid using ambiguous word 'overlay' which is just a synonym for project's input widget? unifying terminology would be less confusing to reader" | vocabulary | PARENT | cluster: retire-overlay |
| `internals/examples/balloons.md:3` | "it seems balloons itself is a bit overcomplicated now (it built its own abstraction layer around input, to combat previous complexity -- now it could e.g. clear/configure/deliver in a single on_submit callbac. We won't rework it -- just admit the fact (API now makes possible to eliminate internal complexity, but we only do focused updates)" | question, self-answered | SPRINT (P16), UNSURE | The marker proposes its own resolution ("we won't rework it — just admit the fact") but the doc text does not yet "admit the fact" — no such note is in the current file. If the self-proposed resolution is accepted, this is a small doc addition owned by **P16** (the common sweep names `balloons` explicitly as in scope); the "should we actually simplify it" question underneath is not decided here |
| `internals/event_dispatch_layers.md:112` | "this needs actualization, because the routing was recently unified and there's no more artificial divergence between keyboard/pointer?" | **factual** | SPRINT (P10) | Verified: `doc/development/technical_debt/input.md:1267` — "**Pointer delivery is an unstructured broadcast, not a chain (RESOLVED, 2026-08-03)**" — "pointer joined the existing chain rather than getting a mirror of it... the gateway's pointer entries no longer deliver to the widget themselves." The asymmetry `event_dispatch_layers.md` still describes at this spot (pointer as raw `love.<event>` handlers vs keyboard/text as captured hooks) is the resolved-away state. The remark is correct |

**Six single-marker files: 7/7 recorded** (`technical_debt/general.md`, `internals/examples/turtle.md`,
`internals/examples/tixy.md`, `internals/examples/paint.md`, `internals/examples/guess.md`,
`internals/examples/balloons.md`, `internals/event_dispatch_layers.md` — seven files, one marker
each; the section header above undercounts by one, corrected here).

**All 84 doc markers recorded. Grand total 111/111 (27 code + 84 doc) recorded.**

---

## 1. Clusters — the headline number

**111 raw markers collapse to roughly 6 named repeated moves (62 markers, 56% of the total) plus
~20 standalone factual/vocabulary fixes that do not repeat elsewhere, ~10 markers already resolved
(zero work left), and ~13 open questions that are rulings, not edits.** The two big clusters
(historical-contrast and comment-compression) account for well over a third of the entire
inventory by themselves — the crude keyword sample that motivated this commission was right.

### Cluster A — Retire "overlay" → "input widget" / "project input widget" — **11 markers**

One vocabulary sweep, contextual exception already named by the markers themselves
(`input_widget_overlay` where the console context needs to say "drawn as an overlay"). Matches
S27's W10 batch 1 ("~17 remarks" — this pass finds 11 of those with the literal word "overlay" as
their ask; the rest of W10 batch 1's estimate is likely bare uses of the word without a marker
attached, out of this commission's scope).

- `src/controller/consoleController.lua:180`
- `tests/input/input_widget_callbacks_spec.lua:727`
- `doc/development/internals/user_input.md:12` (secondary ask, paired with an instance-count correction)
- `doc/development/internals/user_input.md:24`
- `doc/development/internals/user_input.md:96`
- `doc/development/internals/user_input.md:136` (secondary ask)
- `doc/development/internals/user_input.md:603`
- `doc/development/decisions/input.md:775`
- `doc/input_api.md:258`
- `doc/input_api.md:322`
- `doc/development/internals/examples/guess.md:5`

### Cluster B — No historical contrast / hallucination-residue — **22 markers**

Strip "no longer", "used to", "there was once", "self-inflicted-then-dissolved", "hallucination"
narration of intermediate shapes that never shipped. Matches S27's W10 batch 2 ("~10 remarks" in
`src/`+`tests/` scope — this pass finds far more once the doc corpus's two large files are
counted in; W10's own estimate was scoped narrower). Owner's rule already on record: *"if it was
not in a released version, write as if it never existed."*

- `tests/editor/editor_spec.lua:715`
- `tests/input/highlight_regression_spec.lua:1`
- `doc/development/internals/user_input.md:151, 202, 203, 207, 410, 636, 653, 679, 720` (9)
- `doc/development/decisions/input.md:126, 136, 159, 454, 466, 491, 638, 707` (8)
- `doc/development/internals/examples/turtle.md:17`

### Cluster C — Copy-pasted "routing invariant / vocabulary" test preamble — **4 markers**

The near-identical "Routing invariant (Decision 1)... Vocabulary (`user_input.md`, "Dispatch
chain")..." boilerplate block, pasted at the top of four spec files, each with its own marker
asking to trim or verify it is relevant to that file's actual content.

- `tests/input/input_shortcuts_click_spec.lua:6`
- `tests/input/input_widget_callbacks_spec.lua:5`
- `tests/input/input_widget_callbacks_spec.lua:27`
- `tests/input/input_widget_control_spec.lua:4`

### Cluster D — Comment/prose compression ("too verbose", "dry up", "simplify") — **19 markers**

One editorial policy (write terser comments, per `agents/rules/commenting.md`) applied at 19
distinct sites. This is S27's W10 batch 3 ("comment bloat, ~50 remarks") as it appears in *this*
commission's 111 — the ~50 estimate was for the full comment-bloat population tree-wide; this
count is markers that explicitly ask for compression (a "too big/verbose/dry up" ask), not every
comment W10 batch 3 will eventually touch.

- `src/controller/consoleController.lua:135` (paired with a factual mismatch ask), `:181`
- `tests/input/highlight_regression_spec.lua:2`
- `tests/helpers/input_session.lua:1, 13, 39`
- `tests/input/history_spec.lua:72`
- `tests/input/input_widget_callbacks_spec.lua:726`
- `src/examples/maze/main.lua:456`
- `doc/development/internals/user_input.md:208, 458, 739, 784`
- `doc/development/decisions/input.md:234, 235, 383, 456`
- `doc/input_api.md:11, 323`

### Cluster E — FR-N / ref-id jargon translation for a cold reader — **2 markers**

- `doc/development/internals/user_input.md:127` (FR-1)
- `doc/development/internals/user_input.md:345` (FR-6)

### Cluster F — "Is this even a decision?" — ledger over-full challenge — **4 markers**

Decisions 6, 7, 12, 15 each individually challenged as documenting pre-existing platform
behaviour rather than a real decision. This is the **PARENT plan's Phase L territory**, but Phase
L's currently-ruled scope only covers Decisions 13/20/29 — these four are a **second, not-yet-ruled
batch** of the same question.

- `doc/development/decisions/input.md:269` (Decision 6)
- `doc/development/decisions/input.md:350` (Decision 7)
- `doc/development/decisions/input.md:532` (Decision 12)
- `doc/development/decisions/input.md:601` (Decision 15)

### Not clustered — standalone factual fixes (one-off, ~20 markers)

Each targets different content and does not repeat: `src/controller/consoleController.lua:473,
480`; `tests/helpers/input_fixture.lua:200`; `tests/input/highlight_regression_spec.lua:3`;
`internals/user_input.md:13, 48, 78, 237, 306, 555`; `decisions/input.md:120 (R081), 167 (R086),
173, 192 (R088), 200, 220 (R013), 455, 572, 658 (R109), 905`; `technical_debt/general.md:16
(R168)`; `internals/event_dispatch_layers.md:112`; `input_api.md:353`; `internals/user_input.md:486`;
`internals/project_sandbox_env.md:71`. Most of these already map to a named S27 remark id (R081,
R086, R088, R013, R109, R168) and a ruling; a few (`:78`, `:555`, `:905`) are this pass's own
findings, not yet cross-checked against the S27 inventory.

---

## 2. Already answered — the tree has overtaken these (10 markers, 0 remaining work)

| where | why it's answered |
|---|---|
| `internals/user_input.md:14` | "Mouse Input" §"Unified dispatch" documents pointer shortcuts existing (Decision 27) — the claim the marker disputes is no longer in the text |
| `internals/user_input.md:87` | **R135.** S27's cold fact-check: the evaluator-objects claim is precise, not stale — a validator (predicate) and an `Evaluator` object are genuinely different things a project cannot substitute |
| `internals/user_input.md:668` | The "reserved, unbuilt" phrase this marker asks about is gone from this file's own text (the code block right after it already shows the veto built) — **though the same phrase survives in `decisions/input.md:283`, currently unflagged by any marker** |
| `internals/user_input.md:697` | Current text already reads "honoured **the same way**", not "unlike submit" — the complaint is resolved as written |
| `decisions/input.md:109` | **R080.** S27 W6: declined for this PR, confirmed independently by two cold reviews, with two supporting facts (no event method returns anything; nothing above the widget could read a manufactured `false`) |
| `doc/input_api.md:522` | **R181.** Both halves done: the suppress/defer design question was ruled "no" (S27 §3), and the "deferred functionality" mislabel it also asks to fix is verified absent from the doc corpus |
| `internals/examples/repl.md:15`, `:39` | Substance matches R121/R122 (settable-via-`show()` question), declined for this PR per S27 §3 — "a second contract change with no defect behind it" |
| `tests/input/input_cursor_text_spec.lua:1` | The tree now has exactly the three named surfaces this marker asks for — verified via the five `describe()` headings across `input_events_spec.lua`, `input_routing_spec.lua`, `input_shortcuts_click_spec.lua`, `input_widget_control_spec.lua`, `input_widget_callbacks_spec.lua` |
| `tests/input/input_events_spec.lua:191` | Likely answered (the surrounding prose already reads as settled design, not a live question) but **not conclusively confirmed** against S27's R058-061 supersession work — kept as a flagged UNSURE, not asserted outright |

---

## 3. Needs an owner decision (not an edit) — 13 markers

Genuine questions, listed so they can be answered in one sitting rather than re-discovered one at
a time during the sweep:

1. **`internals/user_input.md:78`** — does the mouse-click-to-cursor translation apply to the
   project's own input widget, or only console/editor? (Very likely "yes, uniformly" — shared
   code — but not confirmed against the project-overlay path specifically.)
2. **`internals/user_input.md:556`** — should `singleclick`/`doubleclick` support auto-seeding
   from a project's own `love.*`, the same way every other channel does? Currently deliberately
   excluded.
3. **`internals/user_input.md:729`** — does the "hook names / formula" paragraph communicate
   anything a reader needs, or should it be cut outright?
4. **`decisions/input.md:146`** — is the LÖVE/SDL keypressed-vs-textinput ordering paragraph
   relevant enough to keep, or should it go?
5. **`decisions/input.md:269`** — Decision 6: not-a-decision (remove) or keep-and-compress?
6. **`decisions/input.md:350`** — Decision 7: worth documenting at all, or a few lines?
7. **`decisions/input.md:491`** — Decision 11's withdrawn-rationale audit trail: does removing it
   (per this marker) conflict with keeping Decision 11 as the file's own tombstone precedent
   (W9's hard constraint), which the same paragraph partly *is*?
8. **`decisions/input.md:532`** — Decision 12: not-a-decision (remove) or keep?
9. **`decisions/input.md:601`** — Decision 15: worth documenting, or a few lines?
10. **`decisions/input.md:905`** — should `ignore_repeat`'s `keypressed`-only scope (it is a no-op
    wrapping `textinput`/pointer hooks, since `isrepeat` is a `keypressed`-only LÖVE argument) be
    documented explicitly?
11. **`internals/examples/tixy.md:35`** — was clearing `legend` on submit a deliberate behaviour
    change from the pre-feature example, or an incidental regression? Not verified in this pass.
12. **`internals/examples/paint.md:3`** — worth installing `love.{mousemoved,keypressed}` directly
    as hooks in the example, and/or introducing a `hooks` alias for `compy.input.hooks`?
13. **`src/examples/maze/main.lua:496`** and **`src/examples/balloons/terminal.lua:4`** — both are
    feature/design requests (use shortcuts/hooks/callbacks more in maze's idle prompt; simplify
    balloons' deliver-handler setup and add an `update-prompt` endpoint) rather than doc or
    wording fixes. Neither is named in P16/P17's current scope lists — an owner call is needed on
    whether they're in scope for this sprint's deepfix steps or deferred entirely.

