# Stakeholder2 Feedback — Structured (Round 2)

*Source: `input/stakeholder2_notes.md` (principal platform dev), supported
out-of-band by stakeholder1 (founder / customer). This document only
re-orders and renders the original note into a readable narrative; it adds
no new meaning. Inline clarifications by the processor are marked `(( ))`
or quoted with `>`. Decision-number mappings (D-1…D-7) are processor
annotations linking each remark to the matching item in `decisions.md`.*

---

## 0. Scope clarification — touch

Touch is in scope only as far as it is already part of the mouse handlers.
Nothing needs to be done by the user or by us for that to work. The note is
made only because phrasing it as a separate scope item is misleading.

(( i.e. no change to plan; this is a wording correction to the
out-of-scope list, not a new requirement. ))

---

## 1. Responses to the seven blocking decisions (read before the spec)

These are the stakeholder's first-pass answers to the seven questions in
`decisions.md`, given before reading the spec.

**1 — Backward compatibility (( D-1 )).**
As already discussed: we are pre-1.0. No backward-compatibility guarantees
are offered, nor are they desirable.

(( Confirms the existing D-1 ruling — no change. ))

**2 — Second setup call while active (( D-2 )).**
Block it: the second (new) call does nothing by default. Offer a flag for
"I know what I'm doing — override the existing one."

(( This changes the current resolution. Today D-2 is "dissolved —
`show()` reconfigures in-place silently." The stakeholder wants the
default to be a no-op block, with an explicit override flag to
reconfigure. See also the Spec remark on `show()` below — same point. ))

**3 — Key event coverage (( D-3 )).**
The base approach is passing through what LÖVE does. Further helpers should
be added, but not as part of this effort.

(( See the after-spec revision in §3 below, which softens this. ))

**4 — Cancel and submit notifications (( D-4 )).**
> "At first glance, definitely."
Yes to dedicated named events. This will probably be refined during
implementation.

> "I'm not sure what's meant here by 'the framework's own teardown'."

(( The before/after-chain idea is accepted; the phrase "the framework's
own teardown" in the D-4 question is unclear to the stakeholder and needs
to be spelled out. ))

**5 — Cursor boundary definition (( D-5 )).**
There is prior art for this as part of editor navigation, and it is fairly
intuitive (at least to the implementor — the stakeholder asks to be told
if that intuition is not shared). The boundary cases are:

- when moving up/down: being on the first / last line;
- when moving left/right: being on the first / last character, for the
  whole input or for the line.

(( This expands the current D-5 resolution. Today `on_limit_reached`
covers up/down at the whole-input boundary only. The stakeholder adds the
horizontal (left/right, first/last character) case and a "whole input or
the line" granularity distinction. Prior art = the editor's existing
up/down block-navigation boundary checks. ))

**6 — Modifier + character co-occurrence (( D-6 )).**
> "I thought this was part of 3. Same approach."

Treat as D-3: pass through what LÖVE does (two independent channels).

(( Confirms the existing D-6 resolution — no change. ))

**7 — Rollout scope (( D-7 )).**
This is just for user code running in projects. Soon there won't be another
way to run user code.

(( Confirms project-context-first (D-7), and signals a forward direction:
the console REPL path is expected to converge on the project run path, so
"project overlay first" is also "project overlay only, for now." ))

---

## 2. Notes on the proposed controller (the `*` items)

**Naming.** The new controller should not be named `ProjectController` —
that sounds like something that handles project creation / deletion, which
is loosely what `ProjectService` does today. If it is an input controller,
call it `ProjectInputController`.

**Lifecycle.** The proposed lifecycle (persistent singleton widget) is
"very sensible."

(( Lifecycle approved as-is; only the controller name changes. ))

---

## 3. Notes on the spec

**`keys_pressed` table.**
The spec says: "iterate with `for k in pairs(proxy) do`; direct indexing
not supported." The stakeholder asks why — it is straightforward to create
a proxy table that allows read indexing but not write indexing.

(( Requested change: the read-only proxy should permit read indexing
(`proxy[k]`) and block only writes, rather than being iterator-only. ))

**`compy.input.show(config)`.**
The spec says: "Calling `show()` while already active reconfigures
in-place." As in §1 item 2, the stakeholder would gate this behind a
"force" flag.

(( Same point as decision 2 — default is to not reconfigure an active
session; a `force` flag opts in. ))

---

## 4. Revised response after reading the spec

**3 — Key event coverage (( D-3, revised )).**
> "Ok, it makes sense with this implementation to improve upon it."

Having seen the implementation, the stakeholder accepts improving on the
raw LÖVE pass-through (the combo / handler layer the spec describes is an
acceptable improvement, not just bare pass-through).

(( Net effect on §1 item 3: the combo/dispatch layer stays. The
"further helpers, but not as part of this effort" caveat still bounds
scope — additional convenience helpers beyond what the spec already
describes remain out of this effort. ))
