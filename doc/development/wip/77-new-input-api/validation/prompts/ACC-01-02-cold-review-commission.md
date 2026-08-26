# Review commission — the new input API, as a pull request

You are reviewing a **pull request** for an open-source LÖVE2D project called **compy** (a
kid-oriented programmable handheld/IDE). You are the reviewer on the **stakeholder side**: you did
not write this, you have no stake in it, and your job is to decide whether it does what was asked
and whether you would merge it.

**Everything you need is in this directory. Work only from here.**

```
BRIEF.md      <- this file
spec/         <- what was asked for
slices/       <- the change, as reviewable patches
baseline/     <- the code as it was BEFORE the change
```

---

## Hard rules

1. **Do not read `/repo`, and do not use the `lua-lsp` MCP server if one is offered.** `/repo`
   holds the *landed* state — the answer key. Reviewing against it would tell you what the author
   did, not whether it was right. Your ground truth is `baseline/` plus the patches in `slices/`.
2. **Do not read the whole codebase.** `baseline/platform` is a full application and reading it end
   to end would waste the entire budget and teach you little. Read the patch first; open a baseline
   file **only** when you need to see what a hunk is changing, what a caller expected, or whether a
   claim holds. Targeted `grep` over `baseline/` is the right instrument for "who else calls this".
3. **Verify before asserting.** If you claim something is broken, name the file and the line and
   say what would happen. A reviewer who guesses is worse than one who says "I could not tell".
4. **Distinguish what you could not check** from what you checked and found fine. Say so explicitly.
   You cannot run the code, and there is no device here.

---

## What is in `spec/` — the ask

| file | what it is |
|---|---|
| `01-original-ticket-and-clarification.md` | **verbatim** original ticket + the requester's own clarification. This is the primary source of intent |
| `02-stakeholder-round2-notes.md`, `03-…-structured.md` | a second round of stakeholder input |
| `04-normalized-requirements.md` | the team's normalization of the above into requirements |
| `05-pr-description-DRAFT.md` | the PR description, **a draft dated 2026-08-03** |

**On `05`:** it is old relative to the change and may no longer describe it accurately. **Any
mismatch between the description and the patches is a finding worth reporting** — a PR whose
description has drifted from its diff is a real defect, and this one is going to a stakeholder
audience that will read the description first.

## What is in `slices/` — the change

The PR is cut into orthogonal slices. Letters follow **apply order**: docs → tests → code →
examples.

| slice | contents |
|---|---|
| `1a` | a mechanical repo-wide annotation pass — one line inserted per file. Skim it; it is deliberately one commit so you *can* skim it |
| `1b` | the meaningful part of the generic docs corpus |
| `3a` | the input feature's permanent documentation, including the user-facing guide `doc/input_api.md` |
| `3b` | tests — deliberately placed **before** the code they cover |
| `3c` | a self-contained regression fix (a guard plus its test) |
| `3d` | routing / dispatch core |
| `3e` | the widget surface, the `compy.input.*` singleton, boot provisioning |
| `3f` | model / view / util |
| `3g` | migrations of the **tracked** in-repo examples |
| `4a`, `4b`, `4c` | **the three nested example repositories** — `balloons`, `maze`, `keyboard` |

**About `4a`/`4b`/`4c`.** Those three examples live in **separate repositories** with their own
remotes, and each ships as **its own pull request** landing alongside this one. They are included
so you can see the whole delivery, but judge them as *companion PRs*: their baselines are
`baseline/balloons`, `baseline/maze`, `baseline/keyboard` respectively — **not** the platform
baseline.

**A set is deliberately missing.** The delivery also contains a set of agent-tooling and
contributor-workflow files, which has been withheld from this review as out of scope. Its absence
is intentional; do not treat it as an omission.

## What is in `baseline/`

Clean exports, no version-control history:

- `baseline/platform/` — the application before the change. **This is the diff base for slices
  `1a`–`3g`.**
- `baseline/balloons/`, `baseline/maze/`, `baseline/keyboard/` — bases for `4a`, `4b`, `4c`.

### Where the helping documentation is

Under `baseline/platform/doc/` and `doc/development/` you will find the project's own
documentation — an architecture overview, `internals/` notes on the console, editor and event
dispatch, and conventions. **Use it to orient yourself instead of reading source**, and note that
it describes the **pre-change** system, which is exactly what you want when judging what the change
does to it. The change's own new documentation arrives inside slice `3a`.

---

## What to judge

Work in this order and let the earlier questions dominate the later ones.

1. **Does it answer the ask?** Take `spec/01` — the requester's own words — and walk its requests
   one by one. For each: delivered, partly delivered, not delivered, or delivered as something
   else. Quote the request and name the slice that satisfies it.
2. **Is it simpler and more robust than what it replaces?** That was the stated goal. Compare the
   new surface against the baseline's. A change that adds capability while adding more concepts
   than it removes has a case to answer.
3. **Would you merge it?** Correctness problems, contract holes, things that will break a user of
   the old API, anything a maintainer inherits and regrets. Read `3d`/`3e` most carefully — that is
   where the routing lives.
4. **Is the public surface coherent?** `doc/input_api.md` in slice `3a` is what a project author
   will actually read. Judge it as its audience: can someone build a prompt from it without reading
   the source?
5. **Vocabulary.** Does the change introduce terms a reader must learn that the ask did not require?
   Name any you think are unearned.
6. **Tests.** Slice `3b` lands before the code. Do the tests describe behaviour a stakeholder would
   recognise, or do they describe the implementation?

---

## Output

Write your review to **`REVIEW-OUTPUT.md` in this directory**. Nothing else you produce is kept.

Structure it as:

- **Verdict** — merge / merge with changes / do not merge, in one paragraph, up front.
- **Against the ask** — the walk of `spec/01`, as a table.
- **Findings** — each with severity (blocker / major / minor / nit), the file and line, what
  happens, and why it matters. Ordered most severe first.
- **What I could not check** — be specific and honest.
- **Description accuracy** — how `05-pr-description-DRAFT.md` compares to what you actually found.

Length: as long as the findings require and no longer. A short review with three real blockers
beats a long one that inventories everything. **Do not pad, and do not soften** — this review
exists to find problems while they are still cheap.
