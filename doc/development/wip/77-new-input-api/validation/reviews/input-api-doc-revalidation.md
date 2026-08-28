# `doc/input_api.md` Friendliness & Precision Revalidation Report

**Date:** 2026-08-28  
**Scope:** Revalidation of session 52's commit `50380a00` (`docs(input-api): add vocabulary, dispatch chain and cognitive improvements`).  
**Baseline:** `990 successes / 0 failures / 0 errors / 10 pending`.

---

## 1. Scope & Objective

Proofread and revalidate session 52's cognitive friendliness additions to `doc/input_api.md`:
- Upfront `Vocabulary` section (lines 29-81).
- `How events reach your project` dispatch chain ASCII diagram (lines 311-336).
- Terminology alignment (changing `combinators` to `wrappers` for `fn.ignore_repeat`, `fn.stop_here`, `fn.side_run`).

---

## 2. Findings & Verification

1. **Vocabulary Section (Lines 29–81):**
   - **Clarity & Formatting:** Clear, structured, bolded terms with concise explanation paragraphs.
   - **Technical Precision:** Definitions for *Channel*, *Combo*, *Shortcut*, *Modifier class*, *Hook*, *Dispatch chain*, and *Consume* match `src/controller/projectInputController.lua` and `doc/development/internals/user_input.md` exactly.
   - **No Drift:** Modifiers set (ctrl, alt, shift), combo normalisation rules, and exact-vs-class matching are stated with zero factual drift.

2. **Dispatch Chain Diagram (Lines 311–336):**
   - **Visual Clarity:** Step-by-step ASCII walk (`LÖVE event` → `① shortcut` → `② hook` → `③ widget`) correctly depicts fallthrough semantics on falsey return and termination on truthy return / shown widget.
   - **Accuracy:** Accurately notes framework reservation behavior (act and pass through, never consume).

3. **Wrappers vs. Combinators (Lines 371–410):**
   - Refactored terminology from `combinators` to `wrappers` improves cognitive friendliness for Lua developers, accurately describing higher-order helper functions (`compy.input.fn.*`).

---

## 3. Summary Verdict

**REVALIDATED & APPROVED.** The updates to `doc/input_api.md` improve clarity, cognitive friendliness, and visual accessibility without any technical drift from code behavior.
