# S29 — revalidation of the S28 suite merge, from outside the S28 checks' shape

Reviewed 2026-08-08, session29. Read-only throughout: no spec, source, doc or
config file was touched; nothing staged/committed/pushed; no branch, checkout
or stash operation. HEAD `8ed4093b` on `feature/77-newapi-analysis-s20260615`
throughout. `git status --porcelain` before and after this pass is identical
(listed in full at the end).

Scope, per the brief: not re-verifying rows/titles/assertion-lines/deletions/
helper-*names*/citations-of-filenames — those were already checked twice and
I take the outcome as given. Looking instead for properties a title/assertion
diff cannot see.

Method note: the four dissolved source files no longer exist in the working
tree, and running the *whole* pre-merge suite (needed for check 3) requires
more than `git show <sha>:<path>` can give — it needs every file at
`90f632cf^`, including two files that are git submodules
(`src/util/string`, `src/lib/metalua`), which `git archive` does not
materialise. Resolution used throughout: `git archive 90f632cf^ | tar -x` into
a scratch dir outside the repo, then the current working tree's copies of the
two submodule directories were copied in on top (submodule content is pinned
identically across this branch; this does not touch `/repo`). The resulting
tree was verified to reproduce the documented pre-merge baseline exactly
(`954 successes / 0 failures / 0 errors / 3 pending`) before being used for
anything comparative. Scratch location:
`/tmp/claude-1000/-repo/7df95d55-3cb7-48c8-9fcc-af9f345cc2ac/scratchpad/s29/`
(`orig/` = the four files via `git show`; `pre/` = the full archived tree).

---

## 1. Enclosing context per row (setup/teardown/before_each at every nesting level) — CONFIRMED

Grepped `before_each|after_each|lazy_setup|strict_setup|^\s*setup(|^\s*teardown(`
across all four originals and both merged files:

```
orig/input_reconfigure_spec.lua:23-25        setup/teardown/before_each (F.setup/F.teardown/F.reset)
orig/input_lifecycle_uniform_spec.lua:41-43   same, at root describe
orig/input_widget_lifecycle_spec.lua:26-28    same, at root describe
orig/input_widgets_callbacks_spec.lua:48-50   same, at root describe
tests/input/input_widget_control_spec.lua:23-25    same
tests/input/input_widget_callbacks_spec.lua:43-45  same
```

Every hit is at the file's single root `describe`; grep found zero hits inside
any nested `describe` in any of the six files — no row anywhere in the four
originals or the two merged files runs under a describe-local
`before_each`/`after_each`/`lazy_setup`/`strict_setup` of its own. So there is
no "row whose source describe had its own nested before_each" case to check —
the class of bug the brief describes cannot occur here because it never
occurred in the source either.

Independently confirmed from git history rather than the plan's prose: none
of the five merge commits (`90f632cf`, `25f70175`, `b0c9d032`, `bc5b97ae`,
`a246c170`) touch `tests/helpers/input_fixture.lua` (`git show --stat` on all
five — no mention of that path). `F.setup`/`F.teardown`/`F.reset` are
therefore the exact same function bodies, from the exact same required
module, for every row in both merged files, regardless of which of the four
originals it came from. This is stronger evidence than the plan's "identical
across all four files" claim (which could be true today and still drift) —
it shows the merge commits themselves could not have changed it even
incidentally.

## 2. Insulation and cross-row state — FINDING (latent, not live) + CONFIRMED for the rest

Inventoried every monkeypatch-with-manual-restore pattern (`X = <replacement>`
... `X = orig`, no `finally`, no `pcall`-wrapping the restore) in both merged
files and checked, for each, **where the restore sits relative to any
assertion that could throw**, and **which describe (and hence which original
source file) is upstream vs downstream of it in the merged file's row order**.

**`Log.warn` — the finding.** File A (`input_widget_control_spec.lua`) has
four such patches:

| row | merged line | restore-before-assert? | original file |
|---|---|---|---|
| `re-activation without force warns + no-ops` | 66-75 | yes (L72 restores, L73-74 assert) | `input_widget_lifecycle_spec.lua` |
| `a state-condition no-op warns and does not raise` | 136-149 | yes (L142 wraps in `pcall`, L147 restores before L148 assert) | `input_widget_lifecycle_spec.lua` |
| `applies text and cursor on the next show` | 320-334 | yes (L327 restores, L328 asserts) | `input_reconfigure_spec.lua` |
| `while hidden warns and no-ops` | 392-400 | yes (L398 restores, L399 asserts) | `input_reconfigure_spec.lua` |

