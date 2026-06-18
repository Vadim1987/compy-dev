# Feature #77 — Open entrypoints

*Maintained list of actionable next steps for this topic. On session boot, offer
these as a selectable menu (recommended-next first). Keep it current: close
entries when done, add new ones as they open.*

Legend: ▶ recommended next · ○ open · ⏳ blocked (see depends-on) · ✓ done

---

| # | Action | Status | Depends on | Where |
|---|---|---|---|---|
| E7 | **Close M2 — run M2-02.** The corrective take **M2-01 code was approved**, C-1 + C-2-runtime confirmed, and **M2-02** unit test successfully implemented and reviewed. The C-2 acceptance gap is closed, M2-01 signed off, and E7 closed. | ✓ | — | `implementation/prompts/M2-02-submit-path-test.md`, `design/spec/M2-02-submit-path-test.md` |
| E9 | **Decide on M3/M4 restructuring** — resolve whether to revive M3 as input-path integration tests (a TDD regression net for M4), what its spec and test-infrastructure requirements look like, whether M4 stays black-box or is escalated, and whether M7 runs in parallel. Analysis materialised: `notes/talk/m3-revival-tdd-for-m4.md`. | ▶ | — | `notes/talk/m3-revival-tdd-for-m4.md`, `design/spec/M4.md` |
| E8 | **Continue the roadmap M4 → M8** — commission each milestone's prompt per the black-box model when reached. Adjacent **closure specs already commissioned**: `M6-01-oneshot-snapshot` (rides M6), `M7-01-retarget` (rides M7), `M8-01-dead-text-input` (rides M8). M5 must also weigh the **anticipated** debt (`combo_string` allocation, `gui_k` consumer) in `implementation/technical_debt.md`. M4/M6 may warrant **escalation** to a managed subtopic (integration-heavy). | ⏳ | E9 | `design/spec/M4…M8.md`, `design/roadmap.md` |
| E5 | **Apply the E4 revalidation cleanups** (session 04 findings; optional, **non-blocking** — pure consistency tidy on a frozen design). F1: sweep stale bare `decisions.md` refs in live chain docs → `notes/decisions-record.md`/`status.md`. F2: fix `process.md` §1/§4 `decisions.md`→`status.md`. F3: narrow-or-sweep the SR/VR over-claim. Plus: add `Derived from:` to the 5 pipeline docs **or** document the intentional non-wiring in `sdlc.md`. | ○ | — | `sessions/.../session04/report.md` |
| E6 | **Build the agentic dev image (M0)** — `just`/`lua5.1`/`luarocks`/`busted`+`luautf8`+`luafilesystem`/`love2d` **+ Claude Code** add-on; prereq for running the suite. | ✓ | — | `implementation/outcomes/M0.md` |
| E3 | **Implement M1 (`keys_pressed` table)** + the **M2a** follow-up hygiene — both **landed and reviewed** (M1 ship-it: [`reviews/M1-01.md`](implementation/reviews/M1-01.md)). | ✓ | — | `implementation/outcomes/M1.md`, `reviews/M1-01.md` |
| E4 | **Establish the design lifecycle's process/rules** — `design/` enrolled as a canonical-SDLC instance; per-milestone spec slices; canonical shape. **Revalidated (session 04).** | ✓ | — | `design/agents/`, `entrypoints/E4-restructure.md` |
| E1 | **Revalidate the design's convergence.** | ✓ | — | `sessions/.../session02/report.md` |
| E2 | ~~Resolve the genuinely-open decisions.~~ **Dissolved by E1** (D-1…D-7 stakeholder-settled; D-8/9/10 architect discretion). A *contingency* only: re-fit round **if** stakeholders object after seeing implementation. | ✓ | — | `design/decisions.md` |

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
- **Implementation** — M0 ✅, M1 ✅ (reviewed), M2a ✅. **M2 take-1 ❌**, **M2-01 ✅** (corrective: code approved, C-1/C-2-runtime confirmed), **M2-02 ✅** (test-only: real-submit reprompt unit test closed C-2). Forward path gates through **E9** (M3/M4 restructuring decision) before E8 resumes.
- **Sweep gate:** `implementation/technical_debt.md` must be clear (closed or accepted) before #77 ships — **C-2** closed; F-5→M7-01, G-1→M8-01, G-2→M6-01 planned; F-4 accepted; `combo_string`/`gui_k`/path-mismatch + new G-A/G-B/turtle-`Esc` anticipated/needs-investigation.
- **Build continuity vs product BC** — product backwards-compat is **withdrawn**, build-time continuity
  is **in force**; `{M,C,V}` is partly transitional scaffolding (read `notes/talk/build-continuity-vs-product-bc.md`
  before M4).
- See topic `README.md` (two-phase model), `design/README.md` (the chain), and `notes/talk/` for how
  we got here.
