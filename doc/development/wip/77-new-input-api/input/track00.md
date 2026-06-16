# Round-2 Application Track

*One line per applied step. Source: `impact_outline00.md` (C1–C7).
Started 2026-06-10.*

- [C3] Renamed `ProjectController` → `ProjectInputController` and `src/projectController.lua` → `src/projectInputController.lua` across decisions.md, design.md, spec.md, roadmap.md, assessment.md, summaries/{decisions,design,roadmap,spec}.md (sed, word-safe).
- [C3] Added naming-rationale note (vs `ProjectService`) at design.md §3 `ProjectInputController` component.
- [C1] D-2: changed `show()`-while-active from silent in-place reconfigure to no-op by default + `show({force=true})` opt-in; `configure()` confirmed as the unchanged mid-run live-update path. Updated decisions.md D-2 (+glance row), spec.md §2 show()/§7 edge case, summaries/{decisions,spec}.md, roadmap.md M2 + test-coverage line.
- [C2] D-5 boundary extended: directions now up/down AND left/right; second arg defined as `scope` ('input'|'line'), previously "reserved/undefined v1". Updated decisions.md D-5 (+glance row), spec.md §4, design.md §3 component row + §7 FR-11/FR-12 walkthrough rows, summaries/{decisions,design}.md, requirements.md §5 (marked RESOLVED), roadmap.md M6 (is_at_limit extension + files/risk) + test-coverage line, summaries/roadmap.md M6.
- [C4] keys_pressed proxy widened from iterator-only to read-indexable (read-only): `__index` reads through, `__newindex` blocked. Updated spec.md §1, design.md §3, summaries/spec.md.
- [C5] D-4: added inline gloss defining "the framework's own teardown" (framework-owned middle step of each named chain: cancel/submit structural work, always runs, non-suppressable). decisions.md D-4 question text.
- [C6] D-3: added round-2 scope-ratification note — combo/dispatch layer accepted as an improvement over raw LÖVE pass-through; no further helpers this effort; matcher/`mods`-string stay as future seams. decisions.md D-3.
- [C7] D-7: added round-2 confirmation + forward note (project-context-only; REPL run path expected to converge on project path; no console/editor migration pulled in). decisions.md D-7.
- [C7] Touch scope wording corrected (no separate touch work; covered via existing mouse handlers; not a distinct out-of-scope item). requirements.md §4, design.md §1.
- [Estimates] Updated PERT tables (both with/without LLM) for round-2 delta: M6 +≈2h (boundary `is_at_limit` extension), Test +≈1h (direction/scope cases). New totals: ≈66h (no LLM, was 63), ≈39h (LLM, was 37). C1/C3/C4 absorbed as noise. Updated roadmap.md Estimates + delta notes, summaries/roadmap.md glance, README.md range (~39–66 h).
- [C1/coherence] Updated spec.md §2 access-control note so it remains accurate under block-by-default (cross-subsystem reconfigure now requires `force`; `force` opts past the active-session block, not past ownership).
