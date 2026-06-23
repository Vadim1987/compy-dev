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
| E9 | **Architect call — commission `M4-0` + confirm the test-first split + resolve the M2-review open design questions** (E14 approved the path). Resolve: (1) the `M4-0` feature-global safety-net spec — its **test-infra feasibility** (can busted drive a project-level input flow via `mock.keystroke`/`EditorSession`?), coverage scope (examples + editor `is_at_limit` block-nav + D-9 coexistence), acceptance criteria; (2) confirm the per-milestone **test-first acceptance step preceding implementation** (M5/M6/M7); (3) M4 black-box vs. escalated (the net makes black-box **safer**); (4) M7 in parallel? **(5) the open design questions surfaced by the M2 human review** ([`M2-human-review.md`](implementation/reviews/M2-human-review.md)): **A1** project-event hooking, **A5** keep-or-refactor the `love.state.user_input` overlay-flag contract, **A6** combo-string serialize-vs-match (**decide before M5**), **A8** the M4-0/test-strategy design + whether the bottom sink should receive `keys_pressed` (**A2**, deferred to m4/m5). **(6) the E20 hand-off** ([`assessment.md`](notes/stakeholder-3-input/assessment.md)): the one open design Q = **combo-tier repeat semantics** (do `handlers[combo]`/`framework_handlers` fire on key-repeats or only fresh presses? — sits next to A6; human-provisional default: handler fires once, `on_key_pressed` fires on repeats); plus `isrepeat` threading (regression undo, M4-0 assert); P1 = M4-0 must not assume event order (no runtime guarantee owed); **P4** = the real leak is **T3 raw-`love.*` global state** (sandbox deep-clones the `love` table but shares leaf C functions, so imperative calls hit real SDL/LÖVE state) crossing run boundaries → **framework snapshot/restore on stop, not a project hook** (crash/force-exit-robust, sandbox-safe; also dissolves the P2 edge-tracking) → parked under A1 as a project-run-lifecycle concern outside #77's keyboard-widget scope. A `before_exit` hook **can** fire on `Ctrl+Esc` (it's framework-invoked code), but is needed only for project-*internal* save/memoize, not global-state restore; narrowed interrogation = confirm T3-global-restore (→ framework) vs internal-save (→ hook); adopt `keyboard`/`maze` as named M4-0/migration targets. Sizing here feeds the E16 recalc. **✓ Done (session 20)** — see [`entrypoints/E9-architect-call.md`](entrypoints/E9-architect-call.md): M4-0 **commissioned** (harness-extension + characterization; infra **feasible** — base is the **raw-handler pattern** per `keys_pressed_spec`, *not* `EditorSession`; add keypress-level driver + textinput/isrepeat emission); test-first **confirmed**; M4 **black-box** (guarded by M4-0); M7 **sequential**; **A6** = keep serialize + scratch-buf, **noop-index** (no `if`) + **return-propagate** (`or`-chain), `__matcher` seam kept; **combo-repeat** = fresh-only via **`handlers[isrepeat][combo]`**, `on_key_pressed` sees repeats; **A5** overlay-flag kept-documented; **A1/P4** two layers — project `before_exit()` hook (enabled-not-enforced, near-term, M6-family) + framework T3 snapshot/restore (guaranteed, postponed); **isrepeat** threaded in M4, M4-0 asserts. | ✓ | E20 ✓ · E11 (soft) | [`entrypoints/E9-architect-call.md`](entrypoints/E9-architect-call.md), `design/spec/M4-0-characterization-net.md`, `implementation/reviews/M2-human-review.md`, `notes/stakeholder-3-input/assessment.md` |
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
| E12 | **Code-review M2, then LLM-reevaluate it.** Done (session 17). *Human* manually code-reviewed M2 (three inline-remark commits on `topics/git`); the LLM reevaluated *incorporating that review* → triage doc [`M2-human-review.md`](implementation/reviews/M2-human-review.md): ~70 remarks classified (`open` A1–A8 / `policy` C1–C2 / `verify` / straight-`fix`), all **6 `verify` checks ran ⇒ M2 code sign-off-clean**, durable fixes landed + every open/ephemeral remark carried as an in-code **`DEFERRED (0.1.0-mN)`** marker. C1 (semver-not-milestones) + C2 (warn-don't-swallow) settled; suite **701** green. Human sign-off loop on M2 **closed**. | ✓ | — | `implementation/reviews/M2-human-review.md` |
| E14 | **Understand & approve the M3→M4 path.** Done (session 12). The human understood and **approved** the path, reframed as the **two-tier test strategy**: a feature-global characterization net (`M4-0`, covering M4+M6, own spec-design cycle) + per-milestone **test-first** acceptance steps preceding implementation. Corrected the revival note's "tests can't precede code" mis-framing (TDD against the spec). Unblocks E9; propagation → E16. | ✓ | — | `notes/talk/two-tier-test-strategy.md`, `notes/talk/m3-revival-tdd-for-m4.md` |
| E15 | **Sanity-check the estimates state & format.** Review the freshly-extracted estimates (E10 output): `estimates.md` + `estimates.versions/version01` + the roadmap **frozen-total / append-only-log** shape — confirm the format is what you want and there are no surprises in the numbers before E11 starts appending to it. *(Operational; off the substantive thread — the human's chosen forward path is E20 → E9.)* | ○ | — | `design/estimates.md`, `design/estimates.versions/`, `design/roadmap.md §Estimates` |
| E20 | **Assess pre-feature input-behavior *pain statements* + two new examples against the design direction.** Done (session 18). **Verdict: design direction holds — validated, not altered; no milestone added/pivoted ⇒ no E11/E16 estimate impact.** Under a human-led *symptoms-not-requirements* reframe, the 4 pains (`compy-input-quirks.md`) collapsed to **one open design Q** + housekeeping for E9: P1 (event-order) = no obligation, only M4-0 test hygiene; P2 (`isrepeat`) = incidental strip (`controller.lua:554`) to thread back + combo-tier repeat semantics (the open Q); P3 (chords) = solved by combo dispatch; P4 (exit hook) = solved-by-dissolution (singleton owns input state), general hook → A1. Examples = M4-0 (`keyboard`) + D-9/M8 migration (`maze`) anchors. **Revalidated clean (session 19)** — see E21 register for the live SR3 carry-list. | ✓ | — | [`notes/stakeholder-3-input/assessment.md`](notes/stakeholder-3-input/assessment.md) |
| E21 | **Operational — maintain the late-input register.** Living index of stakeholder inputs received after the initial session (SR1) + where each is absorbed, so late inputs aren't lost during M4–M8 spec/test refinement and arch calls. **SR2** (round 2) = **fully reincorporated** into design/specs (`ProjectInputController` rename, `show({force=true})`, D-5 horizontal/line `is_at_limit`, `keys_pressed` read-proxy — ✓ landed). **SR3** (round 3) = **resolved at E9** (session 20) — all 6 items decided/parked/landed (combo-repeat + isrepeat + P1 + A6 + T3-park + `keyboard`/`maze` anchors); see the SR3 table + `entrypoints/E9-architect-call.md`. Carried items now flip from at-risk to landed. Estimates-class operational: update when new input arrives or a carried item lands. Not a re-fit (that stays the E2 contingency). | ○ | — | `notes/late-input-register.md` |
| E16 | **Operational — propagate the two-tier test-strategy decision** (settled session 12; see `notes/talk/two-tier-test-strategy.md`). Three parts, to land **atomically after E9** so there's no half-applied state: (1) **roadmap** — retire the M3 tombstone, add **`M4-0`** (feature-global net) + the per-milestone **test-first acceptance step** for M5/M6/M7, repoint cross-refs; (2) **codify the conventions** into `design/agents/process.md` / `sdlc.md` — the `-0` precondition-slice rule and the test-first split; (3) **E11 recalc** — size M4-0 (needs E9's infra answer) + the test steps, recompute the total, write an `estimates.versions/` baseline, append the roadmap log line. Recalc sub-step **depends on E9** (M4-0 sizing hinges on the infra-feasibility outcome). **E9 ✓ (session 20) — now recommended-next:** M4-0 is sized as *harness-extension (3 capabilities) + characterization suite*; codify the `-0` precondition rule + test-first split + the A6/repeat dispatch decisions (ride an adjacent M5 slice — frozen `M5.md` not edited). | ▶ | E9 ✓ · E11 (soft) | `design/roadmap.md`, `design/agents/process.md`, `design/agents/sdlc.md`, `design/estimates.md`, `notes/talk/two-tier-test-strategy.md` |
| E17 | **Operational — MCP-LSP tooling for the agent fleet** *(conceptual assessment; per-agent value stands)*. Per-agent payoff: **reviewer** (Opus, find-references/impact = highest) > **developer** (Sonnet) > read-only **Q&A** (Sonnet/Haiku); **not** the orchestrator. **Architecture pivoted (session 15):** the socat multi-container blueprint is **superseded** by a single human-driven `codeinspect` container (local stdio) — **realized as E18**. **Off the #77 critical path**, operational class like E10/E11. | ○ | — | `notes/talk/mcp-lsp-tooling.md`, `notes/talk/codeinspect-harness.md` |
| E19 | **MCP-LSP adherence — reframe landed; observe during use.** Confirmed (session 16): getting the LSP used is an **adherence**, not capability, problem — MCP was healthy/usable, agent judged it not worth it; the skipped doc-first rule already exists in two rule files. **Reframe authored (session 16):** `orientation.md` MCP/doc nudges moved **token-churn → correctness** (exploratory-grep / known-symbol-LSP / impact-find-refs+grep-backstop / architectural-doc triggers; "you CAN use it when unsure"; docs = right-first-source for architectural/intent Qs). Human's call: **stop tuning, start using.** Remaining = **observe during real use**; decision-time hook (`PreToolUse` on bare-identifier grep) is **contingency only**, build iff it still reverts. Multi-agent shape collapsed to one re-roled agent. | ◐ | E18 (soft) | `notes/talk/mcp-lsp-adherence.md`, `implementation/docker/src/agent/orientation.md` |
| E18 | **Build & verify the `codeinspect` harness** — single-container, human-driven dev/inspection stack: three interchangeable CLIs (`claude` · `cursor-agent` · `agy`), Lua MCP↔LSP (`isaacphi/mcp-language-server` → `lua-language-server`) **over stdio**. Justified as the **human's own comprehension instrument** + CI-matched toolchain, **not** a #77 blocker (E17-class, off critical path). Scaffold drafted + committed under `implementation/docker/`; build fixes landed (Go 1.24, HOST_UID/GID, tmpfs, `/impl` shortcut). **Pending (human, after host disk cleanup):** finish build + smoke-test — LuaLS asset/arch, `--logpath/--metapath` passthrough, watcher→diagnostics. | ◐ | — | `implementation/docker/`, `notes/talk/codeinspect-harness.md` |

## Dependency edges — updated (session 18)

The forward feature path sits behind the **architect call (E9)**, now the recommended-next. The
design-input reassessment (E20) that softly preceded it is **done** — verdict: direction unchanged, so
E9's scope is unshifted (its inputs are merely sharpened). The standing estimate chain remains soft.

- **E20 →(soft) E9 — SATISFIED + REVALIDATED:** reassessment complete; no pain alters the design
  direction. E20's output is now an *input* to E9 (the combo-tier repeat-semantics question +
  `isrepeat`/test-hygiene/A1 items), not a blocker. **Revalidated clean (session 19)** — citations
  verified, hand-off maps without invented scope; two glitch-patches applied (this row's P4 framing +
  assessment `:824`→`:807`). Validation-economics ruling: no requirements re-fit now; `keyboard`/`maze`
  fold in as M4-0 characterization anchors, empirical recheck built into M4-0 (E2 contingency is the
  escape valve). E9 inherits a *sharpened, not reopened* design.
