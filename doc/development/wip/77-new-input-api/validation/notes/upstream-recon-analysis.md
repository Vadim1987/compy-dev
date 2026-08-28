# Upstream RECON Analysis: Branch Overlap & Merge Safety

**Date:** 2026-08-28  
**Scope:** RECON evaluation of branch `feature/77-newinput-premerge` (commit `54cbe57d`) relative to current development branch `feature/77-newapi-analysis-s20260615`.

---

## 1. Branch Structure & Upstream Range

`feature/77-newinput-premerge` represents a clean merge of upstream (`aldum/dev`, commit `af9a5782`) into `feature/77-newapi-analysis-s20260615` (commit `2d402d8c`).

* **Upstream commit range:** 24 commits (`69be0fbe` .. `af9a5782`)
* **Files modified:** 48 files (+866 / -74 lines)

---

## 2. Subsystem Overlap Analysis

### A. Input Subsystem (`src/model/input/`, `src/view/input/`)
* **Upstream changes:**
  * `src/model/input/userInputModel.lua`: Added `sanitize_utf8` filtering for text insertion (`add_text`, `set_text`), fixed string check logic in `set_error`, and passed `cfg.input_history` cap to `History`.
  * `src/model/input/history.lua`: Implemented entry limit capping (`History(limit)` with `self:_trim()`).
  * `src/view/input/userInputView.lua`: Added `gfx.pop()` error guard on invalid UTF-8 string rendering.
* **Overlap with Feature #77 Input API:**
  * Feature #77 establishes the unified key routing grid, action bindings, shortcut dispatching, and formal public input surface contracts.
  * Upstream's input changes are focused on payload sanitization (invalid UTF-8 bytes) and history array bounds.
  * **Verdict:** Zero architectural conflict or contract collision. The changes complement Feature #77 by hardening raw input data structures.

### B. Application Lifecycle & Controllers (`src/controller/controller.lua`)
* **Upstream changes:**
  * Added `FS.sync()` calls on graceful `quit()` and window background events (`set_love_focus`, `set_love_visible`).
  * Coerced `msg` to string in `user_error_handler`.
  * Released screenshot snapshot images to prevent memory leaks.
* **Overlap with Feature #77:**
  * Upstream lifecycle durability calls do not alter keybinding handlers or route dispatch table definitions in `Controller`.
  * **Verdict:** No conflict with #77 controller topology. (Requires the `FS.sync` test stub in `filesystem.lua` as documented in `upstream-regression-inspection.md`).

### C. Core & Support Subsystems
* **Filesystem (`src/util/filesystem.lua`)**: Added durability API (`FS.fsync`, `FS.sync`).
* **Colors & Graphics (`src/util/color.lua`, `src/util/termcolor.lua`, `src/conf/colors.lua`)**: Expanded 64-slot palette.
* **Audio (`src/util/audio.lua`, `src/assets/sounds/`)**: Added micro:bit sound assets.
* **Editor & Parsers (`bufferModel.lua`, `parser.lua`, `project.lua`)**: Crash fixes for empty selection, robust project open handling, and chunkname error reporting.

---

## 3. Merge Safety Verdict

* **Merge status:** Clean merge, zero git conflicts.
* **Suite status:** 992 unit tests pass + 5 project liveness tests pass once `FS.sync` stub is added to `src/util/filesystem.lua`.
* **Conclusion:** It is **completely safe** to merge upstream (`aldum/dev`) into the development branch.
