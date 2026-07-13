# Technical Debt Register

A running list of known debt — discovered during work but deliberately not addressed at
the time it surfaced. Entries are matter-of-fact context, not defects to fix on sight; each
notes where it lives, why it stands, and when it is worth revisiting. Remove an entry when
the debt is paid.

Tone and intent follow
[`../conventions/architecture_principles.md`](../conventions/architecture_principles.md)
and the analytic-notes guidance in [`../../../agents/rules.md`](../../../agents/rules.md).

This register is organised **per subsystem** — one file per area, so a new subsystem gets
its own ledger instead of growing a single flat list.

## Index

- [`general.md`](general.md) — debt not specific to one subsystem (load-order/aliasing
  assumptions, shared utility semantics).
- [`input.md`](input.md) — the input subsystem: keyboard/text/pointer routing, the console
  and project input controllers, and the `compy.input` project-facing surface.
