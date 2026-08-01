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
