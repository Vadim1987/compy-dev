# Feature #77 — Open entrypoints

*Maintained list of actionable next steps for this topic. On session boot, offer
these as a selectable menu (recommended-next first). Keep it current: close
entries when done, add new ones as they open.*

Legend: ▶ recommended next · ○ open · ◐ in progress · ⏳ blocked (hard — see depends-on) · ✓ done

Soft edges (in *Depends on*): `X (soft)` = **soft-block** — prefer-after, not required · `X (soft-gate)` = **proceed-at-risk gate** — skipping leaves silent debt / an approval gap, not a hard stop.

---

| # | Action | Status | Depends on | Where |
|---|---|---|---|---|
| E7 | **Close M2 — run M2-02.** The corrective take **M2-01 code was approved**, C-1 + C-2-runtime confirmed, and **M2-02** unit test successfully implemented and reviewed. The C-2 acceptance gap is closed, M2-01 signed off, and E7 closed. | ✓ | — | `implementation/prompts/M2-02-submit-path-test.md`, `design/spec/M2-02-submit-path-test.md` |
| E9 | **Architect call — commission `M4-0` + confirm the test-first split** (E14 approved the path). Resolve: (1) the `M4-0` feature-global safety-net spec — its **test-infra feasibility** (can busted drive a project-level input flow via `mock.keystroke`/`EditorSession`?), coverage scope (examples + editor `is_at_limit` block-nav + D-9 coexistence), acceptance criteria; (2) confirm the per-milestone **test-first acceptance step preceding implementation** (M5/M6/M7); (3) M4 black-box vs. escalated (the net makes black-box **safer**); (4) M7 in parallel? Sizing here feeds the E16 recalc. | ○ | E11 (soft) | `notes/talk/two-tier-test-strategy.md`, `notes/talk/m3-revival-tdd-for-m4.md`, `design/spec/M4.md` |
| E8 | **Continue the roadmap M4 → M8** — commission each milestone's prompt per the black-box model when reached. Adjacent **closure specs already commissioned**: `M6-01-oneshot-snapshot` (rides M6), `M7-01-retarget` (rides M7), `M8-01-dead-text-input` (rides M8). M5 must also weigh the **anticipated** debt (`combo_string` allocation, `gui_k` consumer) in `implementation/technical_debt.md`. M4/M6 may warrant **escalation** to a managed subtopic (integration-heavy). | ⏳ | E9 · E11 (soft) · E12 (soft-gate) | `design/spec/M4…M8.md`, `design/roadmap.md` |
| E5 | **Apply the E4 revalidation cleanups** (session 04 findings; optional, **non-blocking** — pure consistency tidy on a frozen design). F1: sweep stale bare `decisions.md` refs in live chain docs → `notes/decisions-record.md`/`status.md`. F2: fix `process.md` §1/§4 `decisions.md`→`status.md`. F3: narrow-or-sweep the SR/VR over-claim. Plus: add `Derived from:` to the 5 pipeline docs **or** document the intentional non-wiring in `sdlc.md`. | ○ | — | `sessions/.../session04/report.md` |
| E6 | **Build the agentic dev image (M0)** — `just`/`lua5.1`/`luarocks`/`busted`+`luautf8`+`luafilesystem`/`love2d` **+ Claude Code** add-on; prereq for running the suite. | ✓ | — | `implementation/outcomes/M0.md` |
| E3 | **Implement M1 (`keys_pressed` table)** + the **M2a** follow-up hygiene — both **landed and reviewed** (M1 ship-it: [`reviews/M1-01.md`](implementation/reviews/M1-01.md)). | ✓ | — | `implementation/outcomes/M1.md`, `reviews/M1-01.md` |
| E4 | **Establish the design lifecycle's process/rules** — `design/` enrolled as a canonical-SDLC instance; per-milestone spec slices; canonical shape. **Revalidated (session 04).** | ✓ | — | `design/agents/`, `entrypoints/E4-restructure.md` |
| E1 | **Revalidate the design's convergence.** | ✓ | — | `sessions/.../session02/report.md` |
| E2 | ~~Resolve the genuinely-open decisions.~~ **Dissolved by E1** (D-1…D-7 stakeholder-settled; D-8/9/10 architect discretion). A *contingency* only: re-fit round **if** stakeholders object after seeing implementation. | ✓ | — | `design/decisions.md` |
| E10 | **Operational — extract estimates into a first-class doc.** Done (session 11). Per-milestone PERT moved to `design/estimates.md` (+ `estimates.versions/version01` genesis baseline); `roadmap.md §Estimates` trimmed to the **frozen design-phase total** (historical artifact) + an **append-only total-estimated log** + pointer. Rule `process.md §7` + binding `sdlc.md` amended to the frozen-total/log shape (human add-on: total frozen, recalcs logged not overwritten). | ✓ | — | `design/estimates.md`, `design/roadmap.md`, `design/agents/process.md §7`, `design/agents/sdlc.md` |
| E11 | **Operational — estimate maintenance (recurring, beyond milestones).** Now live (E10 landed). Whenever the milestone set changes (a milestone added or **pivoted** — e.g. `M3-01`) or on periodic review: estimate the new/changed milestone → recalc the total in `estimates.md` → write an `estimates.versions/` baseline (demote-by-freezing the prior latest) → **append one line to the roadmap's total-estimated log** (never touch the frozen design-phase total). Standing action, not a one-off. | ○ | E15 (soft) | `design/estimates.md`, `design/estimates.versions/`, `design/roadmap.md §Estimates`, `design/agents/process.md §7` |
| E13 | **Brief me on the stakeholder input & how it landed.** LLM walks the human through the recent stakeholder feedback (SR1 = `notes/input.md` 2026-06-06; SR2 = `notes/input/stakeholder2_notes.md` 2026-06-10) and **how exactly each point landed across the specs + decision ledger** — explaining/reminding the **meaning** of each change, *not* juggling ref-ids. Orientation that informs E12 and E14. **Done (session 12).** | ✓ | — | `design/notes/input.md`, `design/notes/input/`, `design/status.md` (decision ledger), `design/spec/` |
| E12 | **Code-review M2, then LLM-reevaluate it.** *Human* manually code-reviews the M2 outcome (`M2-01` restore-MVC code + `M2-02` submit-path test) and confirms code-wise approval; **then** the LLM reevaluates the M2 outcomes *incorporating that manual review* (not a fresh re-review). Closes the human sign-off loop on the last completed implementation milestone. | ◐ | — | `implementation/outcomes/M2-01-restore-mvc.md`, `implementation/outcomes/M2-02-submit-path-test.md`, `implementation/reviews/M2-01.md`, `reviews/M2-02-submit-path-test.md` |
| E14 | **Understand & approve the M3→M4 path.** Done (session 12). The human understood and **approved** the path, reframed as the **two-tier test strategy**: a feature-global characterization net (`M4-0`, covering M4+M6, own spec-design cycle) + per-milestone **test-first** acceptance steps preceding implementation. Corrected the revival note's "tests can't precede code" mis-framing (TDD against the spec). Unblocks E9; propagation → E16. | ✓ | — | `notes/talk/two-tier-test-strategy.md`, `notes/talk/m3-revival-tdd-for-m4.md` |
| E15 | **Sanity-check the estimates state & format.** Review the freshly-extracted estimates (E10 output): `estimates.md` + `estimates.versions/version01` + the roadmap **frozen-total / append-only-log** shape — confirm the format is what you want and there are no surprises in the numbers before E11 starts appending to it. | ▶ | — | `design/estimates.md`, `design/estimates.versions/`, `design/roadmap.md §Estimates` |
| E16 | **Operational — propagate the two-tier test-strategy decision** (settled session 12; see `notes/talk/two-tier-test-strategy.md`). Three parts, to land **atomically after E9** so there's no half-applied state: (1) **roadmap** — retire the M3 tombstone, add **`M4-0`** (feature-global net) + the per-milestone **test-first acceptance step** for M5/M6/M7, repoint cross-refs; (2) **codify the conventions** into `design/agents/process.md` / `sdlc.md` — the `-0` precondition-slice rule and the test-first split; (3) **E11 recalc** — size M4-0 (needs E9's infra answer) + the test steps, recompute the total, write an `estimates.versions/` baseline, append the roadmap log line. Recalc sub-step **depends on E9** (M4-0 sizing hinges on the infra-feasibility outcome). | ⏳ | E9 · E11 (soft) | `design/roadmap.md`, `design/agents/process.md`, `design/agents/sdlc.md`, `design/estimates.md`, `notes/talk/two-tier-test-strategy.md` |
| E17 | **Operational — MCP-LSP tooling for the agent fleet** *(conceptual assessment; per-agent value stands)*. Per-agent payoff: **reviewer** (Opus, find-references/impact = highest) > **developer** (Sonnet) > read-only **Q&A** (Sonnet/Haiku); **not** the orchestrator. **Architecture pivoted (session 15):** the socat multi-container blueprint is **superseded** by a single human-driven `codeinspect` container (local stdio) — **realized as E18**. **Off the #77 critical path**, operational class like E10/E11. | ○ | — | `notes/talk/mcp-lsp-tooling.md`, `notes/talk/codeinspect-harness.md` |
| E19 | **MCP-LSP adherence — reframe landed; observe during use.** Confirmed (session 16): getting the LSP used is an **adherence**, not capability, problem — MCP was healthy/usable, agent judged it not worth it; the skipped doc-first rule already exists in two rule files. **Reframe authored (session 16):** `orientation.md` MCP/doc nudges moved **token-churn → correctness** (exploratory-grep / known-symbol-LSP / impact-find-refs+grep-backstop / architectural-doc triggers; "you CAN use it when unsure"; docs = right-first-source for architectural/intent Qs). Human's call: **stop tuning, start using.** Remaining = **observe during real use**; decision-time hook (`PreToolUse` on bare-identifier grep) is **contingency only**, build iff it still reverts. Multi-agent shape collapsed to one re-roled agent. | ◐ | E18 (soft) | `notes/talk/mcp-lsp-adherence.md`, `implementation/docker/src/agent/orientation.md` |
| E18 | **Build & verify the `codeinspect` harness** — single-container, human-driven dev/inspection stack: three interchangeable CLIs (`claude` · `cursor-agent` · `agy`), Lua MCP↔LSP (`isaacphi/mcp-language-server` → `lua-language-server`) **over stdio**. Justified as the **human's own comprehension instrument** + CI-matched toolchain, **not** a #77 blocker (E17-class, off critical path). Scaffold drafted + committed under `implementation/docker/`; build fixes landed (Go 1.24, HOST_UID/GID, tmpfs, `/impl` shortcut). **Pending (human, after host disk cleanup):** finish build + smoke-test — LuaLS asset/arch, `--logpath/--metapath` passthrough, watcher→diagnostics. | ◐ | — | `implementation/docker/`, `notes/talk/codeinspect-harness.md` |