- **E11 →(soft) E9 · E8 · E16** — these reshape **scope/roadmap**, so the estimate-maintenance machinery
  should be *armed* first. (The M4-0-specific recalc still happens **inside E16**, after E9 supplies the
  infra/sizing answer — "E11 soft" = *machinery ready*, not *all numbers final*.)
- **E15 →(soft) E11** — confirm the estimates format before the recurring recalc starts appending.
- **E12 soft-gate on E8 — SATISFIED:** M2 is sign-off-clean (E12 ✓), so building M4→M8 no longer sits
  atop an un-signed-off M2.
- **E9 ✓ (session 20) — architect call held:** M4-0 commissioned + spec written, test-first confirmed,
  M4 black-box, M7 sequential, A6/repeat dispatch decided, A5 kept, A1/T3 parked. Record:
  [`entrypoints/E9-architect-call.md`](entrypoints/E9-architect-call.md). Unblocks **E16**.
- **Net effect:** recommended-next is now **E16** (propagate atomically: roadmap M3→M4-0 + test-first
  steps, codify conventions, E11 recalc sized off M4-0). Then **E8** resumes at M4. E15/E11 are
  operational, runnable anytime off to the side.

## Operational actions (beyond milestones)

Not every entrypoint is a milestone or a feature step. **Operational** entrypoints maintain the
design lifecycle's own artifacts — they recur as the plan evolves rather than closing once. The
estimates pair (**E10** extract, **E11** recurring recalc) is the first of this class; the **late-input
register** (**E21** — track post-SR1 inputs + their absorption) is another. Estimates were formalised
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

