# Session 08 — cosmetic pass C

Files: `tests/input/input_contracts_spec.lua` (owner-reviewed
region + sweep continuation), plus sweep-only:
`tests/helpers/input_session.lua`,
`tests/input/highlight_shape_spec.lua`,
`tests/input/keys_pressed_spec.lua`,
`tests/input/project_open_liveness_spec.lua`,
`tests/input/user_input_model_spec.lua`, `tests/mock.lua`.
Comments only; no executable code or identifier touched. The
predecessor's `tests/helpers/input_fixture.lua` work is reported
via `git diff`, not re-edited.

## 1. Remarks resolved/deleted

**Predecessor, `input_fixture.lua` (via `git diff`)**: no
`REVIEW`/`REVIEW/DOC` line was deleted — every review line in
the current file is a net addition (13 new `REVIEW`/`REVIEW/DOC`
lines, none satisfied yet). Alongside those additions the
predecessor: wrapped three refs (`{badspecref: doc A §5.5}`,
`{badspecref: doc A §6.7}`, `{badspecref: AC-24}`); dropped two
ephemeral refs outright without wrapping (`spec §5 AC-17/19` in
the `wipe()` doc comment, and the `M5c teardown invariant` +
"Tier-1 return/escape ... spec" phrasing in `reset_chain()`'s doc
comment — both replaced by plain prose with the citation simply
removed); and compacted several comments (intro header,
`F.compy_input`, `F.running_project`, `F.activate_project`,
`restore_native_slots`, `reset_chain`) — mostly dropping
`'slot'`/`'tier-3'`/milestone-ruling language in favour of plain
description. Net: 0 REVIEW lines resolved, 4 wraps present,
2 refs deleted-not-wrapped, prose compacted throughout.

**Mine, `input_contracts_spec.lua` owner-reviewed region (down
through "if replacement is confirmed…")**:

- Vocabulary block (`ROUTE`/`WIDGET`/`SINK` definitions):
  deleted `REVIEW/DOC: 'slot' is invented jargon, avoid it` and
  `REVIEW/DOC: 'sink' is the last consumer in chain` — reworded
  WIDGET's definition to drop the `'slot occupant'` negation
  and reworded SINK's definition to the reviewer's own
  suggested wording ("the last consumer in the dispatch
  chain").
- Widget activation/reset intro: deleted `REVIEW: last
  statement of prose describes interim project state, so
  either prose or tests may need update` — dropped the
  forward-looking `"they flip at {badspecref: 0.1.0-m6}"`
  clause, kept the still-valid "no cancel chain facts are
  stable-now" claim.
- `force` reconfiguration intro: deleted `REVIEW: last
  statement of prose describes interim project state,
  review/update?` — dropped `"scope widens at 0.1.0-m7"`,
  kept "today only the text subset takes effect".
- Boundary comment ("keyreleased under a widget… Deleted per
  Scope-10(c)…"): verified the named replacement — `'a native
  keyreleased fires while the widget is shown'` — is present
  and green further down the file, so per the REVIEW's own
  condition ("if replacement is confirmed... may go") deleted
  the whole superseded prose paragraph and the
  `REVIEW/DOC: if replacement is confirmed…` line itself.

## 2. Inventory of markers ADDED + FIX PLAN (propose only)

`input_contracts_spec.lua` sweep region (below the boundary) was
already almost fully wrapped by earlier sessions (186
`{badspecref:}` / 46 `{jargon:}` total in the file). One gap
found and fixed: `design.md` sat unwrapped next to an already-
wrapped `{badspecref: §4}` in the route-connection-lifecycle
intro — merged into a single `{badspecref: design.md §4}`.

| Marker (file) | Proposed persistent target |
|---|---|
| `{badspecref: design.md §4}` — input_contracts_spec.lua | `doc/development/decisions/input.md` Decision 11 (route connects only while running; pointer excluded from the keyboard/text disconnect) |
| `{badspecref: A8}` (×3), `{badspecref: A6}`, `{badspecref: M2-human-review.md}` (×3) — keys_pressed_spec.lua | no persistent-corpus entry found (same "A5/A6/A8 + M2-human-review.md" family flagged as a gap in session08/cosmetic-a.md) — propose a `technical_debt/input.md` "test-infra" entry for the stub-dedup / cross-spec `_G.love` isolation items; none exists yet |
| `{badspecref: 0.1.0-m4}`, `{badspecref: 0.1.0-m5}` — keys_pressed_spec.lua | no persistent target for the milestone id; underlying design content is `doc/development/decisions/input.md` Decision 8 (combo serialisation) |
| `{badspecref: M7-01}`, `{badspecref: AC-8}` — user_input_model_spec.lua | `doc/input_api.md` §"Live reconfigure: `configure`, `set_text`, `clear`, cursor" (same mapping as session08/cosmetic-b.md) |
| `{badspecref: Ruling (a)}` — project_open_liveness_spec.lua | `doc/development/technical_debt/input.md` §"Input-only / pointer-only projects stay live in `project_open` (RESOLVED, ruling a)" — exact existing heading, and already named two lines below in the same comment |
| `{badspecref: P1}` — mock.lua | `doc/development/internals/user_input.md` §"Data flow" (keypressed/textinput ordering discussion) — approximate, no exact anchor |

Sweep-only files with zero findings: `highlight_shape_spec.lua`
(no refs, no jargon).

## 3. Remarks left as conceptual (untouched)

Owner-reviewed region, per the task's explicit categories:

- Buckets A/B/C/D dissolution, tags, file-splitting (3 lines).
- `make_editor_session` "must be displaced" (relocation).
- The format-declaration lines themselves ("I will wrap them
  into `{badspecref:}`…") — meta-instruction, not an actionable
  item; the sweep it describes continues below the boundary.
- `F.console_with` helper-naming nitpick — would require a code
  change, out of scope for a comments-only pass.
- "why not add/implement the test" (×3: editor search pending,
  editor pointer pending, "and why not test it, is it
  complex?").
- Low-level-mocking doubts (×3: global-shortcuts
  reconsideration, "is it how in real scenarios handlers are
  altered?", "suspiciously big amount of lower-level 'magic'
  manipulations").
- "why not setup via 'running_project'?" (click detection).
- "TODO: need to test prompt-labelling and relabelling" (its
  sibling REVIEW about the interim-state milestone ref was
  resolved; this one stays).
- The hidden-widget/console-consumption concept block — all 5
  remarks (hide-deactivates concern, plus the two- and
  three-remark blocks on the hidden-widget describe) — left in
  full per instruction.
- Editor block-nav relocation: the `OPEN (owner call...)` block
  and its `REVIEW/RESPONSE` sibling.
- "OWNER RULING PENDING... maybe moved out of 'provisional'?"
  (inspect-console-ownership test).

## 4. Stale below-boundary remarks (listed, not acted on)

Confirmed present, exactly as named in the task:

- `REVIEW: when we come to testing *propagation* of keypressed
  into consumers...` (held-key-set lifecycle test, "mechanism /
  NFR guards" block).
- `REVIEW: why not set 'ctrl' as pressed too? Much cheaper, no?`
  (left/right names test, same block).
- `REVIEW: do we have pending tests outlined for future
  consideration?` (singleton-identity test, same block).

## 5. Skipped as uncertain

- `input_contracts_spec.lua`: `R13` in
  `it('consuming never removes a tier (R13)', ...)` is a bad ref
  sitting inside a test-description **string** (executable
  code), not a comment — left unwrapped; wrapping it would mean
  editing code, which is out of scope for a comments-only pass.
- `input_contracts_spec.lua`: "a later chunk" (widget-outputs
  persistence test) carries no number/codename, so it doesn't
  meet the formal bad-ref signs — left unwrapped.
- `input_contracts_spec.lua` lines 4-5 (top-of-file
  `REVIEW/DOC`: no comment should point to wip/77; "paragraph X"
  referencing is insufficient) — these describe exactly what the
  file-wide `{badspecref:}` sweep already does, but the intro
  material above the sweep's own declaration (~line 78) was
  never itself wrapped by earlier sessions. Resolving this fully
  means extending the wrap sweep into the owner-reviewed
  region's intro, which is outside this task's split (region 1 =
  cosmetic only, wrap sweep = below the boundary) — left
  untouched, flagging for owner confirmation on scope.
- `tests/helpers/input_session.lua`: `'gateway'` (×3) and
  `'slot'` (×1, "the love slots") appear as plain, unwrapped
  prose. Unlike `input_contracts_spec.lua`, where the owner
  explicitly ruled `'slot'` invented jargon for *that* file,
  `doc/development/internals/user_input.md` — the persistent
  corpus doc for this exact subsystem — uses `gateway` and
  `slot` as its own established vocabulary throughout (13
  occurrences). Extending the spec file's jargon ruling to this
  helper looked like a judgment call rather than a mechanical
  continuation, so left unwrapped; flagging for owner
  confirmation.

## 6. Verification

`busted tests` from `/repo`: 815 successes / 0 failures /
0 errors / 4 pending (pre-existing `pending()` rows in
`tests/input/input_contracts_spec.lua`, unrelated to this pass).
