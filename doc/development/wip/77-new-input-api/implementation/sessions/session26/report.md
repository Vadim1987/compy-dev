# session26 — report

**Commissioned:** wait for the human, then move in coordination. It became the
session that removed the feature's largest piece of self-inflicted complexity
and took the tree to PR-ready.

Suite **904 → 923 / 0 / 0 / 3**, green and stated at every commit. 27 commits.
Nothing pushed, here or in the three nested repos.

## Outcome

**A hallucinated design was found load-bearing and removed.** The owner asked
whether the console route's `forward_*` gate looked like the pre-PIC lockout
surviving. It did — and checking `3256aac` showed worse: the whole
keyboard/pointer split was **this feature's own invention**, not inherited
platform behaviour as Decision 11 claimed. Pre-feature, `set_default_handlers`
is called from exactly two sites and `running → project_open` releases nothing.
`release_keyboard_route` arrived with `386cfe1d`, keyboard-only, and pointer was
then exempted from a release that had not previously existed.

Everything else followed from that. Pointer joined the existing chain rather
than getting a mirror of it; the clicks stopped being a bespoke surface; six
oddly-named functions went; and the error boundary moved to where a route is
entered, which is what made the collapse possible at all.

**Six defects found, four of them ours, all fixed:**

| defect | how it was found |
|---|---|
| A failed project's overlay stayed live and ate keystrokes; re-running swallowed the next `show()` | tracing the owner's question about the gate |
| A failed project's shortcuts, hooks and callbacks outlived it | Decision 11's own teardown invariant |
| A failed project's `before_exit` fired for the **next** project | checking whether it should fire at all |
| `wrap`'s xpcall handler had the wrong arity, so raises in `love.update` and pointer handlers **vanished silently** | asking what else differed between two wrappers |
| pointer hooks survived teardown and blocked the next project's seeding | a row that passed alone and failed in file order |
| `wheelmoved` worked on borrowed wiring | the owner asking what compy does with wheel |

## What the owner ruled

- Three stakeholder-deferred usability items leave the plan — recorded with
  suggested fixes, revisited **after** the PR, so the PR keeps to the ask and
  stakeholders can contest a fix that may have had a reason.
- A certainly-wrong behaviour is **not** preserved on the grounds that changing
  it was never approved, even when pre-feature. This overrode a rule I had
  applied twice and cited back at them.
- Unify pointer completely; `compy.singleclick` retired; `userlove` kept.
- Commit order: docs → tests → code → examples; messages as markdown sections.

## Non-obvious points

- **The failure mode is recorded in the owner's own words**
  (`validation/notes/S26-owner-on-the-failure-mode.md`): an assistant writes
  "currently the system does X", the owner reads *currently* as observed
  behaviour, the assistant meant the design under discussion — including parts
  it had just invented. Second occurrence; the first was the "four-tier" chain,
  still named in two commit subjects.
- **The defence that worked twice: check the PR base.** `git show 3256aac:<file>`
  settled the pointer-lifecycle claim and the `wrap` arity question in minutes,
  and overturned a ratified rationale in the first case.
- **Verifying a sub-agent found a defect of mine**, not of its work:
  `wrap_handler` had been dead for a commit while I had written that it
  "survives". The argument for verifying is not distrust of the agent.
- **Three rows this session were green and blind**, or nearly: one I removed
  (an `inspect` row that passed with its own premise deleted), one whose *name*
  lied about what it proved, and one that characterised the fixture rather than
  the product. Each was caught by asking what the assertion could distinguish.
- **`use_canvas` coverage grew, and nothing shrank.** A project's own
  `love.draw` still runs outside it — which is why handler-drawing is invisible
  for a project with its own draw, and visible for pen-and-paper ones. Verified
  byte-identical to the PR base.

## Deliverables for the PR

- `implementation/pr-description.md` — reviewable from `doc/input_api.md` alone.
- `implementation/pr-commit-messages.md` — one section per commit, apply order.
- `implementation/pr-slices/` — regenerated; 92/92 files covered, all ten apply
  in order, result byte-identical to the tip outside `wip/`.
- `validation/reviews/S26-smoke-test-plan.md` — the part no CI answers.

## Open, and the successor's first business

1. **The owner's smoke test + PR review**, combined by their choice. The plan
   above is what they follow; their feedback is the successor's opening input.
2. **If the feedback is positive:** plan rebasing onto — or merging from —
   upstream, which has moved since `updev`. Not started, not investigated.
3. **Regenerate slices again** if anything changes: they are exact as of
   `264e0c6c` and stale the moment the tree moves.
4. **`wip/77` deletion** — owner-gated, and the phase's formal close-out.

Details: this session's `track.md`, `validation/notes/S26-*`,
`validation/reviews/S26-*`.
