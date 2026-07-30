# S23 — revalidation of session22's pre-TF2 gate work

**Scope:** delta check of session22's outcome, per `agents/rules/revalidation.md`.
Not a feature sweep. Evidence is code/doc/git at HEAD `2942147`; no prior report
was taken on trust.

**Verdict: NOT CLEAN — accept with corrections.** The substance of session22 is
sound: every contract claim in the persistent corpus that I checked matches the
code, the rulings are canonical, and the slice partition is exactly what was
claimed. But two gates session22 recorded as *complete* are demonstrably
**incomplete on their own stated criteria** — C1 (authority integration) and J1
(vocabulary cleanup) — and one navigation slice **cannot be applied at all**.
Everything found is review-visible; nothing requires reopening a ruling or
touching production behaviour.

**The pattern behind the findings:** session22 made the persistent corpus
*authoritative in status* but never reconciled the layer that **points at** it.
Contract text is right; ~22 citations of it are dead, 13 comments cite the tree
that is about to be deleted, and two of the corpus's own references do not
resolve. A reviewer meets all of this on the first pass — which is the second
reading session22 existed to prevent.

---

## 1. Intent reconstruction

Session22 was commissioned to **settle every decision that could still reshape
the #77 PR candidate, execute the resulting work, make the persistent
documentation corpus the authoritative contract, and hand the owner a fresh
navigation batch — so the code review happens once, not twice.**

## 2. Intent-vs-outcome coherence

### a) Internal coherence — PASS

The 12/12 disposition ledger, the commits it names, and the report agree. Each
ruling that claimed execution has a commit, and each commit does what its
message says. Spot-verified `93330dc` (hidden-console fallback), `2e0d93f`
(line-array callbacks), `09eb143` (unsupported-key warnings), `9f23e8a`
(Turtle line array).

### b) Coherence toward intent — PARTIAL

The decisions are settled and the code is aligned. What is *not* settled is the
layer the owner will actually read: the **comments in `src/` and `tests/` that
cite the contract**. They still point at section names the contract no longer
has, at a working tree that is deletion-gated, and — in two places — at a
**model the feature explicitly retired**. A reviewer reading the diff top to
bottom meets this on the first pass. That is the second reading session22 was
commissioned to prevent. See findings **F1**–**F3**.

### c) Coherence toward surrounding context — PARTIAL

`doc/development/conventions/code.md` §"Comment References" and
`doc/development/technical_debt/input.md` §"Comment wip-citation cleanup" both
describe the wip-citation residue as **"two `src/controller/` comments"**. The
true figure is **13 comment blocks in 7 tracked files**, four of them shipped
examples. The corpus is authoritative in status but wrong on this fact (**F2**).

### d) Updated-surroundings self-coherence — PASS

`doc/development/tests.md:70` states `862 successes / 0 failures / 0 errors /
3 pending` — matches the live run exactly. `CHANGELOG.md` describes line arrays
and the warn-and-ignore behaviour, both verified in code. Decisions 15/16/17
are canonical and match the rulings recorded in the session22 track.

## 3. Consistency check — the transformation was not applied uniformly

**J1 (plain vocabulary).** The commit `e28f58d` claims "no source marker
remains". `src/main.lua:355` still carries:

```lua
  -- RESOLVED-BY-REDESIGN (R4-1 inventory; validation/reviews/
  -- R4-U3-callback-model.md, delta-design "Implementation note"):
```

`e28f58d` **touched `src/main.lua`** (4 lines changed), so this is a missed
site inside a swept file, not an out-of-scope file. It is one marker, but it is
the exact class J1 declared closed.

## 4. Integrity check — contract text preserved and accurate

I verified the public contract against the code rather than against the report:

| `doc/input_api.md` claim | Code | Verdict |
|---|---|---|
| `show` accepts prompt/text/cursor/highlighter/validator/on_text_entered/on_limit_reached/force | `SHOW_KEYS`, `consoleController.lua:457` | exact match |
| Unknown keys warn and are ignored | `reject_unknown_show_keys`, `consoleController.lua:468` | warns once per key, nils it |
| Submit order before_submit → validator → on_text_entered → after_submit | `submit_flow`, `userInputController.lua:408` | matches (empty guard sits after `before_submit`) |
| `LuaHighlighter` / `LuaSyntaxValidator` / `LineValidators` are project globals | `evaluator.lua:140-159`, seeded `consoleController.lua:914` | present |
| `configure` accepts the documented keys except `force` | `userInputController.lua:342` | whitelists prompt/highlighter/validator/on_text_entered/on_limit_reached |
| Retired `eval`/`result` warn | `input_widget_lifecycle_spec.lua:74` drives the real route | proven by test |

Tracked examples consume line arrays correctly (`guess`, `repl`, `tixy`,
`valid`, `turtle` — all index `lines[1]` or `string.unlines(lines)`). Nothing
was silently dropped.

## 5. Gap check — one item under-done, nothing over-done

Under-done: the reference layer (F1/F2) and the stray binary (F4). Scope was
not exceeded anywhere; session22 correctly declined to redesign inspect, to
implement `multiline`, and to unify pointer dispatch.

## 6. Artifact check — PASS

All session22 artifacts exist and are complete: `report.md`, `track.md`, the C1
/ J1 / TF2 outcomes under `validation/outcomes/`, eight slice patches, and the
repointed `CURRENT PROMPT`. No placeholders, no truncation.

---

## Findings

### F1 — 8 cited contract sections do not exist (22 sites, 8 tracked files)

A resolver over every quoted `doc/….md, "Section"` citation in tracked `src`
and `tests` (109 citations total) found **8 section names that no longer
resolve**. The contract *content* still exists — the guide was rewritten and
its headings changed — so every one of these is a rehoming, not a contract
question.

| Cited section | Actual home | Sites |
|---|---|---|
| `input_api.md` "Sticky callbacks" | "Callback assignments" | `consoleController.lua:440`, `input_widgets_callbacks_spec.lua:526`, `input_route_lifecycle_spec.lua:120` |
| `input_api.md` "API reference" | "`show(config)`" / "Live changes" | `input_cursor_text_spec.lua:6,20,115,188` |
| `input_api.md` "Live reconfigure" *(and the long form "Live reconfigure: `configure`, `set_text`, `clear`, cursor")* | "Live changes" | `consoleController.lua:575`, `userInputModel.lua:517`, `input_cursor_text_spec.lua:130,144`, `input_reconfigure_spec.lua:316`, `user_input_model_spec.lua:151` |
| `input_api.md` "The continuous-session idiom" | *no successor section* | `input_reconfigure_spec.lua:258,323` |
| `input_api.md` "Activating the widget: `show`" | "`show(config)`" | `input_widget_lifecycle_spec.lua:26,105,117` |
| `internals/user_input.md` "Submit and cancel — the framework submit chain" | "Submit and cancel — widget-owned callback sequences" | `input_reconfigure_spec.lua:320` |
| `internals/user_input.md` "Submit and cancel — the framework tier-1 chains" | same as above | `input_widgets_callbacks_spec.lua:319,334,422` |

**The last two are not cosmetic.** "Framework submit chain" and "framework
tier-1 chains" name the model **Decision 6 revised replaced** — submit and
cancel are widget-owned callback flows, *not* a framework tier. Four test
comments a reviewer will read still assert the superseded architecture.

Related, cosmetic only: nine sites cite `internals/user_input.md` "Cursor
manipulation and 'reset'" with single quotes where the heading uses double
quotes. Greppable-by-eye, not greppable-by-tool.

Also stale in substance, not just in name:
`input_reconfigure_spec.lua:258-262` heads the `#m8` block with *"the migration
recipe: on_text_entered consumes; **after_submit re-shows**… the pattern every
example migration relies on"*. After R2 the overlay stays open and the examples
**clear** instead of re-showing — the second test in that very block says so in
its own comment ("New idiom (Decision 6 revised): the widget stays open"). The
tests are correct; the block header contradicts them.

### F2 — the corpus understates its own recorded wip-citation debt by ~6×

`conventions/code.md:87` and `technical_debt/input.md` §"Comment wip-citation
cleanup" both say **two `src/controller/` comments**, at `consoleController.lua`
~L511 and `userInputController.lua` ~L8. Neither line number is still right, and
the real inventory is **13 comment blocks across 7 tracked files**:

