# M2-02 review — close the C-2 acceptance gap with a real-submit reprompt test

_Reviewer: LLM (Gemini 3.5 Flash / Antigravity): 2026-06-17. Scope: the commit implementing the test-only spec [`../../design/spec/M2-02-submit-path-test.md`](../../design/spec/M2-02-submit-path-test.md)._

Commits reviewed:

| Hash | Subject |
|---|---|
| `dc334d9` | `test: real-submit reprompt test for C-2 closure` |

## Verdict

**Approved.** The implementation is test-only, leaving production files completely untouched. The newly introduced unit test in `tests/input/overlay_spec.lua:54-76` drives the actual oneshot submit path via `UserInputModel:handle(true)` rather than using a proxy, which closes the unit-test half of the C-2 acceptance gap. The fidelity check has been executed and recorded: commenting out the clearing logic in `userInputController.lua:203-205` turns the test red, and restoring it makes it green again. The full unit test suite passes successfully.

**Approval-scope note.** This milestone is test-only. Combined with the previously confirmed runtime behavior of M2-01 (via turtle), the C-2 acceptance criteria are now fully satisfied and verified. The C-2 acceptance gap is formally closed.

## Spec compliance

### C2T-1 — A test that drives the real submit path ✔

The test added at [overlay_spec.lua:54-76](file:///home/hleb/freelance/compy/compy-dev/tests/input/overlay_spec.lua#L54-L76):
- Builds a oneshot singleton controller/model.
- Sets a non-empty text value (`REMEMBER_ME`).
- Mocks `love.event.push`.
- Executes `c.model:handle(true)` to trigger a real oneshot submit and verify the `userinput` event is pushed.
- Hides the controller, then shows it again with no text parameter.
- Asserts that the controller is empty and the previous text was cleared.

This directly exercises the real submit path, satisfying the C2T-1 requirement.

### C2T-2 — Prove the test has teeth (fidelity check) ✔

The fidelity check was executed successfully:
- Mutated [userInputController.lua:203-205](file:///home/hleb/freelance/compy/compy-dev/src/controller/userInputController.lua#L203-L205) by commenting out `self.model:clear_input()`.
- Re-ran `just ut_all`, which resulted in 2 failures out of 699 tests:
  - `tests/input/overlay_spec.lua:51` ("fresh show with no text opens empty")
  - `tests/input/overlay_spec.lua:74` ("real submit reprompt opens empty (C2T-1)")
- Restored the clear logic, which returned the suite to 699 successes.
- The mutation was verified locally and is not committed, matching the spec.

## Scope fence ✔

The scope fence held perfectly. The commit touches only:
- [overlay_spec.lua](file:///home/hleb/freelance/compy/compy-dev/tests/input/overlay_spec.lua)
- [technical_debt.md](file:///home/hleb/freelance/compy/compy-dev/doc/development/wip/77-new-input-api/implementation/technical_debt.md)
- [M2-02-submit-path-test.md](file:///home/hleb/freelance/compy/compy-dev/doc/development/wip/77-new-input-api/implementation/outcomes/M2-02-submit-path-test.md)

No production code files were altered or committed.

## Rules check

- **Hard limits.** The new test code does not introduce new production function bodies or nested conditionals. The mock `love.event.push` callback is a simple 5-line function. The test description and assertions do not exceed the 64-character line length limit (longest line is 63 chars). ✔
- **Formatting.** The test uses the standard Metalua style, blank lines, and brace spacing conventions. ✔
- **Commit hygiene.** Commit prefix `test:` was used with an accurate subject description. The committer identity matches the recent project history. ✔

## Tech-debt + docs ✔

- The C-2 empty re-prompt gap has been struck and marked as closed in the interim debt ledger [technical_debt.md:27](file:///home/hleb/freelance/compy/compy-dev/doc/development/wip/77-new-input-api/implementation/technical_debt.md#L27) and [technical_debt.md:59-70](file:///home/hleb/freelance/compy/compy-dev/doc/development/wip/77-new-input-api/implementation/technical_debt.md#L59-L70).
- No new gaps were surfaced.
- No documentation updates under `/doc/development/` were needed as this did not modify any contracts or APIs.

## Acceptance checklist

- [x] A unit test drives `model:handle(true)` on a oneshot session, then `show()` with no text, and asserts the prompt opens empty — and it passes.
- [x] The fidelity check is recorded: removing `open_fresh`'s clear makes the test red; restoring it makes it green again (the mutation is not committed).
- [x] The full suite is green (699 tests; nothing regressed); the M2-01 method-semantics suite unchanged.
- [x] The C-2 acceptance gap is struck from the interim debt ledger, M2-01 + M2-02 jointly closing it.