## Dependency edges — restructured (session 14)

The forward feature path now sits behind a **soft estimate-readiness chain** and a **soft M2-approval
gate**. All edges are *soft* — nothing is hard-stopped; they encode preferred order + flag what's at
risk if skipped.

- **E15 →(soft) E11** — confirm the estimates format before the recurring recalc starts appending to it.
- **E11 →(soft) E9 · E8 · E16** — these reshape **scope/roadmap**, so the estimate-maintenance
  machinery should be *armed* first. (The M4-0-specific recalc still happens **inside E16**, after E9
  supplies the infra/sizing answer — "E11 soft" here means *machinery ready*, not *all numbers final*;
  that resolves the apparent circularity with E16's recalc sub-step.)
- **E12 →(soft-gate) E8** — building M4→M8 atop an un-signed-off M2 leaves silent tech debt + an
  approval gap. **E12 is in progress** (human reviewing M2 now).
- **Net effect:** recommended-next shifts **E9 → E15** (with E12 in flight). E9 stays *the* substantive
  feature gate — just soft-behind the estimate chain.

## Operational actions (beyond milestones)

Not every entrypoint is a milestone or a feature step. **Operational** entrypoints maintain the
design lifecycle's own artifacts — they recur as the plan evolves rather than closing once. The
estimates pair (**E10** extract, **E11** recurring recalc) is the first of this class: formalised
as a rule in [`design/agents/process.md`](design/agents/process.md) §7 and bound in
[`design/agents/sdlc.md`](design/agents/sdlc.md). When a milestone is added or pivoted, E11 fires
alongside the milestone work — keep it open as a standing reminder, don't close it after one use.

## How implementation runs now — two planes (read before commissioning)

- **Orchestration plane = the brainlab session (this one).** It commissions implementation prompts,
  authors/adjusts specs (corrective + adjacent closure slices `design/spec/MN-NN-<why>.md`, **never**
  editing the frozen `MN.md`), and **ingests outcome + review to decide** approve / corrective-take /
  escalate. It does **not** write feature code or run the review itself.
- **Execution plane = lightweight sessions outside brainlab**, driven by the human, tiny context
  (`/agents/rules.md` + `/agents/development.md` + one task): **implement** (Sonnet) → commits +
  `outcomes/MN….md`; **review** (Opus) → `reviews/MN-NN.md`.
- Full model: [`notes/talk/implementation-orchestration-model.md`](notes/talk/implementation-orchestration-model.md);
  black-box mechanics: [`implementation/README.md`](implementation/README.md).

## Conventions in force

- **Adjacent specs** (corrective takes, closure slices): `design/spec/MN-NN-<why>.md` — per-milestone
  counter from `01`, short purpose suffix in the filename; in-doc id stays bare `MN-NN`. Corrective
  **prompts and outcomes mirror** the spec filename. The design-time `MN.md` slices stay **frozen**.
- **Debt placement:** `/doc/development/technical_debt.md` holds **persistent** (cross-feature) debt
  only; **#77-interim** debt lives in [`implementation/technical_debt.md`](implementation/technical_debt.md)
  and is **swept or formally accepted before the feature ships**. Closures that are *committed* get an
  adjacent spec; *anticipated/conditional* items stay as ledger notes until a need appears.

## State of play

- **Design** — converged (E1) + canonical lifecycle (E4), both revalidated. Roadmap + per-milestone
  specs `design/spec/M1…M8.md` are the frozen input.
- **Implementation** — M0 ✅, M1 ✅ (reviewed), M2a ✅. **M2 take-1 ❌**, **M2-01 ✅** (corrective: code approved, C-1/C-2-runtime confirmed), **M2-02 ✅** (test-only: real-submit reprompt unit test closed C-2). Forward path: **E14 ✅** (path approved as the two-tier test strategy) → **E9** (architect call: commission `M4-0` + confirm test-first split) → **E16** (propagate decision) → **E8** resumes. (M2 also awaits the human code-review sign-off — **E12**.)
- **Sweep gate:** `implementation/technical_debt.md` must be clear (closed or accepted) before #77 ships — **C-2** closed; F-5→M7-01, G-1→M8-01, G-2→M6-01 planned; F-4 accepted; `combo_string`/`gui_k`/path-mismatch + new G-A/G-B/turtle-`Esc` anticipated/needs-investigation.
- **Build continuity vs product BC** — product backwards-compat is **withdrawn**, build-time continuity
  is **in force**; `{M,C,V}` is partly transitional scaffolding (read `notes/talk/build-continuity-vs-product-bc.md`
  before M4).
- See topic `README.md` (two-phase model), `design/README.md` (the chain), and `notes/talk/` for how
  we got here.