| File | Sites |
|---|---|
| `src/controller/userInputController.lua` | 359, 402, 419, 461, 509 |
| `src/controller/consoleController.lua` | 47, 374, 1297 |
| `src/main.lua` | 355 |
| `src/examples/{guess,repl,tixy,valid}/main.lua` | 49 / 1 / 171 / 73 |

All cite `doc/development/wip/77-new-input-api/validation/reviews/…`, i.e. the
tree whose deletion is owner-gated. The four **shipped examples** are the part
the debt entry does not mention at all — and examples are what a stakeholder
reads first. Four of them also carry the construction-era phrase "R4-U4 example
migration".

### F3 — construction-era residue J1 did not reach

- `src/main.lua:355` — `RESOLVED-BY-REDESIGN (R4-1 inventory; …)`. Inside a
  file `e28f58d` edited (see §3).
- `tests/editor/editor_spec.lua:712` — `-- (S21/B-F): this is editor-internal
  behaviour…`, a session/batch-ID citation. This file was outside both J1
  commits' diff scope (they touched `tests/input/` and
  `src/{controller,model,view,util,main}`), so it is a **scope** miss, not an
  execution miss — J1's criterion was the shipping corpus, and
  `tests/editor/` is part of it.

Verified: within their own diff scope both J1 commits are clean and
comment-only — no assertion, expression, or control-flow change
(`validation/outcomes/S23-marker-corpus-sweep.md` §4).

### F5 — two broken/undeletable cross-references *inside* the persistent corpus

The corpus is defined as the docs that survive deletion of `wip/77`, so every
reference in it must resolve without that tree. Two do not:

| Site | Citation | Problem |
|---|---|---|
| `technical_debt/input.md:243` | `tests/input/overlay_spec.lua` | **No such file anywhere in the tree.** The debt entry ("Overlay-shape test exercises a stub") points at nothing. Either the test moved and the entry was not updated, or the entry outlived the test. |
| `decisions/input.md:257` | `design/requirements.md` | Resolves **only** to `doc/development/wip/77-new-input-api/design/requirements.md`. It dangles the moment the wip tree is deleted — and it is load-bearing: it is the evidence cited for a *withdrawn stakeholder guarantee*. |

The second is the more serious: a ratified decision rests its justification on a
document the owner is about to be asked to delete.

Observation, not a finding: `internals/user_input.md:611` cites
`examples/maze/main.lua` as a usage example. The file exists but is
**untracked** — the doc describes the committed tree while resting on something
outside version control.

### Explicitly *not* findings (sub-agent framing corrected)

- **23 bare `#77` citations across four persistent docs are fine.** `#77` is a
  GitHub issue number: permanent, public, and resolvable long after the wip tree
  is gone. That is exactly what a persistent doc should cite. No action.
- **`technical_debt/input.md:570`'s literal `wip/77-new-input-api` path is
  correct in context** — it is the debt entry *about* wip citations and has to
  name its subject.
- Minor, owner's call: `tests.md:53` "in feature-#77 validation (TF1)" and
  `tests.md:64` "removed at 0.1.0-m8, M8-03" carry internal phase/batch labels
  that mean nothing to a post-merge reader. Both sentences parse without them.
  `0.1.0-m8` reads as a version but is a construction batch label.
- `src/util/graphics/bentley_ottmann.lua`'s many "sweep" hits are the
  Bentley–Ottmann sweep-line algorithm. Benign.

### F4 — slice `3d-tests` cannot be applied; a vim swap file is tracked in the diff

`tests/input/.input_nfr_forward_spec.lua.swp` — a **binary vim swap file** — was
added to the repository by `64e5af4` and is inside the `3256aac..HEAD` reviewable
set. The generated patch carries it as `Binary files /dev/null and b/… differ`
with no payload (`3d-tests.patch:909-912`), so `git apply` refuses the **whole
slice**. Independently verified by the slice audit
(`validation/outcomes/S23-slice-partition-verify.md` §4), which confirmed the
other 25 files in `3d-tests` apply cleanly once that one path is isolated.

