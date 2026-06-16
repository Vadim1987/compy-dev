# Round-2 Summary

*What your round-2 note changed, where the plan stands now, and the new
estimate. Full detail in `decisions.md` / `spec.md` / `roadmap.md`; the
one-page view is `summaries/roadmap.md`.*

---

## What you asked for, and what changed

Seven points came out of your note. Two flip a default, one is a rename,
one widens a small thing, and three were confirmations or wording fixes —
nothing reopened the architecture.

1. **A second prompt while one is already open now does nothing by
   default.** You wanted it blocked with an "I know what I'm doing"
   override — that's exactly what it does: `show()` over an active prompt
   is a no-op unless you pass `force`. Changing a label or validator on a
   live prompt still works without any flag (that's the separate
   `configure()` call).

2. **Boundary notifications now cover left/right and end-of-line, not just
   top/bottom.** You pointed at the editor's existing up/down navigation
   as prior art and asked for first/last *character* too, for the whole
   input or just the line. Done: the callback reports a direction
   (up/down/left/right) and whether the boundary is the whole input or the
   current line. The editor's existing up/down behaviour is untouched;
   the rest is added on top.

3. **The new controller is now `ProjectInputController`.** You're right
   that a bare `ProjectController` sounds like it creates and deletes
   projects (that's `ProjectService`). It only routes input, and the name
   now says so.

4. **The held-keys table can be read by index again.** You asked why it
   was iterate-only — no good reason, so it now allows reading a key
   directly (`keys['lctrl']`) while still refusing writes.

5. **"The framework's own teardown" is now spelled out.** It's the
   structural step the framework always runs on Enter/Escape (evaluate and
   store, or close the prompt) — the part your before/after hooks wrap but
   can't switch off. The dedicated submit/cancel events you signed off on
   are unchanged.

6. **Pass-through stays the base; the combo layer stays as the
   improvement.** Matching your "base is what LÖVE does, but it makes sense
   to improve on it with this implementation": the key/combo dispatch
   ships as specified, and no extra helpers are added in this round — the
   nice-to-haves stay parked as future seams.

7. **This is project-input-only, as you said.** Confirmed, and noted your
   point that project runs will soon be the only way to run user code — so
   doing the project context first is also doing the context that will
   absorb the others. No console/editor rewrite is pulled in.

Plus the small wording fix: touch isn't a separate scope item — it already
rides on the mouse handlers, nothing to do.

---

## Did anything regress?

No. Nothing in the architecture was reopened and no decision was reversed.
Every requirement still holds, and two are better served than before:
boundary handling (left/right + line/input) and the editor-expressiveness
check, which now maps onto the editor's real caret navigation rather than
just up/down.

---

## New plan and estimate

Same milestones, same order — nothing added or dropped. The boundary work
lands in the existing before/after-chains milestone (M6); the rename, the
force flag, and the readable keys-table are small enough to absorb where
they already sit.

| | Before | After round 2 |
|---|---|---|
| With LLM help | ≈ 37 h | **≈ 39 h** |
| Without | ≈ 63 h | **≈ 66 h** |

The ≈ 2–3 h increase is almost entirely the broader boundary notification
(new logic in the input model plus its tests). The other four changes are
within estimating noise.

The updated build plan and per-milestone numbers are in
`summaries/roadmap.md` (one page) and `roadmap.md` (full). The change log
for this round is `input/track00.md`; the coherence/requirements check is
`input/evaluation00.md`.