All four restore `Log.warn` **before** the first assertion that could fail —
confirmed by direct read, line numbers above are the actual restore/assert
lines in `tests/input/input_widget_control_spec.lua` today. So there is no
live bug: a normal assertion failure in any of these four rows cannot leave
`Log.warn` monkeypatched.

The property that **did** change is the blast radius of a *different* class of
failure — the call under test (`input.show()`, `input.configure()`,
`input.clear()`) itself raising an unexpected Lua error between the patch and
the restore line, which none of these four rows' own logic guards against
(the restore is placed after the call, not in a `pcall`/`finally`, except the
one row that already wraps its whole body in `pcall`). Before the merge, rows
1-2 lived in `input_widget_lifecycle_spec.lua` (bounded blast radius: only
that file's own later rows, insulated per busted-file from the reconfigure
file's rows) and rows 3-4 lived in `input_reconfigure_spec.lua` (same,
reversed). After the merge, all four sit in one busted-insulated file, and
rows 3-4 (ex-`reconfigure`) now execute **after** row 1-2 (ex-`widget_lifecycle`)
in the same file-scope `Log`. A hypothetical leak from row 1 or 2 could now
reach the `configure()`/`clear()` groups that used to be in an entirely
separate file and could never have observed it. This is exactly the "two rows
that could not see each other's leaked state; merged into one file they can"
class the brief names — it is real and merge-caused, but it is **dormant**:
it requires a production bug (an unexpected raise from `show`/`configure`/
`clear`) that does not exist today, on top of the merge, to manifest.
**Severity: low / latent.** Not something to fix reflexively — `finally`
support isn't used anywhere else in this suite either (see below), so this
would be a suite-wide convention change, not a one-file patch.

**Other monkeypatches checked, all CONFIRMED clean of the same class:**

- `F.cc.evaluate_input` (two sites, file B lines 938-950 and 1046-1057) and
  `model.cancel` (file B lines 825-836) both restore **after** their
  assertions (same as in the original `input_lifecycle_uniform_spec.lua`,
  lines 226-238 / 336-345 / 114-125 respectively — read and diffed, identical
  code) — so the *same* dormant-leak shape exists here too, but it is **not
  merge-introduced**: all three patches, and every row between them that
  could receive a leak, come from `input_lifecycle_uniform_spec.lua` alone.
  In the merged file B, "the same lifecycle on every route #lifecycle" is the
  **last** describe (starts at line 755 of a 1061-line file, nothing follows
  it), so its blast radius is exactly what it was pre-merge: bounded to its
  own rows, now with zero rows after it instead of zero rows after it in a
  smaller file. No change.
- `F.widget.view.draw` reassignment (file A, "a shown overlay is painted",
  three rows, lines 640-668) is never explicitly restored, but this group was
  already the **last** describe in `input_widget_lifecycle_spec.lua` before
  the merge and is still the last content-bearing describe in file A after
  it (only a trailing comment follows) — same non-issue, unchanged by the
  merge.
- No `spy.`/`stub(` calls exist anywhere in the four originals or the two
  merged files (`grep -n 'spy\.\|stub('` — zero hits in either set) — the
  suite's only "spy" is the hand-rolled method-patch pattern above, so there
  is no busted-spy state to worry about leaking via a different mechanism
  (e.g. spy registries that busted itself resets per-test vs per-file).

`package.loaded` manipulation: none found in any of the six files (only
ordinary `require` calls). Module-level upvalues beyond the shared `F`/`mock`/
`TU`/`love` globals: none — both merged files declare no file-scope `local`
state outside the one describe block that needs it (`arm`/`open_on` in file
A, `bare_uic`/`driver`/`open_doc` in file B), each still scoped to its own
single describe, not file scope.

## 3. Order dependence introduced by the merge — CONFIRMED (with a caveat about pre-existing whole-suite flakiness)

Built the full pre-merge tree per the Method note and ran `busted tests
--shuffle -o TAP` 8 times against it and 8 times against HEAD (16 runs
total), then grepped every `not ok` line for any row whose title comes from
one of the four merged/source files.

Raw per-suite failure counts (both trees fluctuate similarly — a **known,
pre-existing, whole-suite** order-dependence unrelated to this merge; e.g.
`Editor #editor plaintext works with scroll and wrap ...` and
`input model spec #input ...` rows fail under shuffle at **both** revisions):

