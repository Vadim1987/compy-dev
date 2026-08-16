# S43 — which recent sessions were not Claude-run

Owner asked (2026-08-16), after session42's P13 defect, which of the recent
sessions were run by a different agent, walking back from session43 until the
first Claude-authored report.

## Method

Commit trailers. Every Claude-run commit in this repo carries
`Co-Authored-By: Claude ... <noreply@anthropic.com>`; the git author is the owner
in all cases, so authorship is *not* readable from `%an`. Corroborating tell: some
non-Claude commit bodies contain literal `\n` escapes instead of newlines
(`e73388ae`, `c08350e7`, `5b6eebc0`, `f45a2588`, `faedac15`, `c3b74959`,
`56c0c26f`, `230cb32e`).

**Boundary: `a1842a2f`** (2026-08-13 09:31, *"docs(P-17-15): commission a cold
review of the maze migration"*) is the last trailered commit. Everything from
`faedac15` through `b54c0778` is untrailered.

## The run

| Session | Agent | Subject | Code touched |
|---|---|---|---|
| 43 | Claude (this one) | P13 correction | none yet |
| 42 | **not Claude** | P9c test isolation, P13 harmony | `src/harmony/init.lua` + 3 scenarios, 3 test files |
| 41 | **not Claude** | P19 sapper disposition, probe row | one comment in `src/examples/sapper/main.lua` |
| 40 | **not Claude** | P16 paint/turtle adoption | `src/examples/{paint,turtle}/main.lua` |
| 39 | **MIXED** | P-17 maze/draw adoption | Claude through `a1842a2f`; tail (P-17-16, wrap, report) not |
| 38 | **not Claude** | P-18 keyboard, 4 cold passes, 3 reopened batches | nested `keyboard` repo only; no platform code |
| 37 | Claude — **search stops** | P-18-00 design of record | — |

Nested repos confirm the same split: `maze` `da9d1c2` untrailered while
`37b996a`/`bef4258`/`569204e`/`e2dacb0` are Claude; all six recent `keyboard`
commits (`e568961`, `f09f1e7`, `80bca7b`, `1033252`, `d9ecdb0`, `7b0d542`) are
untrailered.

## Re-review value, ranked

1. **session38** — by far the largest untrailered footprint: ~20 commits, four
   cold revalidations, two regressions it both introduced and fixed, and it
   claims upstream parity **"measured, not argued"** via its own parity harness.
   That claim is the one to re-test: session42's defect was exactly a harness
   that modelled a mechanism the system does not have (synchronous `push`), and
   a parity harness with the same kind of fidelity gap would carry its
   conclusions along with it.
2. **session42** — the P13 defect is established (`S43-harmony-p13-timing-finding.md`).
   Its other half, P9c, was read at S43 and looks sound: `table.clone` + in-place
   restore of `love.handlers`, `F.reset()` in `before_each`, test-only.
3. **session39 tail** — `da9d1c2` in `maze`, the Shift+Escape modifier variants.
   Narrow and player-visible.
4. **session40** — paint hooks + turtle's duplicate quit; small, cold-reviewed.
5. **session41** — near-zero code; a comment and ledger entries.
