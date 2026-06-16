# Feature #77 — Open entrypoints

*Maintained list of actionable next steps for this topic. On session boot, offer
these as a selectable menu (recommended-next first). Keep it current: close
entries when done, add new ones as they open.*

Legend: ▶ recommended next · ○ open · ⏳ blocked (see depends-on) · ✓ done

---

| # | Action | Status | Depends on | Where |
|---|---|---|---|---|
| E1 | **Revalidate the design's convergence.** | ✓ | — | `sessions/.../session02/report.md` |
| E4 | **Establish the design lifecycle's process/rules** (enroll `design/` as SDLC-for-planning / author its method). Now the gating next step: it (a) slices the converged spec into clear **per-milestone specs** — the input sprint01 needs — and (b) absorbs the cleanups E1 surfaced (see notes). | ▶ | — | `notes/migration/process-evaluation.md`, `design/decisions.md` |
| E3 | **Seed `sprint01/`** — fresh SDLC; requirements derived from roadmap milestone 1 + `design/spec.md`; outcome = commits in this repo. Design freeze achieved (E1), so no longer blocked by decisions — but practically needs E4 to produce the sliced milestone spec it consumes. | ○ | E4 (milestone-spec slicing) | `design/roadmap.md`, `design/spec.md` |
| E2 | ~~Resolve the genuinely-open decisions.~~ **Dissolved by E1.** D-1…D-7 are stakeholder-settled; D-8/D-9/D-10 were ruled **architect's discretion** (proceed now, re-fit later if needed). Collapses to a *contingency*, not an open step: a quick re-fit design round **only if** stakeholders object to D-8/9/10 after seeing implementation. | ✓ | — | `design/decisions.md` |

## Notes for whoever picks this up

- **E1 settled the branch.** The design is **converged** (`session02/report.md`):
  the seven core stakeholder questions (D-1…D-7) carry explicit round-2 stakeholder
  rulings; D-8/D-9/D-10 are architect commitments the owner ruled as discretion.
  Validation chain is at PASS-WITH-NOTES (residue only). This is the *already-converged*
  fast branch — implementation is unblocked.
- **E4 carries two cleanups E1 surfaced** (fold in, don't make separate steps):
  1. **Fix the stale `decisions.md` header** — both the `(D-1…D-9)` parenthetical
     (missing D-10) and the "D-2…D-10… none stakeholder-approved" status line, which
     contradicts the file's own body now that round-2 rulings are recorded in it.
  2. **Disambiguate the two "round" axes** — provenance tags conflate the *stakeholder*
     rounds (`input.md` / `input/`) with the *internal validation* rounds (`validation/`),
     both labelled "round 1/round 2". A per-decision status field (ruled? by whom? where?)
     would make convergence **derived/checked** rather than a hand-maintained prose header
     that drifts.
- **The two design outcomes are settled:** design side = converged roadmap + spec;
  implementation side = list of commits in this repo (per sprint).
- See `README.md` for the two-lifecycle model, `session02/report.md` for the full E1
  finding, and `notes/migration/` + `notes/talk/` for how we got here.