- HEAD, 8 runs: 41, 55, 28, 44, 32, 34, 40, 40 failures.
- `90f632cf^` (pre-merge), 8 runs: 29, 42, 29, 44, 32, 28, 40, 44 failures.

Per the brief's own rule ("a failure at both is pre-existing and is not yours
to fix"), this whole-suite shuffle flakiness is out of scope — but I checked
it is genuinely present at both ends, not just assumed.

The decisive part: across all 16 shuffle runs, **zero** failing-test titles
matched any describe from `input_widget_control_spec`/`input_widget_callbacks_spec`
(HEAD) or `input_widget_lifecycle_spec`/`input_reconfigure_spec`/
`input_widgets_callbacks_spec`/`input_lifecycle_uniform_spec` (pre-merge):

```
grep -h "^not ok" /tmp/hd_*.tap  | grep -iE "widget control|widget callbacks|surface: widget"   -> (no output)
grep -h "^not ok" /tmp/pre_*.tap | grep -iE "widget lifecycle|reconfigure|widget outputs|one input lifecycle" -> (no output)
```

Additionally, per the brief's suggestion: each merged file run alone, and
shuffled alone, 5 times each:

```
busted tests/input/input_widget_control_spec.lua              -> 39 successes / 0 / 0 / 0
busted tests/input/input_widget_callbacks_spec.lua             -> 52 successes / 0 / 0 / 0
busted tests/input/input_widget_control_spec.lua   --shuffle x5 -> 39/0/0/0 every time
busted tests/input/input_widget_callbacks_spec.lua --shuffle x5 -> 52/0/0/0 every time
```

**Verdict:** no order dependence traceable to the merge. The suite-wide
shuffle flakiness is real but symmetric across both revisions and does not
touch the merged content in 16 sampled runs.

## 4. Helper bodies, not helper names — CONFIRMED

Byte-diffed (not eyeballed) the full body of every helper a moved row calls,
original vs. merged:

```
diff <(sed -n '335,353p' orig/input_widget_lifecycle_spec.lua)   <(sed -n '560,578p' tests/input/input_widget_control_spec.lua)    -> identical (arm, open_on)
diff <(sed -n '47,71p'   orig/input_lifecycle_uniform_spec.lua)  <(sed -n '758,782p' tests/input/input_widget_callbacks_spec.lua)  -> identical (bare_uic, driver, open_doc)
```

Both diffs produced no output (identical). Also confirmed via the `lua-lsp`
MCP server (AST-level, not text) that every reference to `open_on` (4 sites)
and `bare_uic` (3 sites, one per call site plus definition) resolves only
within its own merged file, at the lines shown above — no cross-file or
cross-describe resolution exists to check for divergence, because Lua's
lexical scoping makes a same-named `local` in a different file structurally
unable to collide (confirmed, not merely assumed).

`arm`/`open_on` and `bare_uic`/`driver`/`open_doc` are each declared exactly
once, inside exactly one `describe`, in exactly one merged file — same
shape as pre-merge, no reimplementation, no accidental second definition.

## 5. Test-runner selection surfaces (tags, `.busted` profiles) — CONFIRMED

`.busted`'s `default` profile sets `exclude-tags = "delay"`. Grepped for a
`#delay` tag anywhere in `tests/` (not just `tests/input/`): zero hits. So
`exclude-tags = "delay"` is a no-op for this whole suite today, merge or not
— confirmed rather than assumed:

```
grep -rln "#delay" tests/     -> (no output)
busted tests            -> 954 successes / 0 failures / 0 errors / 3 pending
busted tests --run=all  -> 954 successes / 0 failures / 0 errors / 3 pending   (identical — the non-excluding profile changes nothing)
```

Enumerated every literal `#word` inside a `describe(`/`it(` title string in
both merged files (not the four originals again — that was done in S28's
post-move review; I re-ran the grep independently as a check on today's
tree, not a re-trust of that review):

```
input_widget_callbacks_spec.lua:42   #input   (root)
input_widget_callbacks_spec.lua:755  #lifecycle (nested — the b0c9d032 fix)
input_widget_control_spec.lua:22     #input   (root)
```

And on the four originals from scratch, same method: `#input` on all four
root describes, `#lifecycle` only on `input_lifecycle_uniform_spec.lua`'s
root — exact match to the merged-file tags above, independently reproduced.

```
control  --tags=input     -> 39   (== whole-file count; every row still #input)
callbacks --tags=input    -> 52   (== whole-file count)
control  --tags=lifecycle -> 0
callbacks --tags=lifecycle -> 14  (== the moved lifecycle_uniform rows, exactly)
control  --exclude-tags=input -> 0 successes (nothing escapes the file-level tag)
```