Session22 knew of the file and put it out of J1's scope as "deliberately
untouched". That call was made about *vocabulary cleanup*; nobody assessed it as
*PR content*. It is an editor artifact with no reason to ship.

---

## Confirmed clean

- **Suite:** `busted tests` → **862 / 0 / 0 / 3**, matching the prompt. The
  three pendings are the documented routing cells (console key release, editor
  pointer, project-run touch), all in `tests/input/input_routing_spec.lua`.
- **Slice partition:** 8 slices (`1`, `2`, `3a`–`3f`) cover all **89**
  WIP-excluded changed files **exactly once** — complete, disjoint, no extras,
  arithmetic confirmed (23+14+3+3+6+26+5+9 = 89).
- **Slice currency:** the reviewable file set is **identical** at `4c002e8` and
  at HEAD. The owner's Dockerfile commit `16546af` lands entirely inside the
  excluded `wip/77` tree, so it never enters the review set — doubly out of
  scope. Only drift is the one-line `CURRENT PROMPT` pointer in
  `agents/validation.md` (slice `2-agentic`).
- **Contract accuracy:** the table in §4 — every claim checked against code.
- **Test evidence quality:** the R5 acceptance test drives the real public
  `show` route and asserts the direct callback stays authoritative; the R2
  contract rows assert line-array delivery. Both are behavioural per Decision 17.

## Open question for the owner (not a finding)

`show{ eval = … }` warns; `configure{ eval = … }` is **silently dropped**
(`userInputController.lua:342` whitelists five keys and ignores the rest).
Decision 15 deliberately scopes the warning to `show`, so this is consistent
with the ruling as written — but the rationale it gives ("silent configuration
typos have no visible effect and make an otherwise simple API needlessly
difficult to use") applies identically to `configure`, and a project migrating
off `eval`/`result` is as likely to pass them there. Worth one line either way
before the PR: extend, or say why not.

---

## Recommended dispositions

Ordered smallest-risk first; **none is executed** — all await the owner.

1. **F4 — untrack the swap file.** `git rm --cached` +
   `tests/input/.input_nfr_forward_spec.lua.swp` in `.gitignore`. One commit.
   Unblocks `3d-tests`. Requires a slice regeneration afterwards, which the
   remaining items also require.
2. **F1 + F3 — one comment-rehoming pass.** Repoint the 22 dead citations at
   current headings, fix the `#m8` block header to the post-R2 idiom, drop the
   `RESOLVED-BY-REDESIGN` marker. Comment-only; the suite is untouched by
   construction. **The two "framework tier" citations should be treated as the
   priority** — they misstate the architecture, not just a heading.
3. **F2 + F5 — corpus reference repair.** Correct the two entries that
   understate the wip-citation inventory; fix or retire the dead
   `overlay_spec.lua` reference; and rehome `decisions/input.md:257` off
   `design/requirements.md` (quote the stakeholder line inline, so the withdrawn
   guarantee keeps its evidence after `wip/77` is deleted). Rule whether the
   shipped examples' wip citations are rehomed now — recommended, they are the
   most-read files in the PR — or left as recorded debt.
4. **Then** regenerate the navigation slices, since 1–3 all touch reviewable
   files. This is still navigation, not Phase-G assembly.

If the owner prefers to open TF2 immediately, F1/F2/F3 are readable-as-is
noise and defensible to defer; **F4 is not** — one of the eight slices does not
apply today.

---

## Not verified

- Whether the 55-marker figure from J1's original audit was fully worked: I
  checked the *criterion* (no construction-era markers in tracked shipping
  files), not the audit's own list.
- Nested example repos (`balloons`, `maze`) — sanctioned anomalies, excluded by
  the assembly guide §5.
- Whether every one of the 109 doc citations points at the *semantically right*
  section; I verified that the cited section **exists**, and read the ~20 sites
  where it did not.

## Sub-agent evidence

- `validation/prompts/S23-marker-corpus-sweep.md` →
  `validation/outcomes/S23-marker-corpus-sweep.md`
- `validation/prompts/S23-slice-partition-verify.md` →
  `validation/outcomes/S23-slice-partition-verify.md`
