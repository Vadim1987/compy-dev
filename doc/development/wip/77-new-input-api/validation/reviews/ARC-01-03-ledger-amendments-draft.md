# ARC-01-03 — the two ledger amendments, drafted for ratification

_session48, 2026-08-27. **Nothing here is applied.** `doc/development/decisions/input.md` is the
ratified ledger; amending it is an owner ruling. This document holds the exact replacement text so
the ruling is a yes/no on words, not on a summary of them._

**What is being authorized:** the project's input widget is created when a project **run** starts
and destroyed when it stops, instead of living for the whole application. `ARC-01-04` writes that
code; this step is the ledger catching up **first**, because a stakeholder reads the ledger and
because the alternative — arguing that the existing words already allow it — is not honest.

Two decisions are touched, and they are touched differently: **Decision 3 changes**, and
**Decision 7 does not** — only the scope of one word in it needs saying out loud.

---

## Amendment A — Decision 3, a substantive change

Decision 3 currently opens: *"A surface's input widget is **created once at load** and reused across
every session on it — boot-provisioned, never constructed per session."* Per-run creation is not a
reading of that sentence; it is a change to it. The ledger's own convention for this is Decision
11's: a header note naming what was superseded, then a **Decision (as amended)** paragraph.

### Proposed insert, immediately under the `## Decision 3` heading

> **AMENDED IN PART, 2026-08-27.** The **project** widget is created per project **run**, not at
> load. Everything else stands: the console's, the editor's and the search strip's widgets are
> still boot-provisioned, and within a run `show()`/`hide()` are still state flips on one instance,
> never construction and teardown. The NFR below is not withdrawn — it is applied at the boundary
> it actually names.

### Proposed replacement for the **Decision** paragraph

> **Decision (as amended).** A surface's input widget is created **once per lifetime of the surface
> it serves** and reused across every session on it. For the console, the editor and the search
> strip that lifetime is the application, so those three are boot-provisioned. For a project it is
> the **project run**: the widget is constructed when the run starts and destroyed when it stops.
> Projects reach it through the `compy.input.*` surface and never hold the widget object; `show()` /
> `hide()` are state flips on that instance, not construction and teardown.

### Proposed replacement for the **Why** paragraph

> **Why.** A non-functional requirement forbids allocating a fresh object graph **per input
> session** — the device is memory-constrained and the common pattern is repeated prompting.
> Repeated prompting happens *within* a run, so a per-run widget satisfies that requirement in full:
> a project that prompts a hundred times allocates once. The requirement was previously applied one
> boundary wider than it states, and that wider boundary was never examined. A shared-within-the-run
> instance also keeps "hide and bring back with state intact" free — the state is not destroyed
> while the project that owns it is alive — and it is what makes Decision 1 cheap.
>
> **Per-run is strictly less allocation than the system this feature replaced.** At the PR base the
> project's widget was built **per activation** — model, controller and view, fresh on every
> `input_text` / `input_code` call. The application-lifetime singleton is this feature's own
> invention, not inherited behaviour, and it shipped on the same memory-constrained device without
> complaint while doing considerably more allocation than a per-run widget does.
>
> **What it buys.** A store that belongs to a project now *dies with that project*, structurally,
> rather than by a hand-maintained wipe list at teardown. Two cross-project leaks were fixed by
> extending that list, and a third had been missing from it for months.

### Proposed replacement for the first sentence of **Consequence**

> **Consequence.** Four instances exist, not one, and what they share is the widget **code**, not
> the object: the project's (created at the run seam), the console's REPL line
> (`consoleController.lua`), and the editor's input and search strips (`editorController.lua`).

*(The rest of the Consequence paragraph — differing evaluator, capability flags, route, and the
`show()`-on-active no-op — is unchanged.)*

---

## Amendment B — Decision 7, a scope clarification, not a change

Decision 7 freezes *"the identity of each of its three sub-tables (`shortcuts`, `hooks`,
`callbacks`)"*. Under a per-run widget, `compy.input.callbacks` resolves to the current widget's
table, so that identity is per-run rather than per-application.

**The decision itself is unaffected, and that is the point worth stating.** What Decision 7 forbids
is a *project* replacing a sub-table, and its rationale is tamper-resistance. A project exists only
inside its own run, and within a run the identity is constant — so no project can observe the
difference, and nothing the decision protects is weakened. The ledger's convention for exactly this
case is the *"Amended in place"* blockquote.

### Proposed insert, after the **Why** paragraph of Decision 7

> **Amended in place, 2026-08-27 (ARC-01).** "Frozen identity" binds the **project**, not the
> framework. `compy.input.callbacks` **resolves to** the current widget's `callbacks` table
> (owner ruling 2026-07-20, re-made 2026-08-27), and the widget lives for one project run
> (Decision 3, as amended) — so the identity is constant for the whole of the only lifetime a
> project has, and a project cannot observe the resolution. `shortcuts` and `hooks` are the
> surface's own tables and are unchanged. **The decision is unchanged:** the container and all three
> sub-table identities remain unassignable, and every leaf remains writable.

---

## What a reviewer should be able to check in one pass

| claim | where it is verifiable |
|---|---|
| the NFR says *per input session*, not per run | Decision 3's own **Why**, unchanged wording |
| both NFR guards still pass | `input_nfr_mechanism_spec.lua` — identity across show/hide cycles, no model reallocation |
| the base allocated *more* | `3256aac`, `consoleController.lua` — widget built inside the `input()` closure per call |
| no project can observe the resolution | `input_nfr_mechanism_spec.lua`, the three cases added by `ARC-01-02` |
| nothing else in Decision 7 moves | the amendment says so, and `shortcuts`/`hooks` are untouched by `ARC-01` |

## What the PR carries — RULED (owner, 2026-08-27)

**The PR carries only the behaviour.** The amendments stay in the ledger; the description does not
recount them. A stakeholder is told what the software does — a project's input widget lives as long
as the project run does — and is not walked through which internal decision had to be re-worded to
permit it.

This settles the recommendation above (a justification-table line arguing the NFR boundary) in the
narrower direction: **that argument is ledger business, not PR business.** It also fits the
strategic frame, which asks the PR to carry nothing beyond the stakeholders' ask without a one-line
justification — and "the widget stops outliving the project that used it" needs no justification
beyond itself, because the leaks it prevents are the ask.

**Practical consequence for `ARC-01-04` onward:** the behaviour change still has to be visible in the
places a reader *does* have open — the persistent internals guide and the code — per the deviation
rule. Only the PR description is exempt.