- **Doc versioning (C1 — semver-not-milestones):** persistent docs reference **versions**, not
  milestone ids — milestones are a pre-release suffix `-mN` on the single target `0.1.0` (squashed to
  `0.1.0` at release). Markers: *"since 0.1.0-m2"* / *"planned for 0.1.0-m7"*. (To be codified into
  `process.md`/`sdlc.md` via E16.)
- **No silent suppression (C2 — warn-don't-swallow):** any silently-dropped action `Log.warn`s, and
  durable instances are covered by a contract test. Settled session 17.
- **In-code `DEFERRED (0.1.0-mN)` markers:** open/postponed review questions live as greppable
  `-- DEFERRED (0.1.0-mN): … — to be resolved in design session` comments at the code site — never a
  raw `REVIEW`, never silently removed. Keeps intermediary decisions *visibly* intermediary.
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
- **Implementation** — M0 ✅, M1 ✅ (reviewed), M2a ✅. **M2 take-1 ❌**, **M2-01 ✅**, **M2-02 ✅**. **M2 human review closed (E12 ✅, session 17) — code sign-off-clean** (triage: `implementation/reviews/M2-human-review.md`). Forward path: **E14 ✅** (two-tier test strategy) → **E20 ✅** (session 18: pains/examples reassessed — direction unchanged; `notes/stakeholder-3-input/assessment.md`) → **E9 ✅** (session 20: architect call — M4-0 commissioned, test-first confirmed, A6/repeat dispatch + M4-black-box/M7-sequential decided; `entrypoints/E9-architect-call.md`) → **E16** (propagate — *recommended-next*) → **E8** resumes at M4.
- **Sweep gate:** `implementation/technical_debt.md` must be clear (closed or accepted) before #77 ships — **C-2** closed; F-5→M7-01, G-1→M8-01, G-2→M6-01 planned; F-4 accepted; `combo_string`/`gui_k`/path-mismatch + new G-A/G-B/turtle-`Esc` anticipated/needs-investigation.
- **Build continuity vs product BC** — product backwards-compat is **withdrawn**, build-time continuity
  is **in force**; `{M,C,V}` is partly transitional scaffolding (read `notes/talk/build-continuity-vs-product-bc.md`
  before M4).
- See topic `README.md` (two-phase model), `design/README.md` (the chain), and `notes/talk/` for how
  we got here.
