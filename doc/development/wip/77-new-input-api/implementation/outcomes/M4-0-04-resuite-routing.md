# Outcome — M4-0-04: re-author the input suite from the CORRECTED record

_Executed by LLM (Claude Opus 4.8). Test-only slice; no `src/` change.
Awaiting human approval._

## Commit(s)

- `test(input): re-author input suite from corrected contract record`
  (single local commit on `feature/77-newapi-analysis-s20260615`; not pushed)

## Files changed (all under `tests/`)

- **Renamed + rebuilt:** `tests/input/input_routing_spec.lua` →
  `tests/input/input_contracts_spec.lua` (the file is the framework
  **input-contract** suite, not just routing; old name dropped per the
  owner symptom). Content re-derived from the corrected record, not patched.
- `tests/helpers/input_fixture.lua` — added `F.running_project(name, fn)`
  (stand a running project whose native `love.<name>` callback is the
  public seam witnessing project-route delivery); `reset()` now restores
  the native `love.*` slots to `Controller._defaults` and clears the
  shared editor input, so a project-route or editor-route test cannot
  leak into the next; removed the owner `-- REVIEW:` markers.
- `tests/helpers/input_session.lua` — removed `-- REVIEW:` markers;
  replaced with a comment naming the production bootstrap the driver
  reproduces.

No production code touched; `git diff --stat src/` is empty.

## Filter-1 subtractions (PRESERVE-shaped → acceptance/deleted)

Every row below was, or read as, a PRESERVE regression contract in the
old suite. Each is subtracted because a **documented change-intent**
authorizes the change — it cannot be a regression contract.

- **"a keypress reaches only the widget when one is up"** /
  **"a character reaches only the widget when one is up"** — DELETED as
  PRESERVE. These froze *widget-presence-as-routing* (the
  `if get_user_input() then …` overlay gate). Authorized to change by
  `design.md §2` (gate removed; routing no longer keyed on widget
  visibility) and §6. Forward behaviour is now Bucket B **I1**
  (`pending`): project keys reach the project route *under* a widget.
- **"a key release does not reach the route under a widget"** — DELETED
  as PRESERVE; it asserted the very drop #77 fixes. Re-homed to Bucket D
  as factual-today/provisional ("a release under a widget bypasses the
  project handler"), flagged possibly-a-defect (`input-contracts.md`
  §3.3 note); authorized to change by `design.md §2`.
