# session25 — track

## 2026-08-01 — boot

- Booted per `agents/validation.md` boot ritual + `agents/sessions.md`.
  Re-entrance guardrail: `session25/` held only `prompt.md` — no `track.md`,
  no `report.md` → **fresh start**; this entry opens the track.
- HEAD `a77ab9a7` (`docs(session24): wrap — report, session25 prompt,
  pointer`), branch `feature/77-newapi-analysis-s20260615`, `git status`
  clean apart from the sanctioned untracked scratch + the three nested
  example repos (no longer anomalies — owner 2026-07-31).
- Read: `agents/validation.md`, `agents/sessions.md`,
  `agents/rules/revalidation.md`, `session25/prompt.md`,
  `session24/{prompt,report,track}.md`,
  `validation/reviews/S24-contradictions.md`.
- Baseline `busted tests` → **874 / 0 / 0 / 3**, exactly the count the
  session25 prompt and the session24 report state. (`agents/validation.md`'s
  fallback line still says 854/0/0/4 — the prompt is authoritative per that
  same section; noting, not "fixing".)
- Task per prompt: **revalidation of session24** per
  `agents/rules/revalidation.md`, ordered C1 (Decision 19 seal — intent vs
  outcome, recommendation + revert surface, ruling is the owner's) → C2
  (finish maze/balloons/keyboard migrations to the platform standard, correct
  `pr-assembly-guide.md` §5) → re-evaluate what remains between here and a
  stakeholder-readable PR. No next substantive task without owner approval.
- Reported the orientation to the owner; awaiting their go before working the
  checklist.

## 2026-08-01 — C1 ruled and executed

- Owner: *"yes, C1. and to avoid confusion I specifically request reverting any
  relevant codebase/doc changes except the tests that surface the problem. if
  needed, these reversed changes could be stored in wip workspace as suggested
  patch (literally a diff file)."* — the ruling arrived **before** the
  recommendation, so the seal is out on ratification grounds alone.
- `190f0c9` reverts the mechanism everywhere. Completeness proved, not
  asserted: the five non-test files are byte-identical to `eadcc8cd` (the
  commit before the seal landed) and a tree-wide grep for the four symbols is
  empty. C1's revert table was accurate.
- Test disposition: 2 rows kept as `pending` (they reproduce the defect,
  citing the new debt entry); the third pinned the *seal's* lifetime, not the
  contract, so it left with the mechanism into the patch. Suite
  **874 → 871 / 0 / 0 / 5**. Live-and-red was not available —
  suite-green-at-every-commit is standing.
- The race is now persistent-corpus debt: `technical_debt/input.md`, *"An
  overlay opened from a key can receive that key's own echo"*, options (a)–(d),
  revisit = a design pass.
- Four claims re-verified in code rather than carried forward; **two of them
  were wrong**, both mine from session24:
  - "release at update silently assumes no other pump" — over-cautious. compy
    *owns* its loop (`harmony/init.lua:104` replaces `love.run`; poll-all →
    update → draw), and the only other pump is the crash explorer, which never
    reaches `love.handlers`.
  - "no project can fix this for itself" — too strong. A project cannot
    *consume* the echo but can *undo* it (`clear()`/`set_text` on the next
    update). Option (d) is ugly, not impossible — which changes how the
    do-nothing baseline should be priced.
- Assessment + option set (adds (a′) one-textinput and (e) deferred-show to the
  recorded four) + patch pointer:
  `validation/reviews/S25-C1-event-batch-seal.md`. Patch:
  `validation/notes/S25-C1-event-batch-seal.patch`, verified to apply cleanly
  at `190f0c9`.
- `lua-lsp` MCP was down all session (broken pipe on every call); symbol facts
  were established by grep plus byte-identity against `eadcc8cd` instead.

## 2026-08-03 — owner proposes the paired-shortcut idiom; spiked

- Owner: address C1 with *"a specific order-agnostic setup"* — the trigger
  registered on BOTH channels, `shortcuts.keypressed[combo]` opening and
  `shortcuts.textinput[combo]` swallowing the echo and unregistering itself,
  re-armed by whatever closes the widget.
- **It works.** Spiked against the real chain, 6/6 including a deliberate
  negative row. Both delivery orders come up with an empty field; order B (the
  echo arriving BEFORE the keypress) is eaten while the overlay is still
  closed, which is why nothing depends on LÖVE's ordering. Evidence + source:
  `validation/notes/S25-C1-paired-shortcut-spike.md`.
- Why the chain permits it (`projectInputController.lua:71-83`): shortcuts run
  before the widget **on every channel**, the lookup is a direct index (so a
  handler may delete its own slot mid-flight), and leaf writes are allowed
  though sub-table identities are frozen.
- **Two limits, one of them somebody else's bug.** (i) No `after_hide`
  callback and Escape clears without hiding, so the re-arm has no single home
  and rots when a close path is added later. (ii) Only bare combos work:
  measured — dispatch looks up `shift+I`, registration stores `shift+i`, so
  the slot is unreachable. That is the ledger's own "combo_string does not
  normalise the case of a textinput token", whose revisit condition was "if a
  real textinput-combo consumer appears" — this proposal IS that consumer, so
  the entry is updated with the measurement and the trigger noted as fired.
- **Recommendation revised** (was: ratify (a) as implemented). Now split:
  ship-without-framework-change → (d′) documented; if the framework does
  change → (a′), the framework arming the one-shot itself, which as a
  *wildcard* needs no combo lookup and so dodges limit (ii) entirely. The
  owner's idea is what makes (a′) expressible in the existing shortcuts
  vocabulary instead of as new widget state.
- Behavioural note: the owner reaches for composition of existing primitives
  before new mechanism — and it paid, twice: a better (d), and a better (a).

## 2026-08-03 — (d′) adopted; docs + turtle migrated

- Owner: *"now, lets update the docs and turtle example"* → (d′) is the ruled
  answer. Executed in two commits.
- `66e8719f` — `doc/input_api.md` gains "Opening the overlay from a key" (the
  idiom, why it is order-agnostic, where the re-arm goes, and the bare-trigger
  limitation stated plainly). The two parked pendings become **four live
  rows** pinning the guide's shape: a documented idiom rots unless pinned.
  Debt entry restatused from "no mechanism ruled" to "answered by a documented
  idiom"; what stays open is whether the framework should ever take it over.
  Suite **871 → 875 / 0 / 0 / 3** — pending is back to the intentional 3.
- `a0df94aa` — turtle carries `arm_echo_guard()`, re-armed in `after_submit`
  beside the `hide()`. Verified rather than assumed: top-level registration
  survives activation, because `activate()` seeds hooks only and runs *after*
  the project's top-level code (`projectInputController.lua`, `seed_hooks`
  doc comment), so the table the project wrote to is the one dispatch reads.
- Discovered, not fixed (report-don't-fix): `src/examples/turtle/main.lua`
  carries pre-existing comment lines at 68–71 chars, over the 64 hard limit —
  including ones added during this feature. My added lines are ≤64, so the
  file is now mixed-width. Same class as other example-era debt.
- **Scancode question** (owner, same turn): *should combo registration and
  dispatch key on scancode?* Answered, not executed —
  `validation/notes/S25-scancode-question.md`. Short version: **no as a C1
  fix** (`love.textinput(text)` carries no scancode at all, so it cannot
  unify the channels — it widens the gap), and **a real but separate question**
  for the shortcuts surface, where compy has both audiences (positional WASD
  wants scancode; mnemonic ctrl+s and turtle's `i` want the key name). Cost is
  understated at first glance: the gateway *discards* the scancode today
  (`keypressed(k, _, isr)`), and `keys_pressed` is key-name-keyed, so
  `combo_string`'s modifier prefixes would need the same treatment. Recommend
  not now and never as a swap; additively if a positional consumer appears.