No tag lives only on a nested `describe`/`it` inside either file other than
the one `#lifecycle` case, which selects exactly the 14 rows it should.

## 6. `pending`, `finally`, non-assert verification — CONFIRMED

```
grep -rn "pending(" tests/input/        -> 3 hits, all in input_routing_spec.lua (@69, @145, @215)
grep -n "finally("  <merged files + 4 originals>  -> zero hits anywhere
grep -n "spy\.\|stub(" <merged files + 4 originals> -> zero hits anywhere
```

`input_routing_spec.lua` is untouched by any of the five merge commits (only
its root describe was renamed by `a246c170`, per §4 of the plan) — same 3
pending rows, same file, same line numbers, before and after. No `finally`
or busted-spy usage exists anywhere in this corner of the suite to lose in a
merge; the suite's only non-`assert.*` verification technique is the
hand-rolled method-patch pattern already covered in check 2.

## 7. Citations of the six renamed root describes (`a246c170`) — CONFIRMED, one non-finding worth recording

`a246c170`'s diff touches 6 files and renames **7** describe title strings
(`keys_pressed_spec.lua` carries two root-level describes,
`keys_pressed table #input` and `combo_string #input`, both renamed in the
same commit). Extracted all 7 old titles from the commit diff and grepped
each across `src/`, `tests/`, and `doc/development/**/*.md` (both the
"reference docs" tier and the historical `wip/` session-record tier,
reported separately since the brief only cares about the former):

| old title | live hit outside `wip/`? |
|---|---|
| `input API: cursor and text surface` | no |
| `#input events dispatching` | no |
| `input contracts: route connection lifecycle #input` | no |
| `input contracts: routing #input` | no |
| `input contracts: shortcuts and click #input` | no |
| `keys_pressed table #input` | no |
| `combo_string #input` | no |

Every hit for these seven strings falls inside
`doc/development/wip/77-new-input-api/{implementation,validation,reviews}/`
— historical session records, patches and inventories that are expected to
describe the pre-rename state (several predate the rename by weeks, e.g.
`TF1-split-decomposition.md`, `M1.md`) and are explicitly out of the "docs a
reader follows as authoritative" tier per the post-move review's own
carve-out for `.claude/settings.local.json`.