- **"pointer delivery is BOTH" — both the widget and the route receive
  a click** — DELETED. This was the un-gated mouse path promoted to an
  inter-route invariant (`input-contracts-correction.md` row "pointer
  reaches BOTH … **removed**"; §3.5). No mandate, no principle. Replaced
  by active-route EXCLUSIVE delivery (P-row "a pointer reaches the active
  route"); intra-route forwarding to a widget is the route's concern and
  is **not** asserted.
- **touch BOTH (`pending`)** — re-stated as active-route EXCLUSIVE
  (`pending`, surfaced gap): touch has no gateway entry today, so
  delivery is not black-box observable; greened with a touch consumer.

## Intent-altitude rewrites (mechanism assertion → outcome contract)

- **EXCLUSIVE, stated as exactly-one-route across the real route axis.**
  The old single-widget keyboard rows are replaced by sibling coverage
  proving the mode-fixed exclusivity the symptoms asked for: the active
  route **receives** AND the siblings **do not**, across **console**
  (console text mutates, editor input stays empty), **project-running**
  (the project's own `love.keypressed`/`textinput`/`keyreleased`/
  `mousepressed` receives, the console stays empty), and **editor**
  (editor input mutates, console stays empty). `§3.1-3.3`, `§3.5`.
- **keyreleased EXCLUSIVE** witnessed at the project's own release
  callback (a public seam), not a `love.keyreleased` call-count spy on
  the console path.
- **Pointer** stated as "reaches the active route" (console selection /
  project-native receipt), never "reaches the widget and route both".
- **Hidden-widget (§2C)** stated as an observable outcome: input while
  the widget is hidden leaves the widget content untouched and reaches
  the console route — not a visibility-flag mechanism assertion.

## Bucket-by-bucket disposition

- **A — PRESERVE (green):** keyboard/text EXCLUSIVE with console /
  project / editor siblings (§3.1-3.3); keyreleased on the active route
  (§3.3); held-key set lifecycle (§4.1); global shortcuts non-consuming
  + play-mode narrowing (§4.3); pointer EXCLUSIVE on the active route
  (§3.5-3.6); framework click detection (§4.7); slot restoration on stop
  (§4.4); legacy solicitation `#legacy` (§4.5); widget activation/reset
  (§4.6); **hidden widget does not consume (§2C, tagged owner-minted —
  fresh owner ruling, not code-preserved)**; editor block-nav `#editor`.
- **B — IMPLEMENT (`pending`):** I1 project keys reach the project route
  under a widget (m4, §5.1) · I2 stop names the console route (m4, §5.2)
  · I3 native-handler coexistence, reframed *native not legacy* (m4,
  §5.3) · I4 the keypressed path carries the `(k, keys_pressed,
  isrepeat)` triple, **sink included** per D-α (m4, §5.4-m4) · I5
  `on_key_pressed` **and** `on_text_entered` exposed (m5a) · I6 isrepeat
  to `on_key_pressed`, false-fresh/true-repeat (m5, §5.4-m5) · I7 combo
  dispatch on the normalised combo, **repeat keying left provisional**
  per §6 D-C (m5b). Each carries a greppable `DEFERRED (0.1.0-mN)` marker.
- **C — MECHANISM-GUARD (green, labelled):** MG1 singleton identity,
  MG2 no-realloc (NFR-1); block labelled "not behaviour".
- **D — CHARACTERIZE-PROVISIONAL (factual only):** inspect console-owns
  (§3.4, owner-deferred); wheel has no gateway entry (§3.7); keyreleased
  dropped under a widget (§3.3). Each asserts present behaviour only;
  intended shape is a comment.
- **M6/M7 stub:** one `pending` pointer to §5 scope note.

## How each `-- REVIEW:` symptom was resolved

- *file name (`input_routing` vs `input_contracts`)* → renamed.
- *paragraph ids in `describe` strings are bureaucratic* → all `describe`
  strings name behaviour; §ids live only in comments.
- *"widget up" is transitional mechanism, not a routing state* →
  widget-presence PRESERVE rows removed; exclusivity re-stated as
  exactly-one-**route** with the console/project/editor siblings.
- *missing sibling coverage (console / project / editor / inspect)* →
  added as PRESERVE siblings; inspect kept in Bucket D (provisional).
- *"is anyone consuming keyreleased?"* → release is consumed (held-key
  tracker removes it, §4.1, asserted); active-route receipt asserted via
  the project seam; the under-widget drop is Bucket D provisional.
- *keyreleased under widget "sounds like the bug we combat"* → moved out
  of PRESERVE into Bucket D, flagged possibly-a-defect.
- *pointer-BOTH / "active widget defines routing" is a bad abstraction* →
  removed; active-route EXCLUSIVE only.
- *`seen = x; orig(k)` semicolon reads confusing* → split to two lines.
- *editor block-nav mixes concerns* → labelled explicitly as editor-route
  behaviour (not framework routing); the through-the-gate editor sibling
  carries the routing contract.
- *I-row wording (`on_event`, only `on_key_pressed`, isrepeat dup, combo
  milestone, native-not-legacy)* → reframed to the design's real public
  surface; I5 covers both callbacks; I4 vs I6 distinction stated; I7
  repeat keying left provisional; "legacy" → "native".
- *M6/M7 "tracked as tech debt?"* → kept as the structural `pending`
  anchor pointing at the §5 scope note.

No `-- REVIEW:` comment remains in the suite, the fixture, or the driver
(`grep -rn 'REVIEW' tests/input/input_contracts_spec.lua tests/helpers/`
→ none).

## Verification

- `busted tests/input/input_contracts_spec.lua` → **32 successes /
  0 failures / 0 errors / 9 pending**.
- `busted tests` (full) → **717 successes / 0 failures / 0 errors /
  9 pending**.
- **Teeth (perturb → red → restore), working tree only, not committed:**
  - *Keyboard EXCLUSIVE* — broke the gateway's delivery to the active
    keyboard route (`handlers.keypressed` fall-through to
    `love.keypressed`): "console mode routes keys to the console" **red**
    (5 failures total). Restored → green.
  - *Pointer EXCLUSIVE* — early-returned `handlers.mousepressed` before
    the route delivery: "a pointer reaches the active route" **red**
    (2 failures). Restored → green.
  - After restore `git diff --stat src/` is empty; full suite green.

_(Line-width note: comments were rewrapped to the 64-char limit; a
throwaway UTF-8-aware width checker was used to avoid byte-vs-codepoint
false positives. No production code touched.)_

## Surfaced gaps

- **Touch delivery is not black-box observable** today — the production
  gateway wires no `touchpressed`/`touchreleased`/`touchmoved` entry, and
  the widget/route touch handlers are no-ops. Carried as a `pending` with
  the reason; greened when a touch consumer lands.
- **I2 / I3 forward seams** (`active_keyboard_route()`,
  `provision_native()`) are named in `pending` bodies that do not run;
  the implementing milestone owns the exact API name.
- The owner symptom on the fixture standup ("reference the specific
  `main.lua` bootstrap lines / wrap as `mock_compy_bootloading`) and the
  `F` / `compy_input` naming are **non-blocking** fixture-ergonomics
  debt; reported here, not fixed in this slice (KISS / report-don't-fix).
