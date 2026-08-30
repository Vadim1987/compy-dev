# `turtle`'s `pause` key duplicates a framework reservation — the history, checked

**2026-08-30, session56.** Owner ruling plus the verification behind it. Written down because the
question ("did the guard remove something?") will be asked again by anyone reading the `BUG-01-03`
fix cold, and the answer depends on facts that are cheap to check once and expensive to re-derive.

## The ruling

> *"I guess turtle shortcut for pause historically preceded framework's similar one, so if I got it
> correctly removing it is clearing up, not a defect (DRY principle in action)."* — owner

**The conclusion is right. The premise is not**, and the correction strengthens it rather than
weakening it.

## What the history actually shows

- **At the PR base `3256aac`, both already existed.** `turtle/main.lua:44` binds the bare `pause`
  key to the project global; `controller.lua:554` handles `ctrl` + `pause` → `CC:suspend_run`
  inline. So the duplication is **pre-feature**. Nothing in #77 created it, and the guard did not
  introduce it.
- **The framework's machinery is the elder, not turtle's key.** `suspend_run` dates to 2024-01-23;
  turtle's `pause` branch appears 2025-01-11; the `user_break` message the reservation passes today
  arrives 2025-04-15. So the example added a local convenience *on top of* an existing framework
  capability — the opposite order to the one guessed.
- **What is ours** is only the shape: `f31bd312` lifted the inline `Key.ctrl()` checks into the
  `RESERVED` combo table, where `ctrl+pause` now sits (`controller.lua:868`).
- The archaeology on the two dates is `git log -S` over strings that were later reformatted, so
  treat the *ordering* as well-supported and the *exact commits* as indicative. **The base check is
  exact**, and it is the one the conclusion rests on.

## Why the conclusion survives the correction

DRY applies either way: two keys, one capability, and the one that survives is the one **no project
guard can reach**. `ctrl+pause` is a reservation, so it fires above tier 1 whether or not the widget
is shown and whether or not a project returns early from its handler. What `turtle`'s blanket guard
silences is therefore the *duplicate shortcut*, never the *ability to suspend*. Removing it is
cleanup — and it is cleanup of something that was redundant before this feature began.

Cross-references: the fix's peer review and its verification addendum
([`../outcomes/BUG-01-03-turtle-fix-peer-review.md`](../outcomes/BUG-01-03-turtle-fix-peer-review.md));
the reservation-exemption half of `T-GUARD-LIVE`, which is the general form of this note's last
paragraph and is what `FIX-02-23` writes into the guide.
