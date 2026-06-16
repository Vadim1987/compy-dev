# Feature #77 — Open entrypoints

*Maintained list of actionable next steps for this topic. On session boot, offer
these as a selectable menu (recommended-next first). Keep it current: close
entries when done, add new ones as they open.*

Legend: ▶ recommended next · ○ open · ⏳ blocked (see depends-on) · ✓ done

---

| # | Action | Status | Depends on | Where |
|---|---|---|---|---|
| E1 | **Revalidate the design's convergence** — reconcile `design/decisions.md` (D-2…D-10) against the round-2 cycle (`design/input/`) + the `design/validation/` reports. Establishes (a) whether the design is *actually* converged or which decisions remain genuinely open, and (b) how the ad-hoc 2-round process behaved (evidence for E4). | ▶ | — | `design/decisions.md`, `design/input/`, `design/validation/` |
| E4 | **Establish the design lifecycle's process/rules** (enroll `design/` as SDLC-for-planning / author its method). Prerequisite for *any further design alteration* — the old process was ad-hoc and may not survive past the 2 existing rounds. | ○ | informed by E1 | `notes/migration/process-evaluation.md` |
| E2 | **Resolve the genuinely-open decisions** (stakeholder approve/veto) → freezes the design outcome. **Resolving _is_ altering the design**, so it must run on an established process, not ad-hoc. | ⏳ | E1 (is it needed?) **+ E4** (process must exist first) | `design/decisions.md` |
| E3 | **Seed `sprint01/`** — fresh SDLC; requirements derived from roadmap milestone 1 + `design/spec.md`; outcome = commits in this repo. | ⏳ | design freeze: **E1 shows converged → go now**, *or* E2 done | `design/roadmap.md`, `design/spec.md` |

## Notes for whoever picks this up

- **E1 is the honest unblock.** The "design not converged / D-2…D-10 unresolved"
  status is currently only the docs' *self-report* (decisions.md header + the
  "pre-built on assumption" notes in spec/roadmap), **not** a verified conclusion —
  and it predates the round-2 + validation work, so it may be stale. E1 is what
  turns that claim into ground truth.
- **The path branches on E1's finding:**
  - *If already converged* → straight to **E3** (seed `sprint01`). E4 stays
    optional/parallel and need not gate coding. This is the fast ASAP path.
  - *If decisions are genuinely open* → they need **E2**, but **resolving them _is_
    altering the design**, and the ad-hoc process (good for 2 rounds) is not a safe
    footing for more. So **E4 must come first** — establish the process, then alter.
    E3 then waits on that design freeze.
- **So E4 is no longer "just parallel."** It gates further design work (E2). It can
  start now (informed by E1's evidence of how the existing rounds behaved), and only
  the *already-converged* branch lets implementation bypass it.
- **`outcome` (implementation side) is settled:** a sprint's outcome = the list of
  commits in this repo. The design side's outcome = the converged roadmap + spec.
- See `README.md` for the two-lifecycle model and `notes/migration/` +
  `notes/talk/` for how we got here.