Non-finding worth recording so it isn't mistaken for one: `grep` for `route
connection lifecycle` also matches `tests/input/input_route_lifecycle_spec.lua:43`
— `describe('route connection lifecycle', function()`, a **nested** describe
inside that same file, coincidentally sharing wording with the file's own
former root-describe title. It is current, correct content of a file
`a246c170` did not otherwise touch (only its root describe changed), not a
citation of anything — read the file to confirm this is not a second stale
copy of the old root title.

Also checked: the sub-describe titles that changed *during the merge itself*
(e.g. `widget activation and reset` → `show(): activation and reset`,
`configure on an active session` → `configure(): the live session`,
`hidden configure` → `configure(): while hidden`, `continuous-session idiom`
→ `the continuous session`) for the same dangling-citation risk, since
`bc5b97ae`'s repointing commit demonstrably updated some doc citations to
the *new* sub-describe names (e.g. `technical_debt/input.md:878` now says
`"show(): activation and reset"`) — meaning the sweep was aware of renamed
sub-describes, but I wanted to check it caught all of them, not just the
ones it happened to mention in its own commit message. Grepped all seven old
sub-describe titles the same way: zero live hits outside `wip/`. One
coincidental non-citation hit (a prose usage of the phrase "continuous-session
idiom" as the general API-concept name, not a pointer into the test suite, in
`doc/development/internals/examples/{repl,guess}.md`) — read in context and
confirmed it names the *documented idiom*, not a spec describe path.

## 8. An additional check not on the brief's list: did the merge commits touch anything besides the rows they claim to move?

`git show --stat` on all five merge commits, then `git show <sha> -- <touched
file>` for every file each commit lists, read in full (not just the stat
line):

- `90f632cf` (step 1): touches only `input_reconfigure_spec.lua` (shrinking)
  and the widget_lifecycle→control rename+regroup. Diff read in full:
  code changes are exactly the described move; the only non-code delta is
  two `---> REMARK` lines dropped from the header (explicitly named in the
  commit message as intentional).
- `25f70175` (step 2): also touches `input_widget_control_spec.lua` (**not**
  listed as a step-2 file in the plan's own execution order, §5) — 3 lines
  removed. Read in full: two more `---> REMARK` header lines dropped, same
  pattern as step 1, explicitly named in the commit message ("drops the
  header REMARKs asking for this merge and for the rename, in the commit
  that performs them"). No code or assertion touched.
- `b0c9d032`: single-line tag fix, exactly as documented.
- `bc5b97ae`: touches both merged files plus 5 doc/test files. Read every
  hunk in both merged-file diffs: 100% comment-body changes (repointing a
  stale filename reference to a describe-group name, and fixing one comment
  that credited the wrong file for a shared technique) — zero lines of
  executable code or assertion touched in either merged spec file by this
  commit.
- `a246c170`: 6 files, root-describe-only renames, confirmed by diff (no
  row content changed).

No commit in the merge sequence touches anything beyond what its own message
claims. This is a fact about the commits, independent of and additional to
the row/title/assertion-line audit the S28 reviews already performed.

## Repo integrity

```
$ git status --porcelain
?? claude.sh
?? doc/development/wip/77-new-input-api/implementation/sessions/session29/track.md
?? doc/development/wip/77-new-input-api/validation/prompts/S29-merge-revalidation-agent.md
?? doc/development/wip/clarification/
?? doc/development/wip/personal-notes/
?? doc/development/wip/pull-26/
?? doc/tall_blocks.md
?? input-pr-slices.tar.gz
?? src/STEPS.md
?? src/examples/balloons/
?? src/examples/keyboard/
?? src/examples/maze/
$ git diff --stat
(empty)
```

Identical to the state observed at the start of this session (the two extra
`wip/` entries — `sessions/session29/track.md` and this task's own prompt
file — were already present before any tool call in this session; nothing
here was created by this review beyond the deliverable itself). All
comparative work used `git show`/`git archive` into
`/tmp/claude-1000/.../scratchpad/s29/` (outside `/repo`) plus the `lua-lsp`
MCP server; no spec/source/doc/config file was written, staged, committed,
or pushed. `busted tests` at the end of this session: `954 successes / 0
failures / 0 errors / 3 pending`, unchanged.

---

## Closing

**1. Did the merge change the *meaning* of any surviving row — its
enclosing context, its isolation, its selectability, or what it can
distinguish — while leaving its text intact?**

One latent isolation change, not currently live: the four `Log.warn`
monkeypatch-with-manual-restore rows in `input_widget_control_spec.lua`
(two from each of two different source files) now share one busted-insulated
file scope where they used to be split across two. All four restore before
their own assertions, so no test today can fail because of this — but should
`show()`/`configure()`/`clear()` ever raise unexpectedly between a patch and
its restore line, the leak could now reach rows that originated in the other
source file, which it structurally could not before. Everything else checked
(enclosing context, order dependence via 16 shuffle runs across both
revisions, tag selectability, helper-body identity via byte-diff and LSP,
pending/finally/spy inventory, dangling citations of both root and nested
renamed describes, and commit-scope purity) came back CONFIRMED clean — no
other row's meaning changed while its text stayed the same, as far as this
pass could see.

**2. What did you look for and *not* find?**

Came back clean, with the evidence shown above: nested before_each/setup at
any describe depth (none exist, in either state); order dependence
attributable to the merge specifically (16 shuffle runs, 8 per revision, on
both the full suite and each merged file alone, in isolation and shuffled);
helper-body divergence for all 5 named helpers (byte-diffed, not
name-grepped, plus LSP-confirmed reference sites); `#delay`-exclusion or any
other tag silently dropping a row (full tag inventory, both `--run` profiles
identical); loss of the 3 `pending` rows or any `finally`/spy-based
verification (none exist to lose); dangling citations of the six/seven
renamed root describes *and* the sub-describes renamed inside the merge
itself, across `src/`, `tests/`, and the doc/development reference tier
(excluding the historical `wip/` session records, which are expected to
predate the rename); and out-of-scope edits hiding inside the five merge
commits (read every hunk of every file each commit touches — none exceeds
its own commit message). What I could not fully rule out: the whole-suite
shuffle flakiness (29-55 failures per run) is real at both revisions and I
did not chase its root cause — it is out of this task's scope per the
brief's own rule, but it means shuffle-based order-dependence detection in
this suite is inherently noisy, and a small, merge-specific order bug hiding
inside that noise cannot be mathematically excluded by 8 samples per side,
only made unlikely.
