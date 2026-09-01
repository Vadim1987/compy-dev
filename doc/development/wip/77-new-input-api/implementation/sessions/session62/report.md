# session62 — report

**Date:** 2026-08-31 → 2026-09-01 · **Suite:** 1032 / 0 / 0 / 10 throughout — no production code
touched, no test changed hands
**Mode:** architecture assistance — analysis, verification in code, judgment presented for the
owner's ruling. Seven commits, none pushed.

---

## 1. What this session was

The session62 prompt reserved this slot for an architecture discussion the owner would bring, and
they brought one: the **project owner's inquiry about the console/project environment relationship**,
cited verbatim. The session ran entirely in that discussion. It produced no roadmap execution and
touched no code; its whole product is a **side-draft** recorded under `validation/`, banner-marked in
every file as not part of `#77`'s delivery.

One interruption: the session hit a limit early, before any commit, and resumed cleanly — the
re-entrance guardrail found only the two files it had written.

## 2. The product

Five documents, in `wip/77-new-input-api/validation/`:

| document | what it is |
|---|---|
| `notes/owner-inquiry-console-env-lifecycle.md` | the inquiry verbatim, with its three expectations labelled |
| `outcomes/session62-env-lifecycle-code-map.md` (+ its `prompts/` prompt of record) | a commissioned Sonnet map of the environment machinery, cited throughout |
| `notes/console-env-observable-behaviours.md` | six behaviour questions answered from code, base-checked against `3256aac` |
| `notes/unified-dispatch-proposal.md` | the owner's one-dispatcher proposal, verified against `ProjectInputController` |
| `reviews/env-lifecycle-inquiry-assessment.md` | the assessment: `#77` collision, blast radius, the design fork, the question list |
| `reviews/env-and-dispatch-spec-draft.md` | **the deliverable** — a stakeholder-level specification |

The spec draft is the thing to read. The assessment keeps its superseded positions **in place**
rather than rewriting them, because the reasoning that overturned each one is the useful part.

## 3. What the evidence established, and it is worse than the inquiry claimed

- **The console is not sandboxed.** Its environment *is* `_G`. One typed line takes the screen or
  the keyboard, the framework's own bookkeeping is not updated when it happens, and the only
  universal recovery is `Ctrl+Shift+R`, undocumented. Pre-existing: identical at `3256aac`.
- **A run is not a clean start.** The environment reset has exactly one caller — closing a project —
  so `run()` on the open project, and `Ctrl+Alt+R`, reuse the previous run's globals; only
  `run("another")` is clean. This **corrected my own earlier claim** that R2 was already satisfied.
- **`dofile` is literally `loadstring` + call**, wearing a project-scoped file reader: no env
  decision (it runs in `_G` by coincidence, not by construction), no callback policy, and a syntax
  error is reported as *"file does not exist"*.
- **Two `compy` namespace instances exist** — console and project — so two of the namespace's
  members are present at the console and silently inert. Pre-existing at base.
- **`internals/console.md` states the opposite of the code** on `base_env`: it is not write-protected
  (the `table.protect` proxy is discarded — a second site of an already-filed entry), and the
  reset/restart rationale is inverted. **Not corrected** — corpus discipline, below.
- **The parity requirement is already ratified doctrine.** `conventions/code.md`: *"File = console
  equivalence"*, with *"do not use local variables outside their block"* directly above it as its
  fossil. **The inquiry asks for an existing rule to be made true**, which is the strongest framing
  available for the ticket and was found late.

## 4. The collision verdict, which moved once

`#77` needs **no rework to ship**. Its boundary is route plus lifecycle state, not environment
identity — exactly one line in the dispatch path couples the two. Most of what the model changes is
the *reason* behind internals that exist to bridge the environment copy: documentation edits, after
release.

The line moved once, and the successor should carry the moved version: **documentation-only, plus
two pre-release surface decisions.** Neither `compy.input.hooks` nor `compy.before_exit` exists at
the PR base, so settling them now is choosing an API before it is public, not deprecating one.
`before_exit` → `love.quit` additionally needs the veto semantics decided (LÖVE's `love.quit`
aborts the quit; this hook deliberately ignores its return).

## 5. Where the design landed

The owner ruled repeatedly, and each ruling made the model smaller: one shared environment; a
program is a set of claims on interaction rather than a mode; three operations — **load, disarm,
factory reset** — with `run` = reset + load, the reset automatic and disarm automatic on exit.
Nothing guards or rewrites what a user assigns; the framework's machinery is **lifted** into the
layer between the raw event table and the user's slot; restart is the accepted backstop. `suspend`
collapses into disarm-with-memory, `play` is untouched, and the editor turned out to be **host code
that never executes user code at all** — which closed the one corner deferred three times.

The last addition is a suggestion, not part of the minimum: a **managed overlay** beside the raw
slots (`on_draw`, `on_update`, the hook tables), whose advantage is structural — disarm becomes
*detach the overlay* rather than rewriting slot sets.

## 6. Non-obvious points worth carrying

- **Three of my own claims were overturned in-session, all by reading code**: R2 as satisfied, the
  interactive reading as depending on Decision 1's convergence, and containment as what separates
  managed handlers from raw ones. The pattern from session61 holds — *the findings that fail are
  claims, not code.*
- **The owner overruled two designs I proposed** (a guard on the `love` surface; a normalization
  sweep after a load) with the same argument each time: they made loaded code special, which the
  equivalence rule forbids. Both are recorded in place as ruled-against, with reasons.
- **A sub-agent's map was right on every load-bearing claim, and I re-verified each before use.**
  The one item it could not determine — the editor's execution environment — turned out to have the
  answer *"there isn't one"*.
- **Corpus discipline (owner):** all of this stays under `wip/`. Two persistent-corpus corrections
  are identified and **deliberately not made** — `internals/console.md`'s two errors, and the second
  site of the `table.protect` no-op. They are proposals, and they are recorded in the assessment.

## 7. Artifacts

- Track: `session62/track.md` — boot, the interruption, the pivot, the rulings, the wrap
- Seven commits, `44dc1204`..`dedf1b97`, every one touching only `wip/77-new-input-api/`
- **Persistent corpus: untouched.** No production code, no tests, no `doc/` outside `wip/`
