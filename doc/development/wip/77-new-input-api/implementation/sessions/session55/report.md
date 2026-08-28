# session55 — report

**Date:** 2026-08-28  
**Task:** Diagnostic analysis of premerge test failure (`tests/input/project_open_liveness_spec.lua`) and platform upstream RECON.  
**Baseline suite:** 992 / 0 / 0 / 10 (on `feature/77-newapi-analysis-s20260615`).

---

## 1. Outcome & Key Findings

1. **Premerge Test Regression Diagnosis**:
   * Evaluated `feature/77-newinput-premerge` test run (`busted tests/input/project_open_liveness_spec.lua`).
   * 3 test cases failed with `./src/controller/controller.lua:654: attempt to call field 'sync' (a nil value)`.
   * **Root Cause:** Upstream commit `9cb27e0f` added `FS.sync()` to `quit()` and window background handlers in `controller.lua`. `src/util/filesystem.lua` defined `FS.sync` and `FS.fsync` in the production block (`if love and not TESTING then`), but omitted them from the unit test fallback block (`else` when `TESTING = true`).
   * **Fix:** Adding `FS.sync` and `FS.fsync` stubs inside the test block of `src/util/filesystem.lua` (line ~545) restores all tests to 5/5 successes.
   * Documented in `doc/development/wip/77-new-input-api/validation/notes/upstream-regression-inspection.md`.

2. **Upstream RECON Analysis (Platform Repo)**:
   * Diffed `feature/77-newinput-premerge` against `feature/77-newapi-analysis-s20260615` (24 upstream commits).
   * **Subsystem Overlap:** Upstream input changes (`userInputModel.lua`, `history.lua`, `userInputView.lua`) introduce UTF-8 payload sanitization and history entry capping. None conflict with Feature #77 input API routing or dispatch contracts.
   * **Verdict:** Safe for owner to merge upstream (`aldum/dev`) into `development`, along with the `FS.sync` test stub fix.
   * Documented in `doc/development/wip/77-new-input-api/validation/notes/upstream-recon-analysis.md`.
   * Updated `doc/development/wip/77-new-input-api/ROADMAP.md` marking `REC-01` partially complete (platform repo done, example submodules `maze`, `keyboard`, `balloons` pending).

---

## 2. Artifacts Produced

* Track: `implementation/sessions/session55/track.md`
* Report: `implementation/sessions/session55/report.md`
* Inspection Note: `validation/notes/upstream-regression-inspection.md`
* RECON Note: `validation/notes/upstream-recon-analysis.md`
* Roadmap: `ROADMAP.md` (updated `REC-01` status)
