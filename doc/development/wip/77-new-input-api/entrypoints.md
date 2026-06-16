# Feature #77 — Open entrypoints

*Maintained list of actionable next steps for this topic. On session boot, offer
these as a selectable menu (recommended-next first). Keep it current: close
entries when done, add new ones as they open.*

Legend: ▶ recommended next · ○ open · ⏳ blocked (see depends-on) · ✓ done

---

| # | Action | Status | Depends on | Where |
|---|---|---|---|---|
| E1 | **Revalidate the design's convergence.** | ✓ | — | `sessions/.../session02/report.md` |
| E4 | **Establish the design lifecycle's process/rules** — enrolled `design/` as a canonical-SDLC instance: stamped the binding (`design/agents/sdlc.md`) + process doc (`design/agents/process.md`), sliced the spec into **per-milestone specs** (`design/spec/M1…M8.md`), and reshaped `design/` to the canonical shape (status.md dashboard + decision track; notes/ ingest; summaries re-merged; round-history archived; `assessment→context` rename). Outcome: the design lifecycle is **fully canonical in shape**. **Revalidated in session 04** (lossy moves clean, slices correct) — accepted as-is; cleanups deferred to **E5**. Full chain + record in **[`entrypoints/E4-restructure.md`](entrypoints/E4-restructure.md)**. | ✓ | — | `design/agents/`, `design/status.md`, `entrypoints/E4-restructure.md`, `sessions/.../session04/report.md` |
| E6 | **Build the agentic dev image (M0)** — black-box tooling step; prereq for running the suite during M1+. Prompt at [`implementation/prompts/M0.md`](implementation/prompts/M0.md) → installs `just`/`lua5.1`/`luarocks`/`busted`+`luautf8`+`luafilesystem`/`love2d` (per `DEVELOPMENT.md` + CI `package.yml`) **+ Claude Code on board**, as an add-on to the current base. Lives under `implementation/docker/` — **not** a dockerization of the canonical project. Result in [`implementation/outcomes/M0.md`](implementation/outcomes/M0.md). | ▶ | — | `implementation/prompts/M0.md`, `DEVELOPMENT.md` |
| E3 | **Implement M1 (`keys_pressed` table)** — via the **black-box implementation model** (no per-sprint SDLC; see `README.md` → `implementation/`). Prompt at [`implementation/prompts/M1.md`](implementation/prompts/M1.md); hand it to the implementation agent; results land in [`implementation/outcomes/M1.md`](implementation/outcomes/M1.md). Input = [`design/spec/M1.md`](design/spec/M1.md) + `design/spec.md §1`; the agent **commits locally** (Conventional Commits) and **waits for approval**. Slices ready; prompt seeded. Needs **E6** to run the suite during verification. | ○ | E6 (for test-run) | `implementation/prompts/M1.md`, `design/spec/M1.md` |
| E5 | **Apply the E4 revalidation cleanups** (session 04 findings; optional, **non-blocking** — pure consistency tidy on a frozen design). F1: sweep stale bare `decisions.md` refs in live chain docs (`spec.md`, `requirements.md`, `design.md`, `context.md`) → `notes/decisions-record.md`/`status.md`. F2: fix `process.md` §1/§4 `decisions.md`→`status.md` (contradicts §5). F3: narrow-or-sweep the SR/VR "wherever they appear" over-claim. Plus: add `Derived from:` to the 5 pipeline docs **or** document the intentional non-wiring in `sdlc.md`. | ○ | — | `sessions/.../session04/report.md` |
| E2 | ~~Resolve the genuinely-open decisions.~~ **Dissolved by E1.** D-1…D-7 are stakeholder-settled; D-8/D-9/D-10 were ruled **architect's discretion** (proceed now, re-fit later if needed). Collapses to a *contingency*, not an open step: a quick re-fit design round **only if** stakeholders object to D-8/9/10 after seeing implementation. | ✓ | — | `design/decisions.md` |

## Notes for whoever picks this up

- **E1 settled the branch.** The design is **converged** (`session02/report.md`):
  the seven core stakeholder questions (D-1…D-7) carry explicit round-2 stakeholder
  rulings; D-8/D-9/D-10 are architect commitments the owner ruled as discretion.
  Validation chain is at PASS-WITH-NOTES (residue only). This is the *already-converged*
  fast branch — implementation is unblocked.
- **E4 is done (session 03).** Both E1-surfaced cleanups landed: the stale "none
  stakeholder-approved" header is gone (convergence now **derived** from the decision ledger
  in `design/status.md`), and the two "round" axes are disambiguated (**SR** stakeholder vs
  **VR** validation — see `design/agents/process.md` §4). The design lifecycle was also
  reshaped to the **canonical SDLC shape** (see `design/agents/sdlc.md` for the binding).
- **E4 was revalidated (session 04).** E4's output is **sound and accepted as-is** — the lossy
  moves preserved intent and the spec slices are correct. It surfaced consistency residue only
  (stale `decisions.md` refs in live chain docs; a `process.md` internal contradiction; an
  over-claimed SR/VR sweep; 5 pipeline docs missing `Derived from:`). The owner ruled
  **leave-as-findings** → captured as **E5** (optional, non-blocking). Detail:
  `session04/report.md`.
- **The two design outcomes are settled:** design side = converged roadmap + per-milestone
  specs (`design/spec/M1…M8.md`); implementation side = list of commits in this repo, recorded
  per milestone in `implementation/outcomes/MN.md`.
- **Implementation is unmanaged (black-box) by default** — session 05 retired the per-sprint
  SDLC model: implementing a frozen-spec milestone is mechanical, so it runs as a single
  self-contained prompt (`implementation/prompts/MN.md`) with a thin outcome ledger, no SDLC
  chain. A milestone is promoted to a **managed subtopic** only if it proves cognition-heavy
  (e.g. M4 gate removal, M6 boundary model). See `README.md` → `implementation/`.
- **Next is E6 then E3** — build the dev/test image (`implementation/prompts/M0.md`), then hand
  `implementation/prompts/M1.md` to the implementation agent (it can run the suite, commit locally,
  and waits for approval). **E5** (the E4 cleanups) is independent and blocks neither.
- See the topic `README.md` for the two-phase model, `design/README.md` to read the chain,
  `session02/report.md` for the full E1 finding, and `notes/migration/` + `notes/talk/` for how
  we got here.
