# session47 report — two leaks fixed, and the architecture that makes them impossible

Booted to execute the roadmap. Closed `BUG-01-01`, found and fixed its sibling, ran two cold
reviews, and ended having filed **`ARC-01`** — a structural row that dissolves the defect class both
fixes were patching. **8 commits, suite green at every one (968 → 970), nothing pushed.**

## What was fixed

**`BUG-01-01` — `state.pending` survived a project stop** (`bd2a5d49`). Confirmed before fixing:
`prepare_project_env` runs **once**, at `ConsoleController.new`, so the private `state` behind
`compy.input` has application lifetime. Env cloning does not separate instances — the surface is
metatable-only and `table.clone` copies metatables. A project that called `configure()` while hidden
and stopped without showing left its prompt and text for the next project's first `show()`.

Both triage questions were answered rather than assumed. **Siblings in `state` do not share the
hole** (shortcuts/hooks wiped by name, callbacks re-seeded in place) — which is what kept the fix
small. **No shipped example reaches it** (balloons configures while shown, maze guards with
`is_shown()`), so it was fixed on the merits of a public, documented API path.

The fix moved the store onto the widget beside `callbacks`, which lives there for the same lifetime
reason. **No public surface added** — the alternative, a teardown handle threaded out of the
closure, would have cost one. The debt entry covering the area rested on a false premise (*"rebuilt
per project environment"*) and was corrected separately (`abadf244`); the same false premise turned
out to be restated in the internals guide and was retracted there too (`d5526687`).

**The sibling — the prompt label** (`8a9022ec`). Found by the scoped sweep the owner asked for
(`compy.input` + widget singleton, explicitly *not* the whole codebase). `apply_config` mirrors
`cfg.prompt` onto `model.custom_label` **only when `cfg.prompt` is given**, and nothing ever cleared
it — not `hide()`, not teardown, not `clear_input()`, which clears its neighbour `custom_status` in
the same function. Project A labelled project B's field. The breaking test failed **twice**: the
second failure was the previous spec in the file, which had asserted the absence of that exact
string. Cross-project and cross-spec leakage are one leak.

**10 stores checked, 9 clean.** Table in
[`validation/notes/BUG-01-01-pending-lifetime.md`](../../../validation/notes/BUG-01-01-pending-lifetime.md).

## What was learned, and what it became

The owner named the class: **"a hidden persistent mutable store which pretends to be ephemeral."**
The defect was never *"a table was not cleared"* — it was a store whose real lifetime and apparent
lifetime disagreed, in a place where nothing forced them to be reconciled.

That framing produced **`ARC-01`**: give the project widget a **per-project-run lifetime** so the
class becomes structurally impossible instead of defended-against. The unlock was the owner's
reading of Decision 3 — its NFR forbids allocating **per input session**, for the stated reason of
repeated prompting. **A project run is a far coarser boundary, and was never examined.** Decision 3's
own guards agree: both NFR specs assert identity across *show/hide cycles* and pass unchanged.

## Two cold reviews, and what each was worth

**The `BUG-01-01` fix review (Sonnet): approve.** It walked every run-ending path — more thoroughly
than the author had — and **proved** the test was load-bearing by cherry-picking it onto the pre-fix
commit and watching it fail. Its best contribution was in the judgment half, not the findings:
**"draft" is not merely unratified vocabulary, it is overloaded** — `discard_draft()` means the
*user's* typed content, the hidden-`configure` sense means the *programmer's* staged config, both
carrying a `text` field. Registered as `FIX-02-20`.

**The `ARC-01` second opinion: "sound, but not now."** Its four technical findings hold and are
folded into the row — most valuably, **the seam is `run`, not `open`**, because `restart()` and
Ctrl+T quickswitch bypass open/close entirely, so construct-at-open would leave every restart on a
stale widget. It also correctly required that Decision 3 be **amended, not reinterpreted**, and
corrected "net deletion" to "a wash".

**Its timing verdict was overturned by a base check the owner made and the reviewer did not.** At
`3256aac` the widget was built **per activation** — model, controller and view, fresh on every
`input_text`/`input_code` call. So the singleton is *this feature's own invention*, per-run
allocation is **strictly less** than what shipped before, and the merge argument for deferring was
backwards: ARC-01's merge-sensitive sites are code this feature added and ARC-01 removes, so
deferring means reconciling them against 86 commits of drift **and then deleting them**.

**Second time this phase a base check overturned a verdict.** It keeps not being made by anyone but
the owner.

## Non-obvious points for the successor

- **The `lua-lsp` MCP is DOWN and now fully disconnected.** Its language server died 2026-08-25 on a
  proto parse error; the stale bridge was killed at the owner's request and Claude Code did not
  respawn it. Needs `/mcp` from the owner. **ARC-01 is the highest-value LSP row remaining** — it is
  a "who caches this object" question across 101 test touchpoints.
- **Fable is retired from the workspace guidance** (`7ffac945`) — unavailable on this account; hard
  judgment calls are Opus, and better done in the main session than spawned.
- `reset_config` (a table-driven counterpart to `apply_config`) was the smaller alternative to
  ARC-01. **Dropped rather than built**, because ARC-01 removes the machinery it would have
  organised.
