# Upstream Regression Inspection: `FS.sync` Test Failure

**Date:** 2026-08-28  
**Context:** Diagnostic inspection of `feature/77-newinput-premerge` test failure in `tests/input/project_open_liveness_spec.lua`.

---

## 1. Test Failure Symptoms

Executing `busted tests/input/project_open_liveness_spec.lua` on `feature/77-newinput-premerge` yielded **2 successes / 3 errors**:

* **Lines 63, 73, 96:**
  `./src/controller/controller.lua:654: attempt to call field 'sync' (a nil value)`

---

## 2. Root Cause Analysis

Upstream commit `9cb27e0f` ("feat(fs): durability API — FS.fsync(path) and FS.sync()") introduced durability flush calls into `src/controller/controller.lua`:
```lua
local function quit()
  FS.sync()
  ...
end
```

In `src/util/filesystem.lua`, the module is split into two environment blocks:
1. **Production mode** (`if love and not TESTING then` — lines 79–408): Implements `FS.fsync` and `FS.sync` via LuaJIT FFI.
2. **Unit test mode** (`else` — lines 409–545): Activated under `busted` execution (`TESTING = true`). Implements fallback IO functions (`FS.read`, `FS.write`, `FS.mkdir`, `FS.cp`, `FS.exists`, `FS.getInfo`, etc.).

`FS.sync()` and `FS.fsync()` were defined only in the production block and omitted from the unit test fallback block. When `quit()` executes in `project_open_liveness_spec.lua`, `FS.sync()` is called on a `nil` field.

---

## 3. Recommendation: Centralized Stub vs. Per-Fixture Mocking

* **Per-fixture mocking** (e.g., in `tests/helpers/input_fixture.lua`):
  * Only patches tests that explicitly use that fixture.
  * Leaves `FS.sync` and `FS.fsync` undefined across the rest of the unit test suite whenever production code triggers exit or background durability flushes.
* **Centralized stub in `src/util/filesystem.lua`** (Recommended):
  * `src/util/filesystem.lua` is designed as a dual-backend wrapper that satisfies the `FS` interface contract for both environments.
  * Adding `FS.sync` and `FS.fsync` stubs inside the `else` block (near line 545) completes the module contract for unit testing.

### Proposed Code Change (`src/util/filesystem.lua`, line ~545)

```lua
  --- Durability stubs for unit tests (where FFI / OS sync is not run).
  --- @param path string?
  --- @return boolean
  function FS.fsync(path)
    return true
  end

  --- @return boolean
  function FS.sync()
    return true
  end
```

---

## 4. Verification

Applying this change to `src/util/filesystem.lua` on `feature/77-newinput-premerge` results in:
`5 successes / 0 failures / 0 errors / 0 pending` in `tests/input/project_open_liveness_spec.lua`.
